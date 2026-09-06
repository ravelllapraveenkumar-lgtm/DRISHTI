import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../core/utils/geo_calculator.dart';
import '../services/location_service.dart';

// =====================================================================
// DRISHTI Mobile App: Live GPS & Geofence Verification Widget
// Validates physical presence within authorized institution radius
// =====================================================================

class GeofenceStatusCard extends StatelessWidget {
  final double targetLat;
  final double targetLon;
  final int geofenceRadiusMeters;
  final LocationResult? currentLocation;
  final bool isVerified;
  final double distanceMeters;
  final bool isVerifying;
  final VoidCallback onVerifyPressed;

  const GeofenceStatusCard({
    Key? key,
    required this.targetLat,
    required this.targetLon,
    required this.geofenceRadiusMeters,
    this.currentLocation,
    required this.isVerified,
    required this.distanceMeters,
    required this.isVerifying,
    required this.onVerifyPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final bool hasLocation = currentLocation != null;

    return Container(
      decoration: BoxDecoration(
        color: isVerified ? AppColors.statusSuccessBg : AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isVerified ? AppColors.statusSuccess : AppColors.border,
          width: isVerified ? 1.5 : 1.0,
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isVerified ? Icons.verified_user : Icons.location_on,
                color: isVerified ? AppColors.statusSuccess : AppColors.primaryNavy,
                size: 22,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  isVerified ? 'On-Site Presence Verified' : 'GPS Geofence Verification',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: isVerified ? AppColors.statusSuccess : AppColors.textPrimary,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isVerified ? AppColors.statusSuccess : AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  isVerified ? 'VERIFIED' : 'PENDING ARRIVAL',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: isVerified ? Colors.white : AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 12),

          // Coordinate comparison grid
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Target Institution',
                      style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      GeoCalculator.formatCoordinate(targetLat, targetLon),
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                    Text(
                      'Radius: ${geofenceRadiusMeters}m',
                      style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Inspector GPS',
                      style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      hasLocation
                          ? GeoCalculator.formatCoordinate(currentLocation!.latitude, currentLocation!.longitude)
                          : 'Not acquired yet',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                    if (hasLocation)
                      Text(
                        'Distance: ${distanceMeters.toStringAsFixed(1)}m',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: isVerified ? AppColors.statusSuccess : AppColors.statusCritical,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),

          if (currentLocation?.isDemoFallback == true) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.statusWarningBg,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                'Note: Using labeled demo coordinates for prototype testing.',
                style: TextStyle(fontSize: 10, color: AppColors.statusWarning),
              ),
            ),
          ],

          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: isVerifying ? null : onVerifyPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: isVerified ? AppColors.statusSuccess : AppColors.primaryNavy,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              icon: isVerifying
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : Icon(isVerified ? Icons.refresh : Icons.my_location, size: 18),
              label: Text(
                isVerifying
                    ? 'Acquiring GPS Fix...'
                    : (isVerified ? 'Re-Verify Current GPS' : 'Verify On-Site Presence (Arrive)'),
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
