// =====================================================================
// DRISHTI Mobile App: Inspection Assignment Model
// Maps directly to backend InspectionAssignment entity
// =====================================================================

class AssignmentModel {
  final String id;
  final String inspectionId;
  final String inspectorUserId;
  final DateTime assignedAt;
  final DateTime? acceptedAt;
  final DateTime? arrivedAt;
  final DateTime? completedAt;
  final String? inspectorName;
  final String? inspectionCode;
  final String? inspectionStatus;
  final String? notes;

  AssignmentModel({
    required this.id,
    required this.inspectionId,
    required this.inspectorUserId,
    required this.assignedAt,
    this.acceptedAt,
    this.arrivedAt,
    this.completedAt,
    this.inspectorName,
    this.inspectionCode,
    this.inspectionStatus,
    this.notes,
  });

  bool get isAccepted => acceptedAt != null;
  bool get hasArrived => arrivedAt != null;
  bool get isCompleted => completedAt != null;

  factory AssignmentModel.fromJson(Map<String, dynamic> json) {
    return AssignmentModel(
      id: json['id']?.toString() ?? '',
      inspectionId: json['inspection_id']?.toString() ?? '',
      inspectorUserId: json['inspector_user_id']?.toString() ?? '',
      assignedAt: json['assigned_at'] != null
          ? DateTime.parse(json['assigned_at'])
          : DateTime.now(),
      acceptedAt: json['accepted_at'] != null ? DateTime.parse(json['accepted_at']) : null,
      arrivedAt: json['arrived_at'] != null ? DateTime.parse(json['arrived_at']) : null,
      completedAt: json['completed_at'] != null ? DateTime.parse(json['completed_at']) : null,
      inspectorName: json['inspector_name']?.toString(),
      inspectionCode: json['inspection_code']?.toString(),
      inspectionStatus: json['inspection_status']?.toString(),
      notes: json['notes']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'inspection_id': inspectionId,
      'inspector_user_id': inspectorUserId,
      'assigned_at': assignedAt.toIso8601String(),
      'accepted_at': acceptedAt?.toIso8601String(),
      'arrived_at': arrivedAt?.toIso8601String(),
      'completed_at': completedAt?.toIso8601String(),
      'inspector_name': inspectorName,
      'inspection_code': inspectionCode,
      'inspection_status': inspectionStatus,
      'notes': notes,
    };
  }
}
