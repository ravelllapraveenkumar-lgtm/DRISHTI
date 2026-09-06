// =====================================================================
// DRISHTI Mobile App: Centralized API Endpoints Contract
// Strictly mapped to existing DRISHTI FastAPI backend
// =====================================================================

import 'package:shared_preferences/shared_preferences.dart';

class ApiEndpoints {
  // Preset addresses
  static const String defaultPhysicalLanUrl = 'http://10.244.88.171:8001';
  static const String defaultEmulatorUrl = 'http://10.0.2.2:8001';
  static const String defaultLocalhostUrl = 'http://127.0.0.1:8001';

  // Compile-time environment override (--dart-define=BACKEND_URL=...)
  static const String _envUrl = String.fromEnvironment('BACKEND_URL', defaultValue: '');
  static const String _prefKey = 'drishti_backend_base_url';

  // Configurable base URL. Defaults to physical PC LAN IP or environment variable.
  static String baseUrl = _envUrl.isNotEmpty ? _envUrl : defaultPhysicalLanUrl;

  /// Loads persisted base URL from SharedPreferences
  static Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(_prefKey);
      if (saved != null && saved.trim().isNotEmpty) {
        setBaseUrl(saved.trim());
      } else if (_envUrl.isNotEmpty) {
        setBaseUrl(_envUrl);
      }
    } catch (_) {
      // Keep default on storage read error
    }
  }

  /// Sets in-memory base URL
  static void setBaseUrl(String url) {
    String cleanUrl = url.trim();
    if (cleanUrl.endsWith('/')) {
      cleanUrl = cleanUrl.substring(0, cleanUrl.length - 1);
    }
    if (cleanUrl.isNotEmpty) {
      baseUrl = cleanUrl;
    }
  }

  /// Sets in-memory base URL and persists it across restarts
  static Future<void> saveBaseUrl(String url) async {
    setBaseUrl(url);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefKey, baseUrl);
    } catch (_) {}
  }

  // Health
  static String get health => '$baseUrl/api/v1/health';

  // Authentication
  static String get login => '$baseUrl/api/v1/auth/login';
  static String get demoLogin => '$baseUrl/api/v1/auth/demo-login';
  static String get demoUsers => '$baseUrl/api/v1/auth/demo-users';
  static String get me => '$baseUrl/api/v1/auth/me';

  // Inspection Assignments
  static String get assignments => '$baseUrl/api/v1/inspection-assignments';
  static String inspectorAssignments(String inspectorId) =>
      '$baseUrl/api/v1/inspection-assignments/inspector/$inspectorId';
  static String acceptAssignment(String assignmentId) =>
      '$baseUrl/api/v1/inspection-assignments/$assignmentId/accept';
  static String arriveAssignment(String assignmentId) =>
      '$baseUrl/api/v1/inspection-assignments/$assignmentId/arrive';

  // Inspections
  static String get inspections => '$baseUrl/api/v1/inspections';
  static String inspectionDetails(String inspectionId) =>
      '$baseUrl/api/v1/inspections/$inspectionId';
  static String updateInspectionStatus(String inspectionId) =>
      '$baseUrl/api/v1/inspections/$inspectionId/status';

  // Institutions
  static String get institutions => '$baseUrl/api/v1/institutions';
  static String institutionDetails(String institutionId) =>
      '$baseUrl/api/v1/institutions/$institutionId';

  // Checklist Templates & Submissions
  static String get checklistTemplates =>
      '$baseUrl/api/v1/inspection-checklists/templates';
  static String inspectionChecklistResponses(String inspectionId) =>
      '$baseUrl/api/v1/inspection-checklists/inspection/$inspectionId';
  static String get submitChecklists =>
      '$baseUrl/api/v1/inspection-checklists';

  // Evidence Metadata Registration
  static String get evidence => '$baseUrl/api/v1/evidence';
  static String evidenceDetails(String evidenceId) =>
      '$baseUrl/api/v1/evidence/$evidenceId';

  // Final Inspection Reports
  static String get reports => '$baseUrl/api/v1/inspection-reports';
  static String reportDetails(String reportId) =>
      '$baseUrl/api/v1/inspection-reports/$reportId';
}
