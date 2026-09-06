// =====================================================================
// DRISHTI Mobile App: Inspector User Model
// =====================================================================

class UserModel {
  final String id;
  final String email;
  final String fullName;
  final String? designation;
  final String? department;
  final String? state;
  final String? district;
  final List<String> roles;
  final String? token;

  UserModel({
    required this.id,
    required this.email,
    required this.fullName,
    this.designation,
    this.department,
    this.state,
    this.district,
    required this.roles,
    this.token,
  });

  bool get isInspector => roles.contains('FIELD_INSPECTOR');

  factory UserModel.fromJson(Map<String, dynamic> json, {String? token}) {
    return UserModel(
      id: json['id']?.toString() ?? json['user_id']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      fullName: json['full_name']?.toString() ?? '',
      designation: json['designation']?.toString(),
      department: json['department']?.toString(),
      state: json['state']?.toString(),
      district: json['district']?.toString(),
      roles: json['roles'] != null ? List<String>.from(json['roles']) : ['FIELD_INSPECTOR'],
      token: token ?? json['access_token']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'full_name': fullName,
      'designation': designation,
      'department': department,
      'state': state,
      'district': district,
      'roles': roles,
      'token': token,
    };
  }

  Map<String, dynamic> toSqlite() {
    return {
      'id': id,
      'user_id': id,
      'email': email,
      'full_name': fullName,
      'role': roles.isNotEmpty ? roles.first : 'FIELD_INSPECTOR',
      'token': token ?? '',
      'cached_at': DateTime.now().toIso8601String(),
    };
  }
}
