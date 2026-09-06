// =====================================================================
// DRISHTI Mobile App: Field Observation & Deficiency Notes Model
// =====================================================================

class NoteModel {
  final String localId;
  final String inspectionLocalId;
  final String? inspectionServerId;
  final String category; // GENERAL_OBSERVATION, DEFICIENCY, BENEFICIARY_FEEDBACK, FOLLOW_UP
  final String title;
  final String content;
  final String createdAt;
  final String syncStatus;

  NoteModel({
    required this.localId,
    required this.inspectionLocalId,
    this.inspectionServerId,
    required this.category,
    required this.title,
    required this.content,
    required this.createdAt,
    this.syncStatus = 'PENDING',
  });

  factory NoteModel.fromSqlite(Map<String, dynamic> row) {
    return NoteModel(
      localId: row['local_id'] as String,
      inspectionLocalId: row['inspection_local_id'] as String,
      inspectionServerId: row['inspection_server_id'] as String?,
      category: row['category'] as String,
      title: row['title'] as String,
      content: row['content'] as String,
      createdAt: row['created_at'] as String,
      syncStatus: row['sync_status'] as String? ?? 'PENDING',
    );
  }

  Map<String, dynamic> toSqlite() {
    return {
      'local_id': localId,
      'inspection_local_id': inspectionLocalId,
      'inspection_server_id': inspectionServerId,
      'category': category,
      'title': title,
      'content': content,
      'created_at': createdAt,
      'sync_status': syncStatus,
    };
  }
}
