// Flutter imports:
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

// Project imports:
import '../models/reporte.dart';
import '../services/firestore_service.dart';
import '../colors.dart';
import '../location_service.dart';

/// Real-time reports screen using Firestore streams
///
/// This screen displays environmental reports with real-time updates
/// from Firestore. It replaces the static reports list with a live
/// stream that automatically updates when reports are added, modified,
/// or deleted in the database.
class FirestoreReportsScreen extends StatefulWidget {
  const FirestoreReportsScreen({super.key});

  @override
  State<FirestoreReportsScreen> createState() => _FirestoreReportsScreenState();
}

class _FirestoreReportsScreenState extends State<FirestoreReportsScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  String _selectedStatus = 'all';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: EcoColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Header with filters
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: EcoColors.primary,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(24),
                  bottomRight: Radius.circular(24),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Environmental Reports',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: EcoColors.onPrimary,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Status filter
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildStatusChip('all', 'All Reports'),
                        const SizedBox(width: 8),
                        _buildStatusChip('pending', 'Pending'),
                        const SizedBox(width: 8),
                        _buildStatusChip('received', 'Received'),
                        const SizedBox(width: 8),
                        _buildStatusChip('en_route', 'In Progress'),
                        const SizedBox(width: 8),
                        _buildStatusChip('collected', 'Collected'),
                        const SizedBox(width: 8),
                        _buildStatusChip('completed', 'Completed'),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Reports stream
            Expanded(child: _buildReportsStream()),
          ],
        ),
      ),

      // Floating action button to add new report
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Navigate to camera screen
          Navigator.pushNamed(context, '/camera');
        },
        backgroundColor: EcoColors.secondary,
        child: const Icon(Icons.camera_alt, color: Colors.white),
      ),
    );
  }

  /// Build status filter chip
  Widget _buildStatusChip(String status, String label) {
    final isSelected = _selectedStatus == status;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedStatus = status;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? EcoColors.secondary
              : Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? EcoColors.secondary
                : Colors.white.withOpacity(0.5),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.white,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  /// Build the reports stream widget
  Widget _buildReportsStream() {
    Stream<List<Reporte>> reportsStream;
    final currentUserId = _firestoreService.currentUserId;

    if (_selectedStatus == 'all') {
      reportsStream = _firestoreService.getReportsStream(
        limit: 50,
        userId: currentUserId,
      );
    } else {
      // Convert status string to enum
      ReportStatus? statusEnum;
      switch (_selectedStatus) {
        case 'pending':
          statusEnum = ReportStatus.pending;
          break;
        case 'received':
          statusEnum = ReportStatus.received;
          break;
        case 'en_route':
          statusEnum = ReportStatus.enRoute;
          break;
        case 'collected':
          statusEnum = ReportStatus.collected;
          break;
        case 'completed':
          statusEnum = ReportStatus.completed;
          break;
      }

      if (statusEnum != null) {
        reportsStream = _firestoreService.getReportsByStatus(
          statusEnum,
          userId: currentUserId,
        );
      } else {
        reportsStream = _firestoreService.getReportsStream(
          limit: 50,
          userId: currentUserId,
        );
      }
    }

    return StreamBuilder<List<Reporte>>(
      stream: reportsStream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _buildErrorWidget(snapshot.error.toString());
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingWidget();
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return _buildEmptyWidget();
        }

        final reports = snapshot.data!;
        return _buildReportsList(reports);
      },
    );
  }

  /// Build loading widget
  Widget _buildLoadingWidget() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(EcoColors.primary),
          ),
          SizedBox(height: 16),
          Text(
            'Loading reports...',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  /// Build error widget
  Widget _buildErrorWidget(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: EcoColors.error),
          const SizedBox(height: 16),
          Text(
            'Error loading reports',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: EcoColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            error,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              color: EcoColors.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              setState(() {}); // Trigger rebuild to retry
            },
            style: ElevatedButton.styleFrom(backgroundColor: EcoColors.primary),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  /// Build empty widget
  Widget _buildEmptyWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.inbox_outlined,
            size: 64,
            color: EcoColors.textSecondary,
          ),
          const SizedBox(height: 16),
          Text(
            _selectedStatus == 'all'
                ? 'No reports yet'
                : 'No ${_selectedStatus} reports',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: EcoColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Create your first environmental report using the camera button',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: EcoColors.textSecondary),
          ),
        ],
      ),
    );
  }

  /// Build the reports list
  Widget _buildReportsList(List<Reporte> reports) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: reports.length,
      itemBuilder: (context, index) {
        final report = reports[index];
        return _buildReportCard(report);
      },
    );
  }

  /// Build a small thumbnail for a report, supporting URL or base64 data
  Widget _buildThumbnail(Reporte report, {double size = 60}) {
    Widget placeholder = Container(
      width: size,
      height: size,
      color: EcoColors.surface,
      child: const Icon(Icons.photo_camera, color: EcoColors.textSecondary),
    );

    if (report.fotoUrl.isNotEmpty) {
      return SizedBox(
        width: size,
        height: size,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.network(
            report.fotoUrl,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => placeholder,
          ),
        ),
      );
    }

    if (report.fotoBase64 != null && report.fotoBase64!.isNotEmpty) {
      try {
        final dataUrl = report.fotoBase64!;
        final commaIndex = dataUrl.indexOf(',');
        final base64Part = commaIndex >= 0
            ? dataUrl.substring(commaIndex + 1)
            : dataUrl;
        final bytes = base64Decode(base64Part);
        return SizedBox(
          width: size,
          height: size,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.memory(bytes, fit: BoxFit.cover),
          ),
        );
      } catch (_) {
        return placeholder;
      }
    }

    return placeholder;
  }

  /// Build individual report card
  Widget _buildReportCard(Reporte report) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _showReportDetails(report),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with ID and status
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    report.id,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: EcoColors.textPrimary,
                    ),
                  ),
                  _buildStatusBadge(report.estado),
                ],
              ),

              const SizedBox(height: 12),

              // Report details
              Row(
                children: [
                  _buildThumbnail(report),
                  const SizedBox(width: 16),
                  // Details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          report.clasificacion,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: EcoColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          report.ubicacion,
                          style: const TextStyle(
                            fontSize: 14,
                            color: EcoColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _formatDate(report.createdAt),
                          style: const TextStyle(
                            fontSize: 12,
                            color: EcoColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (report.statusEnum == ReportStatus.pending)
                    _buildEditMenu(report),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEditMenu(Reporte report) {
    return PopupMenuButton<String>(
      onSelected: (value) {
        switch (value) {
          case 'edit_photo':
            _onEditPhoto(report);
            break;
          case 'edit_location':
            _onEditLocation(report);
            break;
        }
      },
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: 'edit_photo',
          child: Row(
            children: [
              Icon(Icons.photo_library),
              SizedBox(width: 8),
              Text('Change photo'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'edit_location',
          child: Row(
            children: [
              Icon(Icons.my_location),
              SizedBox(width: 8),
              Text('Change location'),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _onEditPhoto(Reporte report) async {
    try {
      // Re-check latest status to avoid editing non-pending
      final latest = await FirestoreService().getReport(report.id);
      if (latest == null || latest.statusEnum != ReportStatus.pending) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('This report is no longer editable.')),
          );
        }
        return;
      }

      // Pick image
      // ignore: use_build_context_synchronously
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );
      if (picked == null) return; // user canceled

      final file = File(picked.path);
      final base64Thumb = await FirestoreService().createBase64Thumbnail(file);

      final ok = await FirestoreService().updateReport(report.id, {
        'foto_url': '',
        'foto_base64': base64Thumb,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(ok ? 'Photo updated.' : 'Failed to update photo.'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _onEditLocation(Reporte report) async {
    try {
      // Re-check latest status to avoid editing non-pending
      final latest = await FirestoreService().getReport(report.id);
      if (latest == null || latest.statusEnum != ReportStatus.pending) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('This report is no longer editable.')),
          );
        }
        return;
      }

      // Ask LocationService for a precise location, else let user input
      final result = await LocationService.getCurrentLocation();
      double? lat = result.latitude;
      double? lng = result.longitude;
      double? acc = result.accuracy;

      if (!result.success || result.isLowAccuracy) {
        // ignore: use_build_context_synchronously
        final manual = await showDialog<LocationResult>(
          context: context,
          builder: (_) => const ManualLocationDialog(),
        );
        if (manual == null || !manual.success) return;
        lat = manual.latitude;
        lng = manual.longitude;
        acc = manual.accuracy;
      }

      if (lat == null || lng == null) return;

      final locationStr = LocationService.formatCoordinates(lat, lng);
      final ok = await FirestoreService().updateReport(report.id, {
        'ubicacion': locationStr,
        'location': {'latitude': lat, 'longitude': lng, 'accuracy': acc ?? 0.0},
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              ok ? 'Location updated.' : 'Failed to update location.',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  /// Build status badge
  Widget _buildStatusBadge(String status) {
    Color color;
    switch (status.toLowerCase()) {
      case 'pendiente':
        color = Colors.orange;
        break;
      case 'recibido':
        color = Colors.blue;
        break;
      case 'en recorrido':
        color = Colors.purple;
        break;
      case 'recogido':
        color = Colors.green;
        break;
      case 'finalizado':
        color = Colors.grey;
        break;
      default:
        color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color),
      ),
      child: Text(
        status,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  /// Format date for display
  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 0) {
      return '${difference.inDays} days ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hours ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minutes ago';
    } else {
      return 'Just now';
    }
  }

  /// Show report details dialog
  void _showReportDetails(Reporte report) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Report ${report.id}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Classification: ${report.clasificacion}'),
            Text('Status: ${report.estado}'),
            Text('Location: ${report.ubicacion}'),
            Text('Priority: ${report.prioridad}'),
            Text('Created: ${_formatDate(report.createdAt)}'),
            if (report.deviceInfo != null) Text('Device: ${report.deviceInfo}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
