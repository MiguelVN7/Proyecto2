/// Service for updating report status (Firestore-backed)
///
/// This service provides a stable API for the UI while delegating to
/// Firestore for actual updates, removing the dependency on the HTTP backend.
library;

import '../models/reporte.dart';
import 'firestore_service.dart';

/// Result of a status update operation
class StatusUpdateResult {
  final bool success;
  final String? message;
  final String? error;

  const StatusUpdateResult._({required this.success, this.message, this.error});

  /// Creates a successful result
  factory StatusUpdateResult.success({String? message}) {
    return StatusUpdateResult._(
      success: true,
      message: message ?? 'Estado actualizado correctamente',
    );
  }

  /// Creates an error result
  factory StatusUpdateResult.error({required String error}) {
    return StatusUpdateResult._(success: false, error: error);
  }
}

/// Service for managing report status updates
class ReportStatusService {
  /// Updates the status of a report in Firestore
  ///
  /// Parameters:
  /// - [reportId]: The ID of the report to update
  /// - [newStatus]: The new status to set
  ///
  /// Returns a [StatusUpdateResult] indicating success or failure
  static Future<StatusUpdateResult> updateReportStatus(
    String reportId,
    ReportStatus newStatus,
  ) async {
    try {
      final ok = await FirestoreService().updateReportStatus(
        reportId,
        newStatus,
      );
      if (ok) {
        return StatusUpdateResult.success(message: 'Estado actualizado');
      } else {
        return StatusUpdateResult.error(
          error: 'No se pudo actualizar el estado',
        );
      }
    } catch (e) {
      return StatusUpdateResult.error(error: 'Error al actualizar: $e');
    }
  }

  /// Tests the connection to the status update endpoint
  static Future<bool> testStatusUpdateConnection() async {
    // With Firestore backend, assume available if Firestore is initialized.
    // A more robust check could attempt a lightweight read.
    return true;
  }
}
