/// Screen for displaying environmental reports on an interactive map.
///
/// This screen shows all submitted reports as markers on a Google Maps view,
/// allowing users to visualize the geographic distribution of environmental issues.
/// Each marker displays report details including classification and location.
import 'package:flutter/material.dart';
import '../models/reporte.dart';
import '../colors.dart';

/// Map screen widget displaying reports as interactive markers.
class MapaReportesScreen extends StatefulWidget {
  /// List of reports to display on the map.
  final List<Reporte> reportes;

  /// Creates a map screen with the provided reports.
  const MapaReportesScreen({super.key, required this.reportes});

  @override
  State<MapaReportesScreen> createState() => _MapaReportesScreenState();
}

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

  /// Builds the map view with report markers.
  Widget _buildMapView() {
    // Temporary fallback: show reports in a visual list instead of map
    // This prevents crashes while Google Maps is being configured
    return _buildReportsList();
  }

  /// Builds a visual list of reports as a temporary map replacement.
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

  /// Returns appropriate color based on waste type.
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

  /// Returns appropriate icon based on waste type.
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
