import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../core/errors/app_exception.dart';
import '../data/local/database_helper.dart';
import '../data/remote/checklist_api_service.dart';
import '../data/remote/inspection_api_service.dart';
import '../models/checklist_model.dart';
import '../models/evidence_model.dart';
import '../models/inspection_model.dart';
import '../models/institution_model.dart';
import '../models/note_model.dart';
import '../models/report_model.dart';
import '../models/sync_queue_item.dart';
import '../services/evidence_service.dart';
import '../services/location_service.dart';
import '../services/sync_manager.dart';

// =====================================================================
// DRISHTI Mobile App: Single Inspection Workspace Provider
// Coordinates Geofence, Checklists, Evidence Vault, Notes, and Final Report
// =====================================================================

class InspectionDetailProvider extends ChangeNotifier {
  final DatabaseHelper _dbHelper;
  final InspectionApiService _inspectionApi;
  final ChecklistApiService _checklistApi;
  final EvidenceService _evidenceService;
  final SyncManager _syncManager;
  final Uuid _uuid = const Uuid();

  InspectionModel? _inspection;
  InstitutionModel? _institution;
  List<ChecklistItemModel> _checklistItems = [];
  Map<String, ChecklistSubmissionModel> _responses = {};
  List<EvidenceModel> _evidences = [];
  List<NoteModel> _notes = [];
  ReportModel? _reportDraft;

  bool _isLoading = false;
  String? _statusMessage;
  LocationResult? _lastLocation;
  bool _isGeofenceVerified = false;
  double _distanceToTargetMeters = 0.0;

  InspectionDetailProvider({
    DatabaseHelper? dbHelper,
    required InspectionApiService inspectionApi,
    required ChecklistApiService checklistApi,
    required EvidenceService evidenceService,
    required SyncManager syncManager,
  })  : _dbHelper = dbHelper ?? DatabaseHelper.instance,
        _inspectionApi = inspectionApi,
        _checklistApi = checklistApi,
        _evidenceService = evidenceService,
        _syncManager = syncManager;

  InspectionModel? get inspection => _inspection;
  InstitutionModel? get institution => _institution;
  List<ChecklistItemModel> get checklistItems => _checklistItems;
  Map<String, ChecklistSubmissionModel> get responses => _responses;
  List<EvidenceModel> get evidences => _evidences;
  List<NoteModel> get notes => _notes;
  ReportModel? get reportDraft => _reportDraft;
  bool get isLoading => _isLoading;
  String? get statusMessage => _statusMessage;
  LocationResult? get lastLocation => _lastLocation;
  bool get isGeofenceVerified => _isGeofenceVerified;
  double get distanceToTargetMeters => _distanceToTargetMeters;

  /// Loads full inspection state from SQLite, and attempts to pull fresh checklist templates
  Future<void> loadInspection(String localId) async {
    _isLoading = true;
    _statusMessage = null;
    notifyListeners();

    try {
      // 1. Load inspection from local SQLite
      _inspection = await _dbHelper.getInspectionByLocalId(localId);

      if (_inspection == null) {
        throw LocalDatabaseException('Inspection record not found in local cache.');
      }

      // 2. Load responses, evidence, notes, and report draft
      final localResponses = await _dbHelper.getChecklistResponses(localId);
      _responses = {for (var r in localResponses) r.checklistItemId: r};

      _evidences = await _dbHelper.getEvidenceForInspection(localId);
      _notes = await _dbHelper.getNotesForInspection(localId);
      _reportDraft = await _dbHelper.getReportForInspection(localId);

      // 3. Load checklist items (from SQLite or fetch templates)
      var items = await _dbHelper.getCachedChecklistItems();
      if (items.isEmpty) {
        try {
          final templates = await _checklistApi.getChecklistTemplates();
          if (templates.isNotEmpty) {
            await _dbHelper.cacheChecklistTemplates(templates);
            items = await _dbHelper.getCachedChecklistItems();
          }
        } catch (_) {
          // Keep offline if server unreachable
        }
      }
      _checklistItems = items;

      // 4. Institution details
      try {
        if (_inspection!.institutionId.isNotEmpty) {
          _institution = await _inspectionApi.getInstitutionDetails(_inspection!.institutionId);
        }
      } catch (_) {
        // Institution details will display from inspection cache
      }

      // 5. Check if already arrived
      if (_inspection!.status == 'IN_PROGRESS' || _inspection!.status == 'SUBMITTED') {
        _isGeofenceVerified = true;
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Verifies inspector presence via GPS hardware against target institution
  Future<bool> verifyArrivalGeofence({bool allowDemoFallback = true}) async {
    if (_inspection == null) return false;

    _isLoading = true;
    _statusMessage = 'Acquiring GPS fix...';
    notifyListeners();

    try {
      final loc = await LocationService.getCurrentPosition(allowDemoFallback: allowDemoFallback);
      _lastLocation = loc;

      final proximity = LocationService.verifyProximity(
        location: loc,
        targetLat: _inspection!.targetLatitude,
        targetLon: _inspection!.targetLongitude,
        geofenceRadiusMeters: _inspection!.geofenceRadiusMeters,
      );

      _distanceToTargetMeters = proximity['distance_meters'] as double;
      _isGeofenceVerified = proximity['is_within_geofence'] == true;

      if (_isGeofenceVerified) {
        _statusMessage =
            'Geofence verified! Distance: ${_distanceToTargetMeters.toStringAsFixed(1)}m (Allowed: ${_inspection!.geofenceRadiusMeters}m)';

        // Mark inspection IN_PROGRESS locally
        _inspection = _inspection!.copyWith(status: 'IN_PROGRESS');
        await _dbHelper.updateInspectionStatus(_inspection!.localId, 'IN_PROGRESS');

        // If online, notify backend
        if (_inspection!.serverId != null) {
          try {
            await _inspectionApi.updateInspectionStatus(_inspection!.serverId!, 'IN_PROGRESS');
          } catch (_) {
            // Queue status update offline
            await _dbHelper.enqueueSyncItem(
              SyncQueueItem(
                id: 'sync_status_${_inspection!.localId}',
                entityType: 'STATUS_UPDATE',
                entityLocalId: _inspection!.localId,
                parentServerId: _inspection!.serverId,
                endpoint: '/api/v1/inspections/${_inspection!.serverId}/status',
                httpMethod: 'PATCH',
                payloadJson: '{"status":"IN_PROGRESS"}',
              ),
            );
          }
        }
        return true;
      } else {
        _statusMessage =
            'Outside geofence! Device is ${_distanceToTargetMeters.toStringAsFixed(1)}m away. Allowed radius is ${_inspection!.geofenceRadiusMeters}m.';
        return false;
      }
    } catch (e) {
      _statusMessage = 'GPS Error: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Records single checklist item answer and persists immediately to SQLite
  Future<void> recordChecklistResponse({
    required ChecklistItemModel item,
    bool? compliant,
    String? comment,
    String? textValue,
  }) async {
    if (_inspection == null) return;

    final existing = _responses[item.id];
    final localId = existing?.localId ?? 'chk_${_uuid.v4()}';

    final response = ChecklistSubmissionModel(
      localId: localId,
      serverId: existing?.serverId,
      inspectionLocalId: _inspection!.localId,
      inspectionServerId: _inspection!.serverId,
      checklistItemId: item.id,
      itemQuestion: item.itemQuestion,
      sectionName: item.sectionName,
      responseBoolean: compliant,
      responseValue: textValue ?? existing?.responseValue,
      inspectorComment: comment ?? existing?.inspectorComment,
      gpsLatitude: _lastLocation?.latitude,
      gpsLongitude: _lastLocation?.longitude,
      capturedAt: DateTime.now(),
      syncStatus: 'PENDING',
    );

    _responses[item.id] = response;
    await _dbHelper.saveChecklistResponse(response);
    notifyListeners();
  }

  /// Queues checklist batch for synchronization
  Future<void> queueChecklistBatchForSync() async {
    if (_inspection == null) return;

    await _dbHelper.enqueueSyncItem(
      SyncQueueItem(
        id: 'sync_chk_batch_${_inspection!.localId}',
        entityType: 'CHECKLIST_BATCH',
        entityLocalId: _inspection!.localId,
        parentServerId: _inspection!.serverId,
        endpoint: '/api/v1/inspection-checklists',
        httpMethod: 'POST',
        payloadJson: '{"inspection_id":"${_inspection!.serverId ?? _inspection!.localId}"}',
      ),
    );
  }

  /// Captures and registers evidence photo
  Future<void> addCameraEvidence(String description) async {
    if (_inspection == null) return;

    final evidence = await _evidenceService.capturePhotoEvidence(
      inspectionLocalId: _inspection!.localId,
      inspectionServerId: _inspection!.serverId,
      targetLat: _inspection!.targetLatitude,
      targetLon: _inspection!.targetLongitude,
      geofenceRadiusMeters: _inspection!.geofenceRadiusMeters,
      description: description,
    );

    if (evidence != null) {
      _evidences.insert(0, evidence);
      notifyListeners();
    }
  }

  /// Adds synthetic demo evidence photo (ideal for testing in emulator)
  Future<void> addDemoEvidence(String description, {String type = 'GEO_TAGGED_PHOTO'}) async {
    if (_inspection == null) return;

    final evidence = await _evidenceService.createDemoEvidence(
      inspectionLocalId: _inspection!.localId,
      inspectionServerId: _inspection!.serverId,
      targetLat: _inspection!.targetLatitude,
      targetLon: _inspection!.targetLongitude,
      geofenceRadiusMeters: _inspection!.geofenceRadiusMeters,
      description: description,
      evidenceType: type,
    );

    _evidences.insert(0, evidence);
    notifyListeners();
  }

  /// Saves an offline field note or deficiency observation
  Future<void> addNote({
    required String title,
    required String content,
    String category = 'OBSERVATION',
  }) async {
    if (_inspection == null) return;

    final note = NoteModel(
      localId: 'note_${_uuid.v4()}',
      inspectionLocalId: _inspection!.localId,
      inspectionServerId: _inspection!.serverId,
      category: category,
      title: title,
      content: content,
      createdAt: DateTime.now().toIso8601String(),
      syncStatus: 'SAVED_LOCAL',
    );

    await _dbHelper.saveNote(note);
    _notes.insert(0, note);
    notifyListeners();
  }

  /// Saves final report draft and enqueues sync
  Future<void> submitReportDraft({
    required int physicalCount,
    required int discrepancyCount,
    required int cleanlinessScore,
    required int nutritionScore,
    required int infraScore,
    required String summary,
    required String verdict,
  }) async {
    if (_inspection == null) return;

    final localId = _reportDraft?.localId ?? 'rep_${_uuid.v4()}';
    final report = ReportModel(
      localId: localId,
      serverId: _reportDraft?.serverId,
      inspectionLocalId: _inspection!.localId,
      inspectionServerId: _inspection!.serverId,
      physicalBeneficiaryCount: physicalCount,
      rosterDiscrepancyCount: discrepancyCount,
      cleanlinessScore: cleanlinessScore,
      foodNutritionScore: nutritionScore,
      infrastructureConditionScore: infraScore,
      inspectorSummary: summary,
      overallVerdict: verdict,
      submissionTimestamp: DateTime.now(),
      syncStatus: 'PENDING',
    );

    _reportDraft = report;
    await _dbHelper.saveReportDraft(report);

    // Enqueue checklist batch and report into outbox sync queue
    await queueChecklistBatchForSync();

    await _dbHelper.enqueueSyncItem(
      SyncQueueItem(
        id: 'sync_rep_${report.localId}',
        entityType: 'REPORT',
        entityLocalId: _inspection!.localId,
        parentServerId: _inspection!.serverId,
        endpoint: '/api/v1/inspection-reports',
        httpMethod: 'POST',
        payloadJson: '{"inspection_id":"${_inspection!.serverId ?? _inspection!.localId}"}',
      ),
    );

    _inspection = _inspection!.copyWith(status: 'SUBMITTED');
    await _dbHelper.updateInspectionStatus(_inspection!.localId, 'SUBMITTED');

    notifyListeners();

    // Trigger sync if online
    await _syncManager.processSyncQueue();
  }

  /// Triggers full sync queue processing
  Future<SyncProgressState> triggerSync() async {
    final result = await _syncManager.processSyncQueue();
    // Reload local state to reflect updated server IDs
    if (_inspection != null) {
      await loadInspection(_inspection!.localId);
    }
    return result;
  }
}
