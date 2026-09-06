import 'package:flutter/material.dart';
import '../core/errors/app_exception.dart';
import '../data/local/database_helper.dart';
import '../data/remote/inspection_api_service.dart';
import '../models/inspection_model.dart';
import '../models/user_model.dart';

// =====================================================================
// DRISHTI Mobile App: Inspections List State Provider
// Loads SQLite cache first, then fetches fresh assignments when online
// =====================================================================

class InspectionsProvider extends ChangeNotifier {
  final InspectionApiService _apiService;
  final DatabaseHelper _dbHelper;

  List<InspectionModel> _inspections = [];
  bool _isLoading = false;
  String? _errorMessage;
  int _pendingSyncCount = 0;
  String _currentFilter = 'ALL'; // ALL, HIGH_PRIORITY, IN_PROGRESS, SUBMITTED

  InspectionsProvider({
    required InspectionApiService apiService,
    DatabaseHelper? dbHelper,
  })  : _apiService = apiService,
        _dbHelper = dbHelper ?? DatabaseHelper.instance;

  List<InspectionModel> get inspections {
    switch (_currentFilter) {
      case 'HIGH_PRIORITY':
        return _inspections.where((i) => i.isHighPriority).toList();
      case 'IN_PROGRESS':
        return _inspections.where((i) => i.isInProgress).toList();
      case 'SUBMITTED':
        return _inspections.where((i) => i.isSubmitted).toList();
      case 'ALL':
      default:
        return _inspections;
    }
  }

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  int get pendingSyncCount => _pendingSyncCount;
  String get currentFilter => _currentFilter;

  int get totalCount => _inspections.length;
  int get highPriorityCount => _inspections.where((i) => i.isHighPriority).length;
  int get inProgressCount => _inspections.where((i) => i.isInProgress).length;
  int get submittedCount => _inspections.where((i) => i.isSubmitted).length;

  void setFilter(String filter) {
    _currentFilter = filter;
    notifyListeners();
  }

  /// Initial load: fetches SQLite first for zero-latency offline start
  Future<void> loadLocalInspections() async {
    _isLoading = true;
    notifyListeners();

    try {
      _inspections = await _dbHelper.getAllCachedInspections();
      _pendingSyncCount = await _dbHelper.getPendingSyncCount();
    } catch (e) {
      _errorMessage = 'Failed to load local inspections: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Synchronizes assignments with FastAPI backend
  Future<void> refreshFromBackend(UserModel user) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // 1. Fetch assigned assignments for inspector
      final assignments = await _apiService.getInspectorAssignments(user.id);
      final List<InspectionModel> remoteList = [];

      for (final assignment in assignments) {
        try {
          final inspection = await _apiService.getInspectionDetails(assignment.inspectionId);
          remoteList.add(inspection);
        } catch (_) {
          // If individual detail fetch fails, continue
        }
      }

      if (remoteList.isNotEmpty) {
        // Cache to local SQLite
        await _dbHelper.cacheInspectionsBatch(remoteList);
      }

      // Re-read consolidated list from SQLite
      _inspections = await _dbHelper.getAllCachedInspections();
      _pendingSyncCount = await _dbHelper.getPendingSyncCount();
    } catch (e) {
      _errorMessage = e is AppException ? e.message : 'Working offline: using local cache.';
      // Fallback: reload local cache
      _inspections = await _dbHelper.getAllCachedInspections();
      _pendingSyncCount = await _dbHelper.getPendingSyncCount();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Refreshes the count of unsynced items in the outbox
  Future<void> updatePendingCount() async {
    _pendingSyncCount = await _dbHelper.getPendingSyncCount();
    notifyListeners();
  }
}
