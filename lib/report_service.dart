import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class ReportService {
  static const String baseUrl = 'http://192.168.1.115:3000/api';

  static Future<ReportSubmissionResult> submitReport({
    required File imageFile,
    required double latitude,
    required double longitude,
    required double accuracy,
    required String classification,
  }) async {
    try {
      // Convertir imagen a Base64
      final bytes = await imageFile.readAsBytes();
      final base64Image = 'data:image/jpeg;base64,${base64Encode(bytes)}';

      // Preparar datos del reporte
      final reportData = {
        'photo': base64Image,
        'latitude': latitude,
        'longitude': longitude,
        'accuracy': accuracy,
        'classification': classification,
        'timestamp': DateTime.now().toIso8601String(),
        'device_info': Platform.operatingSystem,
      };

      // Enviar al backend
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
          message: responseData['message'] ?? 'Error enviando reporte',
        );
      }
    } catch (e) {
      return ReportSubmissionResult.error(message: 'Error de conexión: $e');
    }
  }

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

class ReportSubmissionResult {
  final bool success;
  final String? reportCode;
  final String message;
  final String? timestamp;

  ReportSubmissionResult._({
    required this.success,
    this.reportCode,
    required this.message,
    this.timestamp,
  });

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

  factory ReportSubmissionResult.error({required String message}) {
    return ReportSubmissionResult._(success: false, message: message);
  }
}
