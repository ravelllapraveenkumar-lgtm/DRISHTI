import 'package:flutter/foundation.dart';
import '../models/inspection_model.dart';
import '../repositories/inspection_repository.dart';

// =====================================================================
// DRISHTI Mobile App: Inspection Controller
// Manages assignment lifecycle, offline cache indication & filtering
// =====================================================================

class InspectionController extends ChangeNotifier {
  final InspectionRepository _inspectionRepository;

  List<InspectionModel> _allInspections = [];
  InspectionModel? _selectedInspection;
  bool _isLoading = false;
  bool _isFromCache = false;
  String? _statusNotice;
  String _filterStatus = 'ALL'; // ALL, ASSIGNED, IN_PROGRESS, COMPLETED
  String _searchQuery = '';

  InspectionController({InspectionRepository? inspectionRepository})
      : _inspectionRepository = inspectionRepository ?? InspectionRepository();

  List<InspectionModel> get allInspections => _allInspections;
  InspectionModel? get selectedInspection => _selectedInspection;
  bool get isLoading => _isLoading;
  bool get isFromCache => _isFromCache;
  String? get statusNotice => _statusNotice;
  String get filterStatus => _filterStatus;
  String get searchQuery => _searchQuery;

  List<InspectionModel> get filteredInspections {
    return _allInspections.where((insp) {
      // Filter status
      if (_filterStatus != 'ALL') {
        if (_filterStatus == 'ASSIGNED' && insp.status != 'ASSIGNED') return false;
        if (_filterStatus == 'IN_PROGRESS' && insp.status != 'IN_PROGRESS') return false;
        if (_filterStatus == 'COMPLETED' && insp.status != 'COMPLETED') return false;
      }
      // Search query
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        final matchesName = insp.institutionName.toLowerCase().contains(query);
        final matchesDistrict = insp.institutionDistrict.toLowerCase().contains(query);
        final matchesCode = insp.inspectionCode.toLowerCase().contains(query);
        return matchesName || matchesDistrict || matchesCode;
      }
      return true;
    }).toList();
  }

  int get pendingCount => _allInspections.where((i) => i.status == 'ASSIGNED').length;
  int get inProgressCount => _allInspections.where((i) => i.status == 'IN_PROGRESS').length;
  int get completedCount => _allInspections.where((i) => i.status == 'COMPLETED').length;

  void setFilterStatus(String status) {
    _filterStatus = status;
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void selectInspection(InspectionModel inspection) {
    _selectedInspection = inspection;
    notifyListeners();
  }

  Future<void> fetchInspections(String inspectorId) async {
    _isLoading = true;
    notifyListeners();

    try {
      final result = await _inspectionRepository.getInspectorInspections(inspectorId);
      _allInspections = result.inspections;
      _isFromCache = result.isFromCache;
      _statusNotice = result.notice;

      // Update selectedInspection if currently open
      if (_selectedInspection != null) {
        final match = _allInspections.firstWhere(
          (i) => i.localId == _selectedInspection!.localId,
          orElse: () => _selectedInspection!,
        );
        _selectedInspection = match;
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> acceptAssignment(InspectionModel inspection) async {
    await _inspectionRepository.acceptAssignment(inspection);
    final updated = inspection.copyWith(status: 'ASSIGNED', assignmentStatus: 'ACCEPTED');
    _updateInspectionInList(updated);
  }

  Future<void> arriveOnSite(InspectionModel inspection) async {
    await _inspectionRepository.arriveOnSite(inspection);
    final updated = inspection.copyWith(
      status: 'IN_PROGRESS',
      assignmentStatus: 'ON_SITE',
      syncStatus: 'PENDING',
    );
    _updateInspectionInList(updated);
  }

  void _updateInspectionInList(InspectionModel updated) {
    final index = _allInspections.indexWhere((i) => i.localId == updated.localId);
    if (index != -1) {
      _allInspections[index] = updated;
    }
    if (_selectedInspection?.localId == updated.localId) {
      _selectedInspection = updated;
    }
    notifyListeners();
  }
}
