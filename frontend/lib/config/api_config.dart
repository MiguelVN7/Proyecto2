/// API configuration that automatically detects platform and uses appropriate URLs
///
/// This configuration handles the difference between development on
/// different platforms (macOS, Android, iOS) and ensures the correct
/// backend URL is used for each platform.

import 'dart:io';
import 'package:flutter/foundation.dart';

/// API configuration class that provides platform-specific URLs
class ApiConfig {
  // Private constructor to prevent instantiation
  ApiConfig._();

  /// Base URL for the backend API
  ///
  /// Uses localhost for desktop platforms (macOS, Windows, Linux)
  /// Uses network IP for mobile platforms (Android, iOS)
  static String get baseUrl {
    if (kIsWeb) {
      // For web, use localhost
      return 'http://localhost:3000';
    } else if (Platform.isAndroid || Platform.isIOS) {
      // For mobile devices, use network IP (updated for current network)
      return 'http://192.168.1.115:3000';
    } else {
      // For desktop platforms (macOS, Windows, Linux), use localhost
      return 'http://localhost:3000';
    }
  }

  /// API endpoint base URL
  static String get apiUrl => '$baseUrl/api';

  /// Health check endpoint
  static String get healthUrl => '$baseUrl/health';

  /// Reports endpoint
  static String get reportsUrl => '$apiUrl/reports';

  /// Get status update URL for a specific report
  static String statusUrl(String reportId) =>
      '$apiUrl/reports/$reportId/status';

  /// Current platform information for debugging
  static String get platformInfo {
    if (kIsWeb) {
      return 'Web';
    } else if (Platform.isAndroid) {
      return 'Android';
    } else if (Platform.isIOS) {
      return 'iOS';
    } else if (Platform.isMacOS) {
      return 'macOS';
    } else if (Platform.isWindows) {
      return 'Windows';
    } else if (Platform.isLinux) {
      return 'Linux';
    } else {
      return 'Unknown';
    }
  }

  /// Debug information about current configuration
  static Map<String, String> get debugInfo => {
    'platform': platformInfo,
    'baseUrl': baseUrl,
    'apiUrl': apiUrl,
    'healthUrl': healthUrl,
    'reportsUrl': reportsUrl,
  };
}
