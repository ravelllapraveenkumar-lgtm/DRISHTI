import 'dart:convert';
import 'package:uuid/uuid.dart';
import '../models/inspection_model.dart';
import '../models/sync_item_model.dart';
import '../data/local/sqlite_database_helper.dart';
import '../data/remote/remote_data_source.dart';

// =====================================================================
// DRISHTI Mobile App: Inspections Repository (Offline-First)
// Caches assignments locally, coordinates arrives, and manages sync queue
// =====================================================================

class InspectionFetchResult {
  final List<InspectionModel> inspections;
  final bool isFromCache;
  final String? notice;

  InspectionFetchResult({
    required this.inspections,
    required this.isFromCache,
    this.notice,
  });
}

class InspectionRepository {
  final RemoteDataSource _remoteDataSource;
  final SqliteDatabaseHelper _dbHelper;
  final Uuid _uuid = const Uuid();

  InspectionRepository({
    RemoteDataSource? remoteDataSource,
    SqliteDatabaseHelper? dbHelper,
  })  : _remoteDataSource = remoteDataSource ?? RemoteDataSource(),
        _dbHelper = dbHelper ?? SqliteDatabaseHelper.instance;

  Future<InspectionFetchResult> getInspectorInspections(String inspectorId) async {
    try {
      final remoteList = await _remoteDataSource.getInspectorAssignments(inspectorId);
      if (remoteList.isNotEmpty) {
        await _dbHelper.saveInspections(remoteList);
      }
      return InspectionFetchResult(
        inspections: remoteList,
        isFromCache: false,
        notice: 'Live synchronization active with DRISHTI Central.',
      );
    } catch (e) {
      final cachedList = await _dbHelper.getCachedInspections();
      return InspectionFetchResult(
        inspections: cachedList,
        isFromCache: true,
        notice: 'Offline — changes saved locally in secure SQLite storage.',
      );
    }
  }

  Future<InspectionModel?> getInspectionDetails(String localId) async {
    return await _dbHelper.getInspectionByLocalId(localId);
  }

  Future<void> acceptAssignment(InspectionModel inspection) async {
    final assignmentId = inspection.assignmentId ?? inspection.serverId;
    if (assignmentId != null) {
      try {
        await _remoteDataSource.acceptAssignment(assignmentId);
      } catch (_) {
        // Enqueue or fallback to local state
      }
    }
    await _dbHelper.updateInspectionStatus(
      localId: inspection.localId,
      status: 'ASSIGNED',
      syncStatus: 'SYNCED',
    );
  }

  Future<void> arriveOnSite(InspectionModel inspection) async {
    // 1. Update local database immediately
    await _dbHelper.updateInspectionStatus(
      localId: inspection.localId,
      status: 'IN_PROGRESS',
      syncStatus: 'PENDING',
    );

    // 2. Enqueue in Outbox
    final assignmentId = inspection.assignmentId ?? inspection.serverId ?? inspection.localId;
    final syncItem = SyncItemModel(
      id: 'sync_arr_${_uuid.v4()}',
      entityType: 'ASSIGNMENT_ARRIVE',
      entityLocalId: inspection.localId,
      parentServerId: inspection.serverId,
      endpoint: '/api/v1/inspection-assignments/$assignmentId/arrive',
      httpMethod: 'POST',
      payloadJson: jsonEncode({'assignment_id': assignmentId}),
      createdAt: DateTime.now().toIso8601String(),
    );
    await _dbHelper.enqueueSyncItem(syncItem);

    // 3. Opportunistic instant sync if online
    try {
      await _remoteDataSource.arriveAssignment(assignmentId);
      await _dbHelper.updateSyncItemStatus(id: syncItem.id, syncStatus: 'SYNCED');
      await _dbHelper.updateInspectionStatus(
        localId: inspection.localId,
        status: 'IN_PROGRESS',
        syncStatus: 'SYNCED',
      );
    } catch (_) {
      // Retained in queue for background sync engine
    }
  }
}
