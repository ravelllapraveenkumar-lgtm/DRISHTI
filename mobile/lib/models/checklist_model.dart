// =====================================================================
// DRISHTI Mobile App: Checklist Templates & Submission Models
// Maps strictly to backend ChecklistTemplate and ChecklistSubmission schemas
// =====================================================================

class ChecklistItemModel {
  final String id;
  final String templateId;
  final String sectionName;
  final String itemQuestion;
  final String fieldType; // BOOLEAN, NUMERIC, TEXT, MULTI_SELECT
  final bool isMandatory;
  final String? guidanceNotes;
  final int orderIndex;

  ChecklistItemModel({
    required this.id,
    required this.templateId,
    required this.sectionName,
    required this.itemQuestion,
    this.fieldType = 'BOOLEAN',
    this.isMandatory = true,
    this.guidanceNotes,
    this.orderIndex = 0,
  });

  factory ChecklistItemModel.fromJson(Map<String, dynamic> json) {
    return ChecklistItemModel(
      id: json['id']?.toString() ?? '',
      templateId: json['template_id']?.toString() ?? '',
      sectionName: json['section_name']?.toString() ?? 'General Compliance',
      itemQuestion: json['item_question']?.toString() ?? '',
      fieldType: json['field_type']?.toString() ?? 'BOOLEAN',
      isMandatory: json['is_mandatory'] == true || json['is_mandatory'] == 1,
      guidanceNotes: json['guidance_notes']?.toString(),
      orderIndex: json['order_index'] != null ? int.tryParse(json['order_index'].toString()) ?? 0 : 0,
    );
  }

  factory ChecklistItemModel.fromSqlite(Map<String, dynamic> row) {
    return ChecklistItemModel(
      id: row['id'] as String,
      templateId: row['template_id'] as String,
      sectionName: row['section_name'] as String,
      itemQuestion: row['item_question'] as String,
      fieldType: row['field_type'] as String,
      isMandatory: (row['is_mandatory'] as int) == 1,
      guidanceNotes: row['guidance_notes'] as String?,
      orderIndex: row['order_index'] as int,
    );
  }

  Map<String, dynamic> toSqlite() {
    return {
      'id': id,
      'template_id': templateId,
      'section_name': sectionName,
      'item_question': itemQuestion,
      'field_type': fieldType,
      'is_mandatory': isMandatory ? 1 : 0,
      'guidance_notes': guidanceNotes,
      'order_index': orderIndex,
    };
  }
}

class ChecklistTemplateModel {
  final String id;
  final String name;
  final String schemeCategory;
  final int version;
  final List<ChecklistItemModel> items;

  ChecklistTemplateModel({
    required this.id,
    required this.name,
    required this.schemeCategory,
    this.version = 1,
    required this.items,
  });

  factory ChecklistTemplateModel.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'] as List<dynamic>? ?? [];
    return ChecklistTemplateModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Standard MoSJE Inspection Checklist',
      schemeCategory: json['scheme_category']?.toString() ?? 'ALL',
      version: json['version'] != null ? int.tryParse(json['version'].toString()) ?? 1 : 1,
      items: rawItems.map((e) => ChecklistItemModel.fromJson(e as Map<String, dynamic>)).toList(),
    );
  }

  Map<String, dynamic> toSqlite() {
    return {
      'id': id,
      'name': name,
      'scheme_category': schemeCategory,
      'version': version,
      'cached_at': DateTime.now().toIso8601String(),
    };
  }
}

class ChecklistResponseModel {
  final String localId;
  final String? serverId;
  final String inspectionLocalId;
  final String? inspectionServerId;
  final String checklistItemId;
  final String? questionText;
  final String? sectionName;
  final bool? responseBoolean;
  final String? responseValue;
  final String? inspectorComment;
  final double? gpsLatitude;
  final double? gpsLongitude;
  final String capturedAt;
  final String syncStatus; // PENDING, SYNCING, SYNCED, FAILED
  final String? lastError;

  String get itemQuestion => questionText ?? '';

  ChecklistResponseModel({
    required this.localId,
    this.serverId,
    required this.inspectionLocalId,
    this.inspectionServerId,
    required this.checklistItemId,
    String? questionText,
    String? itemQuestion,
    this.sectionName,
    this.responseBoolean,
    this.responseValue,
    this.inspectorComment,
    this.gpsLatitude,
    this.gpsLongitude,
    dynamic capturedAt,
    this.syncStatus = 'PENDING',
    this.lastError,
  })  : questionText = questionText ?? itemQuestion,
        capturedAt = (capturedAt is DateTime)
            ? capturedAt.toIso8601String()
            : (capturedAt?.toString() ?? DateTime.now().toIso8601String());

  factory ChecklistResponseModel.fromSqlite(Map<String, dynamic> row) {
    return ChecklistResponseModel(
      localId: row['local_id'] as String,
      serverId: row['server_id'] as String?,
      inspectionLocalId: row['inspection_local_id'] as String,
      inspectionServerId: row['inspection_server_id'] as String?,
      checklistItemId: row['checklist_item_id'] as String,
      questionText: row['question_text'] as String?,
      sectionName: row['section_name'] as String?,
      responseBoolean: row['response_boolean'] != null ? (row['response_boolean'] as int) == 1 : null,
      responseValue: row['response_value'] as String?,
      inspectorComment: row['inspector_comment'] as String?,
      gpsLatitude: row['gps_latitude'] != null ? (row['gps_latitude'] as num).toDouble() : null,
      gpsLongitude: row['gps_longitude'] != null ? (row['gps_longitude'] as num).toDouble() : null,
      capturedAt: row['captured_at'] as String,
      syncStatus: row['sync_status'] as String? ?? 'PENDING',
      lastError: row['last_error'] as String?,
    );
  }

  Map<String, dynamic> toSqlite() {
    return {
      'local_id': localId,
      'server_id': serverId,
      'inspection_local_id': inspectionLocalId,
      'inspection_server_id': inspectionServerId,
      'checklist_item_id': checklistItemId,
      'question_text': questionText,
      'section_name': sectionName,
      'response_boolean': responseBoolean == null ? null : (responseBoolean! ? 1 : 0),
      'response_value': responseValue,
      'inspector_comment': inspectorComment,
      'gps_latitude': gpsLatitude,
      'gps_longitude': gpsLongitude,
      'captured_at': capturedAt,
      'sync_status': syncStatus,
      'last_error': lastError,
    };
  }

  /// Maps to backend ChecklistSubmissionCreate schema item
  Map<String, dynamic> toBackendJson({String? parentServerUuid}) {
    final payload = <String, dynamic>{
      'checklist_item_id': checklistItemId,
      'response_boolean': responseBoolean,
      'response_value': responseValue,
      'inspector_comment': inspectorComment,
      'gps_latitude': gpsLatitude,
      'gps_longitude': gpsLongitude,
    };
    if (parentServerUuid != null || inspectionServerId != null) {
      payload['inspection_id'] = parentServerUuid ?? inspectionServerId;
    }
    return payload;
  }

  /// Maps to backend ChecklistSubmissionCreate schema
  Map<String, dynamic> toApiPayload(String resolvedInspectionServerId) {
    return {
      'inspection_id': resolvedInspectionServerId,
      'checklist_item_id': checklistItemId,
      'response_boolean': responseBoolean,
      'response_value': responseValue,
      'inspector_comment': inspectorComment,
      'gps_latitude': gpsLatitude,
      'gps_longitude': gpsLongitude,
    };
  }

  ChecklistResponseModel copyWith({
    String? serverId,
    String? inspectionServerId,
    bool? responseBoolean,
    String? responseValue,
    String? inspectorComment,
    double? gpsLatitude,
    double? gpsLongitude,
    String? syncStatus,
    String? lastError,
  }) {
    return ChecklistResponseModel(
      localId: localId,
      serverId: serverId ?? this.serverId,
      inspectionLocalId: inspectionLocalId,
      inspectionServerId: inspectionServerId ?? this.inspectionServerId,
      checklistItemId: checklistItemId,
      questionText: questionText,
      sectionName: sectionName,
      responseBoolean: responseBoolean ?? this.responseBoolean,
      responseValue: responseValue ?? this.responseValue,
      inspectorComment: inspectorComment ?? this.inspectorComment,
      gpsLatitude: gpsLatitude ?? this.gpsLatitude,
      gpsLongitude: gpsLongitude ?? this.gpsLongitude,
      capturedAt: capturedAt,
      syncStatus: syncStatus ?? this.syncStatus,
      lastError: lastError ?? this.lastError,
    );
  }
}

/// Type alias for backward compatibility across data and provider layers
typedef ChecklistSubmissionModel = ChecklistResponseModel;

