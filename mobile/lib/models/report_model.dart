// =====================================================================
// DRISHTI Mobile App: Final Inspection Report Model
// Adheres strictly to backend InspectionReportCreate schema
// =====================================================================

class ReportModel {
  final String localId;
  final String? serverId;
  final String inspectionLocalId;
  final String? inspectionServerId;
  final int physicalBeneficiaryCount;
  final int rosterDiscrepancyCount;
  final int? cleanlinessScore; // 1-5
  final int? foodNutritionScore; // 1-5
  final int? infrastructureConditionScore; // 1-5
  final String inspectorSummary;
  final String overallVerdict; // NO_CONCERN, MINOR_ISSUES_RECTIFIED_ON_SITE, VERIFICATION_REQUIRED, SERIOUS_VIOLATION_REPORTED
  final String submissionTimestamp;
  final String syncStatus; // PENDING, SYNCING, SYNCED, FAILED
  final String? lastError;

  ReportModel({
    required this.localId,
    this.serverId,
    required this.inspectionLocalId,
    this.inspectionServerId,
    required this.physicalBeneficiaryCount,
    this.rosterDiscrepancyCount = 0,
    this.cleanlinessScore,
    this.foodNutritionScore,
    this.infrastructureConditionScore,
    required this.inspectorSummary,
    required this.overallVerdict,
    required dynamic submissionTimestamp,
    this.syncStatus = 'PENDING',
    this.lastError,
  }) : submissionTimestamp = submissionTimestamp is DateTime
            ? submissionTimestamp.toIso8601String()
            : submissionTimestamp.toString();

  factory ReportModel.fromSqlite(Map<String, dynamic> row) {
    return ReportModel(
      localId: row['local_id'] as String,
      serverId: row['server_id'] as String?,
      inspectionLocalId: row['inspection_local_id'] as String,
      inspectionServerId: row['inspection_server_id'] as String?,
      physicalBeneficiaryCount: row['physical_beneficiary_count'] as int,
      rosterDiscrepancyCount: row['roster_discrepancy_count'] as int? ?? 0,
      cleanlinessScore: row['cleanliness_score'] as int?,
      foodNutritionScore: row['food_nutrition_score'] as int?,
      infrastructureConditionScore: row['infrastructure_condition_score'] as int?,
      inspectorSummary: row['inspector_summary'] as String,
      overallVerdict: row['overall_verdict'] as String,
      submissionTimestamp: row['submission_timestamp'] as String,
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
      'physical_beneficiary_count': physicalBeneficiaryCount,
      'roster_discrepancy_count': rosterDiscrepancyCount,
      'cleanliness_score': cleanlinessScore,
      'food_nutrition_score': foodNutritionScore,
      'infrastructure_condition_score': infrastructureConditionScore,
      'inspector_summary': inspectorSummary,
      'overall_verdict': overallVerdict,
      'submission_timestamp': submissionTimestamp,
      'sync_status': syncStatus,
      'last_error': lastError,
    };
  }

  /// Maps strictly to backend InspectionReportCreate schema
  Map<String, dynamic> toBackendJson({required String parentServerUuid}) {
    return {
      'inspection_id': parentServerUuid,
      'physical_beneficiary_count': physicalBeneficiaryCount,
      'roster_discrepancy_count': rosterDiscrepancyCount,
      'cleanliness_score': cleanlinessScore,
      'food_nutrition_score': foodNutritionScore,
      'infrastructure_condition_score': infrastructureConditionScore,
      'inspector_summary': inspectorSummary,
      'overall_verdict': overallVerdict,
    };
  }

  /// Maps strictly to backend InspectionReportCreate schema
  Map<String, dynamic> toApiPayload(String resolvedInspectionServerId) {
    return toBackendJson(parentServerUuid: resolvedInspectionServerId);
  }

  ReportModel copyWith({
    String? serverId,
    String? inspectionServerId,
    String? syncStatus,
    String? lastError,
  }) {
    return ReportModel(
      localId: localId,
      serverId: serverId ?? this.serverId,
      inspectionLocalId: inspectionLocalId,
      inspectionServerId: inspectionServerId ?? this.inspectionServerId,
      physicalBeneficiaryCount: physicalBeneficiaryCount,
      rosterDiscrepancyCount: rosterDiscrepancyCount,
      cleanlinessScore: cleanlinessScore,
      foodNutritionScore: foodNutritionScore,
      infrastructureConditionScore: infrastructureConditionScore,
      inspectorSummary: inspectorSummary,
      overallVerdict: overallVerdict,
      submissionTimestamp: submissionTimestamp,
      syncStatus: syncStatus ?? this.syncStatus,
      lastError: lastError ?? this.lastError,
    );
  }
}
