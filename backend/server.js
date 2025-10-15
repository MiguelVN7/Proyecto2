const express = require('express');
const cors = require('cors');
const fs = require('fs-extra');
const path = require('path');
const { v4: uuidv4 } = require('uuid');
const firestoreService = require('./firestore_service');
const fcmService = require('./fcm_service');

const app = express();
const PORT = process.env.PORT || 3000;

// Firestore service instance
const db = firestoreService;

// Middleware
app.use(cors());
app.use(express.json({ limit: '50mb' })); // Para imágenes base64 grandes
app.use(express.urlencoded({ limit: '50mb', extended: true }));

// Crear directorio para reportes si no existe
const reportsDir = path.join(__dirname, 'reports');
const imagesDir = path.join(__dirname, 'images');
fs.ensureDirSync(reportsDir);
fs.ensureDirSync(imagesDir);

// Endpoint de salud
app.get('/health', (req, res) => {
  res.json({ 
    status: 'OK', 
    message: 'EcoTrack Backend API funcionando correctamente',
    timestamp: new Date().toISOString(),
    storage_mode: 'sqlite',
    database: 'ecotrack.db'
  });
});

// Endpoint principal: Recibir reportes
app.post('/api/reports', async (req, res) => {
  try {
    const {
      photo,
      latitude,
      longitude,
      accuracy,
      classification,
      timestamp,
      device_info
    } = req.body;

    // Validar datos requeridos
    if (!photo || !latitude || !longitude || !classification) {
      return res.status(400).json({
        success: false,
        message: 'Faltan datos requeridos: photo, latitude, longitude, classification'
      });
    }

    // Generar código único del reporte
    const reportId = uuidv4().split('-')[0].toUpperCase(); // Ej: A1B2C3D4
    const fullReportId = `ECO-${reportId}`;
    
    // Procesar imagen base64
    let imagePath = null;
    if (photo.startsWith('data:image')) {
      const base64Data = photo.replace(/^data:image\/\w+;base64,/, '');
      const imageExtension = photo.match(/data:image\/(\w+);/)?.[1] || 'jpg';
      const imageName = `${fullReportId}.${imageExtension}`;
      imagePath = path.join(imagesDir, imageName);
      
      await fs.writeFile(imagePath, base64Data, 'base64');
    }

    // Crear objeto del reporte
    const report = {
      id: fullReportId,
      timestamp: timestamp || new Date().toISOString(),
      location: {
        latitude: parseFloat(latitude),
        longitude: parseFloat(longitude),
        accuracy: parseFloat(accuracy) || 0
      },
      classification,
      device_info: device_info || 'Unknown',
      image_path: imagePath ? `/images/${path.basename(imagePath)}` : null,
      status: 'received',
      created_at: new Date().toISOString()
    };

    // Guardar reporte en Firestore
    await db.insertReport(report);

    // Guardar reporte en archivo JSON (respaldo opcional)
    const reportPath = path.join(reportsDir, `${fullReportId}.json`);
    await fs.writeJson(reportPath, report, { spaces: 2 });

    // Log para monitoreo
    console.log(`📄 Nuevo reporte recibido: ${fullReportId}`);
    console.log(`📍 Ubicación: ${latitude}, ${longitude} (±${accuracy}m)`);
    console.log(`🗂️ Clasificación: ${classification}`);
    console.log(`💾 Guardado en: ${reportPath}`);

    // Send notification for new report received (optional - for admin notifications)
    try {
      const notificationResult = await fcmService.sendReportStatusNotification(fullReportId, 'received');
      if (notificationResult.success) {
        console.log(`📤 Report received notification sent: ${notificationResult.totalSent} devices`);
      }
    } catch (notificationError) {
      console.error('❌ Error sending report received notification:', notificationError.message);
      // Don't fail the report submission if notification fails
    }

    // Respuesta exitosa
    res.status(201).json({
      success: true,
      message: 'Reporte recibido exitosamente',
      report_code: fullReportId,
      timestamp: new Date().toISOString(),
      data: {
        id: report.id,
        location: report.location,
        classification: report.classification,
        status: report.status
      }
    });

  } catch (error) {
    console.error('❌ Error procesando reporte:', error);
    res.status(500).json({
      success: false,
      message: 'Error interno del servidor',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
});

// Endpoint para consultar reportes (opcional)
app.get('/api/reports/:reportId', async (req, res) => {
  try {
    const { reportId } = req.params;
    
    const report = await db.getReport(reportId);
    
    if (!report) {
      return res.status(404).json({
        success: false,
        message: 'Reporte no encontrado'
      });
    }
    
    res.json({
      success: true,
      report
    });
  } catch (error) {
    console.error('Error consultando reporte:', error);
    res.status(500).json({
      success: false,
      message: 'Error consultando reporte'
    });
  }
});

// Endpoint para actualizar estado de reporte
app.patch('/api/reports/:reportId/status', async (req, res) => {
  try {
    const { reportId } = req.params;
    const { status, timestamp } = req.body;

    // Validar datos requeridos
    if (!status) {
      return res.status(400).json({
        success: false,
        message: 'Estado requerido (status)'
      });
    }

    // Validar estados permitidos
    const allowedStatuses = ['pending', 'received', 'en_route', 'collected', 'completed'];
    if (!allowedStatuses.includes(status.toLowerCase().replace(' ', '_'))) {
      return res.status(400).json({
        success: false,
        message: 'Estado no válido. Estados permitidos: ' + allowedStatuses.join(', ')
      });
    }

    // Actualizar estado en Firestore
    const updateTimestamp = timestamp || new Date().toISOString();
    await db.updateReportStatus(reportId, status, updateTimestamp);

    console.log(`🔄 Estado actualizado: ${reportId} -> ${status}`);

    // Send push notification for status update
    try {
      const notificationResult = await fcmService.sendReportStatusNotification(reportId, status);
      if (notificationResult.success) {
        console.log(`📤 Status notification sent for ${reportId}: ${notificationResult.totalSent} devices`);
      } else {
        console.log(`⚠️ Status notification failed for ${reportId}: ${notificationResult.error}`);
      }
    } catch (notificationError) {
      console.error('❌ Error sending status notification:', notificationError.message);
      // Don't fail the status update if notification fails
    }

    res.json({
      success: true,
      message: 'Estado actualizado correctamente',
      data: {
        reportId,
        newStatus: status,
        timestamp: updateTimestamp
      }
    });

  } catch (error) {
    console.error('❌ Error actualizando estado:', error);

    if (error.message.includes('not found')) {
      return res.status(404).json({
        success: false,
        error: 'Reporte no encontrado'
      });
    }

    res.status(500).json({
      success: false,
      error: 'Error interno del servidor',
      message: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
});

// Endpoint para estadísticas
app.get('/api/stats', async (_req, res) => {
  try {
    const stats = await db.getStats();
    res.json({
      success: true,
      stats
    });
  } catch (error) {
    console.error('Error obteniendo estadísticas:', error);
    res.status(500).json({
      success: false,
      message: 'Error obteniendo estadísticas'
    });
  }
});

// FCM Endpoints

// Register FCM token
app.post('/api/fcm/register', async (req, res) => {
  try {
    const { fcm_token, platform, app_version, device_info } = req.body;

    if (!fcm_token) {
      return res.status(400).json({
        success: false,
        message: 'FCM token is required'
      });
    }

    const tokenData = fcmService.registerToken(fcm_token, {
      platform,
      app_version,
      device_info,
    });

    console.log(`📱 FCM token registered from ${platform || 'unknown'}`);

    res.json({
      success: true,
      message: 'FCM token registered successfully',
      data: {
        token_id: fcm_token.substring(0, 20) + '...',
        registered_at: tokenData.registeredAt,
      }
    });

  } catch (error) {
    console.error('❌ Error registering FCM token:', error);
    res.status(500).json({
      success: false,
      message: 'Error registering FCM token',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
});

// Unregister FCM token
app.delete('/api/fcm/unregister', async (req, res) => {
  try {
    const { fcm_token } = req.body;

    if (!fcm_token) {
      return res.status(400).json({
        success: false,
        message: 'FCM token is required'
      });
    }

    const removed = fcmService.unregisterToken(fcm_token);

    if (removed) {
      console.log(`🗑️ FCM token unregistered`);
      res.json({
        success: true,
        message: 'FCM token unregistered successfully'
      });
    } else {
      res.status(404).json({
        success: false,
        message: 'FCM token not found'
      });
    }

  } catch (error) {
    console.error('❌ Error unregistering FCM token:', error);
    res.status(500).json({
      success: false,
      message: 'Error unregistering FCM token',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
});

// Send test notification
app.post('/api/fcm/test', async (req, res) => {
  try {
    const { fcm_token, title, body, data } = req.body;

    let result;
    if (fcm_token) {
      // Send to specific token
      const notification = {
        title: title || '🧪 EcoTrack Test',
        body: body || 'Test notification from EcoTrack backend'
      };
      result = await fcmService.sendNotificationToToken(fcm_token, notification, data || {});
    } else {
      // Broadcast test notification
      result = await fcmService.sendTestNotification();
    }

    if (result.success) {
      res.json({
        success: true,
        message: 'Test notification sent successfully',
        data: result
      });
    } else {
      res.status(500).json({
        success: false,
        message: 'Failed to send test notification',
        error: result.error
      });
    }

  } catch (error) {
    console.error('❌ Error sending test notification:', error);
    res.status(500).json({
      success: false,
      message: 'Error sending test notification',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
});

// Get FCM statistics
app.get('/api/fcm/stats', async (_req, res) => {
  try {
    const stats = fcmService.getStats();
    res.json({
      success: true,
      stats
    });
  } catch (error) {
    console.error('❌ Error getting FCM stats:', error);
    res.status(500).json({
      success: false,
      message: 'Error getting FCM statistics',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
});

// Servir imágenes estáticamente
app.use('/images', express.static(imagesDir));

// Endpoint para listar todos los reportes (para admin)
app.get('/api/reports', async (req, res) => {
  try {
    const limit = parseInt(req.query.limit) || 100;
    const offset = parseInt(req.query.offset) || 0;
    
    const reports = await db.getAllReports(limit, offset);
    
    res.json({
      success: true,
      count: reports.length,
      limit,
      offset,
      reports: reports.map(report => ({
        id: report.id,
        timestamp: report.timestamp,
        classification: report.classification,
        status: report.status,
        location: report.location
      }))
    });
  } catch (error) {
    console.error('Error listando reportes:', error);
    res.status(500).json({
      success: false,
      message: 'Error listando reportes'
    });
  }
});

// Inicializar Firestore y servidor
(async () => {
  try {
    await db.initialize();

    // Initialize FCM service
    fcmService.initialize();

    app.listen(PORT, '0.0.0.0', () => {
      console.log(`🌱 EcoTrack Backend API ejecutándose en puerto ${PORT}`);
      console.log(`📊 Health check: http://localhost:${PORT}/health`);
      console.log(`📝 Reportes API: http://localhost:${PORT}/api/reports`);
      console.log(`📊 Estadísticas: http://localhost:${PORT}/api/stats`);
      console.log(`📁 Directorio reportes: ${reportsDir}`);
      console.log(`🖼️ Directorio imágenes: ${imagesDir}`);
      console.log(`🔥 Base de datos: Firestore (cloud-based)`);
      console.log(`🌐 Accesible desde la red en: http://192.168.1.115:${PORT}`);
    });
  } catch (error) {
    console.error('❌ Error inicializando aplicación:', error);
    process.exit(1);
  }
})();

// Manejar cierre graceful
process.on('SIGINT', () => {
  console.log('\n🔄 Cerrando servidor...');
  db.close();
  process.exit(0);
});