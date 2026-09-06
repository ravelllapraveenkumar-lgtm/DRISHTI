import 'package:flutter_test/flutter_test.dart';
import 'package:drishti_inspector/core/utils/geo_calculator.dart';

void main() {
  group('GeoCalculator Tests', () {
    test('Haversine distance between Lucknow points is accurate', () {
      // Lucknow Hazratganj to Charbagh (~3.5km)
      const lat1 = 26.8500;
      const lon1 = 80.9500;
      const lat2 = 26.8300;
      const lon2 = 80.9200;

      final distance = GeoCalculator.calculateDistanceMeters(
        lat1: lat1,
        lon1: lon1,
        lat2: lat2,
        lon2: lon2,
      );

      expect(distance, greaterThan(3000));
      expect(distance, lessThan(4500));
    });

    test('Geofence check passes within radius buffer', () {
      const targetLat = 26.8467;
      const targetLon = 80.9462;
      const currentLat = 26.8468;
      const currentLon = 80.9463;

      final isWithin = GeoCalculator.isWithinGeofence(
        currentLat: currentLat,
        currentLon: currentLon,
        accuracyMeters: 5.0,
        targetLat: targetLat,
        targetLon: targetLon,
        geofenceRadiusMeters: 150,
      );

      expect(isWithin, isTrue);
    });

    test('Geofence check fails when device is far away', () {
      const targetLat = 26.8467;
      const targetLon = 80.9462;
      const currentLat = 28.6139; // Delhi
      const currentLon = 77.2090;

      final isWithin = GeoCalculator.isWithinGeofence(
        currentLat: currentLat,
        currentLon: currentLon,
        accuracyMeters: 5.0,
        targetLat: targetLat,
        targetLon: targetLon,
        geofenceRadiusMeters: 150,
      );

      expect(isWithin, isFalse);
    });
  });
}
