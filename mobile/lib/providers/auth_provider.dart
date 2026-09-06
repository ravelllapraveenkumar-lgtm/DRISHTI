import 'package:flutter/material.dart';
import '../core/errors/app_exception.dart';
import '../data/local/database_helper.dart';
import '../data/remote/auth_api_service.dart';
import '../models/user_model.dart';

// =====================================================================
// DRISHTI Mobile App: Authentication State Provider
// Supports local offline cached sessions and demo role switching
// =====================================================================

class AuthProvider extends ChangeNotifier {
  final AuthApiService _authApi;
  final DatabaseHelper _dbHelper;

  UserModel? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;

  AuthProvider({
    required AuthApiService authApi,
    DatabaseHelper? dbHelper,
  })  : _authApi = authApi,
        _dbHelper = dbHelper ?? DatabaseHelper.instance;

  UserModel? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// Restores cached offline session on app launch
  Future<void> restoreSession() async {
    _isLoading = true;
    notifyListeners();

    try {
      final cached = await _dbHelper.getCachedUserSession();
      if (cached != null) {
        _currentUser = cached;
      }
    } catch (_) {
      // Ignore cache read failures on cold start
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Login with email and password
  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final user = await _authApi.login(email: email, password: password);
      _currentUser = user;
      await _dbHelper.saveUserSession(user);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e is AppException ? e.message : 'Login failed: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Quick Demo login as Field Inspector
  Future<bool> demoLogin({String? userId}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final user = await _authApi.demoLogin(role: 'FIELD_INSPECTOR', userId: userId);
      _currentUser = user;
      await _dbHelper.saveUserSession(user);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      // Fallback offline inspector session if backend unreachable during initial cold boot
      _currentUser = UserModel(
        id: 'inspector_demo_offline',
        email: 'inspector.offline@mosje.gov.in',
        fullName: 'Shri Rajesh Kumar (Offline Inspector)',
        designation: 'Senior Social Welfare Officer',
        department: 'Dept. of Social Justice & Empowerment',
        state: 'Uttar Pradesh',
        district: 'Lucknow',
        roles: ['FIELD_INSPECTOR'],
        token: 'OFFLINE_DEMO_TOKEN',
      );
      await _dbHelper.saveUserSession(_currentUser!);
      _errorMessage = 'Offline mode activated: Using cached inspector credentials.';
      _isLoading = false;
      notifyListeners();
      return true;
    }
  }

  Future<void> logout() async {
    _currentUser = null;
    await _dbHelper.clearUserSession();
    notifyListeners();
  }
}
