import 'dart:async';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'sqlite_schema.dart';
import '../../models/inspection_model.dart';
import '../../models/checklist_model.dart';
import '../../models/evidence_model.dart';
import '../../models/note_model.dart';
import '../../models/report_model.dart';
import '../../models/sync_queue_item.dart';
import '../../models/user_model.dart';

// =====================================================================
// DRISHTI Mobile App: Local SQLite Database Helper
// Singleton with safe migrations and transactional offline persistence
// =====================================================================

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._internal();
  static Database? _database;

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, DrishtiSqliteSchema.databaseName);

    return await openDatabase(
      path,
      version: DrishtiSqliteSchema.databaseVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    for (final tableSql in DrishtiSqliteSchema.allTables) {
      await db.execute(tableSql);
    }
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Migration safe: never drop tables, execute IF NOT EXISTS
    for (final tableSql in DrishtiSqliteSchema.allTables) {
      await db.execute(tableSql);
    }
  }

  // -------------------------------------------------------------------
  // 1. Session & Auth Cache
  // -------------------------------------------------------------------
  Future<void> saveUserSession(UserModel user) async {
    final db = await database;
    await db.insert(
      'local_user_session',
      user.toSqlite(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<UserModel?> getCachedUserSession() async {
    final db = await database;
    final maps = await db.query('local_user_session', limit: 1);
    if (maps.isEmpty) return null;
    final m = maps.first;
    return UserModel(
      id: m['user_id']?.toString() ?? '',
      email: m['email']?.toString() ?? '',
      fullName: m['full_name']?.toString() ?? '',
      roles: [m['role']?.toString() ?? 'FIELD_INSPECTOR'],
      token: m['token']?.toString(),
    );
  }

  Future<void> clearUserSession() async {
    final db = await database;
    await db.delete('local_user_session');
  }

  // -------------------------------------------------------------------
  // 2. Inspections Cache
  // -------------------------------------------------------------------
  Future<void> upsertInspection(InspectionModel inspection) async {
    final db = await database;
    await db.insert(
      'local_inspections',
      inspection.toSqlite(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> cacheInspectionsBatch(List<InspectionModel> inspections) async {
    final db = await database;
    final batch = db.batch();
    for (final insp in inspections) {
      batch.insert(
        'local_inspections',
        insp.toSqlite(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  Future<List<InspectionModel>> getAllCachedInspections() async {
    final db = await database;
    final results = await db.query('local_inspections', orderBy: 'due_date ASC');
    return results.map((m) => InspectionModel.fromSqlite(m)).toList();
  }

  Future<InspectionModel?> getInspectionByLocalId(String localId) async {
    final db = await database;
    final results = await db.query(
      'local_inspections',
      where: 'local_id = ?',
      whereArgs: [localId],
      limit: 1,
    );
    if (results.isEmpty) return null;
    return InspectionModel.fromSqlite(results.first);
  }

  Future<InspectionModel?> getInspectionByServerId(String serverId) async {
    final db = await database;
    final results = await db.query(
      'local_inspections',
      where: 'server_id = ?',
      whereArgs: [serverId],
      limit: 1,
    );
    if (results.isEmpty) return null;
    return InspectionModel.fromSqlite(results.first);
  }

  Future<void> updateInspectionServerId(String localId, String serverId) async {
    final db = await database;
    await db.update(
      'local_inspections',
      {'server_id': serverId, 'sync_status': 'SYNCED'},
      where: 'local_id = ?',
      whereArgs: [localId],
    );
    // Cascade update to children with missing server ID
    await db.update(
      'local_checklist_responses',
      {'inspection_server_id': serverId},
      where: 'inspection_local_id = ? AND inspection_server_id IS NULL',
      whereArgs: [localId],
    );
    await db.update(
      'local_evidence',
      {'inspection_server_id': serverId},
      where: 'inspection_local_id = ? AND inspection_server_id IS NULL',
      whereArgs: [localId],
    );
    await db.update(
      'local_reports',
      {'inspection_server_id': serverId},
      where: 'inspection_local_id = ? AND inspection_server_id IS NULL',
      whereArgs: [localId],
    );
    // Cascade to outbox sync queue items
    await db.update(
      'local_sync_queue',
      {'parent_server_id': serverId},
      where: 'parent_server_id IS NULL AND (entity_local_id = ? OR entity_local_id IN (SELECT local_id FROM local_evidence WHERE inspection_local_id = ?) OR entity_local_id IN (SELECT local_id FROM local_reports WHERE inspection_local_id = ?))',
      whereArgs: [localId, localId, localId],
    );
  }

  Future<void> updateInspectionStatus(String localId, String status) async {
    final db = await database;
    await db.update(
      'local_inspections',
      {'status': status},
      where: 'local_id = ?',
      whereArgs: [localId],
    );
  }

  // -------------------------------------------------------------------
  // 3. Checklist Templates & Questions Cache
  // -------------------------------------------------------------------
  Future<void> cacheChecklistTemplates(List<ChecklistTemplateModel> templates) async {
    final db = await database;
    final batch = db.batch();
    for (final t in templates) {
      batch.insert(
        'local_checklist_templates',
        {
          'id': t.id,
          'name': t.name,
          'scheme_category': t.schemeCategory,
          'version': t.version,
          'cached_at': DateTime.now().toIso8601String(),
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      for (final item in t.items) {
        batch.insert(
          'local_checklist_items',
          item.toSqlite(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    }
    await batch.commit(noResult: true);
  }

  Future<List<ChecklistItemModel>> getCachedChecklistItems({String? templateId}) async {
    final db = await database;
    final List<Map<String, dynamic>> results;
    if (templateId != null && templateId.isNotEmpty) {
      results = await db.query(
        'local_checklist_items',
        where: 'template_id = ?',
        whereArgs: [templateId],
        orderBy: 'order_index ASC',
      );
    } else {
      results = await db.query('local_checklist_items', orderBy: 'order_index ASC');
    }
    return results.map((m) => ChecklistItemModel.fromJson(m)).toList();
  }

  // -------------------------------------------------------------------
  // 4. Checklist Responses
  // -------------------------------------------------------------------
  Future<void> saveChecklistResponse(ChecklistSubmissionModel response) async {
    final db = await database;
    await db.insert(
      'local_checklist_responses',
      response.toSqlite(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<ChecklistSubmissionModel>> getChecklistResponses(String inspectionLocalId) async {
    final db = await database;
    final results = await db.query(
      'local_checklist_responses',
      where: 'inspection_local_id = ?',
      whereArgs: [inspectionLocalId],
    );
    return results.map((m) => ChecklistSubmissionModel.fromSqlite(m)).toList();
  }

  // -------------------------------------------------------------------
  // 5. Evidence
  // -------------------------------------------------------------------
  Future<void> saveEvidence(EvidenceModel evidence) async {
    final db = await database;
    await db.insert(
      'local_evidence',
      evidence.toSqlite(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<EvidenceModel?> getEvidenceByLocalId(String localId) async {
    final db = await database;
    final results = await db.query(
      'local_evidence',
      where: 'local_id = ?',
      whereArgs: [localId],
      limit: 1,
    );
    if (results.isEmpty) return null;
    return EvidenceModel.fromSqlite(results.first);
  }

  Future<List<EvidenceModel>> getEvidenceForInspection(String inspectionLocalId) async {
    final db = await database;
    final results = await db.query(
      'local_evidence',
      where: 'inspection_local_id = ?',
      whereArgs: [inspectionLocalId],
      orderBy: 'timestamp_captured DESC',
    );
    return results.map((m) => EvidenceModel.fromSqlite(m)).toList();
  }

  Future<void> updateEvidenceSyncStatus(
    String localId,
    String status, {
    String? serverId,
    String? error,
  }) async {
    final db = await database;
    final values = <String, dynamic>{'sync_status': status};
    if (serverId != null) values['server_id'] = serverId;
    if (error != null) values['last_error'] = error;
    await db.update('local_evidence', values, where: 'local_id = ?', whereArgs: [localId]);
  }

  // -------------------------------------------------------------------
  // 6. Notes & Deficiencies
  // -------------------------------------------------------------------
  Future<void> saveNote(NoteModel note) async {
    final db = await database;
    await db.insert(
      'local_notes',
      note.toSqlite(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<NoteModel>> getNotesForInspection(String inspectionLocalId) async {
    final db = await database;
    final results = await db.query(
      'local_notes',
      where: 'inspection_local_id = ?',
      whereArgs: [inspectionLocalId],
      orderBy: 'created_at DESC',
    );
    return results.map((m) => NoteModel.fromSqlite(m)).toList();
  }

  // -------------------------------------------------------------------
  // 7. Inspection Reports
  // -------------------------------------------------------------------
  Future<void> saveReportDraft(ReportModel report) async {
    final db = await database;
    await db.insert(
      'local_reports',
      report.toSqlite(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<ReportModel?> getReportByLocalId(String localId) async {
    final db = await database;
    final results = await db.query(
      'local_reports',
      where: 'local_id = ?',
      whereArgs: [localId],
      limit: 1,
    );
    if (results.isEmpty) return null;
    return ReportModel.fromSqlite(results.first);
  }

  Future<ReportModel?> getReportForInspection(String inspectionLocalId) async {
    final db = await database;
    final results = await db.query(
      'local_reports',
      where: 'inspection_local_id = ?',
      whereArgs: [inspectionLocalId],
      limit: 1,
    );
    if (results.isEmpty) return null;
    return ReportModel.fromSqlite(results.first);
  }

  Future<void> updateReportSyncStatus(
    String localId,
    String status, {
    String? serverId,
    String? error,
  }) async {
    final db = await database;
    final values = <String, dynamic>{'sync_status': status};
    if (serverId != null) values['server_id'] = serverId;
    if (error != null) values['last_error'] = error;
    await db.update('local_reports', values, where: 'local_id = ?', whereArgs: [localId]);
  }

  // -------------------------------------------------------------------
  // 8. Outbox Sync Queue State Machine
  // -------------------------------------------------------------------
  Future<void> enqueueSyncItem(SyncQueueItem item) async {
    final db = await database;
    await db.insert(
      'local_sync_queue',
      item.toSqlite(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<SyncQueueItem>> getPendingOrFailedSyncItems() async {
    final db = await database;
    final results = await db.query(
      'local_sync_queue',
      where: "sync_status IN ('PENDING', 'FAILED', 'LOCAL_PENDING', 'SYNC_FAILED')",
      orderBy: 'created_at ASC',
    );
    return results.map((m) => SyncQueueItem.fromSqlite(m)).toList();
  }

  Future<List<SyncQueueItem>> getAllSyncQueueItems() async {
    final db = await database;
    final results = await db.query('local_sync_queue', orderBy: 'created_at DESC');
    return results.map((m) => SyncQueueItem.fromSqlite(m)).toList();
  }

  Future<int> getPendingSyncCount() async {
    final db = await database;
    final count = Sqflite.firstIntValue(
      await db.rawQuery(
        "SELECT COUNT(*) FROM local_sync_queue WHERE sync_status IN ('PENDING', 'SYNCING', 'FAILED', 'LOCAL_PENDING', 'SYNC_FAILED')",
      ),
    );
    return count ?? 0;
  }

  Future<void> updateSyncItemStatus(
    String id,
    SyncStatus status, {
    String? errorMessage,
    String? parentServerId,
  }) async {
    final db = await database;
    final values = <String, dynamic>{
      'sync_status': status.code,
      'last_attempt_at': DateTime.now().toIso8601String(),
    };
    if (errorMessage != null) values['error_message'] = errorMessage;
    if (parentServerId != null) values['parent_server_id'] = parentServerId;

    await db.rawUpdate(
      'UPDATE local_sync_queue SET sync_status = ?, attempt_count = attempt_count + 1, last_attempt_at = ?, error_message = ? WHERE id = ?',
      [status.code, DateTime.now().toIso8601String(), errorMessage, id],
    );
  }

  Future<void> markSyncItemSuccessful(String id) async {
    final db = await database;
    await db.update(
      'local_sync_queue',
      {
        'sync_status': 'SYNCED',
        'error_message': null,
        'last_attempt_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> deleteSyncItem(String id) async {
    final db = await database;
    await db.delete('local_sync_queue', where: 'id = ?', whereArgs: [id]);
  }
}
