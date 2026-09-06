import '../../core/constants/api_endpoints.dart';
import '../../core/network/api_client.dart';
import '../../models/checklist_model.dart';

// =====================================================================
// DRISHTI Mobile App: Checklist Remote Service
// Supports fetching templates and atomic batch submission with GPS
// =====================================================================

class ChecklistApiService {
  final ApiClient _client;

  ChecklistApiService(this._client);

  /// Retrieves all active checklist templates with ordered questions
  Future<List<ChecklistTemplateModel>> getChecklistTemplates() async {
    final response = await _client.get(ApiEndpoints.checklistTemplates);
    if (response is List) {
      return response
          .map((e) => ChecklistTemplateModel.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    }
    return [];
  }

  /// Submits answers in batch for an inspection
  Future<List<ChecklistSubmissionModel>> submitChecklistBatch({
    required String inspectionServerId,
    required List<ChecklistSubmissionModel> items,
  }) async {
    final payload = {
      'inspection_id': inspectionServerId,
      'items': items.map((i) => i.toBackendJson()).toList(),
    };

    final response = await _client.post(ApiEndpoints.submitChecklists, body: payload);

    if (response is List) {
      return response.map((e) {
        final map = Map<String, dynamic>.from(e as Map);
        return ChecklistSubmissionModel(
          localId: 'server_${map['id']}',
          serverId: map['id']?.toString(),
          inspectionLocalId: 'local_$inspectionServerId',
          inspectionServerId: inspectionServerId,
          checklistItemId: map['checklist_item_id']?.toString() ?? '',
          itemQuestion: map['item_question']?.toString(),
          sectionName: map['section_name']?.toString(),
          responseBoolean: map['response_boolean'],
          responseValue: map['response_value']?.toString(),
          inspectorComment: map['inspector_comment']?.toString(),
          gpsLatitude: (map['gps_latitude'] as num?)?.toDouble(),
          gpsLongitude: (map['gps_longitude'] as num?)?.toDouble(),
          capturedAt: map['captured_at'] != null
              ? DateTime.parse(map['captured_at'])
              : DateTime.now(),
          syncStatus: 'SYNCED',
        );
      }).toList();
    }
    return [];
  }

  /// Retrieves previously submitted checklist answers for an inspection
  Future<List<ChecklistSubmissionModel>> getSubmittedResponses(String inspectionServerId) async {
    final response = await _client.get(
      ApiEndpoints.inspectionChecklistResponses(inspectionServerId),
    );
    if (response is List) {
      return response.map((e) {
        final map = Map<String, dynamic>.from(e as Map);
        return ChecklistSubmissionModel(
          localId: 'server_${map['id']}',
          serverId: map['id']?.toString(),
          inspectionLocalId: 'local_$inspectionServerId',
          inspectionServerId: inspectionServerId,
          checklistItemId: map['checklist_item_id']?.toString() ?? '',
          itemQuestion: map['item_question']?.toString(),
          sectionName: map['section_name']?.toString(),
          responseBoolean: map['response_boolean'],
          responseValue: map['response_value']?.toString(),
          inspectorComment: map['inspector_comment']?.toString(),
          gpsLatitude: (map['gps_latitude'] as num?)?.toDouble(),
          gpsLongitude: (map['gps_longitude'] as num?)?.toDouble(),
          capturedAt: map['captured_at'] != null
              ? DateTime.parse(map['captured_at'])
              : DateTime.now(),
          syncStatus: 'SYNCED',
        );
      }).toList();
    }
    return [];
  }
}
