import '../../core/constants/api_endpoints.dart';
import '../../core/network/api_client.dart';
import '../../models/assignment_model.dart';
import '../../models/inspection_model.dart';
import '../../models/institution_model.dart';

// =====================================================================
// DRISHTI Mobile App: Inspections & Assignments Remote Service
// Fetches assignments, inspection specifics, and institution profile
// =====================================================================

class InspectionApiService {
  final ApiClient _client;

  InspectionApiService(this._client);

  /// Fetches assignments for the logged-in inspector
  Future<List<AssignmentModel>> getInspectorAssignments(String inspectorId) async {
    final response = await _client.get(ApiEndpoints.inspectorAssignments(inspectorId));
    if (response is List) {
      return response
          .map((e) => AssignmentModel.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    }
    return [];
  }

  /// Fetches single inspection details by server UUID
  Future<InspectionModel> getInspectionDetails(String inspectionServerId) async {
    final response = await _client.get(ApiEndpoints.inspectionDetails(inspectionServerId));
    return InspectionModel.fromBackendJson(Map<String, dynamic>.from(response as Map));
  }

  /// Fetches institution profile (with GPS lat, lon, and geofence radius)
  Future<InstitutionModel> getInstitutionDetails(String institutionId) async {
    final response = await _client.get(ApiEndpoints.institutionDetails(institutionId));
    return InstitutionModel.fromJson(Map<String, dynamic>.from(response as Map));
  }

  /// Acknowledges / accepts an inspection assignment
  Future<AssignmentModel> acceptAssignment(String assignmentId) async {
    final response = await _client.patch(ApiEndpoints.acceptAssignment(assignmentId));
    return AssignmentModel.fromJson(Map<String, dynamic>.from(response as Map));
  }

  /// Marks inspector's physical arrival at the institution
  Future<AssignmentModel> markArrival(String assignmentId) async {
    final response = await _client.patch(ApiEndpoints.arriveAssignment(assignmentId));
    return AssignmentModel.fromJson(Map<String, dynamic>.from(response as Map));
  }

  /// Updates inspection status (e.g. IN_PROGRESS)
  Future<void> updateInspectionStatus(String inspectionServerId, String status) async {
    await _client.patch(
      ApiEndpoints.updateInspectionStatus(inspectionServerId),
      body: {'status': status},
    );
  }
}
