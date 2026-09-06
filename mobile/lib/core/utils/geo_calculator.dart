import 'dart:math';

// =====================================================================
// DRISHTI Mobile App: GPS & Geofence Verification Utility
// Uses standard Haversine great-circle distance matching backend logic
// =====================================================================

class GeoCalculator {
  static const double earthRadiusMeters = 6371000.0;

  /// Calculates distance in meters between two GPS coordinates (lat, lon).
  static double calculateDistanceMeters({
    required double lat1,
    required double lon1,
    required double lat2,
    required double lon2,
  }) {
    final double phi1 = _degreesToRadians(lat1);
    final double phi2 = _degreesToRadians(lat2);
    final double deltaPhi = _degreesToRadians(lat2 - lat1);
    final double deltaLambda = _degreesToRadians(lon2 - lon1);

    final double a = sin(deltaPhi / 2.0) * sin(deltaPhi / 2.0) +
        cos(phi1) * cos(phi2) * sin(deltaLambda / 2.0) * sin(deltaLambda / 2.0);

    final double c = 2.0 * atan2(sqrt(a), sqrt(1.0 - a));
    return earthRadiusMeters * c;
  }

  /// Evaluates whether current GPS position falls within allowed geofence.
  /// Allowed threshold includes institution radius + device accuracy buffer.
  static bool isWithinGeofence({
    required double currentLat,
    required double currentLon,
    required double accuracyMeters,
    required double targetLat,
    required double targetLon,
    required int geofenceRadiusMeters,
  }) {
    final double dist = calculateDistanceMeters(
      lat1: currentLat,
      lon1: currentLon,
      lat2: targetLat,
      lon2: targetLon,
    );
    final double allowed = geofenceRadiusMeters + accuracyMeters;
    return dist <= allowed;
  }

  static double _degreesToRadians(double degrees) {
    return degrees * (pi / 180.0);
  }

  /// Formats coordinate nicely for field inspector UI
  static String formatCoordinate(double lat, double lon) {
    final latDirection = lat >= 0 ? 'N' : 'S';
    final lonDirection = lon >= 0 ? 'E' : 'W';
    return '${lat.abs().toStringAsFixed(5)}° $latDirection, ${lon.abs().toStringAsFixed(5)}° $lonDirection';
  }
}
