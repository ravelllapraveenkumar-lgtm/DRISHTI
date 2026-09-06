import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../errors/app_exception.dart';

// =====================================================================
// DRISHTI Mobile App: Centralized Typed API Client
// Handles Bearer tokens, timeouts, JSON serialization, and error mapping
// =====================================================================

class ApiClient {
  final http.Client _httpClient;
  String? _authToken;
  final Duration defaultTimeout;

  ApiClient({
    http.Client? httpClient,
    this.defaultTimeout = const Duration(seconds: 12),
  }) : _httpClient = httpClient ?? http.Client();

  void setAuthToken(String? token) {
    _authToken = token;
  }

  String? get authToken => _authToken;

  Map<String, String> _buildHeaders({Map<String, String>? extraHeaders}) {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (_authToken != null && _authToken!.isNotEmpty) {
      headers['Authorization'] = 'Bearer $_authToken';
    }
    if (extraHeaders != null) {
      headers.addAll(extraHeaders);
    }
    return headers;
  }

  Future<dynamic> get(String url, {Map<String, String>? headers}) async {
    try {
      final uri = Uri.parse(url);
      final response = await _httpClient
          .get(uri, headers: _buildHeaders(extraHeaders: headers))
          .timeout(defaultTimeout);
      return _processResponse(response);
    } on SocketException catch (e) {
      throw NetworkException('Network unreachable. Inspection data will be saved locally.', details: e.message);
    } on TimeoutException catch (e) {
      throw NetworkException('Connection to DRISHTI server timed out.', details: e.message);
    } catch (e) {
      if (e is AppException) rethrow;
      throw NetworkException('Network error: ${e.toString()}');
    }
  }

  Future<dynamic> post(String url, {dynamic body, Map<String, String>? headers}) async {
    try {
      final uri = Uri.parse(url);
      final payload = body != null ? jsonEncode(body) : null;
      final response = await _httpClient
          .post(uri, headers: _buildHeaders(extraHeaders: headers), body: payload)
          .timeout(defaultTimeout);
      return _processResponse(response);
    } on SocketException catch (e) {
      throw NetworkException('Network unreachable. Operation queued for sync.', details: e.message);
    } on TimeoutException catch (e) {
      throw NetworkException('Connection to DRISHTI server timed out.', details: e.message);
    } catch (e) {
      if (e is AppException) rethrow;
      throw NetworkException('Network error: ${e.toString()}');
    }
  }

  Future<dynamic> patch(String url, {dynamic body, Map<String, String>? headers}) async {
    try {
      final uri = Uri.parse(url);
      final payload = body != null ? jsonEncode(body) : null;
      final response = await _httpClient
          .patch(uri, headers: _buildHeaders(extraHeaders: headers), body: payload)
          .timeout(defaultTimeout);
      return _processResponse(response);
    } on SocketException catch (e) {
      throw NetworkException('Network unreachable. Patch operation queued.', details: e.message);
    } on TimeoutException catch (e) {
      throw NetworkException('Connection to DRISHTI server timed out.', details: e.message);
    } catch (e) {
      if (e is AppException) rethrow;
      throw NetworkException('Network error: ${e.toString()}');
    }
  }

  dynamic _processResponse(http.Response response) {
    final statusCode = response.statusCode;
    final bodyString = response.body;
    dynamic decoded;

    if (bodyString.isNotEmpty) {
      try {
        decoded = jsonDecode(bodyString);
      } catch (_) {
        decoded = bodyString;
      }
    }

    if (statusCode >= 200 && statusCode < 300) {
      return decoded;
    } else if (statusCode == 401) {
      throw UnauthorizedException(
        decoded is Map && decoded['detail'] != null
            ? decoded['detail'].toString()
            : 'Authentication credentials expired or invalid.',
      );
    } else {
      final errorMsg = (decoded is Map && decoded['detail'] != null)
          ? decoded['detail'].toString()
          : 'Server returned HTTP $statusCode: $bodyString';
      throw ApiException(errorMsg, statusCode: statusCode, details: decoded);
    }
  }
}
