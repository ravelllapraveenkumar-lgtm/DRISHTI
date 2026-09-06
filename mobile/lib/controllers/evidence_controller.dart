import 'package:flutter/foundation.dart';
import '../models/evidence_model.dart';
import '../repositories/evidence_repository.dart';

// =====================================================================
// DRISHTI Mobile App: Evidence Controller
// Coordinates evidence lists, tamper-evident SHA-256 states & capture
// =====================================================================

class EvidenceController extends ChangeNotifier {
  final EvidenceRepository _evidenceRepository;

  List<EvidenceModel> _evidenceList = [];
  bool _isLoading = false;
  bool _isCapturing = false;
  String? _errorMessage;

  EvidenceController({EvidenceRepository? evidenceRepository})
      : _evidenceRepository = evidenceRepository ?? EvidenceRepository();

  List<EvidenceModel> get evidenceList => _evidenceList;
  bool get isLoading => _isLoading;
  bool get isCapturing => _isCapturing;
  String? get errorMessage => _errorMessage;

  int get photoCount => _evidenceList.where((e) => e.evidenceType == 'GEO_TAGGED_PHOTO').length;
  int get geofenceCompliantCount => _evidenceList.where((e) => e.geofenceVerified).length;

  Future<void> loadEvidence(String inspectionLocalId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _evidenceList = await _evidenceRepository.getEvidenceForInspection(inspectionLocalId);
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<EvidenceModel?> capturePhoto({
    required String inspectionLocalId,
    String? inspectionServerId,
    required double targetLat,
    required double targetLon,
    required int geofenceRadiusMeters,
    required String description,
  }) async {
    _isCapturing = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final evidence = await _evidenceRepository.capturePhoto(
        inspectionLocalId: inspectionLocalId,
        inspectionServerId: inspectionServerId,
        targetLat: targetLat,
        targetLon: targetLon,
        geofenceRadiusMeters: geofenceRadiusMeters,
        description: description,
      );

      if (evidence != null) {
        _evidenceList.insert(0, evidence);
      }
      return evidence;
    } catch (e) {
      _errorMessage = e.toString();
      return null;
    } finally {
      _isCapturing = false;
      notifyListeners();
    }
  }
}
