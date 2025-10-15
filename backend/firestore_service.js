const admin = require('firebase-admin');

/**
 * Firestore service for backend operations
 *
 * This service handles Firestore operations on the backend using Firebase Admin SDK.
 * It replaces the SQLite database with cloud-based Firestore for better scalability,
 * real-time updates, and seamless integration with the frontend.
 */
class FirestoreService {
  constructor() {
    this.isInitialized = false;
    this.db = null;
  }

  /**
   * Initialize Firestore service with Firebase Admin SDK
   */
  async initialize() {
    try {
      if (this.isInitialized) {
        console.log('🔥 Firestore Service already initialized');
        return;
      }

      // Use the same Firebase app instance from FCM service if available
      let app;
      try {
        app = admin.app(); // Get default app if it exists
      } catch (error) {
        // Initialize if no app exists
        try {
          const serviceAccount = require('./firebase-service-account.json');
          app = admin.initializeApp({
            credential: admin.credential.cert(serviceAccount),
            projectId: serviceAccount.project_id,
          });
          console.log('🔥 Firebase Admin initialized with service account');
        } catch (fileError) {
          app = admin.initializeApp({
            projectId: process.env.FIREBASE_PROJECT_ID || 'your-project-id',
          });
          console.log('🔥 Firebase Admin initialized with default credentials');
        }
      }

      this.db = admin.firestore();

      // Configure Firestore settings
      this.db.settings({
        ignoreUndefinedProperties: true,
      });

      this.isInitialized = true;
      console.log('✅ Firestore Service initialized successfully');

    } catch (error) {
      console.error('❌ Error initializing Firestore Service:', error.message);
      throw error;
    }
  }

  /**
   * Insert a new report into Firestore
   */
  async insertReport(report) {
    try {
      if (!this.isInitialized) {
        throw new Error('Firestore service not initialized');
      }

      console.log(`📄 Inserting report into Firestore: ${report.id}`);

      // Transform the report data to match Firestore structure
      const firestoreData = {
        id: report.id,
        foto_url: report.image_path || '',
        ubicacion: report.location ? `${report.location.latitude}, ${report.location.longitude}` : '',
        clasificacion: report.classification || '',
        estado: report.status || 'received',
        prioridad: 'Media', // Default priority
        tipo_residuo: report.classification || '',
        location: {
          latitude: report.location?.latitude || 0,
          longitude: report.location?.longitude || 0,
          accuracy: report.location?.accuracy || 0,
        },
        created_at: admin.firestore.Timestamp.fromDate(new Date(report.timestamp || new Date())),
        updated_at: admin.firestore.Timestamp.now(),
        device_info: report.device_info || '',
        user_id: report.user_id || null,
      };

      // Use the report ID as the document ID
      await this.db.collection('reports').doc(report.id).set(firestoreData);

      console.log(`✅ Report ${report.id} inserted into Firestore successfully`);
      return { success: true, id: report.id };

    } catch (error) {
      console.error('❌ Error inserting report into Firestore:', error.message);
      throw error;
    }
  }

  /**
   * Get a report by ID from Firestore
   */
  async getReport(reportId) {
    try {
      if (!this.isInitialized) {
        throw new Error('Firestore service not initialized');
      }

      console.log(`📖 Getting report from Firestore: ${reportId}`);

      const doc = await this.db.collection('reports').doc(reportId).get();

      if (!doc.exists) {
        console.log(`⚠️ Report not found: ${reportId}`);
        return null;
      }

      const data = doc.data();

      // Transform Firestore data back to expected format
      const report = {
        id: doc.id,
        timestamp: data.created_at.toDate().toISOString(),
        location: {
          latitude: data.location.latitude,
          longitude: data.location.longitude,
          accuracy: data.location.accuracy,
        },
        classification: data.clasificacion,
        device_info: data.device_info,
        image_path: data.foto_url,
        status: data.estado,
        created_at: data.created_at.toDate().toISOString(),
        updated_at: data.updated_at.toDate().toISOString(),
      };

      console.log(`✅ Report retrieved from Firestore: ${reportId}`);
      return report;

    } catch (error) {
      console.error('❌ Error getting report from Firestore:', error.message);
      throw error;
    }
  }

  /**
   * Get all reports with pagination
   */
  async getAllReports(limit = 100, offset = 0) {
    try {
      if (!this.isInitialized) {
        throw new Error('Firestore service not initialized');
      }

      console.log(`📋 Getting all reports from Firestore (limit: ${limit}, offset: ${offset})`);

      // Use Firestore pagination with startAfter for better performance
      let query = this.db
        .collection('reports')
        .orderBy('created_at', 'desc')
        .limit(limit);

      // For offset, we need to get the document to start after
      if (offset > 0) {
        const offsetDoc = await this.db
          .collection('reports')
          .orderBy('created_at', 'desc')
          .offset(offset)
          .limit(1)
          .get();

        if (!offsetDoc.empty) {
          query = query.startAfter(offsetDoc.docs[0]);
        }
      }

      const snapshot = await query.get();

      const reports = snapshot.docs.map(doc => {
        const data = doc.data();
        return {
          id: doc.id,
          timestamp: data.created_at.toDate().toISOString(),
          location: {
            latitude: data.location.latitude,
            longitude: data.location.longitude,
            accuracy: data.location.accuracy,
          },
          classification: data.clasificacion,
          device_info: data.device_info,
          image_path: data.foto_url,
          status: data.estado,
          created_at: data.created_at.toDate().toISOString(),
          updated_at: data.updated_at.toDate().toISOString(),
        };
      });

      console.log(`✅ Retrieved ${reports.length} reports from Firestore`);
      return reports;

    } catch (error) {
      console.error('❌ Error getting all reports from Firestore:', error.message);
      throw error;
    }
  }

  /**
   * Update report status in Firestore
   */
  async updateReportStatus(reportId, newStatus, timestamp = null) {
    try {
      if (!this.isInitialized) {
        throw new Error('Firestore service not initialized');
      }

      console.log(`🔄 Updating report status in Firestore: ${reportId} -> ${newStatus}`);

      const updateData = {
        estado: newStatus,
        updated_at: admin.firestore.Timestamp.now(),
      };

      if (timestamp) {
        updateData.timestamp = admin.firestore.Timestamp.fromDate(new Date(timestamp));
      }

      const docRef = this.db.collection('reports').doc(reportId);

      // Check if document exists
      const doc = await docRef.get();
      if (!doc.exists) {
        throw new Error(`Report with ID ${reportId} not found`);
      }

      await docRef.update(updateData);

      console.log(`✅ Report status updated in Firestore: ${reportId} -> ${newStatus}`);
      return { success: true, changes: 1 };

    } catch (error) {
      console.error('❌ Error updating report status in Firestore:', error.message);
      throw error;
    }
  }

  /**
   * Get statistics from Firestore
   */
  async getStats() {
    try {
      if (!this.isInitialized) {
        throw new Error('Firestore service not initialized');
      }

      console.log('📊 Getting statistics from Firestore...');

      // Get total reports count
      const totalQuery = await this.db.collection('reports').count().get();
      const totalReports = totalQuery.data().count;

      // Get reports by classification
      const classificationStats = {};
      const snapshot = await this.db.collection('reports').get();

      snapshot.docs.forEach(doc => {
        const data = doc.data();
        const classification = data.clasificacion || 'Unknown';
        classificationStats[classification] = (classificationStats[classification] || 0) + 1;
      });

      // Get reports by status
      const statusStats = {};
      snapshot.docs.forEach(doc => {
        const data = doc.data();
        const status = data.estado || 'Unknown';
        statusStats[status] = (statusStats[status] || 0) + 1;
      });

      const stats = {
        total_reports: totalReports,
        classifications: classificationStats,
        status_breakdown: statusStats,
        last_updated: new Date().toISOString(),
      };

      console.log('✅ Statistics retrieved from Firestore:', stats);
      return stats;

    } catch (error) {
      console.error('❌ Error getting statistics from Firestore:', error.message);
      throw error;
    }
  }

  /**
   * Delete a report from Firestore
   */
  async deleteReport(reportId) {
    try {
      if (!this.isInitialized) {
        throw new Error('Firestore service not initialized');
      }

      console.log(`🗑️ Deleting report from Firestore: ${reportId}`);

      const docRef = this.db.collection('reports').doc(reportId);

      // Check if document exists
      const doc = await docRef.get();
      if (!doc.exists) {
        throw new Error(`Report with ID ${reportId} not found`);
      }

      await docRef.delete();

      console.log(`✅ Report deleted from Firestore: ${reportId}`);
      return { success: true };

    } catch (error) {
      console.error('❌ Error deleting report from Firestore:', error.message);
      throw error;
    }
  }

  /**
   * Get reports by status
   */
  async getReportsByStatus(status, limit = 50) {
    try {
      if (!this.isInitialized) {
        throw new Error('Firestore service not initialized');
      }

      console.log(`📋 Getting reports by status from Firestore: ${status}`);

      const snapshot = await this.db
        .collection('reports')
        .where('estado', '==', status)
        .orderBy('created_at', 'desc')
        .limit(limit)
        .get();

      const reports = snapshot.docs.map(doc => {
        const data = doc.data();
        return {
          id: doc.id,
          timestamp: data.created_at.toDate().toISOString(),
          location: {
            latitude: data.location.latitude,
            longitude: data.location.longitude,
            accuracy: data.location.accuracy,
          },
          classification: data.clasificacion,
          device_info: data.device_info,
          image_path: data.foto_url,
          status: data.estado,
          created_at: data.created_at.toDate().toISOString(),
        };
      });

      console.log(`✅ Retrieved ${reports.length} reports with status ${status}`);
      return reports;

    } catch (error) {
      console.error('❌ Error getting reports by status from Firestore:', error.message);
      throw error;
    }
  }

  /**
   * Register FCM token in Firestore
   */
  async registerFCMToken(token, userId, metadata = {}) {
    try {
      if (!this.isInitialized) {
        throw new Error('Firestore service not initialized');
      }

      console.log(`📱 Registering FCM token in Firestore: ${token.substring(0, 20)}...`);

      const tokenData = {
        token,
        user_id: userId || 'anonymous',
        platform: metadata.platform || 'unknown',
        app_version: metadata.app_version || '1.0.0',
        device_info: metadata.device_info || 'unknown',
        created_at: admin.firestore.Timestamp.now(),
        updated_at: admin.firestore.Timestamp.now(),
        last_used: admin.firestore.Timestamp.now(),
      };

      // Use token as document ID or generate one
      const docId = userId || token.substring(0, 20);
      await this.db.collection('fcm_tokens').doc(docId).set(tokenData, { merge: true });

      console.log(`✅ FCM token registered in Firestore: ${docId}`);
      return { success: true };

    } catch (error) {
      console.error('❌ Error registering FCM token in Firestore:', error.message);
      throw error;
    }
  }

  /**
   * Get FCM tokens from Firestore
   */
  async getFCMTokens(userId = null) {
    try {
      if (!this.isInitialized) {
        throw new Error('Firestore service not initialized');
      }

      console.log('📱 Getting FCM tokens from Firestore...');

      let query = this.db.collection('fcm_tokens');

      if (userId) {
        query = query.where('user_id', '==', userId);
      }

      const snapshot = await query.get();
      const tokens = snapshot.docs
        .map(doc => doc.data().token)
        .filter(token => token);

      console.log(`✅ Retrieved ${tokens.length} FCM tokens from Firestore`);
      return tokens;

    } catch (error) {
      console.error('❌ Error getting FCM tokens from Firestore:', error.message);
      return [];
    }
  }

  /**
   * Close Firestore connection (cleanup)
   */
  close() {
    if (this.isInitialized) {
      console.log('🔥 Closing Firestore connection...');
      // Firestore connections are managed by Firebase Admin SDK
      // No explicit close needed
      this.isInitialized = false;
    }
  }
}

// Export singleton instance
module.exports = new FirestoreService();