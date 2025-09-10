/// Screen for displaying environmental reports on an interactive map.
///
/// This screen shows all submitted reports as markers on a Google Maps view,
/// allowing users to visualize the geographic distribution of environmental issues.
/// Each marker displays report details including classification and location.

// Flutter imports:
import 'package:flutter/material.dart';

// Project imports:
import '../colors.dart';
import '../models/reporte.dart';

/// Map screen widget displaying reports as interactive markers.
///
/// Displays environmental reports in a visual format showing their geographic
/// distribution. Currently implements a fallback list view while Google Maps
/// integration is being configured. Each report shows classification, location,
/// coordinates, and current status.
class MapaReportesScreen extends StatefulWidget {
  /// List of reports to display on the map.
  final List<Reporte> reportes;

  /// Creates a map screen with the provided reports data.
  ///
  /// The [reportes] parameter contains the list of environmental reports
  /// to be displayed. If empty, an appropriate empty state will be shown.
  const MapaReportesScreen({super.key, required this.reportes});

  @override
  State<MapaReportesScreen> createState() => _MapaReportesScreenState();
}

/// State class for MapaReportesScreen managing display and interactions.
///
/// Handles the rendering of reports in a visual list format as a temporary
/// replacement for Google Maps while proper API configuration is completed.
/// Manages the color coding and iconography for different waste types.
class _MapaReportesScreenState extends State<MapaReportesScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Map of Reports'),
        backgroundColor: EcoColors.primary,
        foregroundColor: EcoColors.onPrimary,
      ),
      body: widget.reportes.isEmpty ? _buildEmptyState() : _buildMapView(),
    );
  }

  /// Builds the empty state when no reports are available.
  ///
  /// Displays a user-friendly message with an icon and instructions
  /// when there are no environmental reports to show on the map.
  /// Encourages users to submit their first report.
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.location_off, size: 64, color: EcoColors.secondary),
          const SizedBox(height: 16),
          Text(
            'No reports available',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: EcoColors.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Submit your first environmental report to see it on the map',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: EcoColors.onSurface.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  /// Builds the main map view displaying environmental reports.
  ///
  /// Currently implements a fallback list view instead of Google Maps
  /// due to API configuration requirements. Shows reports in a scrollable
  /// list format with status indicators and location information.
  ///
  /// Future implementation will integrate Google Maps Flutter plugin
  /// for geographic visualization of report locations.
  Widget _buildMapView() {
    // Temporary fallback: show reports in a visual list instead of map
    // This prevents crashes while Google Maps is being configured
    return _buildReportsList();
  }

  /// Builds a visual list of reports as a temporary map replacement.
  ///
  /// Creates a scrollable ListView of environmental reports with
  /// visual cards for each report. Each card displays:
  /// - Type-specific icon and color coding
  /// - Classification and location text
  /// - Precise GPS coordinates
  /// - Status indicator
  ///
  /// This serves as a fallback UI while Google Maps integration
  /// is being configured, providing a user-friendly alternative
  /// for viewing all environmental reports.
  Widget _buildReportsList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: widget.reportes.length,
      itemBuilder: (context, index) {
        final reporte = widget.reportes[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 2,
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: _getColorByType(reporte.clasificacion),
              child: Icon(
                _getIconByType(reporte.clasificacion),
                color: Colors.white,
              ),
            ),
            title: Text(
              reporte.clasificacion,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(reporte.ubicacion),
                const SizedBox(height: 4),
                Text(
                  'Lat: ${reporte.lat.toStringAsFixed(4)}, '
                  'Lng: ${reporte.lng.toStringAsFixed(4)}',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
            trailing: Chip(
              label: Text(reporte.estado, style: const TextStyle(fontSize: 10)),
              backgroundColor: reporte.estado == 'Completado'
                  ? Colors.green[100]
                  : Colors.orange[100],
            ),
          ),
        );
      },
    );
  }

  /// Returns appropriate color based on waste type classification.
  ///
  /// Provides color coding for different types of environmental waste
  /// to improve visual identification and user experience:
  /// - Plastic waste: Blue color (ocean/water association)
  /// - Glass waste: Green color (recycling/nature association)
  /// - Paper waste: Yellow/brown color (natural material)
  /// - Metal waste: Orange color (industrial/rust association)
  /// - Unknown types: Red color (attention/warning)
  ///
  /// Parameters:
  /// - [clasificacion]: The waste type classification string
  ///
  /// Returns the appropriate [Color] for the given waste type.
  Color _getColorByType(String clasificacion) {
    switch (clasificacion.toLowerCase()) {
      case 'plástico':
        return Colors.blue;
      case 'vidrio':
        return Colors.green;
      case 'papel':
        return Colors.yellow[700]!;
      case 'metal':
        return Colors.orange;
      default:
        return Colors.red;
    }
  }

  /// Returns appropriate icon based on waste type classification.
  ///
  /// Provides intuitive iconography for different types of environmental
  /// waste to enhance visual recognition and user experience:
  /// - Plastic waste: Local drink icon (bottles/containers)
  /// - Glass waste: Wine bar icon (glass containers)
  /// - Paper waste: Description icon (documents/paper)
  /// - Metal waste: Build icon (tools/construction materials)
  /// - Unknown types: Delete icon (general waste)
  ///
  /// Parameters:
  /// - [clasificacion]: The waste type classification string
  ///
  /// Returns the appropriate [IconData] for the given waste type.
  IconData _getIconByType(String clasificacion) {
    switch (clasificacion.toLowerCase()) {
      case 'plástico':
        return Icons.local_drink;
      case 'vidrio':
        return Icons.wine_bar;
      case 'papel':
        return Icons.description;
      case 'metal':
        return Icons.build;
      default:
        return Icons.delete;
    }
  }
}
