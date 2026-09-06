import 'dart:async';
import 'dart:convert';
import '../data/local/sqlite_database_helper.dart';
import '../data/remote/remote_data_source.dart';
import '../models/sync_item_model.dart';
import '../core/errors/app_exception.dart';

// =====================================================================
// DRISHTI Mobile App: Asynchronous Outbox Sync Engine
// Manages dependency resolution, atomic transitions & retry policies
// =====================================================================

class SyncProgress {
  final int total;
  final int completed;
  final int failed;
  final bool isRunning;
  final String? currentAction;

  SyncProgress({
    required this.total,
    required this.completed,
    required this.failed,
    required this.isRunning,
    this.currentAction,
  });
}

class SyncEngineService {
  final SqliteDatabaseHelper _dbHelper;
  final RemoteDataSource _remoteDataSource;
  bool _isSyncing = false;

  final StreamController<SyncProgress> _progressController =
      StreamController<SyncProgress>.broadcast();

  SyncEngineService({
    SqliteDatabaseHelper? dbHelper,
    RemoteDataSource? remoteDataSource,
  })  : _dbHelper = dbHelper ?? SqliteDatabaseHelper.instance,
        _remoteDataSource = remoteDataSource ?? RemoteDataSource();

  Stream<SyncProgress> get progressStream => _progressController.stream;
  bool get isSyncing => _isSyncing;

  /// Executes a full synchronization cycle across the Outbox queue
  Future<SyncProgress> processOutboxQueue() async {
    if (_isSyncing) {
      return SyncProgress(total: 0, completed: 0, failed: 0, isRunning: true);
    }

    _isSyncing = true;
    int completedCount = 0;
    int failedCount = 0;

    try {
      final queueItems = await _dbHelper.getPendingSyncItems();
      final total = queueItems.length;

      _notifyProgress(total, completedCount, failedCount, 'Starting sync...');

      for (final item in queueItems) {
        _notifyProgress(
          total,
          completedCount,
          failedCount,
          'Syncing ${item.entityType} (${item.entityLocalId})...',
        );

        try {
          await _processSingleItem(item);
          completedCount++;
        } catch (e) {
          failedCount++;
          await _dbHelper.updateSyncItemStatus(
            id: item.id,
            syncStatus: 'FAILED',
            errorMessage: e.toString(),
          );
        }
        _notifyProgress(total, completedCount, failedCount, null);
      }

      return SyncProgress(
        total: total,
        completed: completedCount,
        failed: failedCount,
        isRunning: false,
      );
    } finally {
      _isSyncing = false;
      _notifyProgress(0, completedCount, failedCount, 'Sync complete');
    }
  }

  Future<void> _processSingleItem(SyncItemModel item) async {
    await _dbHelper.updateSyncItemStatus(id: item.id, syncStatus: 'SYNCING');

    switch (item.entityType) {
      case 'ASSIGNMENT_ARRIVE':
        await _syncAssignmentArrive(item);
        break;

      case 'CHECKLIST_SUBMISSION':
        await _syncChecklistSubmissions(item);
        break;

      case 'EVIDENCE_METADATA':
        await _syncEvidenceMetadata(item);
        break;

      case 'FINAL_REPORT':
        await _syncFinalReport(item);
        break;

      default:
        throw AppException('Unknown entity type: ${item.entityType}');
    }

    // On complete success:
    await _dbHelper.updateSyncItemStatus(id: item.id, syncStatus: 'SYNCED');
  }

  Future<void> _syncAssignmentArrive(SyncItemModel item) async {
    // item.entityLocalId is the assignment ID or inspection local ID
    final assignmentId = item.payloadJson.isNotEmpty
        ? (jsonDecode(item.payloadJson)['assignment_id']?.toString() ?? item.entityLocalId)
        : item.entityLocalId;

    await _remoteDataSource.arriveAssignment(assignmentId);
    await _dbHelper.updateInspectionStatus(
      localId: item.entityLocalId,
      status: 'IN_PROGRESS',
      syncStatus: 'SYNCED',
    );
  }

  Future<void> _syncChecklistSubmissions(SyncItemModel item) async {
    final parentServerId = await _resolveParentServerId(item.entityLocalId, item.parentServerId);
    if (parentServerId == null || parentServerId.isEmpty) {
      throw SyncDependencyException(
        parentEntityType: 'Inspection',
        parentLocalId: item.entityLocalId,
      );
    }

    final responses = await _dbHelper.getResponsesForInspection(item.entityLocalId);
    if (responses.isEmpty) return;

    final payloadList = responses.map((r) => r.toApiPayload(parentServerId)).toList();
    await _remoteDataSource.submitChecklistResponses(
      inspectionId: parentServerId,
      items: payloadList,
    );

    // Update all responses in local SQLite to SYNCED
    for (final r in responses) {
      final updated = r.copyWith(syncStatus: 'SYNCED');
      await _dbHelper.saveChecklistResponses([updated]);
    }
  }

  Future<void> _syncEvidenceMetadata(SyncItemModel item) async {
    // item.entityLocalId is the evidence local ID
    final db = await _dbHelper.database;
    final rows = await db.query('local_evidence', where: 'local_id = ?', whereArgs: [item.entityLocalId]);
    if (rows.isEmpty) return;

    final row = rows.first;
    final inspectionLocalId = row['inspection_local_id'] as String;
    final parentServerId = await _resolveParentServerId(
      inspectionLocalId,
      row['inspection_server_id'] as String?,
    );

    if (parentServerId == null || parentServerId.isEmpty) {
      throw SyncDependencyException(
        parentEntityType: 'Inspection',
        parentLocalId: inspectionLocalId,
      );
    }

    final payload = {
      'inspection_id': parentServerId,
      'evidence_type': row['evidence_type'],
      'file_name': row['file_name'],
      'file_path_or_url': row['local_file_path'],
      'sha256_checksum': row['sha256_checksum'],
      'description': row['description'],
      'timestamp_captured': row['timestamp_captured'],
      'gps_latitude': row['gps_latitude'],
      'gps_longitude': row['gps_longitude'],
      'gps_accuracy_meters': row['gps_accuracy_meters'],
      'local_sqlite_id': item.entityLocalId,
    };

    final result = await _remoteDataSource.registerEvidence(payload);
    final serverId = result['id']?.toString();

    await _dbHelper.updateEvidenceSyncStatus(
      localId: item.entityLocalId,
      syncStatus: 'SYNCED',
      serverId: serverId,
    );
  }

  Future<void> _syncFinalReport(SyncItemModel item) async {
    final db = await _dbHelper.database;
    final rows = await db.query('local_reports', where: 'local_id = ?', whereArgs: [item.entityLocalId]);
    if (rows.isEmpty) return;

    final row = rows.first;
    final inspectionLocalId = row['inspection_local_id'] as String;
    final parentServerId = await _resolveParentServerId(
      inspectionLocalId,
      row['inspection_server_id'] as String?,
    );

    if (parentServerId == null || parentServerId.isEmpty) {
      throw SyncDependencyException(
        parentEntityType: 'Inspection',
        parentLocalId: inspectionLocalId,
      );
    }

    final payload = {
      'inspection_id': parentServerId,
      'physical_beneficiary_count': row['physical_beneficiary_count'],
      'roster_discrepancy_count': row['roster_discrepancy_count'],
      'cleanliness_score': row['cleanliness_score'],
      'food_nutrition_score': row['food_nutrition_score'],
      'infrastructure_condition_score': row['infrastructure_condition_score'],
      'inspector_summary': row['inspector_summary'],
      'overall_verdict': row['overall_verdict'],
    };

    final result = await _remoteDataSource.submitReport(payload);
    final serverId = result['id']?.toString();

    await _dbHelper.updateReportSyncStatus(
      localId: item.entityLocalId,
      syncStatus: 'SYNCED',
      serverId: serverId,
    );

    await _dbHelper.updateInspectionStatus(
      localId: inspectionLocalId,
      status: 'COMPLETED',
      syncStatus: 'SYNCED',
    );
  }

  Future<String?> _resolveParentServerId(String localId, String? currentParentServerId) async {
    if (currentParentServerId != null &&
        currentParentServerId.isNotEmpty &&
        !currentParentServerId.startsWith('local_')) {
      return currentParentServerId;
    }
    final inspection = await _dbHelper.getInspectionByLocalId(localId);
    if (inspection?.serverId != null &&
        inspection!.serverId!.isNotEmpty &&
        !inspection.serverId!.startsWith('local_')) {
      return inspection.serverId;
    }
    return null;
  }

  void _notifyProgress(int total, int completed, int failed, String? action) {
    if (!_progressController.isClosed) {
      _progressController.add(SyncProgress(
        total: total,
        completed: completed,
        failed: failed,
        isRunning: _isSyncing,
        currentAction: action,
      ));
    }
  }

  void dispose() {
    _progressController.close();
  }
}
