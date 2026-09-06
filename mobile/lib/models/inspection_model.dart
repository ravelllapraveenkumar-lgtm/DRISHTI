// =====================================================================
// DRISHTI Mobile App: Inspection & Assignment Model
// Maps strictly to existing PostgreSQL schema and FastAPI schemas
// =====================================================================

class InspectionModel {
  final String localId;
  final String? serverId;
  final String inspectionCode;
  final String institutionId;
  final String institutionName;
  final String institutionDistrict;
  final String institutionState;
  final String? institutionAddress;
  final double targetLatitude;
  final double targetLongitude;
  final int geofenceRadiusMeters;
  final String priority; // ROUTINE, HIGH, EMERGENCY, SURPRISE_INSPECTION
  final String status; // SCHEDULED, ASSIGNED, IN_PROGRESS, COMPLETED, CANCELLED
  final String mandatedDate;
  final String dueDate;
  final String inspectionReason;
  final String? specialInstructions;
  final String? aiAlertSummary;
  final double? aiAttentionScore;
  final String? assignmentId;
  final String? assignmentStatus; // PENDING_ACCEPTANCE, ACCEPTED, ON_SITE, COMPLETED
  final String cachedAt;
  final String syncStatus; // PENDING, SYNCING, SYNCED, FAILED
  final String? lastError;

  InspectionModel({
    required this.localId,
    this.serverId,
    required this.inspectionCode,
    required this.institutionId,
    required this.institutionName,
    required this.institutionDistrict,
    required this.institutionState,
    this.institutionAddress,
    required this.targetLatitude,
    required this.targetLongitude,
    this.geofenceRadiusMeters = 150,
    required this.priority,
    required this.status,
    required this.mandatedDate,
    required this.dueDate,
    required this.inspectionReason,
    this.specialInstructions,
    this.aiAlertSummary,
    this.aiAttentionScore,
    this.assignmentId,
    this.assignmentStatus,
    required this.cachedAt,
    this.syncStatus = 'SYNCED',
    this.lastError,
  });

  bool get isCompleted => status == 'COMPLETED';
  bool get isInProgress => status == 'IN_PROGRESS' || assignmentStatus == 'ON_SITE';
  bool get hasAiAlert => aiAlertSummary != null && aiAlertSummary!.isNotEmpty;
  bool get isHighPriority =>
      priority.toUpperCase() == 'HIGH' ||
      priority.toUpperCase() == 'EMERGENCY' ||
      priority.toUpperCase() == 'SURPRISE_INSPECTION' ||
      priority.toUpperCase() == 'URGENT';
  bool get isSubmitted =>
      status.toUpperCase() == 'SUBMITTED' ||
      status.toUpperCase() == 'COMPLETED' ||
      status.toUpperCase() == 'APPROVED';

  factory InspectionModel.fromApiAssignment(Map<String, dynamic> json) {
    final serverInspectionId = json['inspection_id']?.toString() ?? json['id']?.toString() ?? '';
    return InspectionModel(
      localId: 'local_insp_$serverInspectionId',
      serverId: serverInspectionId,
      inspectionCode: json['inspection_code']?.toString() ?? 'INSP-PENDING',
      institutionId: json['institution_id']?.toString() ?? '',
      institutionName: json['institution_name']?.toString() ?? 'MoSJE Grantee Institution',
      institutionDistrict: json['institution_district']?.toString() ?? json['district']?.toString() ?? 'District Office',
      institutionState: json['institution_state']?.toString() ?? json['state']?.toString() ?? 'State Department',
      institutionAddress: json['institution_address']?.toString() ?? json['address']?.toString(),
      targetLatitude: (json['latitude'] != null)
          ? double.tryParse(json['latitude'].toString()) ?? 26.8467
          : 26.8467,
      targetLongitude: (json['longitude'] != null)
          ? double.tryParse(json['longitude'].toString()) ?? 80.9462
          : 80.9462,
      geofenceRadiusMeters: json['geofence_radius_meters'] != null
          ? int.tryParse(json['geofence_radius_meters'].toString()) ?? 150
          : 150,
      priority: json['priority']?.toString() ?? 'ROUTINE',
      status: json['inspection_status']?.toString() ?? json['status']?.toString() ?? 'ASSIGNED',
      mandatedDate: json['assigned_at']?.toString() ?? DateTime.now().toIso8601String(),
      dueDate: json['due_date']?.toString() ?? DateTime.now().add(const Duration(days: 7)).toIso8601String(),
      inspectionReason: json['notes']?.toString() ?? 'Routine Annual Compliance Audit',
      specialInstructions: json['special_instructions']?.toString(),
      aiAlertSummary: json['ai_alert_summary']?.toString(),
      aiAttentionScore: json['ai_attention_score'] != null
          ? double.tryParse(json['ai_attention_score'].toString())
          : null,
      assignmentId: json['id']?.toString(),
      assignmentStatus: json['status']?.toString() ?? 'PENDING_ACCEPTANCE',
      cachedAt: DateTime.now().toIso8601String(),
      syncStatus: 'SYNCED',
    );
  }

  factory InspectionModel.fromBackendJson(Map<String, dynamic> json) {
    final serverInspectionId = json['id']?.toString() ?? '';
    return InspectionModel(
      localId: 'local_insp_$serverInspectionId',
      serverId: serverInspectionId,
      inspectionCode: json['inspection_code']?.toString() ?? 'INSP-PENDING',
      institutionId: json['institution_id']?.toString() ?? '',
      institutionName: json['institution_name']?.toString() ?? 'MoSJE Grantee Institution',
      institutionDistrict: json['institution_district']?.toString() ?? 'District Office',
      institutionState: json['institution_state']?.toString() ?? 'State Department',
      institutionAddress: json['institution_address']?.toString() ?? json['address']?.toString(),
      targetLatitude: (json['latitude'] != null)
          ? double.tryParse(json['latitude'].toString()) ?? 26.8467
          : 26.8467,
      targetLongitude: (json['longitude'] != null)
          ? double.tryParse(json['longitude'].toString()) ?? 80.9462
          : 80.9462,
      geofenceRadiusMeters: json['geofence_radius_meters'] != null
          ? int.tryParse(json['geofence_radius_meters'].toString()) ?? 150
          : 150,
      priority: json['priority']?.toString() ?? 'ROUTINE',
      status: json['status']?.toString() ?? 'ASSIGNED',
      mandatedDate: json['mandated_date']?.toString() ?? DateTime.now().toIso8601String(),
      dueDate: json['due_date']?.toString() ?? DateTime.now().add(const Duration(days: 7)).toIso8601String(),
      inspectionReason: json['inspection_reason']?.toString() ?? 'Routine Annual Compliance Audit',
      specialInstructions: json['special_instructions']?.toString(),
      aiAlertSummary: json['ai_alert_summary']?.toString(),
      aiAttentionScore: json['ai_attention_score'] != null
          ? double.tryParse(json['ai_attention_score'].toString())
          : null,
      cachedAt: DateTime.now().toIso8601String(),
      syncStatus: 'SYNCED',
    );
  }

  factory InspectionModel.fromSqlite(Map<String, dynamic> row) {
    return InspectionModel(
      localId: row['local_id'] as String,
      serverId: row['server_id'] as String?,
      inspectionCode: row['inspection_code'] as String,
      institutionId: row['institution_id'] as String,
      institutionName: row['institution_name'] as String,
      institutionDistrict: row['institution_district'] as String,
      institutionState: row['institution_state'] as String,
      targetLatitude: (row['target_latitude'] as num).toDouble(),
      targetLongitude: (row['target_longitude'] as num).toDouble(),
      geofenceRadiusMeters: row['geofence_radius_meters'] as int? ?? 150,
      priority: row['priority'] as String,
      status: row['status'] as String,
      mandatedDate: row['mandated_date'] as String,
      dueDate: row['due_date'] as String,
      inspectionReason: row['inspection_reason'] as String,
      specialInstructions: row['special_instructions'] as String?,
      aiAlertSummary: row['ai_alert_summary'] as String?,
      aiAttentionScore: row['ai_attention_score'] != null
          ? (row['ai_attention_score'] as num).toDouble()
          : null,
      cachedAt: row['cached_at'] as String,
      syncStatus: row['sync_status'] as String? ?? 'SYNCED',
      lastError: row['last_error'] as String?,
    );
  }

  Map<String, dynamic> toSqlite() {
    return {
      'local_id': localId,
      'server_id': serverId,
      'inspection_code': inspectionCode,
      'institution_id': institutionId,
      'institution_name': institutionName,
      'institution_district': institutionDistrict,
      'institution_state': institutionState,
      'target_latitude': targetLatitude,
      'target_longitude': targetLongitude,
      'geofence_radius_meters': geofenceRadiusMeters,
      'priority': priority,
      'status': status,
      'mandated_date': mandatedDate,
      'due_date': dueDate,
      'inspection_reason': inspectionReason,
      'special_instructions': specialInstructions,
      'ai_alert_summary': aiAlertSummary,
      'ai_attention_score': aiAttentionScore,
      'cached_at': cachedAt,
      'sync_status': syncStatus,
      'last_error': lastError,
    };
  }

  InspectionModel copyWith({
    String? status,
    String? assignmentStatus,
    String? syncStatus,
    String? lastError,
    String? serverId,
  }) {
    return InspectionModel(
      localId: localId,
      serverId: serverId ?? this.serverId,
      inspectionCode: inspectionCode,
      institutionId: institutionId,
      institutionName: institutionName,
      institutionDistrict: institutionDistrict,
      institutionState: institutionState,
      institutionAddress: institutionAddress,
      targetLatitude: targetLatitude,
      targetLongitude: targetLongitude,
      geofenceRadiusMeters: geofenceRadiusMeters,
      priority: priority,
      status: status ?? this.status,
      mandatedDate: mandatedDate,
      dueDate: dueDate,
      inspectionReason: inspectionReason,
      specialInstructions: specialInstructions,
      aiAlertSummary: aiAlertSummary,
      aiAttentionScore: aiAttentionScore,
      assignmentId: assignmentId,
      assignmentStatus: assignmentStatus ?? this.assignmentStatus,
      cachedAt: cachedAt,
      syncStatus: syncStatus ?? this.syncStatus,
      lastError: lastError ?? this.lastError,
    );
  }
}
