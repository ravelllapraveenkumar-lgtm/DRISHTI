import '../../core/constants/api_endpoints.dart';
import '../../core/network/api_client.dart';
import '../../models/evidence_model.dart';

// =====================================================================
// DRISHTI Mobile App: Evidence Remote API Service
// Registers tamper-resistant SHA-256 evidence metadata with FastAPI
// =====================================================================

class EvidenceApiService {
  final ApiClient _client;

  EvidenceApiService(this._client);

  /// Registers geotagged evidence metadata on the backend
  Future<EvidenceModel> registerEvidenceMetadata({
    required EvidenceModel localEvidence,
    required String parentServerUuid,
  }) async {
    final payload = localEvidence.toBackendJson(parentServerUuid: parentServerUuid);
    final response = await _client.post(ApiEndpoints.evidence, body: payload);

    final map = Map<String, dynamic>.from(response as Map);
    return localEvidence.copyWith(
      serverId: map['id']?.toString(),
      inspectionServerId: parentServerUuid,
      geofenceVerified: map['geofence_verified'] == true,
      syncStatus: 'SYNCED',
      syncAttempts: localEvidence.syncAttempts + 1,
      lastError: null,
    );
  }

  /// Lists evidence records for an inspection
  Future<List<EvidenceModel>> getEvidenceForInspection(String inspectionServerId) async {
    final response = await _client.get(
      '${ApiEndpoints.evidence}?inspection_id=$inspectionServerId',
    );
    if (response is Map && response['items'] is List) {
      final items = response['items'] as List;
      return items.map((e) {
        final m = Map<String, dynamic>.from(e as Map);
        return EvidenceModel(
          localId: m['local_sqlite_id']?.toString() ?? 'server_${m['id']}',
          serverId: m['id']?.toString(),
          inspectionLocalId: 'local_$inspectionServerId',
          inspectionServerId: inspectionServerId,
          evidenceType: m['evidence_type']?.toString() ?? 'GEO_TAGGED_PHOTO',
          fileName: m['file_name']?.toString() ?? '',
          localFilePath: m['file_path_or_url']?.toString() ?? '',
          sha256Checksum: m['sha256_checksum']?.toString() ?? '',
          description: m['description']?.toString() ?? '',
          gpsLatitude: (m['gps_latitude'] as num?)?.toDouble() ?? 0.0,
          gpsLongitude: (m['gps_longitude'] as num?)?.toDouble() ?? 0.0,
          gpsAccuracyMeters: (m['gps_accuracy_meters'] as num?)?.toDouble() ?? 5.0,
          geofenceVerified: m['geofence_verified'] == true,
          timestampCaptured: m['timestamp_captured'] != null
              ? DateTime.parse(m['timestamp_captured'])
              : DateTime.now(),
          syncStatus: 'SYNCED',
        );
      }).toList();
    }
    return [];
  }
}
