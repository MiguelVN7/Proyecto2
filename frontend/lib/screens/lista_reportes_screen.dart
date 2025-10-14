<<<<<<< HEAD
// Se crea una pantalla para listar los reportes con filtros

import 'package:flutter/material.dart';
import '../models/reporte.dart';

class ListaReportesScreen extends StatefulWidget {
  final List<Reporte> reportes;
=======
/// Screen for displaying and filtering environmental reports.
///
/// This screen provides a comprehensive list view of all submitted environmental reports
/// with advanced filtering capabilities. Users can filter reports by:
/// - Status (Pending, In Progress, Completed)
/// - Priority level (High, Medium, Low)
/// - Waste type (Plastic, Organic, Glass, etc.)
///
/// Each report is displayed as a card showing the photo, classification,
/// location, and current status information.

// Flutter imports:
import 'dart:convert';
import 'package:flutter/material.dart';

// Project imports:
import '../colors.dart';
import '../models/reporte.dart';
import '../services/report_status_service.dart';

/// Reports list screen widget with filtering capabilities.
///
/// Displays environmental reports in a scrollable list format with
/// dropdown filters for status, priority, and waste type. The screen
/// automatically updates the display when filter criteria change.
class ListaReportesScreen extends StatefulWidget {
  /// List of reports to display and filter.
  final List<Reporte> reportes;

  /// Creates a reports list screen with the provided reports data.
>>>>>>> origin/main
  const ListaReportesScreen({super.key, required this.reportes});

  @override
  State<ListaReportesScreen> createState() => _ListaReportesScreenState();
}

<<<<<<< HEAD
class _ListaReportesScreenState extends State<ListaReportesScreen> {
  String? estado;
  String? prioridad;
  String? tipoResiduo;
  // Mapa para guardar el estado seleccionado de cada reporte
  final Map<String, String> estadoBoton = {};

  @override
  Widget build(BuildContext context) {
    var filtrados = widget.reportes.where((r) {
      if (estado != null && r.estado != estado) return false;
      if (prioridad != null && r.prioridad != prioridad) return false;
      if (tipoResiduo != null && r.tipoResiduo != tipoResiduo) return false;
      return true;
    }).toList();

    return Column(
      children: [
        // Filtros
        Row(
          children: [
            DropdownButton<String>(
              hint: const Text('Estado'),
              value: estado,
              items: ['Pendiente', 'En proceso', 'Completado']
                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                  .toList(),
              onChanged: (v) => setState(() => estado = v),
            ),
            DropdownButton<String>(
              hint: const Text('Prioridad'),
              value: prioridad,
              items: ['Alta', 'Media', 'Baja']
                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                  .toList(),
              onChanged: (v) => setState(() => prioridad = v),
            ),
            DropdownButton<String>(
              hint: const Text('Tipo'),
              value: tipoResiduo,
              items: ['Plástico', 'Orgánico', 'Vidrio']
                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                  .toList(),
              onChanged: (v) => setState(() => tipoResiduo = v),
            ),
          ],
        ),
        Expanded(
          child: ListView.builder(
            itemCount: filtrados.length,
            itemBuilder: (context, i) {
              final r = filtrados[i];
              // Estado actual del botón para este reporte
              final estadoActual = estadoBoton[r.id] ?? 'Recibido';
              return Card(
                child: ListTile(
                  leading: Image.network(r.fotoUrl, width: 50, height: 50, fit: BoxFit.cover),
                  title: Text(r.clasificacion),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${r.ubicacion}\n${r.estado} - ${r.prioridad} - ${r.tipoResiduo}'),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Text('Estado: '),
                          DropdownButton<String>(
                            value: estadoActual,
                            items: const [
                              DropdownMenuItem(value: 'Recibido', child: Text('Recibido')),
                              DropdownMenuItem(value: 'En recorrido', child: Text('En recorrido')),
                              DropdownMenuItem(value: 'Recogido', child: Text('Recogido')),
                            ],
                            onChanged: (nuevoEstado) {
                              if (nuevoEstado != null) {
                                setState(() {
                                  estadoBoton[r.id] = nuevoEstado;
                                });
                              }
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
=======
/// State class for ListaReportesScreen managing filters and UI updates.
///
/// Handles the filtering logic for reports based on user-selected criteria
/// and manages the dropdown filter states. The filtered results are
/// automatically recalculated when filter values change.
class _ListaReportesScreenState extends State<ListaReportesScreen> {
  /// Currently selected status filter (null means no filter applied).
  String? estado;

  /// Currently selected priority filter (null means no filter applied).
  String? prioridad;

  /// Currently selected waste type filter (null means no filter applied).
  String? tipoResiduo;

  /// Local copy of reports that can be modified
  late List<Reporte> _reportes;

  /// Set to track reports currently being updated
  final Set<String> _updatingReports = <String>{};

  @override
  void initState() {
    super.initState();
    _reportes = List<Reporte>.from(widget.reportes);
  }

  @override
  Widget build(BuildContext context) {
    // Apply filters to the reports list (using local copy)
    final filteredReports = _reportes.where((reporte) {
      if (estado != null && reporte.estado != estado) return false;
      if (prioridad != null && reporte.prioridad != prioridad) return false;
      if (tipoResiduo != null && reporte.tipoResiduo != tipoResiduo)
        return false;
      return true;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reports'),
        backgroundColor: EcoColors.primary,
        foregroundColor: EcoColors.onPrimary,
      ),
      body: Column(
        children: [
          // Filter section with dropdown buttons
          _buildFilterSection(),
          // Reports list section
          Expanded(child: _buildReportsList(filteredReports)),
        ],
      ),
    );
  }

  /// Builds the filter section with dropdown buttons for status, priority, and type.
  ///
  /// Contains three dropdown buttons allowing users to filter reports by:
  /// - Status (Pending, In Progress, Completed)
  /// - Priority (High, Medium, Low)
  /// - Waste Type (Plastic, Organic, Glass)
  Widget _buildFilterSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: EcoColors.surface,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(16),
          bottomRight: Radius.circular(16),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Status filter dropdown
          Expanded(
            child: _buildDropdownFilter(
              hint: 'Status',
              value: estado,
              items: ['Pending', 'In Progress', 'Completed'],
              onChanged: (value) => setState(() => estado = value),
            ),
          ),
          const SizedBox(width: 8),
          // Priority filter dropdown
          Expanded(
            child: _buildDropdownFilter(
              hint: 'Priority',
              value: prioridad,
              items: ['High', 'Medium', 'Low'],
              onChanged: (value) => setState(() => prioridad = value),
            ),
          ),
          const SizedBox(width: 8),
          // Waste type filter dropdown
          Expanded(
            child: _buildDropdownFilter(
              hint: 'Type',
              value: tipoResiduo,
              items: ['Plastic', 'Organic', 'Glass', 'Metal', 'Paper'],
              onChanged: (value) => setState(() => tipoResiduo = value),
            ),
          ),
        ],
      ),
    );
  }

  /// Builds a reusable dropdown filter widget.
  ///
  /// Creates a styled dropdown button with the provided configuration.
  /// Automatically handles null values and provides a clear visual design.
  Widget _buildDropdownFilter({
    required String hint,
    required String? value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        border: Border.all(color: EcoColors.grey300),
        borderRadius: BorderRadius.circular(8),
        color: EcoColors.background,
      ),
      child: DropdownButton<String>(
        hint: Text(
          hint,
          style: TextStyle(
            color: EcoColors.onSurface.withOpacity(0.7),
            fontSize: 12,
          ),
        ),
        value: value,
        isExpanded: true,
        underline: const SizedBox(),
        style: TextStyle(color: EcoColors.onSurface, fontSize: 12),
        items: [
          // Add a "Clear" option
          DropdownMenuItem<String>(
            value: null,
            child: Text(
              'All',
              style: TextStyle(
                color: EcoColors.secondary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          // Add the actual filter options
          ...items.map(
            (item) => DropdownMenuItem(value: item, child: Text(item)),
          ),
        ],
        onChanged: onChanged,
      ),
    );
  }

  /// Builds the reports list section.
  ///
  /// Creates a scrollable list of report cards displaying each report's
  /// information including photo, classification, location, and status.
  Widget _buildReportsList(List<Reporte> filteredReports) {
    if (filteredReports.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filteredReports.length,
      itemBuilder: (context, index) {
        final reporte = filteredReports[index];
        return _buildReportCard(reporte);
      },
    );
  }

  /// Builds an empty state widget when no reports match the filters.
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 64,
            color: EcoColors.secondary.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'No reports found',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: EcoColors.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try adjusting your filter criteria',
            style: TextStyle(
              fontSize: 14,
              color: EcoColors.onSurface.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              setState(() {
                estado = null;
                prioridad = null;
                tipoResiduo = null;
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: EcoColors.secondary,
              foregroundColor: EcoColors.onPrimary,
            ),
            child: const Text('Clear Filters'),
          ),
        ],
      ),
    );
  }

  /// Builds a single report card widget.
  ///
  /// Creates a card displaying the report's photo, classification, location,
  /// and status with appropriate styling and error handling for images.
  Widget _buildReportCard(Reporte reporte) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Report photo with error handling
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                width: 60,
                height: 60,
                child: _buildReportImage(reporte),
              ),
            ),
            const SizedBox(width: 12),
            // Report information
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Classification title
                  Text(
                    reporte.clasificacion,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Location
                  Text(
                    reporte.ubicacion,
                    style: TextStyle(
                      fontSize: 14,
                      color: EcoColors.onSurface.withOpacity(0.7),
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Status update section
                  Row(
                    children: [
                      // Status dropdown
                      Expanded(flex: 2, child: _buildStatusDropdown(reporte)),
                      const SizedBox(width: 8),
                      // Priority chip
                      _buildStatusChip(
                        reporte.prioridad,
                        _getPriorityColor(reporte.prioridad),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build image widget supporting URL or base64 data URLs
  Widget _buildReportImage(Reporte reporte) {
    final placeholder = Container(
      color: EcoColors.grey100,
      child: Icon(
        Icons.image_not_supported,
        color: EcoColors.secondary,
        size: 30,
      ),
    );

    if (reporte.fotoUrl.isNotEmpty) {
      return Image.network(
        reporte.fotoUrl,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => placeholder,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            color: EcoColors.grey100,
            child: Center(
              child: CircularProgressIndicator(
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded /
                          loadingProgress.expectedTotalBytes!
                    : null,
                strokeWidth: 2,
                color: EcoColors.secondary,
              ),
            ),
          );
        },
      );
    }

    if (reporte.fotoBase64 != null && reporte.fotoBase64!.isNotEmpty) {
      try {
        final dataUrl = reporte.fotoBase64!;
        final commaIndex = dataUrl.indexOf(',');
        final base64Part = commaIndex >= 0
            ? dataUrl.substring(commaIndex + 1)
            : dataUrl;
        final bytes = base64Decode(base64Part);
        return Image.memory(bytes, fit: BoxFit.cover);
      } catch (_) {
        return placeholder;
      }
    }

    return placeholder;
  }

  /// Builds a status chip widget for displaying report status or priority.
  Widget _buildStatusChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: color,
        ),
      ),
    );
  }

  /// Builds a dropdown for updating report status.
  ///
  /// Creates an interactive dropdown that allows users to select and update
  /// the status of a report. Shows loading indicator during updates and
  /// provides visual feedback for successful or failed operations.
  Widget _buildStatusDropdown(Reporte reporte) {
    final bool isUpdating = _updatingReports.contains(reporte.id);
    final Color statusColor = _getStatusColorFromEnum(reporte.statusEnum);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: statusColor.withOpacity(0.3)),
      ),
      child: isUpdating
          ? Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 12,
                  height: 12,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: statusColor,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Actualizando...',
                  style: TextStyle(fontSize: 12, color: statusColor),
                ),
              ],
            )
          : DropdownButtonHideUnderline(
              child: DropdownButton<ReportStatus>(
                value: reporte.statusEnum,
                isDense: true,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: statusColor,
                ),
                dropdownColor: Colors.white,
                icon: Icon(Icons.arrow_drop_down, color: statusColor, size: 18),
                items: ReportStatus.values.map((ReportStatus status) {
                  final Color itemColor = _getStatusColorFromEnum(status);
                  return DropdownMenuItem<ReportStatus>(
                    value: status,
                    child: Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: itemColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          status.displayName,
                          style: TextStyle(
                            color: itemColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (ReportStatus? newStatus) {
                  if (newStatus != null && newStatus != reporte.statusEnum) {
                    _updateReportStatus(reporte, newStatus);
                  }
                },
              ),
            ),
    );
  }

  /// Returns appropriate color for status enum values.
  ///
  /// Provides semantic color coding for each report status:
  /// - Pending: Orange (waiting for action)
  /// - Received: Blue (information/acknowledgment)
  /// - En Route: Purple (in progress)
  /// - Collected: Green (success)
  /// - Completed: Grey (finished)
  Color _getStatusColorFromEnum(ReportStatus status) {
    switch (status) {
      case ReportStatus.pending:
        return const Color(0xFFFF9800); // Orange
      case ReportStatus.received:
        return const Color(0xFF2196F3); // Blue
      case ReportStatus.enRoute:
        return const Color(0xFF9C27B0); // Purple
      case ReportStatus.collected:
        return const Color(0xFF4CAF50); // Green
      case ReportStatus.completed:
        return const Color(0xFF607D8B); // Blue Grey
    }
  }

  /// Updates the status of a report both locally and in the backend.
  ///
  /// This method performs an optimistic update, immediately updating the UI
  /// and then syncing with the backend. If the backend update fails, the
  /// local state is reverted to maintain consistency.
  ///
  /// Parameters:
  /// - [reporte]: The report to update
  /// - [newStatus]: The new status to set
  Future<void> _updateReportStatus(
    Reporte reporte,
    ReportStatus newStatus,
  ) async {
    // Start loading state
    setState(() {
      _updatingReports.add(reporte.id);
    });

    // Store original state for potential rollback
    final originalStatus = reporte.statusEnum;

    // Optimistic update - update UI immediately
    final updatedReporte = reporte.updateStatus(newStatus);
    final reportIndex = _reportes.indexWhere((r) => r.id == reporte.id);

    if (reportIndex != -1) {
      setState(() {
        _reportes[reportIndex] = updatedReporte;
      });
    }

    try {
      // Update in backend
      final result = await ReportStatusService.updateReportStatus(
        reporte.id,
        newStatus,
      );

      if (result.success) {
        // Show success message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                result.message ?? 'Estado actualizado correctamente',
              ),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
              action: SnackBarAction(
                label: 'OK',
                textColor: Colors.white,
                onPressed: () {
                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                },
              ),
            ),
          );
        }
      } else {
        // Rollback on failure
        final revertedReporte = reporte.updateStatus(originalStatus);
        if (reportIndex != -1 && mounted) {
          setState(() {
            _reportes[reportIndex] = revertedReporte;
          });
        }

        // Show error message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result.error ?? 'Error al actualizar estado'),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
              action: SnackBarAction(
                label: 'Reintentar',
                textColor: Colors.white,
                onPressed: () {
                  _updateReportStatus(reporte, newStatus);
                },
              ),
            ),
          );
        }
      }
    } catch (e) {
      // Rollback on exception
      final revertedReporte = reporte.updateStatus(originalStatus);
      if (reportIndex != -1 && mounted) {
        setState(() {
          _reportes[reportIndex] = revertedReporte;
        });
      }

      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error de conexión: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            action: SnackBarAction(
              label: 'Reintentar',
              textColor: Colors.white,
              onPressed: () {
                _updateReportStatus(reporte, newStatus);
              },
            ),
          ),
        );
      }
    } finally {
      // Stop loading state
      if (mounted) {
        setState(() {
          _updatingReports.remove(reporte.id);
        });
      }
    }
  }

  /// Returns appropriate color for priority display.
  Color _getPriorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'high':
      case 'alta':
        return Colors.red;
      case 'medium':
      case 'media':
        return Colors.orange;
      case 'low':
      case 'baja':
        return Colors.green;
      default:
        return EcoColors.secondary;
    }
  }
}
>>>>>>> origin/main
