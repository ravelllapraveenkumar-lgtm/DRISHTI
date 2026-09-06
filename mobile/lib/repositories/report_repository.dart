import 'package:uuid/uuid.dart';
import '../models/report_model.dart';
import '../models/sync_item_model.dart';
import '../data/local/sqlite_database_helper.dart';
import '../data/remote/remote_data_source.dart';

// =====================================================================
// DRISHTI Mobile App: Final Report Repository
// Handles drafting, verdict selection, offline persistence & outbox sync
// =====================================================================

class ReportRepository {
  final RemoteDataSource _remoteDataSource;
  final SqliteDatabaseHelper _dbHelper;
  final Uuid _uuid = const Uuid();

  ReportRepository({
    RemoteDataSource? remoteDataSource,
    SqliteDatabaseHelper? dbHelper,
  })  : _remoteDataSource = remoteDataSource ?? RemoteDataSource(),
        _dbHelper = dbHelper ?? SqliteDatabaseHelper.instance;

  Future<ReportModel?> getReport(String inspectionLocalId) async {
    return await _dbHelper.getReportForInspection(inspectionLocalId);
  }

  Future<void> submitFinalReport(ReportModel report) async {
    // 1. Save locally with PENDING status
    await _dbHelper.saveReport(report);

    // 2. Enqueue in Outbox Queue
    final syncItem = SyncItemModel(
      id: 'sync_rep_${_uuid.v4()}',
      entityType: 'FINAL_REPORT',
      entityLocalId: report.localId,
      parentServerId: report.inspectionServerId,
      endpoint: '/api/v1/inspection-reports',
      httpMethod: 'POST',
      payloadJson: '',
      createdAt: DateTime.now().toIso8601String(),
    );
    await _dbHelper.enqueueSyncItem(syncItem);

    // 3. Opportunistic instant submission if online and server ID is resolved
    if (report.inspectionServerId != null &&
        report.inspectionServerId!.isNotEmpty &&
        !report.inspectionServerId!.startsWith('local_')) {
      try {
        final payload = report.toApiPayload(report.inspectionServerId!);
        final response = await _remoteDataSource.submitReport(payload);
        final serverId = response['id']?.toString();

        await _dbHelper.updateReportSyncStatus(
          localId: report.localId,
          syncStatus: 'SYNCED',
          serverId: serverId,
        );

        await _dbHelper.updateInspectionStatus(
          localId: report.inspectionLocalId,
          status: 'COMPLETED',
          syncStatus: 'SYNCED',
        );

        await _dbHelper.updateSyncItemStatus(id: syncItem.id, syncStatus: 'SYNCED');
      } catch (_) {
        // Stays queued for background sync engine
      }
    }
  }
}
