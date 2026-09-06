// =====================================================================
// DRISHTI Mobile App: Outbox Sync Queue Item Model
// Manages asynchronous dependency-ordered synchronization
// =====================================================================

enum SyncStatus { pending, syncing, synced, failed }

class SyncItemModel {
  final String id;
  final String entityType; // ASSIGNMENT_ARRIVE, CHECKLIST_SUBMISSION, EVIDENCE_METADATA, FINAL_REPORT
  final String entityLocalId;
  final String? parentServerId;
  final String endpoint;
  final String httpMethod; // POST, PATCH, PUT
  final String payloadJson;
  final String? dependencySyncId;
  final int attemptCount;
  final String? lastAttemptAt;
  final String? errorMessage;
  final String syncStatus; // PENDING, SYNCING, SYNCED, FAILED
  final String createdAt;

  SyncItemModel({
    required this.id,
    required this.entityType,
    required this.entityLocalId,
    this.parentServerId,
    required this.endpoint,
    required this.httpMethod,
    required this.payloadJson,
    this.dependencySyncId,
    this.attemptCount = 0,
    this.lastAttemptAt,
    this.errorMessage,
    this.syncStatus = 'PENDING',
    required this.createdAt,
  });

  bool get isPending => syncStatus == 'PENDING';
  bool get isSyncing => syncStatus == 'SYNCING';
  bool get isSynced => syncStatus == 'SYNCED';
  bool get isFailed => syncStatus == 'FAILED';

  factory SyncItemModel.fromSqlite(Map<String, dynamic> row) {
    return SyncItemModel(
      id: row['id'] as String,
      entityType: row['entity_type'] as String,
      entityLocalId: row['entity_local_id'] as String,
      parentServerId: row['parent_server_id'] as String?,
      endpoint: row['endpoint'] as String,
      httpMethod: row['http_method'] as String,
      payloadJson: row['payload_json'] as String,
      dependencySyncId: row['dependency_sync_id'] as String?,
      attemptCount: row['attempt_count'] as int? ?? 0,
      lastAttemptAt: row['last_attempt_at'] as String?,
      errorMessage: row['error_message'] as String?,
      syncStatus: row['sync_status'] as String? ?? 'PENDING',
      createdAt: row['created_at'] as String,
    );
  }

  Map<String, dynamic> toSqlite() {
    return {
      'id': id,
      'entity_type': entityType,
      'entity_local_id': entityLocalId,
      'parent_server_id': parentServerId,
      'endpoint': endpoint,
      'http_method': httpMethod,
      'payload_json': payloadJson,
      'dependency_sync_id': dependencySyncId,
      'attempt_count': attemptCount,
      'last_attempt_at': lastAttemptAt,
      'error_message': errorMessage,
      'sync_status': syncStatus,
      'created_at': createdAt,
    };
  }

  SyncItemModel copyWith({
    String? syncStatus,
    int? attemptCount,
    String? lastAttemptAt,
    String? errorMessage,
    String? parentServerId,
  }) {
    return SyncItemModel(
      id: id,
      entityType: entityType,
      entityLocalId: entityLocalId,
      parentServerId: parentServerId ?? this.parentServerId,
      endpoint: endpoint,
      httpMethod: httpMethod,
      payloadJson: payloadJson,
      dependencySyncId: dependencySyncId,
      attemptCount: attemptCount ?? this.attemptCount,
      lastAttemptAt: lastAttemptAt ?? this.lastAttemptAt,
      errorMessage: errorMessage ?? this.errorMessage,
      syncStatus: syncStatus ?? this.syncStatus,
      createdAt: createdAt,
    );
  }
}
