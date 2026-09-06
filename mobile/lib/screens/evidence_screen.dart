import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_strings.dart';
import '../core/utils/geo_calculator.dart';
import '../models/evidence_model.dart';
import '../providers/inspection_detail_provider.dart';
import '../widgets/sync_status_badge.dart';

// =====================================================================
// DRISHTI Mobile App: Tamper-Resistant Evidence Vault Screen
// Displays geotagged media with SHA-256 cryptographic verification hashes
// =====================================================================

class EvidenceScreen extends StatelessWidget {
  final String inspectionLocalId;

  const EvidenceScreen({Key? key, required this.inspectionLocalId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final detailProv = context.watch<InspectionDetailProvider>();
    final evidences = detailProv.evidences;

    return Column(
      children: [
        // Prototype Architecture Banner
        Container(
          width: double.infinity,
          color: AppColors.statusInfoBg,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.security, size: 16, color: AppColors.statusInfo),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  AppStrings.demoNotice,
                  style: const TextStyle(fontSize: 10.5, color: AppColors.textSecondary),
                ),
              ),
            ],
          ),
        ),

        // Action Toolbar
        Container(
          padding: const EdgeInsets.all(12),
          color: Colors.white,
          child: Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _showCaptureDialog(context, detailProv),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryNavy,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  icon: const Icon(Icons.camera_alt, size: 16),
                  label: const Text('CAPTURE EVIDENCE', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: () => _addDemoMockEvidence(context, detailProv),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                icon: const Icon(Icons.add_photo_alternate_outlined, size: 16),
                label: const Text('MOCK TEST PHOTO', style: TextStyle(fontSize: 12)),
              ),
            ],
          ),
        ),

        // Evidence Items List
        Expanded(
          child: evidences.isEmpty
              ? _buildEmptyState(context, detailProv)
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: evidences.length,
                  itemBuilder: (context, index) {
                    final item = evidences[index];
                    return _buildEvidenceCard(context, item);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildEvidenceCard(BuildContext context, EvidenceModel item) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.photo_camera_back, size: 20, color: AppColors.primaryNavy),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.description.isNotEmpty ? item.description : 'Field Photographic Evidence',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      Text(
                        'Captured: ${DateTime.tryParse(item.timestampCaptured)?.toLocal().toString().split('.').first ?? item.timestampCaptured}',
                        style: const TextStyle(fontSize: 10.5, color: AppColors.textMuted),
                      ),
                    ],
                  ),
                ),
                SyncStatusBadge(status: item.syncStatus),
              ],
            ),
            const SizedBox(height: 10),
            const Divider(height: 1),
            const SizedBox(height: 10),

            // Geotag coordinates & geofence indicator
            Row(
              children: [
                const Icon(Icons.location_on, size: 13, color: AppColors.primaryNavy),
                const SizedBox(width: 4),
                Text(
                  GeoCalculator.formatCoordinate(item.gpsLatitude, item.gpsLongitude),
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: item.geofenceVerified ? AppColors.statusSuccessBg : AppColors.statusWarningBg,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    item.geofenceVerified ? 'GEOFENCE VERIFIED' : 'OUTSIDE GEOFENCE',
                    style: TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.bold,
                      color: item.geofenceVerified ? AppColors.statusSuccess : AppColors.statusWarning,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // SHA-256 Checksum Container
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  const Icon(Icons.fingerprint, size: 14, color: AppColors.textMuted),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'SHA-256: ${item.sha256Checksum}',
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 10,
                        color: AppColors.textSecondary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.copy, size: 13, color: AppColors.primaryNavy),
                    tooltip: 'Copy Hash',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: item.sha256Checksum));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('SHA-256 checksum copied to clipboard.')),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, InspectionDetailProvider detailProv) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.photo_library_outlined, size: 56, color: AppColors.textMuted),
          const SizedBox(height: 16),
          const Text(
            'No Evidence Captured Yet',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          const Text(
            'Capture photos of premises, facilities, or records to register SHA-256 metadata.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => _showCaptureDialog(context, detailProv),
            icon: const Icon(Icons.camera_alt, size: 16),
            label: const Text('CAPTURE FIRST PHOTO'),
          ),
        ],
      ),
    );
  }

  void _showCaptureDialog(BuildContext context, InspectionDetailProvider detailProv) {
    final controller = TextEditingController(text: 'Physical facility visual verification');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Capture Geotagged Photo', style: TextStyle(fontSize: 15)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'A photo will be captured with current GPS coordinates and sealed with a SHA-256 cryptographic hash.',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: 'Evidence Description',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('CANCEL'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              detailProv.addCameraEvidence(controller.text.trim());
            },
            child: const Text('OPEN CAMERA'),
          ),
        ],
      ),
    );
  }

  void _addDemoMockEvidence(BuildContext context, InspectionDetailProvider detailProv) {
    detailProv.addDemoEvidence('Routine kitchen & dining hall inspection photo');
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Mock photo with SHA-256 hash registered to local SQLite.')),
    );
  }
}
