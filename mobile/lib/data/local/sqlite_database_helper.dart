import 'dart:async';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';
import 'sqlite_schema.dart';
import '../../models/inspection_model.dart';
import '../../models/checklist_model.dart';
import '../../models/evidence_model.dart';
import '../../models/note_model.dart';
import '../../models/report_model.dart';
import '../../models/sync_item_model.dart';
import '../../models/user_model.dart';

// =====================================================================
// DRISHTI Mobile App: Local SQLite Database Helper
// Supports offline-first durability, transactions & sync queue operations
// =====================================================================

class SqliteDatabaseHelper {
  static final SqliteDatabaseHelper instance = SqliteDatabaseHelper._internal();
  static Database? _database;

  SqliteDatabaseHelper._internal();

  /// For unit testing or headless runtime without native sqlite drivers:
  /// can inject an open mock/in-memory database instance.
  static void setMockDatabase(Database? mockDb) {
    _database = mockDb;
  }

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, DrishtiSqliteSchema.databaseName);

    return await openDatabase(
      path,
      version: DrishtiSqliteSchema.databaseVersion,
      onCreate: (db, version) async {
        final batch = db.batch();
        for (final tableSql in DrishtiSqliteSchema.allTables) {
          batch.execute(tableSql);
        }
        await batch.commit(noResult: true);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          // Migration from version 1 to 2: ensure all new tables exist without data loss
          for (final tableSql in DrishtiSqliteSchema.allTables) {
            await db.execute(tableSql);
          }
        }
      },
    );
  }

  // -------------------------------------------------------------
  // USER SESSION
  // -------------------------------------------------------------
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
    final rows = await db.query('local_user_session', limit: 1);
    if (rows.isEmpty) return null;
    final row = rows.first;
    return UserModel(
      id: row['user_id'] as String,
      email: row['email'] as String,
      fullName: row['full_name'] as String,
      roles: [(row['role'] as String? ?? 'FIELD_INSPECTOR')],
      token: row['token'] as String?,
    );
  }

  Future<void> clearUserSession() async {
    final db = await database;
    await db.delete('local_user_session');
  }

  // -------------------------------------------------------------
  // INSPECTIONS
  // -------------------------------------------------------------
  Future<void> saveInspections(List<InspectionModel> inspections) async {
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

  Future<List<InspectionModel>> getCachedInspections() async {
    final db = await database;
    final rows = await db.query('local_inspections', orderBy: 'due_date ASC');
    return rows.map((r) => InspectionModel.fromSqlite(r)).toList();
  }

  Future<InspectionModel?> getInspectionByLocalId(String localId) async {
    final db = await database;
    final rows = await db.query('local_inspections', where: 'local_id = ?', whereArgs: [localId]);
    if (rows.isEmpty) return null;
    return InspectionModel.fromSqlite(rows.first);
  }

  Future<InspectionModel?> getInspectionByServerId(String serverId) async {
    final db = await database;
    final rows = await db.query('local_inspections', where: 'server_id = ?', whereArgs: [serverId]);
    if (rows.isEmpty) return null;
    return InspectionModel.fromSqlite(rows.first);
  }

  Future<void> updateInspectionStatus({
    required String localId,
    required String status,
    String? syncStatus,
  }) async {
    final db = await database;
    final values = <String, dynamic>{'status': status};
    if (syncStatus != null) values['sync_status'] = syncStatus;
    await db.update('local_inspections', values, where: 'local_id = ?', whereArgs: [localId]);
  }

  // -------------------------------------------------------------
  // CHECKLIST TEMPLATES & ITEMS
  // -------------------------------------------------------------
  Future<void> saveChecklistTemplates(List<ChecklistTemplateModel> templates) async {
    final db = await database;
    await db.transaction((txn) async {
      for (final t in templates) {
        await txn.insert('local_checklist_templates', t.toSqlite(), conflictAlgorithm: ConflictAlgorithm.replace);
        for (final item in t.items) {
          await txn.insert('local_checklist_items', item.toSqlite(), conflictAlgorithm: ConflictAlgorithm.replace);
        }
      }
    });
  }

  Future<List<ChecklistItemModel>> getChecklistItemsForTemplate(String templateId) async {
    final db = await database;
    final rows = await db.query(
      'local_checklist_items',
      where: 'template_id = ?',
      whereArgs: [templateId],
      orderBy: 'order_index ASC',
    );
    return rows.map((r) => ChecklistItemModel.fromSqlite(r)).toList();
  }

  Future<List<ChecklistItemModel>> getAllCachedChecklistItems() async {
    final db = await database;
    final rows = await db.query('local_checklist_items', orderBy: 'order_index ASC');
    return rows.map((r) => ChecklistItemModel.fromSqlite(r)).toList();
  }

  // -------------------------------------------------------------
  // CHECKLIST RESPONSES
  // -------------------------------------------------------------
  Future<void> saveChecklistResponses(List<ChecklistResponseModel> responses) async {
    final db = await database;
    final batch = db.batch();
    for (final r in responses) {
      batch.insert(
        'local_checklist_responses',
        r.toSqlite(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  Future<List<ChecklistResponseModel>> getResponsesForInspection(String inspectionLocalId) async {
    final db = await database;
    final rows = await db.query(
      'local_checklist_responses',
      where: 'inspection_local_id = ?',
      whereArgs: [inspectionLocalId],
    );
    return rows.map((r) => ChecklistResponseModel.fromSqlite(r)).toList();
  }

  // -------------------------------------------------------------
  // EVIDENCE
  // -------------------------------------------------------------
  Future<void> saveEvidence(EvidenceModel evidence) async {
    final db = await database;
    await db.insert(
      'local_evidence',
      evidence.toSqlite(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<EvidenceModel>> getEvidenceForInspection(String inspectionLocalId) async {
    final db = await database;
    final rows = await db.query(
      'local_evidence',
      where: 'inspection_local_id = ?',
      whereArgs: [inspectionLocalId],
      orderBy: 'timestamp_captured DESC',
    );
    return rows.map((r) => EvidenceModel.fromSqlite(r)).toList();
  }

  Future<void> updateEvidenceSyncStatus({
    required String localId,
    required String syncStatus,
    String? serverId,
    String? lastError,
  }) async {
    final db = await database;
    if (serverId != null && lastError != null) {
      await db.rawUpdate(
        'UPDATE local_evidence SET sync_status = ?, sync_attempts = sync_attempts + 1, server_id = ?, last_error = ? WHERE local_id = ?',
        [syncStatus, serverId, lastError, localId],
      );
    } else if (serverId != null) {
      await db.rawUpdate(
        'UPDATE local_evidence SET sync_status = ?, sync_attempts = sync_attempts + 1, server_id = ? WHERE local_id = ?',
        [syncStatus, serverId, localId],
      );
    } else if (lastError != null) {
      await db.rawUpdate(
        'UPDATE local_evidence SET sync_status = ?, sync_attempts = sync_attempts + 1, last_error = ? WHERE local_id = ?',
        [syncStatus, lastError, localId],
      );
    } else {
      await db.rawUpdate(
        'UPDATE local_evidence SET sync_status = ?, sync_attempts = sync_attempts + 1 WHERE local_id = ?',
        [syncStatus, localId],
      );
    }
  }

  // -------------------------------------------------------------
  // NOTES
  // -------------------------------------------------------------
  Future<void> saveNote(NoteModel note) async {
    final db = await database;
    await db.insert('local_notes', note.toSqlite(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<NoteModel>> getNotesForInspection(String inspectionLocalId) async {
    final db = await database;
    final rows = await db.query(
      'local_notes',
      where: 'inspection_local_id = ?',
      whereArgs: [inspectionLocalId],
      orderBy: 'created_at DESC',
    );
    return rows.map((r) => NoteModel.fromSqlite(r)).toList();
  }

  // -------------------------------------------------------------
  // FINAL REPORTS
  // -------------------------------------------------------------
  Future<void> saveReport(ReportModel report) async {
    final db = await database;
    await db.insert('local_reports', report.toSqlite(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<ReportModel?> getReportForInspection(String inspectionLocalId) async {
    final db = await database;
    final rows = await db.query('local_reports', where: 'inspection_local_id = ?', whereArgs: [inspectionLocalId]);
    if (rows.isEmpty) return null;
    return ReportModel.fromSqlite(rows.first);
  }

  Future<void> updateReportSyncStatus({
    required String localId,
    required String syncStatus,
    String? serverId,
    String? lastError,
  }) async {
    final db = await database;
    final values = <String, dynamic>{'sync_status': syncStatus};
    if (serverId != null) values['server_id'] = serverId;
    if (lastError != null) values['last_error'] = lastError;
    await db.update('local_reports', values, where: 'local_id = ?', whereArgs: [localId]);
  }

  // -------------------------------------------------------------
  // OUTBOX SYNC QUEUE
  // -------------------------------------------------------------
  Future<void> enqueueSyncItem(SyncItemModel item) async {
    final db = await database;
    await db.insert('local_sync_queue', item.toSqlite(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<SyncItemModel>> getPendingSyncItems() async {
    final db = await database;
    final rows = await db.query(
      'local_sync_queue',
      where: 'sync_status IN (?, ?)',
      whereArgs: ['PENDING', 'FAILED'],
      orderBy: 'created_at ASC',
    );
    return rows.map((r) => SyncItemModel.fromSqlite(r)).toList();
  }

  Future<List<SyncItemModel>> getAllSyncItems() async {
    final db = await database;
    final rows = await db.query('local_sync_queue', orderBy: 'created_at DESC');
    return rows.map((r) => SyncItemModel.fromSqlite(r)).toList();
  }

  Future<int> getPendingSyncCount() async {
    final db = await database;
    final count = Sqflite.firstIntValue(await db.rawQuery(
      "SELECT COUNT(*) FROM local_sync_queue WHERE sync_status IN ('PENDING', 'FAILED')",
    ));
    return count ?? 0;
  }

  Future<void> updateSyncItemStatus({
    required String id,
    required String syncStatus,
    String? errorMessage,
  }) async {
    final db = await database;
    final now = DateTime.now().toIso8601String();
    if (errorMessage != null) {
      await db.rawUpdate(
        'UPDATE local_sync_queue SET sync_status = ?, attempt_count = attempt_count + 1, last_attempt_at = ?, error_message = ? WHERE id = ?',
        [syncStatus, now, errorMessage, id],
      );
    } else {
      await db.rawUpdate(
        'UPDATE local_sync_queue SET sync_status = ?, attempt_count = attempt_count + 1, last_attempt_at = ? WHERE id = ?',
        [syncStatus, now, id],
      );
    }
  }

  Future<void> updateDependentParentServerId({
    required String parentLocalId,
    required String parentServerId,
  }) async {
    final db = await database;
    // Update local_inspections
    await db.update(
      'local_inspections',
      {'server_id': parentServerId},
      where: 'local_id = ?',
      whereArgs: [parentLocalId],
    );

    // Update child records
    await db.update(
      'local_checklist_responses',
      {'inspection_server_id': parentServerId},
      where: 'inspection_local_id = ?',
      whereArgs: [parentLocalId],
    );

    await db.update(
      'local_evidence',
      {'inspection_server_id': parentServerId},
      where: 'inspection_local_id = ?',
      whereArgs: [parentLocalId],
    );

    await db.update(
      'local_reports',
      {'inspection_server_id': parentServerId},
      where: 'inspection_local_id = ?',
      whereArgs: [parentLocalId],
    );

    // Update queue items
    await db.update(
      'local_sync_queue',
      {'parent_server_id': parentServerId},
      where: 'entity_local_id = ? OR parent_server_id IS NULL',
      whereArgs: [parentLocalId],
    );
  }
}
