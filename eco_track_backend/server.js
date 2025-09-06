const express = require('express');
const cors = require('cors');
const fs = require('fs-extra');
const path = require('path');
const { v4: uuidv4 } = require('uuid');
const Database = require('./database');

const app = express();
const PORT = process.env.PORT || 3000;

// Instancia de base de datos
const db = new Database();

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

    // Guardar reporte en base de datos SQLite
    db.insertReport(report);

    // Guardar reporte en archivo JSON (respaldo opcional)
    const reportPath = path.join(reportsDir, `${fullReportId}.json`);
    await fs.writeJson(reportPath, report, { spaces: 2 });

    // Log para monitoreo
    console.log(`📄 Nuevo reporte recibido: ${fullReportId}`);
    console.log(`📍 Ubicación: ${latitude}, ${longitude} (±${accuracy}m)`);
    console.log(`🗂️ Clasificación: ${classification}`);
    console.log(`💾 Guardado en: ${reportPath}`);

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
    
    const report = db.getReport(reportId);
    
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

// Endpoint para estadísticas
app.get('/api/stats', async (req, res) => {
  try {
    const stats = db.getStats();
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

// Servir imágenes estáticamente
app.use('/images', express.static(imagesDir));

// Endpoint para listar todos los reportes (para admin)
app.get('/api/reports', async (req, res) => {
  try {
    const limit = parseInt(req.query.limit) || 100;
    const offset = parseInt(req.query.offset) || 0;
    
    const reports = db.getAllReports(limit, offset);
    
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

// Inicializar base de datos y servidor
(async () => {
  try {
    await db.initialize();
    
    app.listen(PORT, () => {
      console.log(`🌱 EcoTrack Backend API ejecutándose en puerto ${PORT}`);
      console.log(`📊 Health check: http://localhost:${PORT}/health`);
      console.log(`📝 Reportes API: http://localhost:${PORT}/api/reports`);
      console.log(`� Estadísticas: http://localhost:${PORT}/api/stats`);
      console.log(`�📁 Directorio reportes: ${reportsDir}`);
      console.log(`🖼️ Directorio imágenes: ${imagesDir}`);
      console.log(`�️ Base de datos: SQLite (ecotrack.db)`);
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