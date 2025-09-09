import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

/// A service class that handles environmental report submission and backend communication.
///
/// This service provides functionality to:
/// - Submit environmental reports with photos and location data
/// - Test backend connectivity
/// - Handle photo encoding and data transmission to the API
///
/// The service uses HTTP POST requests to send reports to the backend server
/// and includes proper error handling for network and server issues.
class ReportService {
  /// The base URL for the backend API endpoints.
  static const String baseUrl = 'http://192.168.1.115:3000/api';

  /// Submits an environmental report to the backend server.
  ///
  /// This method takes a photo file and location data, converts the image to Base64,
  /// and sends it along with metadata to the backend API for processing.
  ///
  /// Parameters:
  /// - [imageFile]: The photo file captured by the user
  /// - [latitude]: GPS latitude coordinate
  /// - [longitude]: GPS longitude coordinate
  /// - [accuracy]: GPS accuracy in meters
  /// - [classification]: The waste type classification
  ///
  /// Returns a [ReportSubmissionResult] indicating success or failure.
  ///
  /// Throws no exceptions - all errors are wrapped in the result object.
  static Future<ReportSubmissionResult> submitReport({
    required File imageFile,
    required double latitude,
    required double longitude,
    required double accuracy,
    required String classification,
  }) async {
    try {
      // Convert image to Base64 format
      final bytes = await imageFile.readAsBytes();
      final base64Image = 'data:image/jpeg;base64,${base64Encode(bytes)}';

      // Prepare report data payload
      final reportData = {
        'photo': base64Image,
        'latitude': latitude,
        'longitude': longitude,
        'accuracy': accuracy,
        'classification': classification,
        'timestamp': DateTime.now().toIso8601String(),
        'device_info': Platform.operatingSystem,
      };

      // Send data to backend API
      final response = await http.post(
        Uri.parse('$baseUrl/reports'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode(reportData),
      );

      final responseData = json.decode(response.body);

      if (response.statusCode == 201 && responseData['success'] == true) {
        return ReportSubmissionResult.success(
          reportCode: responseData['report_code'],
          message: responseData['message'],
          timestamp: responseData['timestamp'],
        );
      } else {
        return ReportSubmissionResult.error(
          message: responseData['message'] ?? 'Error sending report',
        );
      }
    } catch (e) {
      return ReportSubmissionResult.error(message: 'Connection error: $e');
    }
  }

  /// Tests the connection to the backend server.
  ///
  /// This method sends a GET request to the health endpoint to verify
  /// that the backend server is running and accessible.
  ///
  /// Returns `true` if the server responds successfully, `false` otherwise.
  ///
  /// The request times out after 5 seconds to prevent long waits.
  static Future<bool> testConnection() async {
    try {
      final response = await http
          .get(
            Uri.parse('http://192.168.1.115:3000/health'),
            headers: {'Accept': 'application/json'},
          )
          .timeout(const Duration(seconds: 5));

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}

/// Represents the result of a report submission operation.
///
/// This class encapsulates the response from the backend after attempting
/// to submit an environmental report. It provides both success and error
/// states with relevant data for each case.
///
/// For successful submissions, it includes:
/// - A unique report code for tracking
/// - Success message from the server
/// - Timestamp of when the report was processed
///
/// For failed submissions, it includes:
/// - Error message describing what went wrong
///
/// Example usage:
/// ```dart
/// final result = await ReportService.submitReport(...);
/// if (result.success) {
///   print('Report submitted with code: ${result.reportCode}');
/// } else {
///   print('Error: ${result.message}');
/// }
/// ```
class ReportSubmissionResult {
  /// Whether the report submission was successful.
  final bool success;

  /// The unique report code assigned by the backend (only for successful submissions).
  final String? reportCode;

  /// Message from the server describing the result or error details.
  final String message;

  /// Timestamp when the report was processed by the backend (only for successful submissions).
  final String? timestamp;

  /// Private constructor to ensure instances are created through named constructors.
  ReportSubmissionResult._({
    required this.success,
    this.reportCode,
    required this.message,
    this.timestamp,
  });

  /// Creates a successful report submission result.
  ///
  /// This factory constructor should be used when the backend successfully
  /// processes and stores the environmental report.
  ///
  /// Parameters:
  /// - [reportCode]: Unique identifier assigned to the report by the backend
  /// - [message]: Success message from the server
  /// - [timestamp]: Optional timestamp of when the report was processed
  factory ReportSubmissionResult.success({
    required String reportCode,
    required String message,
    String? timestamp,
  }) {
    return ReportSubmissionResult._(
      success: true,
      reportCode: reportCode,
      message: message,
      timestamp: timestamp,
    );
  }

  /// Creates an error report submission result.
  ///
  /// This factory constructor should be used when the report submission
  /// fails due to network issues, server errors, or validation problems.
  ///
  /// Parameters:
  /// - [message]: Error message describing what went wrong
  factory ReportSubmissionResult.error({required String message}) {
    return ReportSubmissionResult._(success: false, message: message);
  }
}
