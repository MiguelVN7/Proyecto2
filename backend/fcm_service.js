const admin = require('firebase-admin');

/**
 * Firebase Cloud Messaging service for sending push notifications
 *
 * This service handles FCM token management and notification sending
 * for the EcoTrack application. It integrates with the existing
 * database to manage user tokens and send status update notifications.
 */
class FCMService {
  constructor() {
    this.isInitialized = false;
    this.fcmTokens = new Map(); // In-memory token storage (should be persisted in production)
  }

  /**
   * Initialize Firebase Admin SDK
   *
   * For development, we'll use a service account key file.
   * In production, you should use environment variables or Firebase hosting.
   */
  initialize() {
    try {
      if (this.isInitialized) {
        console.log('🔔 FCM Service already initialized');
        return;
      }

      // For development - you'll need to add your Firebase service account key
      // Download from Firebase Console > Project Settings > Service Accounts
      // Save as 'firebase-service-account.json' in the backend directory

      // Option 1: Using service account file (for development)
      try {
        const serviceAccount = require('./firebase-service-account.json');
        admin.initializeApp({
          credential: admin.credential.cert(serviceAccount),
          projectId: serviceAccount.project_id,
        });
        console.log('🔔 FCM Service initialized with service account');
      } catch (fileError) {
        console.log('ℹ️ Service account file not found, using default credentials');

        // Option 2: Using default credentials (for production/Firebase hosting)
        admin.initializeApp({
          projectId: process.env.FIREBASE_PROJECT_ID || 'your-project-id',
        });
        console.log('🔔 FCM Service initialized with default credentials');
      }

      this.isInitialized = true;
      console.log('✅ FCM Service ready');

    } catch (error) {
      console.error('❌ Error initializing FCM Service:', error.message);
      console.log('ℹ️ FCM notifications will be disabled');
      // Don't throw error - allow app to continue without notifications
    }
  }

  /**
   * Register a new FCM token
   */
  registerToken(token, deviceInfo = {}) {
    if (!token) {
      throw new Error('FCM token is required');
    }

    const tokenData = {
      token,
      platform: deviceInfo.platform || 'unknown',
      appVersion: deviceInfo.app_version || '1.0.0',
      deviceInfo: deviceInfo.device_info || 'unknown',
      registeredAt: new Date().toISOString(),
      lastUsed: new Date().toISOString(),
    };

    this.fcmTokens.set(token, tokenData);
    console.log(`📱 FCM token registered: ${token.substring(0, 20)}...`);
    console.log(`📱 Platform: ${tokenData.platform}, Version: ${tokenData.appVersion}`);

    return tokenData;
  }

  /**
   * Unregister an FCM token
   */
  unregisterToken(token) {
    if (this.fcmTokens.has(token)) {
      this.fcmTokens.delete(token);
      console.log(`🗑️ FCM token unregistered: ${token.substring(0, 20)}...`);
      return true;
    }
    return false;
  }

  /**
   * Get all registered tokens
   */
  getAllTokens() {
    return Array.from(this.fcmTokens.values());
  }

  /**
   * Send notification to specific token
   */
  async sendNotificationToToken(token, notification, data = {}) {
    if (!this.isInitialized) {
      console.log('⚠️ FCM Service not initialized, skipping notification');
      return { success: false, error: 'FCM not initialized' };
    }

    try {
      const message = {
        token,
        notification: {
          title: notification.title,
          body: notification.body,
        },
        data: {
          ...data,
          timestamp: new Date().toISOString(),
        },
        android: {
          notification: {
            icon: 'ic_notification',
            color: '#4CAF50', // EcoColors.primary
            channelId: 'ecotrack_notifications',
            priority: 'high',
          },
        },
        apns: {
          payload: {
            aps: {
              alert: {
                title: notification.title,
                body: notification.body,
              },
              badge: 1,
              sound: 'default',
            },
          },
        },
      };

      const response = await admin.messaging().send(message);
      console.log(`✅ Notification sent successfully: ${response}`);

      // Update last used timestamp
      if (this.fcmTokens.has(token)) {
        const tokenData = this.fcmTokens.get(token);
        tokenData.lastUsed = new Date().toISOString();
        this.fcmTokens.set(token, tokenData);
      }

      return { success: true, messageId: response };

    } catch (error) {
      console.error('❌ Error sending notification:', error.message);

      // Handle invalid token errors
      if (error.code === 'messaging/registration-token-not-registered' ||
          error.code === 'messaging/invalid-registration-token') {
        console.log('🗑️ Removing invalid token:', token.substring(0, 20) + '...');
        this.unregisterToken(token);
      }

      return { success: false, error: error.message };
    }
  }

  /**
   * Send notification to all registered tokens
   */
  async sendNotificationToAll(notification, data = {}) {
    const tokens = Array.from(this.fcmTokens.keys());

    if (tokens.length === 0) {
      console.log('ℹ️ No registered tokens for broadcast notification');
      return { success: false, error: 'No registered tokens' };
    }

    console.log(`📢 Sending notification to ${tokens.length} devices`);

    const results = await Promise.allSettled(
      tokens.map(token => this.sendNotificationToToken(token, notification, data))
    );

    const successful = results.filter(r => r.status === 'fulfilled' && r.value.success).length;
    const failed = results.length - successful;

    console.log(`📊 Notification results: ${successful} sent, ${failed} failed`);

    return {
      success: successful > 0,
      totalSent: successful,
      totalFailed: failed,
      results: results.map(r => r.status === 'fulfilled' ? r.value : { success: false, error: r.reason?.message })
    };
  }

  /**
   * Send report status update notification
   */
  async sendReportStatusNotification(reportId, newStatus, tokens = null) {
    // Define notification content based on status
    const statusNotifications = {
      'received': {
        title: '✅ Report Received',
        body: `Your environmental report ${reportId} has been received and is being processed.`,
        type: 'report_received'
      },
      'en_route': {
        title: '🚛 Collection Started',
        body: `Collection team is on route to your location for report ${reportId}.`,
        type: 'report_in_progress'
      },
      'collected': {
        title: '♻️ Waste Collected',
        body: `Waste has been successfully collected for report ${reportId}.`,
        type: 'report_collected'
      },
      'completed': {
        title: '🎉 Report Completed',
        body: `Your environmental report ${reportId} has been completed. Thank you for helping keep our environment clean!`,
        type: 'report_completed'
      }
    };

    const notificationConfig = statusNotifications[newStatus.toLowerCase()];

    if (!notificationConfig) {
      console.log(`ℹ️ No notification configured for status: ${newStatus}`);
      return { success: false, error: 'Invalid status for notification' };
    }

    const data = {
      report_id: reportId,
      type: notificationConfig.type,
      new_status: newStatus,
    };

    // If specific tokens provided, send to those; otherwise broadcast to all
    if (tokens && tokens.length > 0) {
      console.log(`📤 Sending status notification for ${reportId} to ${tokens.length} specific devices`);

      const results = await Promise.allSettled(
        tokens.map(token => this.sendNotificationToToken(token, notificationConfig, data))
      );

      const successful = results.filter(r => r.status === 'fulfilled' && r.value.success).length;

      return {
        success: successful > 0,
        totalSent: successful,
        totalFailed: results.length - successful
      };

    } else {
      console.log(`📤 Broadcasting status notification for ${reportId} to all devices`);
      return await this.sendNotificationToAll(notificationConfig, data);
    }
  }

  /**
   * Send test notification
   */
  async sendTestNotification(token = null) {
    const notification = {
      title: '🧪 EcoTrack Test',
      body: 'This is a test notification from EcoTrack backend. FCM is working correctly!',
    };

    const data = {
      type: 'test',
      test_id: Math.random().toString(36).substring(7),
    };

    if (token) {
      console.log(`🧪 Sending test notification to specific token: ${token.substring(0, 20)}...`);
      return await this.sendNotificationToToken(token, notification, data);
    } else {
      console.log('🧪 Broadcasting test notification to all devices');
      return await this.sendNotificationToAll(notification, data);
    }
  }

  /**
   * Get FCM service statistics
   */
  getStats() {
    const tokens = this.getAllTokens();
    const platformStats = tokens.reduce((acc, token) => {
      acc[token.platform] = (acc[token.platform] || 0) + 1;
      return acc;
    }, {});

    return {
      totalTokens: tokens.length,
      platformBreakdown: platformStats,
      isInitialized: this.isInitialized,
      lastActivity: tokens.length > 0 ? Math.max(...tokens.map(t => new Date(t.lastUsed).getTime())) : null,
    };
  }
}

// Export singleton instance
module.exports = new FCMService();