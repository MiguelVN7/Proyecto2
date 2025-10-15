/// Utilidades de geolocalización usadas por HU-21 y pruebas.
import 'dart:math';

class GeoUtils {
  /// Distancia en metros entre dos puntos (Haversine).
  static double distanceMeters({
    required double lat1,
    required double lon1,
    required double lat2,
    required double lon2,
  }) {
    const earthRadius = 6371000.0; // m
    double toRad(double d) => d * pi / 180.0;

    final dLat = toRad(lat2 - lat1);
    final dLon = toRad(lon2 - lon1);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(toRad(lat1)) * cos(toRad(lat2)) * sin(dLon / 2) * sin(dLon / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadius * c;
  }

  /// Bounding box aproximado para un radio (m) alrededor de lat/lon.
  /// Retorna [minLat, minLon, maxLat, maxLon].
  static List<double> boundingBox({
    required double lat,
    required double lon,
    required double radiusMeters,
  }) {
    // Aproximaciones: 1° lat ≈ 111_320 m; 1° lon ≈ 111_320 * cos(lat)
    const metersPerDegLat = 111320.0;
    final metersPerDegLon = metersPerDegLat * cos(lat * pi / 180);
    final dLat = radiusMeters / metersPerDegLat;
    final dLon = radiusMeters / metersPerDegLon;

    return [lat - dLat, lon - dLon, lat + dLat, lon + dLon];
  }
}
