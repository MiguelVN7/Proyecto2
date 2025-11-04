// Flutter imports:
import 'dart:io';

// Package imports:
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

// Project imports:
import '../config/api_config.dart';
import '../models/reporte.dart';
import 'firestore_service.dart';

/// Firebase Cloud Messaging service for handling push notifications
///
/// This service manages FCM token registration, notification handling,
/// and provides methods for sending notifications from the backend.
/// It integrates with local notifications for enhanced user experience.
class FCMService {
  static final FCMService _instance = FCMService._internal();
  factory FCMService() => _instance;
  FCMService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  String? _fcmToken;
  bool _isInitialized = false;

  /// Gets the current FCM token
  String? get fcmToken => _fcmToken;

  /// Checks if the service is initialized
  bool get isInitialized => _isInitialized;

  /// Initialize FCM service and configure notifications
  Future<void> initialize() async {
    try {
      debugPrint('🔔 Initializing FCM Service...');

      // Initialize Firebase if not already done
      if (!Firebase.apps.isNotEmpty) {
        await Firebase.initializeApp();
      }

      // Request notification permissions
      await _requestPermissions();

      // Initialize local notifications
      await _initializeLocalNotifications();

      // Get FCM token
      await _getFCMToken();

      // Configure message handlers
      _configureMessageHandlers();

      _isInitialized = true;
      debugPrint('✅ FCM Service initialized successfully');
      debugPrint('📱 FCM Token: $_fcmToken');
    } catch (e) {
      debugPrint('❌ Error initializing FCM Service: $e');
      rethrow;
    }
  }

  /// Request notification permissions from user
  Future<void> _requestPermissions() async {
    debugPrint('🔐 Requesting notification permissions...');

    final settings = await _firebaseMessaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    debugPrint(
      '🔐 Notification permission status: ${settings.authorizationStatus}',
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      debugPrint('✅ User granted notifications permission');
    } else if (settings.authorizationStatus ==
        AuthorizationStatus.provisional) {
      debugPrint('⚠️ User granted provisional notifications permission');
    } else {
      debugPrint('❌ User declined notifications permission');
    }
  }

  /// Initialize local notifications plugin
  Future<void> _initializeLocalNotifications() async {
    debugPrint('📱 Initializing local notifications...');

    const androidSettings = AndroidInitializationSettings(
      '@drawable/ic_notification',
    );
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Create notification channel for Android
    if (Platform.isAndroid) {
      await _createNotificationChannel();
    }

    debugPrint('✅ Local notifications initialized');
  }

  /// Create notification channel for Android
  Future<void> _createNotificationChannel() async {
    const androidChannel = AndroidNotificationChannel(
      'ecotrack_notifications',
      'EcoTrack Notifications',
      description: 'Notifications for waste report status updates',
      importance: Importance.high,
      sound: RawResourceAndroidNotificationSound('notification_sound'),
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(androidChannel);

    debugPrint('✅ Android notification channel created');
  }

  /// Get FCM token and register with backend
  Future<void> _getFCMToken() async {
    try {
      _fcmToken = await _firebaseMessaging.getToken();
      debugPrint('📱 FCM Token obtained: $_fcmToken');

      if (_fcmToken != null) {
        // Always register token in Firestore for a backendless setup
        try {
          await FirestoreService().registerFCMToken(_fcmToken!);
        } catch (e) {
          debugPrint('⚠️ Could not save FCM token in Firestore: $e');
        }

        // Optionally register with HTTP backend if available (non-blocking)
        await _registerTokenWithBackend(_fcmToken!);
      }

      // Listen for token refresh
      _firebaseMessaging.onTokenRefresh.listen((newToken) {
        debugPrint('🔄 FCM Token refreshed: $newToken');
        _fcmToken = newToken;
        _registerTokenWithBackend(newToken);
      });
    } catch (e) {
      debugPrint('❌ Error getting FCM token: $e');
    }
  }

  /// Register FCM token with backend
  Future<void> _registerTokenWithBackend(String token) async {
    try {
      debugPrint('📤 Registering FCM token with backend...');

      final response = await http
          .post(
            Uri.parse('${ApiConfig.apiUrl}/fcm/register'),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: json.encode({
              'fcm_token': token,
              'platform': Platform.operatingSystem,
              'app_version': '1.0.0',
              'device_info': Platform.operatingSystem,
            }),
          )
          .timeout(const Duration(seconds: 3));

      if (response.statusCode == 200) {
        debugPrint('✅ FCM token registered successfully with backend');
      } else {
        debugPrint('⚠️ Failed to register FCM token: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint(
        'ℹ️ Skipping backend FCM registration (backend likely offline): $e',
      );
    }
  }

  /// Configure message handlers for different states
  void _configureMessageHandlers() {
    debugPrint('🔧 Configuring FCM message handlers...');

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('📨 Foreground message received');
      debugPrint('📨 Title: ${message.notification?.title}');
      debugPrint('📨 Body: ${message.notification?.body}');
      debugPrint('📨 Data: ${message.data}');

      _showLocalNotification(message);
    });

    // Handle background message tap
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('📨 Background message tapped');
      debugPrint('📨 Data: ${message.data}');

      _handleNotificationNavigation(message.data);
    });

    // Handle notification when app is terminated
    _firebaseMessaging.getInitialMessage().then((RemoteMessage? message) {
      if (message != null) {
        debugPrint('📨 App opened from terminated state via notification');
        debugPrint('📨 Data: ${message.data}');

        _handleNotificationNavigation(message.data);
      }
    });

    debugPrint('✅ FCM message handlers configured');
  }

  /// Show local notification for foreground messages
  Future<void> _showLocalNotification(RemoteMessage message) async {
    const androidDetails = AndroidNotificationDetails(
      'ecotrack_notifications',
      'EcoTrack Notifications',
      channelDescription: 'Notifications for waste report status updates',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
      icon: '@drawable/ic_notification',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      message.hashCode,
      message.notification?.title ?? 'EcoTrack',
      message.notification?.body ?? 'You have a new notification',
      details,
      payload: json.encode(message.data),
    );
  }

  /// Handle notification tap navigation
  void _onNotificationTapped(NotificationResponse response) {
    debugPrint('👆 Local notification tapped');

    if (response.payload != null) {
      try {
        final data = json.decode(response.payload!) as Map<String, dynamic>;
        _handleNotificationNavigation(data);
      } catch (e) {
        debugPrint('❌ Error parsing notification payload: $e');
      }
    }
  }

  /// Handle navigation based on notification data
  void _handleNotificationNavigation(Map<String, dynamic> data) {
    debugPrint('🧭 Handling notification navigation: $data');

    final reportId = data['report_id'] as String?;
    final notificationType = data['type'] as String?;

    if (reportId != null && notificationType != null) {
      // Store navigation data for the app to handle when ready
      _pendingNavigation = {
        'report_id': reportId,
        'type': notificationType,
        'timestamp': DateTime.now().toIso8601String(),
      };

      debugPrint(
        '🧭 Stored pending navigation for report: $reportId (type: $notificationType)',
      );

      // If we have a navigation callback, use it
      if (_navigationCallback != null) {
        _navigationCallback!(reportId, notificationType);
      }
    }
  }

  // Navigation state management
  Map<String, dynamic>? _pendingNavigation;
  Function(String reportId, String type)? _navigationCallback;

  /// Set navigation callback for handling notification taps
  void setNavigationCallback(Function(String reportId, String type) callback) {
    _navigationCallback = callback;

    // If there's a pending navigation, execute it now
    if (_pendingNavigation != null) {
      final reportId = _pendingNavigation!['report_id'] as String;
      final type = _pendingNavigation!['type'] as String;

      debugPrint('🧭 Executing pending navigation: $reportId ($type)');
      callback(reportId, type);
      _pendingNavigation = null;
    }
  }

  /// Get pending navigation data and clear it
  Map<String, dynamic>? getPendingNavigation() {
    final pending = _pendingNavigation;
    _pendingNavigation = null;
    return pending;
  }

  /// Send test notification (for development)
  Future<void> sendTestNotification() async {
    if (_fcmToken == null) {
      debugPrint('❌ No FCM token available for test notification');
      return;
    }

    try {
      debugPrint('🧪 Sending test notification...');

      final response = await http.post(
        Uri.parse('${ApiConfig.apiUrl}/fcm/test'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode({
          'fcm_token': _fcmToken,
          'title': 'Test Notification',
          'body': 'This is a test notification from EcoTrack',
          'data': {
            'type': 'test',
            'timestamp': DateTime.now().toIso8601String(),
          },
        }),
      );

      if (response.statusCode == 200) {
        debugPrint('✅ Test notification sent successfully');
      } else {
        debugPrint(
          '❌ Failed to send test notification: ${response.statusCode}',
        );
      }
    } catch (e) {
      debugPrint('❌ Error sending test notification: $e');
    }
  }

  /// Unregister FCM token (on logout or app uninstall)
  Future<void> unregisterToken() async {
    if (_fcmToken == null) return;

    try {
      debugPrint('🔄 Unregistering FCM token...');

      final response = await http.delete(
        Uri.parse('${ApiConfig.apiUrl}/fcm/unregister'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode({'fcm_token': _fcmToken}),
      );

      if (response.statusCode == 200) {
        debugPrint('✅ FCM token unregistered successfully');
      }

      await _firebaseMessaging.deleteToken();
      _fcmToken = null;
    } catch (e) {
      debugPrint('❌ Error unregistering FCM token: $e');
    }
  }
}

/// Background message handler (must be top-level function)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();

  debugPrint('📨 Background message received');
  debugPrint('📨 Title: ${message.notification?.title}');
  debugPrint('📨 Body: ${message.notification?.body}');
  debugPrint('📨 Data: ${message.data}');
}

/// Notification types for different report status changes
enum NotificationType {
  reportReceived(
    'report_received',
    'Report Received',
    '✅ Your report has been received and is being processed',
  ),
  reportInProgress(
    'report_in_progress',
    'Collection Started',
    '🚛 Collection team is on route to your location',
  ),
  reportCollected(
    'report_collected',
    'Waste Collected',
    '♻️ Waste has been successfully collected',
  ),
  reportCompleted(
    'report_completed',
    'Report Completed',
    '🎉 Your environmental report has been completed',
  );

  const NotificationType(this.key, this.title, this.defaultMessage);

  final String key;
  final String title;
  final String defaultMessage;

  /// Get notification type from report status
  static NotificationType? fromReportStatus(ReportStatus status) {
    switch (status) {
      case ReportStatus.received:
        return NotificationType.reportReceived;
      case ReportStatus.assigned:
        return NotificationType.reportInProgress;
      case ReportStatus.inProgress:
        return NotificationType.reportInProgress;
      case ReportStatus.completed:
        return NotificationType.reportCompleted;
      case ReportStatus.cancelled:
        return NotificationType.reportCollected;
      case ReportStatus.pending:
        return null; // No notification for pending status
    }
  }
}
