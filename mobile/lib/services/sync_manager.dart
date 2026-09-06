import 'dart:async';
import 'package:flutter/foundation.dart';
import '../core/errors/app_exception.dart';
import '../data/local/database_helper.dart';
import '../data/remote/checklist_api_service.dart';
import '../data/remote/evidence_api_service.dart';
import '../data/remote/inspection_api_service.dart';
import '../data/remote/report_api_service.dart';
import '../models/checklist_model.dart';
import '../models/evidence_model.dart';
import '../models/report_model.dart';
import '../models/sync_queue_item.dart';

// =====================================================================
// DRISHTI Mobile App: Outbox Sync Manager State Machine
// Enforces atomic dependency ordering: Inspection -> Checklist -> Evidence -> Report
// =====================================================================

class SyncProgressState {
  final bool isSyncing;
  final int pendingCount;
  final int completedCount;
  final int failedCount;
  final String? lastMessage;

  SyncProgressState({
    this.isSyncing = false,
    this.pendingCount = 0,
    this.completedCount = 0,
    this.failedCount = 0,
    this.lastMessage,
  });
}

class SyncManager {
  final DatabaseHelper _dbHelper;
  final ChecklistApiService _checklistApi;
  final EvidenceApiService _evidenceApi;
  final ReportApiService _reportApi;
  final InspectionApiService? _inspectionApi;

  final ValueNotifier<SyncProgressState> stateNotifier =
      ValueNotifier<SyncProgressState>(SyncProgressState());

  bool _isProcessing = false;

  SyncManager({
    DatabaseHelper? dbHelper,
    required ChecklistApiService checklistApi,
    required EvidenceApiService evidenceApi,
    required ReportApiService reportApi,
    InspectionApiService? inspectionApi,
  })  : _dbHelper = dbHelper ?? DatabaseHelper.instance,
        _checklistApi = checklistApi,
        _evidenceApi = evidenceApi,
        _reportApi = reportApi,
        _inspectionApi = inspectionApi;

  /// Trigger synchronization of all queued offline operations
  Future<SyncProgressState> processSyncQueue() async {
    if (_isProcessing) return stateNotifier.value;
    _isProcessing = true;

    int completed = 0;
    int failed = 0;

    try {
      final queueItems = await _dbHelper.getPendingOrFailedSyncItems();
      final totalPending = queueItems.length;

      stateNotifier.value = SyncProgressState(
        isSyncing: true,
        pendingCount: totalPending,
        completedCount: 0,
        failedCount: 0,
        lastMessage: totalPending == 0 ? 'All local records synchronized.' : 'Synchronizing $totalPending pending records...',
      );

      if (totalPending == 0) {
        _isProcessing = false;
        return stateNotifier.value;
      }

      // Group and sort items strictly according to dependency order:
      // 0. INSPECTION
      // 1. STATUS_UPDATE
      // 2. CHECKLIST_BATCH
      // 3. EVIDENCE
      // 4. REPORT
      final sortedItems = _sortQueueByDependency(queueItems);

      for (final item in sortedItems) {
        try {
          await _dbHelper.updateSyncItemStatus(item.id, SyncStatus.syncing);

          final success = await _syncSingleItem(item);
          if (success) {
            completed++;
            await _dbHelper.markSyncItemSuccessful(item.id);
          } else {
            failed++;
          }
        } catch (e) {
          failed++;
          final errorMsg = e is AppException ? e.message : e.toString();
          await _dbHelper.updateSyncItemStatus(
            item.id,
            SyncStatus.failed,
            errorMessage: errorMsg,
          );
        }

        stateNotifier.value = SyncProgressState(
          isSyncing: true,
          pendingCount: totalPending - completed - failed,
          completedCount: completed,
          failedCount: failed,
          lastMessage: 'Synchronized $completed of $totalPending items...',
        );
      }
    } finally {
      _isProcessing = false;
      stateNotifier.value = SyncProgressState(
        isSyncing: false,
        pendingCount: await _dbHelper.getPendingSyncCount(),
        completedCount: completed,
        failedCount: failed,
        lastMessage: failed > 0
            ? 'Sync finished with $failed errors. Tap retry.'
            : 'All records successfully synchronized with DRISHTI Central.',
      );
    }

    return stateNotifier.value;
  }

  /// Syncs individual queue item with strict parent UUID verification
  Future<bool> _syncSingleItem(SyncQueueItem item) async {
    // 1. Resolve parent server UUID
    String? serverUuid = item.parentServerId;
    String parentLocalId = item.entityLocalId;

    if (item.entityType == 'CHECKLIST_BATCH' || item.entityType == 'CHECKLIST') {
      parentLocalId = item.entityLocalId;
      if (serverUuid == null || serverUuid.isEmpty) {
        final insp = await _dbHelper.getInspectionByLocalId(item.entityLocalId);
        serverUuid = insp?.serverId;
      }
    } else if (item.entityType == 'EVIDENCE') {
      final evidence = await _dbHelper.getEvidenceByLocalId(item.entityLocalId);
      if (evidence != null) {
        parentLocalId = evidence.inspectionLocalId;
        if (serverUuid == null || serverUuid.isEmpty) {
          final insp = await _dbHelper.getInspectionByLocalId(evidence.inspectionLocalId);
          serverUuid = insp?.serverId ?? evidence.inspectionServerId;
        }
      } else {
        final insp = await _dbHelper.getInspectionByLocalId(item.entityLocalId);
        serverUuid ??= insp?.serverId;
      }
    } else if (item.entityType == 'REPORT' || item.entityType == 'FINAL_REPORT') {
      final report = await _dbHelper.getReportByLocalId(item.entityLocalId) ??
          await _dbHelper.getReportForInspection(item.entityLocalId);
      if (report != null) {
        parentLocalId = report.inspectionLocalId;
        if (serverUuid == null || serverUuid.isEmpty) {
          final insp = await _dbHelper.getInspectionByLocalId(report.inspectionLocalId);
          serverUuid = insp?.serverId ?? report.inspectionServerId;
        }
      } else {
        final insp = await _dbHelper.getInspectionByLocalId(item.entityLocalId);
        serverUuid ??= insp?.serverId;
      }
    } else if (item.entityType == 'STATUS_UPDATE') {
      parentLocalId = item.entityLocalId;
      if (serverUuid == null || serverUuid.isEmpty) {
        final insp = await _dbHelper.getInspectionByLocalId(item.entityLocalId);
        serverUuid = insp?.serverId;
      }
    }

    // A child record must NOT sync before its parent has a valid server ID
    if (serverUuid == null || serverUuid.isEmpty) {
      throw SyncDependencyException(
        parentEntityType: 'INSPECTION',
        parentLocalId: parentLocalId,
      );
    }

    switch (item.entityType) {
      case 'CHECKLIST_BATCH':
      case 'CHECKLIST':
        return await _syncChecklistBatch(item, serverUuid);

      case 'EVIDENCE':
        return await _syncEvidence(item, serverUuid);

      case 'REPORT':
      case 'FINAL_REPORT':
        return await _syncReport(item, serverUuid);

      case 'STATUS_UPDATE':
        if (_inspectionApi != null) {
          await _inspectionApi!.updateInspectionStatus(serverUuid, 'IN_PROGRESS');
          return true;
        }
        return false;

      default:
        return false;
    }
  }

  Future<bool> _syncChecklistBatch(SyncQueueItem item, String serverInspectionUuid) async {
    final responses = await _dbHelper.getChecklistResponses(item.entityLocalId);
    if (responses.isEmpty) return true;

    final result = await _checklistApi.submitChecklistBatch(
      inspectionServerId: serverInspectionUuid,
      items: responses,
    );

    // Update local responses with server ID
    for (int i = 0; i < responses.length; i++) {
      final local = responses[i];
      final serverMatch = i < result.length ? result[i] : null;
      await _dbHelper.saveChecklistResponse(
        local.copyWith(
          serverId: serverMatch?.serverId,
          inspectionServerId: serverInspectionUuid,
          syncStatus: 'SYNCED',
        ),
      );
    }

    return true;
  }

  Future<bool> _syncEvidence(SyncQueueItem item, String serverInspectionUuid) async {
    final evidence = await _dbHelper.getEvidenceByLocalId(item.entityLocalId);
    final evidences = await _dbHelper.getEvidenceForInspection(item.entityLocalId);
    final match = evidence ?? (evidences.isNotEmpty ? evidences.first : null);

    if (match == null) return true;

    final updated = await _evidenceApi.registerEvidenceMetadata(
      localEvidence: match,
      parentServerUuid: serverInspectionUuid,
    );

    await _dbHelper.updateEvidenceSyncStatus(
      match.localId,
      'SYNCED',
      serverId: updated.serverId,
    );

    return true;
  }

  Future<bool> _syncReport(SyncQueueItem item, String serverInspectionUuid) async {
    final report = await _dbHelper.getReportByLocalId(item.entityLocalId) ??
        await _dbHelper.getReportForInspection(item.entityLocalId);
    if (report == null) return true;

    final updated = await _reportApi.submitInspectionReport(
      localReport: report,
      parentServerUuid: serverInspectionUuid,
    );

    await _dbHelper.updateReportSyncStatus(
      report.localId,
      'SYNCED',
      serverId: updated.serverId,
    );

    // Update local inspection status to SUBMITTED
    await _dbHelper.updateInspectionStatus(report.inspectionLocalId, 'SUBMITTED');

    return true;
  }

  List<SyncQueueItem> _sortQueueByDependency(List<SyncQueueItem> items) {
    int getOrder(String entityType) {
      switch (entityType) {
        case 'INSPECTION':
          return 0;
        case 'STATUS_UPDATE':
          return 1;
        case 'CHECKLIST_BATCH':
        case 'CHECKLIST':
          return 2;
        case 'EVIDENCE':
          return 3;
        case 'REPORT':
        case 'FINAL_REPORT':
          return 4;
        default:
          return 5;
      }
    }

    final sorted = List<SyncQueueItem>.from(items);
    sorted.sort((a, b) => getOrder(a.entityType).compareTo(getOrder(b.entityType)));
    return sorted;
  }
}
