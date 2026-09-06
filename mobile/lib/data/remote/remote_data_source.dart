import '../../core/constants/api_endpoints.dart';
import '../../core/network/api_client.dart';
import '../../models/user_model.dart';
import '../../models/inspection_model.dart';
import '../../models/checklist_model.dart';

// =====================================================================
// DRISHTI Mobile App: Remote FastAPI Data Source
// Strictly maps to DRISHTI v1 REST API contracts
// =====================================================================

class RemoteDataSource {
  final ApiClient _apiClient;

  RemoteDataSource({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  ApiClient get apiClient => _apiClient;

  void setAuthToken(String? token) {
    _apiClient.setAuthToken(token);
  }

  // -------------------------------------------------------------
  // AUTHENTICATION
  // -------------------------------------------------------------
  Future<UserModel> login({required String email, required String password}) async {
    final response = await _apiClient.post(
      ApiEndpoints.login,
      body: {'email': email, 'password': password},
    );
    final user = UserModel.fromJson(response as Map<String, dynamic>);
    if (user.token != null) {
      _apiClient.setAuthToken(user.token);
    }
    return user;
  }

  Future<UserModel> demoLogin({String? role = 'FIELD_INSPECTOR', String? email, String? userId}) async {
    final body = <String, dynamic>{'role': role ?? 'FIELD_INSPECTOR'};
    if (userId != null) body['user_id'] = userId;
    final response = await _apiClient.post(
      ApiEndpoints.demoLogin,
      body: body,
    );
    final user = UserModel.fromJson(response as Map<String, dynamic>);
    if (user.token != null) {
      _apiClient.setAuthToken(user.token);
    }
    return user;
  }

  Future<List<Map<String, dynamic>>> getDemoUsers() async {
    final response = await _apiClient.get(ApiEndpoints.demoUsers);
    if (response is List) {
      return List<Map<String, dynamic>>.from(response);
    }
    return [];
  }

  Future<UserModel> getMe() async {
    final response = await _apiClient.get(ApiEndpoints.me);
    return UserModel.fromJson(response as Map<String, dynamic>, token: _apiClient.authToken);
  }

  // -------------------------------------------------------------
  // ASSIGNMENTS & INSPECTIONS
  // -------------------------------------------------------------
  Future<List<InspectionModel>> getInspectorAssignments(String inspectorId) async {
    final response = await _apiClient.get(ApiEndpoints.inspectorAssignments(inspectorId));
    List<dynamic> items = [];
    if (response is List) {
      items = response;
    } else if (response is Map && response['items'] is List) {
      items = response['items'] as List<dynamic>;
    }
    return items.map((e) => InspectionModel.fromApiAssignment(e as Map<String, dynamic>)).toList();
  }

  Future<Map<String, dynamic>> acceptAssignment(String assignmentId) async {
    final response = await _apiClient.patch(ApiEndpoints.acceptAssignment(assignmentId));
    return response is Map<String, dynamic> ? response : {};
  }

  Future<Map<String, dynamic>> arriveAssignment(String assignmentId) async {
    final response = await _apiClient.patch(ApiEndpoints.arriveAssignment(assignmentId));
    return response is Map<String, dynamic> ? response : {};
  }

  Future<Map<String, dynamic>> getInspectionDetails(String inspectionId) async {
    final response = await _apiClient.get(ApiEndpoints.inspectionDetails(inspectionId));
    return response is Map<String, dynamic> ? response : {};
  }

  Future<Map<String, dynamic>> updateInspectionStatus(String inspectionId, String status) async {
    final response = await _apiClient.patch(
      ApiEndpoints.updateInspectionStatus(inspectionId),
      body: {'status': status},
    );
    return response is Map<String, dynamic> ? response : {};
  }

  // -------------------------------------------------------------
  // CHECKLIST TEMPLATES & SUBMISSIONS
  // -------------------------------------------------------------
  Future<List<ChecklistTemplateModel>> getChecklistTemplates() async {
    final response = await _apiClient.get(ApiEndpoints.checklistTemplates);
    List<dynamic> items = [];
    if (response is List) {
      items = response;
    } else if (response is Map && response['items'] is List) {
      items = response['items'] as List<dynamic>;
    }
    return items.map((e) => ChecklistTemplateModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<dynamic> submitChecklistResponses({
    String? inspectionId,
    required dynamic items,
  }) async {
    dynamic payload;
    if (items is Map<String, dynamic> && items.containsKey('inspection_id')) {
      payload = items;
    } else if (inspectionId != null && items is List) {
      payload = {
        'inspection_id': inspectionId,
        'items': items,
      };
    } else {
      payload = items;
    }
    return await _apiClient.post(
      ApiEndpoints.submitChecklists,
      body: payload,
    );
  }

  // -------------------------------------------------------------
  // EVIDENCE REGISTRATION
  // -------------------------------------------------------------
  Future<Map<String, dynamic>> registerEvidence(Map<String, dynamic> payload) async {
    final response = await _apiClient.post(
      ApiEndpoints.evidence,
      body: payload,
    );
    return response is Map<String, dynamic> ? response : {};
  }

  // -------------------------------------------------------------
  // FINAL REPORTS
  // -------------------------------------------------------------
  Future<Map<String, dynamic>> submitReport(Map<String, dynamic> payload) async {
    final response = await _apiClient.post(
      ApiEndpoints.reports,
      body: payload,
    );
    return response is Map<String, dynamic> ? response : {};
  }
}
