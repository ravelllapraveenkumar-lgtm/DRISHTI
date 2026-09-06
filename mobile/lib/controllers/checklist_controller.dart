import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/checklist_model.dart';
import '../repositories/checklist_repository.dart';

// =====================================================================
// DRISHTI Mobile App: Checklist Controller
// Manages field responses, validation, draft saves & progress metrics
// =====================================================================

class ChecklistController extends ChangeNotifier {
  final ChecklistRepository _checklistRepository;
  final Uuid _uuid = const Uuid();

  List<ChecklistItemModel> _items = [];
  Map<String, ChecklistResponseModel> _responses = {};
  bool _isLoading = false;
  bool _isSavingDraft = false;
  String? _errorMessage;

  ChecklistController({ChecklistRepository? checklistRepository})
      : _checklistRepository = checklistRepository ?? ChecklistRepository();

  List<ChecklistItemModel> get items => _items;
  Map<String, ChecklistResponseModel> get responses => _responses;
  bool get isLoading => _isLoading;
  bool get isSavingDraft => _isSavingDraft;
  String? get errorMessage => _errorMessage;

  List<String> get sections {
    final s = <String>{};
    for (final item in _items) {
      s.add(item.sectionName);
    }
    return s.toList();
  }

  List<ChecklistItemModel> itemsForSection(String section) {
    return _items.where((item) => item.sectionName == section).toList();
  }

  int get totalQuestions => _items.length;
  int get answeredQuestions {
    return _items.where((i) => _responses[i.id]?.responseBoolean != null).length;
  }

  double get progressPercentage {
    if (_items.isEmpty) return 0.0;
    return answeredQuestions / _items.length;
  }

  bool get isMandatoryComplete {
    for (final item in _items) {
      if (item.isMandatory) {
        final resp = _responses[item.id];
        if (resp == null || resp.responseBoolean == null) {
          return false;
        }
      }
    }
    return true;
  }

  Future<void> loadChecklist({
    required String inspectionLocalId,
    String? inspectionServerId,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _items = await _checklistRepository.getChecklistItems();
      final existingResponses = await _checklistRepository.getResponses(inspectionLocalId);

      _responses = {};
      for (final r in existingResponses) {
        _responses[r.checklistItemId] = r;
      }

      // Initialize empty response models for unanswered items
      for (final item in _items) {
        if (!_responses.containsKey(item.id)) {
          _responses[item.id] = ChecklistResponseModel(
            localId: 'resp_${_uuid.v4()}',
            inspectionLocalId: inspectionLocalId,
            inspectionServerId: inspectionServerId,
            checklistItemId: item.id,
            questionText: item.itemQuestion,
            sectionName: item.sectionName,
            capturedAt: DateTime.now().toIso8601String(),
          );
        }
      }
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void updateResponseBoolean(String itemId, bool value) {
    final current = _responses[itemId];
    if (current != null) {
      _responses[itemId] = current.copyWith(
        responseBoolean: value,
      );
      notifyListeners();
    }
  }

  void updateResponseComment(String itemId, String comment) {
    final current = _responses[itemId];
    if (current != null) {
      _responses[itemId] = current.copyWith(
        inspectorComment: comment,
      );
      notifyListeners();
    }
  }

  Future<void> saveDraft() async {
    _isSavingDraft = true;
    notifyListeners();

    try {
      await _checklistRepository.saveDraftResponses(_responses.values.toList());
    } finally {
      _isSavingDraft = false;
      notifyListeners();
    }
  }

  Future<bool> submitChecklist({
    required String inspectionLocalId,
    String? inspectionServerId,
  }) async {
    if (!isMandatoryComplete) {
      _errorMessage = 'Please complete all mandatory checklist questions before submitting.';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    notifyListeners();

    try {
      await _checklistRepository.submitChecklist(
        inspectionLocalId: inspectionLocalId,
        inspectionServerId: inspectionServerId,
        responses: _responses.values.toList(),
      );
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
}
