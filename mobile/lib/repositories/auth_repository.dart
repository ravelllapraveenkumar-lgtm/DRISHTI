import '../models/user_model.dart';
import '../data/local/sqlite_database_helper.dart';
import '../data/remote/remote_data_source.dart';

// =====================================================================
// DRISHTI Mobile App: Authentication Repository
// Coordinates credentials, session caching & offline restoration
// =====================================================================

class AuthRepository {
  final RemoteDataSource _remoteDataSource;
  final SqliteDatabaseHelper _dbHelper;

  AuthRepository({
    RemoteDataSource? remoteDataSource,
    SqliteDatabaseHelper? dbHelper,
  })  : _remoteDataSource = remoteDataSource ?? RemoteDataSource(),
        _dbHelper = dbHelper ?? SqliteDatabaseHelper.instance;

  Future<UserModel?> getCachedSession() async {
    final cached = await _dbHelper.getCachedUserSession();
    if (cached != null && cached.token != null) {
      _remoteDataSource.setAuthToken(cached.token);
    }
    return cached;
  }

  Future<UserModel> login({required String email, required String password}) async {
    final user = await _remoteDataSource.login(email: email, password: password);
    await _dbHelper.saveUserSession(user);
    return user;
  }

  Future<UserModel> demoLogin({required String email}) async {
    final user = await _remoteDataSource.demoLogin(email: email);
    await _dbHelper.saveUserSession(user);
    return user;
  }

  Future<List<Map<String, dynamic>>> getDemoUsers() async {
    try {
      return await _remoteDataSource.getDemoUsers();
    } catch (_) {
      // Fallback demo users for offline demo startup
      return [
        {
          'email': 'vikram.inspector@drishti.gov.in',
          'full_name': 'Vikramaditya Sharma',
          'role': 'FIELD_INSPECTOR',
          'designation': 'Senior Field Vigilance Officer',
          'department': 'MoSJE Vigilance Division',
          'state': 'Uttar Pradesh',
          'district': 'Lucknow',
        },
        {
          'email': 'anita.director@drishti.gov.in',
          'full_name': 'Dr. Anita Desai',
          'role': 'CENTRAL_DIRECTOR',
          'designation': 'Joint Secretary (Social Defence)',
          'department': 'MoSJE Central Secretariat',
          'state': 'Delhi',
          'district': 'New Delhi',
        },
      ];
    }
  }

  Future<void> logout() async {
    _remoteDataSource.setAuthToken(null);
    await _dbHelper.clearUserSession();
  }
}
