import '../models/evidence_model.dart';
import '../data/local/sqlite_database_helper.dart';
import '../services/evidence_capture_service.dart';

// =====================================================================
// DRISHTI Mobile App: Evidence Repository
// Coordinates digital chain-of-custody, capture & local retrieval
// =====================================================================

class EvidenceRepository {
  final SqliteDatabaseHelper _dbHelper;
  final EvidenceCaptureService _captureService;

  EvidenceRepository({
    SqliteDatabaseHelper? dbHelper,
    EvidenceCaptureService? captureService,
  })  : _dbHelper = dbHelper ?? SqliteDatabaseHelper.instance,
        _captureService = captureService ?? EvidenceCaptureService();

  Future<List<EvidenceModel>> getEvidenceForInspection(String inspectionLocalId) async {
    return await _dbHelper.getEvidenceForInspection(inspectionLocalId);
  }

  Future<EvidenceModel?> capturePhoto({
    required String inspectionLocalId,
    String? inspectionServerId,
    required double targetLat,
    required double targetLon,
    required int geofenceRadiusMeters,
    required String description,
  }) async {
    return await _captureService.captureAndProcessPhoto(
      inspectionLocalId: inspectionLocalId,
      inspectionServerId: inspectionServerId,
      targetLat: targetLat,
      targetLon: targetLon,
      geofenceRadiusMeters: geofenceRadiusMeters,
      description: description,
    );
  }
}
