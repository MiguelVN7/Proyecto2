// Se crea una pantalla para mostrar los reportes en un mapa

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../models/reporte.dart';

class MapaReportesScreen extends StatelessWidget {
  final List<Reporte> reportes;
  const MapaReportesScreen({super.key, required this.reportes});

  @override
  Widget build(BuildContext context) {
    return GoogleMap(
      initialCameraPosition: CameraPosition(
        target: LatLng(reportes.first.lat, reportes.first.lng),
        zoom: 12,
      ),
      markers: reportes
          .map((r) => Marker(
                markerId: MarkerId(r.id),
                position: LatLng(r.lat, r.lng),
                infoWindow: InfoWindow(
                  title: r.clasificacion,
                  snippet: r.ubicacion,
                ),
              ))
          .toSet(),
    );
  }
}