// =====================================================================
// DRISHTI Mobile App: Sync Queue Item State Machine Model
// Ensures atomic sync ordering: Inspection -> Checklist -> Evidence -> Report
// =====================================================================

enum SyncStatus {
  pending,
  syncing,
  synced,
  failed;

  String get code {
    switch (this) {
      case SyncStatus.pending:
        return 'PENDING';
      case SyncStatus.syncing:
        return 'SYNCING';
      case SyncStatus.synced:
        return 'SYNCED';
      case SyncStatus.failed:
        return 'FAILED';
    }
  }

  static SyncStatus fromCode(String code) {
    switch (code.toUpperCase()) {
      case 'SYNCING':
        return SyncStatus.syncing;
      case 'SYNCED':
      case 'SYNCED_SUCCESS':
        return SyncStatus.synced;
      case 'FAILED':
      case 'SYNC_FAILED':
        return SyncStatus.failed;
      case 'PENDING':
      case 'LOCAL_PENDING':
      default:
        return SyncStatus.pending;
    }
  }
}

class SyncQueueItem {
  final String id;
  final String entityType; // CHECKLIST_BATCH, EVIDENCE, REPORT, STATUS_UPDATE
  final String entityLocalId;
  final String? parentServerId; // Required server UUID of the inspection
  final String endpoint;
  final String httpMethod; // POST, PATCH
  final String payloadJson;
  final String? dependencySyncId;
  final int attemptCount;
  final DateTime? lastAttemptAt;
  final String? errorMessage;
  final SyncStatus syncStatus;
  final DateTime createdAt;

  SyncQueueItem({
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
    this.syncStatus = SyncStatus.pending,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  bool get isPending => syncStatus == SyncStatus.pending;
  bool get isSyncing => syncStatus == SyncStatus.syncing;
  bool get isSynced => syncStatus == SyncStatus.synced;
  bool get isFailed => syncStatus == SyncStatus.failed;

  factory SyncQueueItem.fromSqlite(Map<String, dynamic> map) {
    return SyncQueueItem(
      id: map['id']?.toString() ?? '',
      entityType: map['entity_type'] ?? 'CHECKLIST_BATCH',
      entityLocalId: map['entity_local_id'] ?? map['inspection_id'] ?? '',
      parentServerId: map['parent_server_id'],
      endpoint: map['endpoint'] ?? '',
      httpMethod: map['http_method'] ?? 'POST',
      payloadJson: map['payload_json'] ?? '{}',
      dependencySyncId: map['dependency_sync_id'],
      attemptCount: (map['attempt_count'] as num?)?.toInt() ?? 0,
      lastAttemptAt: map['last_attempt_at'] != null
          ? DateTime.parse(map['last_attempt_at'])
          : null,
      errorMessage: map['error_message'],
      syncStatus: SyncStatus.fromCode(map['sync_status'] ?? 'PENDING'),
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'])
          : DateTime.now(),
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
      'last_attempt_at': lastAttemptAt?.toIso8601String(),
      'error_message': errorMessage,
      'sync_status': syncStatus.code,
      'created_at': createdAt.toIso8601String(),
    };
  }

  SyncQueueItem copyWith({
    SyncStatus? syncStatus,
    int? attemptCount,
    DateTime? lastAttemptAt,
    String? errorMessage,
    String? parentServerId,
  }) {
    return SyncQueueItem(
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
