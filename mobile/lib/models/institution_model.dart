// =====================================================================
// DRISHTI Mobile App: Institution Profile Model
// Maps to backend InstitutionResponse schema
// =====================================================================

class InstitutionModel {
  final String id;
  final String registrationCode;
  final String name;
  final String institutionType;
  final String state;
  final String district;
  final String address;
  final String pincode;
  final double latitude;
  final double longitude;
  final int geofenceRadiusMeters;
  final String contactPersonName;
  final String contactPhone;
  final String contactEmail;
  final int registeredCapacity;
  final int? currentOccupancy;
  final String? riskLevel;

  InstitutionModel({
    required this.id,
    required this.registrationCode,
    required this.name,
    required this.institutionType,
    required this.state,
    required this.district,
    required this.address,
    required this.pincode,
    required this.latitude,
    required this.longitude,
    this.geofenceRadiusMeters = 150,
    required this.contactPersonName,
    required this.contactPhone,
    required this.contactEmail,
    this.registeredCapacity = 50,
    this.currentOccupancy,
    this.riskLevel,
  });

  factory InstitutionModel.fromJson(Map<String, dynamic> json) {
    return InstitutionModel(
      id: json['id']?.toString() ?? '',
      registrationCode: json['registration_code']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      institutionType: json['institution_type']?.toString() ?? 'GENERAL',
      state: json['state']?.toString() ?? '',
      district: json['district']?.toString() ?? '',
      address: json['address']?.toString() ?? '',
      pincode: json['pincode']?.toString() ?? '',
      latitude: (json['latitude'] != null)
          ? double.tryParse(json['latitude'].toString()) ?? 0.0
          : 0.0,
      longitude: (json['longitude'] != null)
          ? double.tryParse(json['longitude'].toString()) ?? 0.0
          : 0.0,
      geofenceRadiusMeters: json['geofence_radius_meters'] != null
          ? int.tryParse(json['geofence_radius_meters'].toString()) ?? 150
          : 150,
      contactPersonName: json['contact_person_name']?.toString() ?? '',
      contactPhone: json['contact_phone']?.toString() ?? '',
      contactEmail: json['contact_email']?.toString() ?? '',
      registeredCapacity: json['registered_capacity'] != null
          ? int.tryParse(json['registered_capacity'].toString()) ?? 50
          : 50,
      currentOccupancy: json['current_occupancy'] != null
          ? int.tryParse(json['current_occupancy'].toString())
          : null,
      riskLevel: json['risk_level']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'registration_code': registrationCode,
      'name': name,
      'institution_type': institutionType,
      'state': state,
      'district': district,
      'address': address,
      'pincode': pincode,
      'latitude': latitude,
      'longitude': longitude,
      'geofence_radius_meters': geofenceRadiusMeters,
      'contact_person_name': contactPersonName,
      'contact_phone': contactPhone,
      'contact_email': contactEmail,
      'registered_capacity': registeredCapacity,
      'current_occupancy': currentOccupancy,
      'risk_level': riskLevel,
    };
  }
}
