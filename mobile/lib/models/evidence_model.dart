// =====================================================================
// DRISHTI Mobile App: Evidence Metadata Model
// Handles tamper-resistant SHA-256 hash, GPS coordinates & offline status
// =====================================================================

class EvidenceModel {
  final String localId;
  final String? serverId;
  final String inspectionLocalId;
  final String? inspectionServerId;
  final String evidenceType; // GEO_TAGGED_PHOTO, GEO_TAGGED_VIDEO, DOCUMENT_SCAN, AUDIO_INTERVIEW
  final String fileName;
  final String localFilePath;
  final String sha256Checksum;
  final String description;
  final double gpsLatitude;
  final double gpsLongitude;
  final double gpsAccuracyMeters;
  final bool geofenceVerified;
  final String timestampCaptured;
  final String syncStatus; // PENDING, SYNCING, SYNCED, FAILED
  final int syncAttempts;
  final String? lastError;

  EvidenceModel({
    required this.localId,
    this.serverId,
    required this.inspectionLocalId,
    this.inspectionServerId,
    required this.evidenceType,
    required this.fileName,
    required this.localFilePath,
    required this.sha256Checksum,
    required this.description,
    required this.gpsLatitude,
    required this.gpsLongitude,
    required this.gpsAccuracyMeters,
    this.geofenceVerified = false,
    required dynamic timestampCaptured,
    this.syncStatus = 'PENDING',
    this.syncAttempts = 0,
    this.lastError,
  }) : timestampCaptured = timestampCaptured is DateTime
            ? timestampCaptured.toIso8601String()
            : timestampCaptured.toString();

  factory EvidenceModel.fromSqlite(Map<String, dynamic> row) {
    return EvidenceModel(
      localId: row['local_id'] as String,
      serverId: row['server_id'] as String?,
      inspectionLocalId: row['inspection_local_id'] as String,
      inspectionServerId: row['inspection_server_id'] as String?,
      evidenceType: row['evidence_type'] as String,
      fileName: row['file_name'] as String,
      localFilePath: row['local_file_path'] as String,
      sha256Checksum: row['sha256_checksum'] as String,
      description: row['description'] as String,
      gpsLatitude: (row['gps_latitude'] as num).toDouble(),
      gpsLongitude: (row['gps_longitude'] as num).toDouble(),
      gpsAccuracyMeters: (row['gps_accuracy_meters'] as num).toDouble(),
      geofenceVerified: (row['geofence_verified'] as int) == 1,
      timestampCaptured: row['timestamp_captured'] as String,
      syncStatus: row['sync_status'] as String? ?? 'PENDING',
      syncAttempts: row['sync_attempts'] as int? ?? 0,
      lastError: row['last_error'] as String?,
    );
  }

  Map<String, dynamic> toSqlite() {
    return {
      'local_id': localId,
      'server_id': serverId,
      'inspection_local_id': inspectionLocalId,
      'inspection_server_id': inspectionServerId,
      'evidence_type': evidenceType,
      'file_name': fileName,
      'local_file_path': localFilePath,
      'sha256_checksum': sha256Checksum,
      'description': description,
      'gps_latitude': gpsLatitude,
      'gps_longitude': gpsLongitude,
      'gps_accuracy_meters': gpsAccuracyMeters,
      'geofence_verified': geofenceVerified ? 1 : 0,
      'timestamp_captured': timestampCaptured,
      'sync_status': syncStatus,
      'sync_attempts': syncAttempts,
      'last_error': lastError,
    };
  }

  /// Maps strictly to backend EvidenceCreate schema
  Map<String, dynamic> toBackendJson({required String parentServerUuid}) {
    return {
      'inspection_id': parentServerUuid,
      'evidence_type': evidenceType,
      'file_name': fileName,
      'file_path_or_url': localFilePath,
      'sha256_checksum': sha256Checksum,
      'description': description,
      'timestamp_captured': timestampCaptured,
      'gps_latitude': gpsLatitude,
      'gps_longitude': gpsLongitude,
      'gps_accuracy_meters': gpsAccuracyMeters,
      'local_sqlite_id': localId,
    };
  }

  /// Maps strictly to backend EvidenceCreate schema
  Map<String, dynamic> toApiPayload(String resolvedInspectionServerId) {
    return toBackendJson(parentServerUuid: resolvedInspectionServerId);
  }

  EvidenceModel copyWith({
    String? serverId,
    String? inspectionServerId,
    String? syncStatus,
    int? syncAttempts,
    String? lastError,
    bool? geofenceVerified,
  }) {
    return EvidenceModel(
      localId: localId,
      serverId: serverId ?? this.serverId,
      inspectionLocalId: inspectionLocalId,
      inspectionServerId: inspectionServerId ?? this.inspectionServerId,
      evidenceType: evidenceType,
      fileName: fileName,
      localFilePath: localFilePath,
      sha256Checksum: sha256Checksum,
      description: description,
      gpsLatitude: gpsLatitude,
      gpsLongitude: gpsLongitude,
      gpsAccuracyMeters: gpsAccuracyMeters,
      geofenceVerified: geofenceVerified ?? this.geofenceVerified,
      timestampCaptured: timestampCaptured,
      syncStatus: syncStatus ?? this.syncStatus,
      syncAttempts: syncAttempts ?? this.syncAttempts,
      lastError: lastError ?? this.lastError,
    );
  }
}
