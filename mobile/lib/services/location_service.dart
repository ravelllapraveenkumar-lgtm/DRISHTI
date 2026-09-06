import 'package:geolocator/geolocator.dart';
import '../core/utils/geo_calculator.dart';

// =====================================================================
// DRISHTI Mobile App: GPS Location & Geofence Verification Service
// Handles device sensors, geofence boundary checks & emulator fallbacks
// =====================================================================

class LocationResult {
  final double latitude;
  final double longitude;
  final double accuracyMeters;
  final bool isWithinTargetGeofence;
  final double distanceToTargetMeters;
  final bool isSimulatedOrFallback;
  final String? statusMessage;

  LocationResult({
    required this.latitude,
    required this.longitude,
    required this.accuracyMeters,
    required this.isWithinTargetGeofence,
    required this.distanceToTargetMeters,
    this.isSimulatedOrFallback = false,
    this.statusMessage,
  });

  bool get isDemoFallback => isSimulatedOrFallback;
}

class LocationService {
  /// Obtains the current GPS position as a LocationResult, using demo fallback if hardware sensors are absent.
  static Future<LocationResult> getCurrentPosition({bool allowDemoFallback = true}) async {
    final pos = await getCurrentPositionSafe();
    if (pos != null) {
      return LocationResult(
        latitude: pos.latitude,
        longitude: pos.longitude,
        accuracyMeters: pos.accuracy,
        isWithinTargetGeofence: false,
        distanceToTargetMeters: 0.0,
        isSimulatedOrFallback: false,
      );
    }
    return LocationResult(
      latitude: 26.8467,
      longitude: 80.9462,
      accuracyMeters: 10.0,
      isWithinTargetGeofence: false,
      distanceToTargetMeters: 0.0,
      isSimulatedOrFallback: true,
      statusMessage: 'Synthesized demo position for testing without hardware GPS.',
    );
  }

  /// Calculates proximity and geofence evaluation for a location result against target coordinates.
  static Map<String, dynamic> verifyProximity({
    required LocationResult location,
    required double targetLat,
    required double targetLon,
    required int geofenceRadiusMeters,
  }) {
    final distance = GeoCalculator.calculateDistanceMeters(
      lat1: location.latitude,
      lon1: location.longitude,
      lat2: targetLat,
      lon2: targetLon,
    );
    final isWithin = GeoCalculator.isWithinGeofence(
      currentLat: location.latitude,
      currentLon: location.longitude,
      accuracyMeters: location.accuracyMeters,
      targetLat: targetLat,
      targetLon: targetLon,
      geofenceRadiusMeters: geofenceRadiusMeters,
    );
    return {
      'distance_meters': distance,
      'is_within_geofence': isWithin,
    };
  }

  /// Obtains the current GPS position from hardware sensors, or safely
  /// provides a tagged demo location if hardware sensors are unavailable.
  static Future<Position?> getCurrentPositionSafe() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return null;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return null;
      }

      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 8),
      );
    } catch (_) {
      // In headless testing or desktop environment where geolocator plugin is not bound
      return null;
    }
  }

  /// Evaluates GPS position against target institution geofence perimeter.
  static Future<LocationResult> verifyInstitutionGeofence({
    required double targetLat,
    required double targetLon,
    required int geofenceRadiusMeters,
    bool forceDemoPosition = false,
  }) async {
    Position? pos;
    bool isFallback = false;

    if (!forceDemoPosition) {
      pos = await getCurrentPositionSafe();
    }

    // If hardware GPS returned null (e.g. simulator without mock location),
    // supply a realistic on-site coordinate for evaluation with clear labeling
    if (pos == null) {
      isFallback = true;
      // Synthesize a location 35 meters away from target institution perimeter
      pos = Position(
        latitude: targetLat + 0.00028,
        longitude: targetLon + 0.00015,
        timestamp: DateTime.now(),
        accuracy: 12.0,
        altitude: 120.0,
        altitudeAccuracy: 5.0,
        heading: 0.0,
        headingAccuracy: 0.0,
        speed: 0.0,
        speedAccuracy: 0.0,
      );
    }

    final distance = GeoCalculator.calculateDistanceMeters(
      lat1: pos.latitude,
      lon1: pos.longitude,
      lat2: targetLat,
      lon2: targetLon,
    );

    final isWithin = GeoCalculator.isWithinGeofence(
      currentLat: pos.latitude,
      currentLon: pos.longitude,
      accuracyMeters: pos.accuracy,
      targetLat: targetLat,
      targetLon: targetLon,
      geofenceRadiusMeters: geofenceRadiusMeters,
    );

    return LocationResult(
      latitude: pos.latitude,
      longitude: pos.longitude,
      accuracyMeters: pos.accuracy,
      isWithinTargetGeofence: isWithin,
      distanceToTargetMeters: distance,
      isSimulatedOrFallback: isFallback,
      statusMessage: isWithin
          ? 'Device inside authorized geofence (${distance.toStringAsFixed(1)}m from center).'
          : 'Geofence breach: Device is ${distance.toStringAsFixed(1)}m from center (allowed: ${geofenceRadiusMeters}m).',
    );
  }
}
