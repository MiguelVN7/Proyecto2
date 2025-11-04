/// Screen for displaying environmental reports on an interactive map.
///
/// This screen shows all submitted reports as markers on an OpenStreetMap view,
/// allowing users to visualize the geographic distribution of environmental issues.
/// Each marker displays report details including classification and location.
library;

// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_marker_cluster/flutter_map_marker_cluster.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';

// Project imports:
import '../colors.dart';
import '../models/reporte.dart';
import '../services/firestore_service.dart';

/// Map screen widget displaying reports as interactive markers.
///
/// Displays environmental reports using OpenStreetMap with custom markers
/// for each report. Shows user's current location and allows interaction
/// with markers to view report details.
class MapaReportesScreen extends StatefulWidget {
  /// Creates a map screen that loads reports from Firestore.
  const MapaReportesScreen({super.key});

  @override
  State<MapaReportesScreen> createState() => _MapaReportesScreenState();
}

class _MapaReportesScreenState extends State<MapaReportesScreen> {
  final MapController _mapController = MapController();
  final FirestoreService _firestoreService = FirestoreService();
  LatLng? _userLocation;
  bool _isLoadingLocation = true;

  @override
  void initState() {
    super.initState();
    _getUserLocation();
  }

  /// Get user's current location
  Future<void> _getUserLocation() async {
    try {
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        await Geolocator.requestPermission();
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _userLocation = LatLng(position.latitude, position.longitude);
        _isLoadingLocation = false;
      });
    } catch (e) {
      debugPrint('Error getting location: $e');
      setState(() {
        _isLoadingLocation = false;
        // Default to Medellín, Colombia if location fails
        _userLocation = const LatLng(6.2476, -75.5658);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Map of Reports'),
        backgroundColor: EcoColors.primary,
        foregroundColor: EcoColors.onPrimary,
        actions: [
          // Center on user location button
          if (_userLocation != null)
            IconButton(
              icon: const Icon(Icons.my_location),
              tooltip: 'Center on my location',
              onPressed: () {
                _mapController.move(_userLocation!, 15.0);
              },
            ),
        ],
      ),
      body: StreamBuilder<List<Reporte>>(
        stream: _firestoreService.getReportsStream(),
        builder: (context, snapshot) {
          if (_isLoadingLocation) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Loading reports...'),
                ],
              ),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('Error loading reports: ${snapshot.error}'),
                ],
              ),
            );
          }

          final reportes = snapshot.data ?? [];

          if (reportes.isEmpty) {
            return _buildEmptyState();
          }

          return _buildMapViewWithData(reportes);
        },
      ),
    );
  }

  /// Builds the empty state when no reports are available.
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.location_off, size: 64, color: EcoColors.secondary),
          const SizedBox(height: 16),
          const Text(
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

  /// Builds the interactive map view with report markers
  Widget _buildMapViewWithData(List<Reporte> reportes) {
    // Calculate center point based on reports or user location
    LatLng center = _userLocation ?? const LatLng(6.2476, -75.5658);

    if (reportes.isNotEmpty) {
      // Calculate average position of all reports
      double avgLat = reportes.map((r) => r.lat).reduce((a, b) => a + b) /
                      reportes.length;
      double avgLng = reportes.map((r) => r.lng).reduce((a, b) => a + b) /
                      reportes.length;
      center = LatLng(avgLat, avgLng);
    }

    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: center,
        initialZoom: 13.0,
        minZoom: 3.0,
        maxZoom: 18.0,
      ),
      children: [
        // OpenStreetMap tile layer
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.example.eco_track',
          maxZoom: 19,
        ),

        // Report markers with clustering
        MarkerClusterLayerWidget(
          options: MarkerClusterLayerOptions(
            maxClusterRadius: 80,
            size: const Size(50, 50),
            markers: _buildReportMarkers(reportes),
            builder: (context, markers) {
              return _buildClusterMarker(markers);
            },
          ),
        ),

        // User location marker (separate layer, not clustered)
        if (_userLocation != null)
          MarkerLayer(
            markers: [
              Marker(
                point: _userLocation!,
                width: 40,
                height: 40,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.3),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.blue, width: 3),
                  ),
                  child: const Icon(
                    Icons.person_pin_circle,
                    color: Colors.blue,
                    size: 30,
                  ),
                ),
              ),
            ],
          ),

        // Attribution layer (required by OpenStreetMap)
        RichAttributionWidget(
          attributions: [
            TextSourceAttribution(
              'OpenStreetMap contributors',
              onTap: () {
                // Optional: open OSM website
              },
            ),
          ],
        ),
      ],
    );
  }

  /// Build markers for all reports
  List<Marker> _buildReportMarkers(List<Reporte> reportes) {
    return reportes.map((reporte) {
      return Marker(
        point: LatLng(reporte.lat, reporte.lng),
        width: 50,
        height: 50,
        child: GestureDetector(
          onTap: () => _showReportDetails(reporte),
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _getColorByClassification(reporte.clasificacion),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(
              _getIconByClassification(reporte.clasificacion),
              color: Colors.white,
              size: 24,
            ),
          ),
        ),
      );
    }).toList();
  }

  /// Build cluster marker widget
  Widget _buildClusterMarker(List<Marker> markers) {
    final count = markers.length;

    // Determine cluster color based on count (size of cluster)
    Color clusterColor = EcoColors.primary;
    if (count >= 10) {
      clusterColor = Colors.red[600]!;
    } else if (count >= 5) {
      clusterColor = Colors.orange[700]!;
    } else if (count >= 3) {
      clusterColor = Colors.blue[600]!;
    }

    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        color: clusterColor,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 3),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              count.toString(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Text(
              'reports',
              style: TextStyle(
                color: Colors.white,
                fontSize: 8,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Show report details in a bottom sheet
  void _showReportDetails(Reporte reporte) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Classification with icon
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: _getColorByClassification(reporte.clasificacion),
                  child: Icon(
                    _getIconByClassification(reporte.clasificacion),
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        reporte.clasificacion,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        reporte.id,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Chip(
                  label: Text(
                    reporte.estado,
                    style: const TextStyle(fontSize: 12),
                  ),
                  backgroundColor: _getStatusColor(reporte.estado),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Location info
            _buildInfoRow(Icons.location_on, 'Location', reporte.ubicacion),
            _buildInfoRow(
              Icons.gps_fixed,
              'Coordinates',
              '${reporte.lat.toStringAsFixed(6)}, ${reporte.lng.toStringAsFixed(6)}',
            ),
            _buildInfoRow(Icons.access_time, 'Time', reporte.createdAt.toString().substring(0, 16)),

            const SizedBox(height: 16),

            // Actions
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _mapController.move(
                        LatLng(reporte.lat, reporte.lng),
                        16.0,
                      );
                    },
                    icon: const Icon(Icons.center_focus_strong),
                    label: const Text('Center'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: EcoColors.primary,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                    label: const Text('Close'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Build an info row for the bottom sheet
  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(fontSize: 14),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }


  /// Get color based on waste classification
  Color _getColorByClassification(String clasificacion) {
    final lower = clasificacion.toLowerCase();

    // Organic waste - green
    if (lower.contains('orgánico') || lower.contains('organic')) {
      return Colors.green;
    }
    // Recyclable - blue
    if (lower.contains('reciclable') || lower.contains('recyclable')) {
      return Colors.blue;
    }
    // Non-recyclable - orange/red
    if (lower.contains('no reciclable') || lower.contains('non-recyclable')) {
      return Colors.orange;
    }

    // Legacy classifications
    if (lower.contains('plástico') || lower.contains('plastic')) {
      return Colors.blue;
    }
    if (lower.contains('vidrio') || lower.contains('glass')) {
      return Colors.green;
    }
    if (lower.contains('papel') || lower.contains('paper')) {
      return Colors.yellow[700]!;
    }
    if (lower.contains('metal')) {
      return Colors.grey;
    }

    return Colors.red;
  }

  /// Get icon based on waste classification
  IconData _getIconByClassification(String clasificacion) {
    final lower = clasificacion.toLowerCase();

    if (lower.contains('orgánico') || lower.contains('organic')) {
      return Icons.eco;
    }
    if (lower.contains('reciclable') || lower.contains('recyclable')) {
      return Icons.recycling;
    }
    if (lower.contains('no reciclable') || lower.contains('non-recyclable')) {
      return Icons.delete;
    }

    // Legacy classifications
    if (lower.contains('plástico') || lower.contains('plastic')) {
      return Icons.local_drink;
    }
    if (lower.contains('vidrio') || lower.contains('glass')) {
      return Icons.wine_bar;
    }
    if (lower.contains('papel') || lower.contains('paper')) {
      return Icons.description;
    }
    if (lower.contains('metal')) {
      return Icons.build;
    }

    return Icons.report;
  }

  /// Get color based on report status
  Color _getStatusColor(String estado) {
    final lower = estado.toLowerCase();

    if (lower.contains('complet') || lower.contains('collected')) {
      return Colors.green[100]!;
    }
    if (lower.contains('progress') || lower.contains('route') || lower.contains('en camino')) {
      return Colors.blue[100]!;
    }
    if (lower.contains('pending') || lower.contains('received') || lower.contains('pendiente')) {
      return Colors.orange[100]!;
    }

    return Colors.grey[200]!;
  }
}
