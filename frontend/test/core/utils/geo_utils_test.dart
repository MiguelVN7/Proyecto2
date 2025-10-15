import 'package:flutter_test/flutter_test.dart';
import 'package:eco_track/core/utils/geo.dart';

void main() {
  group('GeoUtils', () {
    test('distanceMeters ~ 50 m entre dos puntos cercanos', () {
      // Punto base (EAFIT aprox)
      const lat = 6.2019, lon = -75.5781;
      // ~50m al norte (aprox 0.00045° lat)
      final d = GeoUtils.distanceMeters(
        lat1: lat,
        lon1: lon,
        lat2: lat + 0.00045,
        lon2: lon,
      );
      expect(d, greaterThan(45));
      expect(d, lessThan(65));
    });

    test('boundingBox cubre el centro', () {
      const lat = 6.2, lon = -75.58, r = 50.0;
      final box = GeoUtils.boundingBox(lat: lat, lon: lon, radiusMeters: r);
      expect(box.length, 4);
      expect(box[0], lessThan(lat));
      expect(box[2], greaterThan(lat));
      expect(box[1], lessThan(lon));
      expect(box[3], greaterThan(lon));
    });
  });
}
