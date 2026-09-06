import '../../core/constants/api_endpoints.dart';
import '../../core/network/api_client.dart';
import '../../models/report_model.dart';

// =====================================================================
// DRISHTI Mobile App: Final Report Submission Service
// Submits consolidated field reports to the DRISHTI FastAPI backend
// =====================================================================

class ReportApiService {
  final ApiClient _client;

  ReportApiService(this._client);

  /// Submits completed field inspection report
  Future<ReportModel> submitInspectionReport({
    required ReportModel localReport,
    required String parentServerUuid,
  }) async {
    final payload = localReport.toBackendJson(parentServerUuid: parentServerUuid);
    final response = await _client.post(ApiEndpoints.reports, body: payload);

    final map = Map<String, dynamic>.from(response as Map);
    return localReport.copyWith(
      serverId: map['id']?.toString(),
      inspectionServerId: parentServerUuid,
      syncStatus: 'SYNCED',
      lastError: null,
    );
  }

  /// Retrieves previously submitted report for an inspection
  Future<ReportModel?> getReport(String reportServerId) async {
    final response = await _client.get(ApiEndpoints.reportDetails(reportServerId));
    if (response is Map) {
      final map = Map<String, dynamic>.from(response);
      return ReportModel(
        localId: 'server_${map['id']}',
        serverId: map['id']?.toString(),
        inspectionLocalId: 'local_${map['inspection_id']}',
        inspectionServerId: map['inspection_id']?.toString(),
        physicalBeneficiaryCount: (map['physical_beneficiary_count'] as num?)?.toInt() ?? 0,
        rosterDiscrepancyCount: (map['roster_discrepancy_count'] as num?)?.toInt() ?? 0,
        cleanlinessScore: (map['cleanliness_score'] as num?)?.toInt(),
        foodNutritionScore: (map['food_nutrition_score'] as num?)?.toInt(),
        infrastructureConditionScore: (map['infrastructure_condition_score'] as num?)?.toInt(),
        inspectorSummary: map['inspector_summary']?.toString() ?? '',
        overallVerdict: map['overall_verdict']?.toString() ?? 'COMPLIANT',
        submissionTimestamp: map['submission_timestamp'] != null
            ? DateTime.parse(map['submission_timestamp'])
            : DateTime.now(),
        syncStatus: 'SYNCED',
      );
    }
    return null;
  }
}
