// =====================================================================
// DRISHTI Mobile App: Domain & Network Exceptions
// =====================================================================

class AppException implements Exception {
  final String message;
  final String? code;
  final dynamic details;

  AppException(this.message, {this.code, this.details});

  @override
  String toString() => message;
}

class NetworkException extends AppException {
  NetworkException(String message, {String? code, dynamic details})
      : super(message, code: code ?? 'NETWORK_ERROR', details: details);
}

class UnauthorizedException extends AppException {
  UnauthorizedException([String message = 'Session expired or unauthorized. Please re-login.'])
      : super(message, code: 'UNAUTHORIZED');
}

class ApiException extends AppException {
  final int statusCode;
  ApiException(String message, {required this.statusCode, String? code, dynamic details})
      : super(message, code: code ?? 'HTTP_$statusCode', details: details);
}

class LocalDatabaseException extends AppException {
  LocalDatabaseException(String message, {String? code, dynamic details})
      : super(message, code: code ?? 'SQLITE_ERROR', details: details);
}

class GeofenceException extends AppException {
  final double distanceMeters;
  final double allowedRadiusMeters;

  GeofenceException({
    required this.distanceMeters,
    required this.allowedRadiusMeters,
    String? message,
  }) : super(
          message ??
              'Device is ${distanceMeters.toStringAsFixed(1)}m from institution. Allowed geofence is ${allowedRadiusMeters.toStringAsFixed(1)}m.',
          code: 'GEOFENCE_EXCEEDED',
        );
}

class SyncDependencyException extends AppException {
  final String parentEntityType;
  final String parentLocalId;

  SyncDependencyException({
    required this.parentEntityType,
    required this.parentLocalId,
  }) : super(
          'Cannot sync dependent record until parent $parentEntityType ($parentLocalId) obtains a valid Server UUID.',
          code: 'DEPENDENCY_UNRESOLVED',
        );
}
