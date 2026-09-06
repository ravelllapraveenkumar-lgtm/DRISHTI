// =====================================================================
// DRISHTI Mobile App: Local SQLite Schema Definition (Dart / sqflite)
// Ministry of Social Justice and Empowerment (MoSJE) - SIH 2026
// Version 2: Enriched with notes, reports, templates, and strict server UUID mapping
// =====================================================================

class DrishtiSqliteSchema {
  static const int databaseVersion = 2;
  static const String databaseName = 'drishti_inspector_local.db';

  // 1. Local Cached Inspections Table
  static const String createTableLocalInspections = '''
    CREATE TABLE IF NOT EXISTS local_inspections (
      local_id TEXT PRIMARY KEY,
      server_id TEXT,
      inspection_code TEXT NOT NULL,
      institution_id TEXT NOT NULL,
      institution_name TEXT NOT NULL,
      institution_district TEXT NOT NULL,
      institution_state TEXT NOT NULL,
      target_latitude REAL NOT NULL,
      target_longitude REAL NOT NULL,
      geofence_radius_meters INTEGER NOT NULL DEFAULT 150,
      priority TEXT NOT NULL,
      status TEXT NOT NULL,
      mandated_date TEXT NOT NULL,
      due_date TEXT NOT NULL,
      inspection_reason TEXT NOT NULL,
      special_instructions TEXT,
      ai_alert_summary TEXT,
      ai_attention_score REAL,
      cached_at TEXT NOT NULL,
      sync_status TEXT NOT NULL DEFAULT 'SYNCED',
      last_error TEXT
    );
  ''';

  // 2. Checklist Templates Cache Table (for full offline checklist rendering)
  static const String createTableChecklistTemplates = '''
    CREATE TABLE IF NOT EXISTS local_checklist_templates (
      id TEXT PRIMARY KEY,
      name TEXT NOT NULL,
      scheme_category TEXT NOT NULL,
      version INTEGER NOT NULL DEFAULT 1,
      cached_at TEXT NOT NULL
    );
  ''';

  // 3. Checklist Items Cache Table
  static const String createTableChecklistItems = '''
    CREATE TABLE IF NOT EXISTS local_checklist_items (
      id TEXT PRIMARY KEY,
      template_id TEXT NOT NULL,
      section_name TEXT NOT NULL,
      item_question TEXT NOT NULL,
      field_type TEXT NOT NULL DEFAULT 'BOOLEAN',
      is_mandatory INTEGER NOT NULL DEFAULT 1,
      guidance_notes TEXT,
      order_index INTEGER NOT NULL DEFAULT 0,
      FOREIGN KEY (template_id) REFERENCES local_checklist_templates (id) ON DELETE CASCADE
    );
  ''';

  // 4. Local Checklist Responses Table
  static const String createTableLocalChecklistResponses = '''
    CREATE TABLE IF NOT EXISTS local_checklist_responses (
      local_id TEXT PRIMARY KEY,
      server_id TEXT,
      inspection_local_id TEXT NOT NULL,
      inspection_server_id TEXT,
      checklist_item_id TEXT NOT NULL,
      question_text TEXT,
      section_name TEXT,
      response_boolean INTEGER,
      response_value TEXT,
      inspector_comment TEXT,
      gps_latitude REAL,
      gps_longitude REAL,
      captured_at TEXT NOT NULL,
      sync_status TEXT NOT NULL DEFAULT 'PENDING',
      last_error TEXT,
      FOREIGN KEY (inspection_local_id) REFERENCES local_inspections (local_id) ON DELETE CASCADE
    );
  ''';

  // 5. Local Evidence Metadata Table (Tamper-Resistant)
  static const String createTableLocalEvidence = '''
    CREATE TABLE IF NOT EXISTS local_evidence (
      local_id TEXT PRIMARY KEY,
      server_id TEXT,
      inspection_local_id TEXT NOT NULL,
      inspection_server_id TEXT,
      evidence_type TEXT NOT NULL,
      file_name TEXT NOT NULL,
      local_file_path TEXT NOT NULL,
      sha256_checksum TEXT NOT NULL,
      description TEXT NOT NULL,
      gps_latitude REAL NOT NULL,
      gps_longitude REAL NOT NULL,
      gps_accuracy_meters REAL NOT NULL,
      geofence_verified INTEGER NOT NULL DEFAULT 0,
      timestamp_captured TEXT NOT NULL,
      sync_status TEXT NOT NULL DEFAULT 'PENDING',
      sync_attempts INTEGER NOT NULL DEFAULT 0,
      last_error TEXT,
      FOREIGN KEY (inspection_local_id) REFERENCES local_inspections (local_id) ON DELETE CASCADE
    );
  ''';

  // 6. Field Notes & Deficiencies Table
  static const String createTableLocalNotes = '''
    CREATE TABLE IF NOT EXISTS local_notes (
      local_id TEXT PRIMARY KEY,
      inspection_local_id TEXT NOT NULL,
      inspection_server_id TEXT,
      category TEXT NOT NULL,
      title TEXT NOT NULL,
      content TEXT NOT NULL,
      created_at TEXT NOT NULL,
      sync_status TEXT NOT NULL DEFAULT 'PENDING',
      FOREIGN KEY (inspection_local_id) REFERENCES local_inspections (local_id) ON DELETE CASCADE
    );
  ''';

  // 7. Inspection Final Reports Table
  static const String createTableLocalReports = '''
    CREATE TABLE IF NOT EXISTS local_reports (
      local_id TEXT PRIMARY KEY,
      server_id TEXT,
      inspection_local_id TEXT NOT NULL,
      inspection_server_id TEXT,
      physical_beneficiary_count INTEGER NOT NULL,
      roster_discrepancy_count INTEGER NOT NULL DEFAULT 0,
      cleanliness_score INTEGER,
      food_nutrition_score INTEGER,
      infrastructure_condition_score INTEGER,
      inspector_summary TEXT NOT NULL,
      overall_verdict TEXT NOT NULL,
      submission_timestamp TEXT NOT NULL,
      sync_status TEXT NOT NULL DEFAULT 'PENDING',
      last_error TEXT,
      FOREIGN KEY (inspection_local_id) REFERENCES local_inspections (local_id) ON DELETE CASCADE
    );
  ''';

  // 8. Outbox Sync Queue Table (Dependency-Ordered)
  static const String createTableLocalSyncQueue = '''
    CREATE TABLE IF NOT EXISTS local_sync_queue (
      id TEXT PRIMARY KEY,
      entity_type TEXT NOT NULL,
      entity_local_id TEXT NOT NULL,
      parent_server_id TEXT,
      endpoint TEXT NOT NULL,
      http_method TEXT NOT NULL,
      payload_json TEXT NOT NULL,
      dependency_sync_id TEXT,
      attempt_count INTEGER NOT NULL DEFAULT 0,
      last_attempt_at TEXT,
      error_message TEXT,
      sync_status TEXT NOT NULL DEFAULT 'PENDING',
      created_at TEXT NOT NULL
    );
  ''';

  // 9. Local Session / User Cache Table
  static const String createTableUserSession = '''
    CREATE TABLE IF NOT EXISTS local_user_session (
      id TEXT PRIMARY KEY,
      user_id TEXT NOT NULL,
      email TEXT NOT NULL,
      full_name TEXT NOT NULL,
      role TEXT NOT NULL,
      token TEXT NOT NULL,
      cached_at TEXT NOT NULL
    );
  ''';

  static const List<String> allTables = [
    createTableLocalInspections,
    createTableChecklistTemplates,
    createTableChecklistItems,
    createTableLocalChecklistResponses,
    createTableLocalEvidence,
    createTableLocalNotes,
    createTableLocalReports,
    createTableLocalSyncQueue,
    createTableUserSession,
  ];
}
