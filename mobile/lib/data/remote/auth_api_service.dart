import '../../core/constants/api_endpoints.dart';
import '../../core/network/api_client.dart';
import '../../models/user_model.dart';

// =====================================================================
// DRISHTI Mobile App: Authentication Remote Service
// Strictly communicates via FastAPI auth endpoints
// =====================================================================

class AuthApiService {
  final ApiClient _client;

  AuthApiService(this._client);

  /// Authenticates inspector with email and password
  Future<UserModel> login({required String email, required String password}) async {
    final response = await _client.post(
      ApiEndpoints.login,
      body: {'email': email, 'password': password},
    );

    final token = response['access_token']?.toString() ?? '';
    _client.setAuthToken(token);

    return UserModel.fromJson(response as Map<String, dynamic>, token: token);
  }

  /// Instant role-based demo login for rapid testing
  Future<UserModel> demoLogin({String role = 'FIELD_INSPECTOR', String? userId}) async {
    final body = <String, dynamic>{'role': role};
    if (userId != null) body['user_id'] = userId;

    final response = await _client.post(ApiEndpoints.demoLogin, body: body);

    final token = response['access_token']?.toString() ?? '';
    _client.setAuthToken(token);

    return UserModel.fromJson(response as Map<String, dynamic>, token: token);
  }

  /// Retrieves available demo user personas
  Future<List<Map<String, dynamic>>> getDemoUsers() async {
    final response = await _client.get(ApiEndpoints.demoUsers);
    if (response is List) {
      return response.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    }
    return [];
  }

  /// Fetches authenticated inspector profile
  Future<UserModel> getProfile() async {
    final response = await _client.get(ApiEndpoints.me);
    return UserModel.fromJson(response as Map<String, dynamic>, token: _client.authToken);
  }
}
