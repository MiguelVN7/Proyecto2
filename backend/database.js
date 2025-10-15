const Database = require('better-sqlite3');
const path = require('path');

class DatabaseManager {
  constructor() {
    this.db = null;
  }

  // Inicializar base de datos
  async initialize() {
    try {
      const dbPath = path.join(__dirname, 'ecotrack.db');
      this.db = new Database(dbPath);
      console.log('✅ Conectado a SQLite database:', dbPath);
      
      this.createTables();
      return true;
    } catch (error) {
      console.error('❌ Error conectando a SQLite:', error.message);
      throw error;
    }
  }

  // Crear tablas si no existen
  createTables() {
    const createReportsTable = `
      CREATE TABLE IF NOT EXISTS reports (
        id TEXT PRIMARY KEY,
        timestamp TEXT NOT NULL,
        latitude REAL NOT NULL,
        longitude REAL NOT NULL,
        accuracy REAL DEFAULT 0,
        classification TEXT NOT NULL,
        device_info TEXT,
        image_path TEXT,
        status TEXT DEFAULT 'received',
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP
      )
    `;

    this.db.exec(createReportsTable);
    console.log('✅ Tabla reports lista');
  }

  // Insertar nuevo reporte
  insertReport(report) {
    const sql = `
      INSERT INTO reports (id, timestamp, latitude, longitude, accuracy, classification, device_info, image_path, status)
      VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
    `;

    const params = [
      report.id,
      report.timestamp,
      report.location.latitude,
      report.location.longitude,
      report.location.accuracy || 0,
      report.classification,
      report.device_info || 'Unknown',
      report.image_path || null,
      report.status || 'received'
    ];

    try {
      const result = this.db.prepare(sql).run(params);
      console.log(`📄 Reporte ${report.id} guardado en SQLite`);
      return result;
    } catch (error) {
      console.error('❌ Error insertando reporte:', error.message);
      throw error;
    }
  }

  // Obtener reporte por ID
  getReport(reportId) {
    const sql = 'SELECT * FROM reports WHERE id = ?';

    try {
      const row = this.db.prepare(sql).get(reportId);

      if (row) {
        return {
          id: row.id,
          timestamp: row.timestamp,
          location: {
            latitude: row.latitude,
            longitude: row.longitude,
            accuracy: row.accuracy
          },
          classification: row.classification,
          device_info: row.device_info,
          image_path: row.image_path,
          status: row.status,
          created_at: row.created_at
        };
      }
      return null;
    } catch (error) {
      console.error('❌ Error obteniendo reporte:', error.message);
      throw error;
    }
  }

  // Listar todos los reportes (con límite y orden)
  getAllReports(limit = 100, offset = 0) {
    const sql = `
      SELECT * FROM reports
      ORDER BY created_at DESC
      LIMIT ? OFFSET ?
    `;

    try {
      const rows = this.db.prepare(sql).all(limit, offset);

      return rows.map(row => ({
        id: row.id,
        timestamp: row.timestamp,
        location: {
          latitude: row.latitude,
          longitude: row.longitude,
          accuracy: row.accuracy
        },
        classification: row.classification,
        device_info: row.device_info,
        image_path: row.image_path,
        status: row.status,
        created_at: row.created_at
      }));
    } catch (error) {
      console.error('❌ Error listando reportes:', error.message);
      throw error;
    }
  }

  // Actualizar estado de reporte
  updateReportStatus(reportId, newStatus, timestamp = null) {
    const sql = `
      UPDATE reports
      SET status = ?, timestamp = COALESCE(?, timestamp)
      WHERE id = ?
    `;

    try {
      const result = this.db.prepare(sql).run(newStatus, timestamp, reportId);

      if (result.changes === 0) {
        throw new Error(`Report with ID ${reportId} not found`);
      }

      console.log(`📄 Estado del reporte ${reportId} actualizado a: ${newStatus}`);
      return result;
    } catch (error) {
      console.error('❌ Error actualizando estado del reporte:', error.message);
      throw error;
    }
  }

  // Obtener estadísticas básicas
  getStats() {
    try {
      const totalSql = 'SELECT COUNT(*) as total FROM reports';
      const classificationSql = `
        SELECT 
          classification,
          COUNT(*) as count
        FROM reports 
        GROUP BY classification
      `;
      
      const totalResult = this.db.prepare(totalSql).get();
      const classificationResults = this.db.prepare(classificationSql).all();
      
      const stats = {
        total_reports: totalResult.total,
        classifications: {}
      };
      
      classificationResults.forEach(row => {
        stats.classifications[row.classification] = row.count;
      });
      
      return stats;
    } catch (error) {
      console.error('❌ Error obteniendo estadísticas:', error.message);
      throw error;
    }
  }

  // Cerrar conexión
  close() {
    if (this.db) {
      this.db.close();
      console.log('SQLite connection closed.');
    }
  }
}

module.exports = DatabaseManager;
