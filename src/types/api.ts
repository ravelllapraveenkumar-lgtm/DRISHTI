/**
 * DRISHTI API Data Transfer Types
 * Synchronized with FastAPI Backend (backend/app/schemas/)
 * SIH 2026 Problem ID: 26095 | Ministry of Social Justice and Empowerment (MoSJE)
 */

export type UserRole =
  | 'SUPER_ADMIN'
  | 'MINISTRY_OFFICIAL'
  | 'DISTRICT_OFFICER'
  | 'FIELD_INSPECTOR'
  | 'INSTITUTION_ADMIN';

export type AnomalySeverity = 'LOW' | 'MEDIUM' | 'HIGH' | 'CRITICAL';
export type AlertSeverity = AnomalySeverity;

export type InspectionStatus =
  | 'PENDING_DISPATCH'
  | 'ASSIGNED'
  | 'IN_PROGRESS'
  | 'SUBMITTED'
  | 'APPROVED'
  | 'CLOSED';

export type PriorityLevel = 'ROUTINE' | 'URGENT' | 'EMERGENCY';

export type ReportVerdict =
  | 'COMPLIANT'
  | 'MINOR_NON_COMPLIANCE'
  | 'CRITICAL_IRREGULARITIES'
  | 'SHOW_CAUSE_RECOMMENDED';

export type OfficialReviewStatus =
  | 'PENDING_OFFICIAL_REVIEW'
  | 'REVIEWED_ACCEPTED'
  | 'ACTION_INITIATED'
  | 'RE_INSPECTION_ORDERED';

export type ReportStatus = OfficialReviewStatus;

export type ActionTakenType =
  | 'SHOW_CAUSE_NOTICE'
  | 'FREEZE_GRANT_INSTALLMENT'
  | 'MANDATORY_RECTIFICATION_AUDIT'
  | 'REVOKE_EMPANELMENT';

export interface Token {
  access_token: string;
  token_type: string;
  expires_in_minutes: number;
  user_id: string;
  email: string;
  full_name: string;
  roles: string[];
}

export interface UserProfile {
  id: string;
  email: string;
  phone_number?: string;
  full_name: string;
  designation?: string;
  department?: string;
  state?: string;
  district?: string;
  is_active: boolean;
  is_demo: boolean;
  roles: string[];
  created_at: string;
  last_login_at?: string;
}

export interface DemoUser {
  id: string;
  email: string;
  full_name: string;
  designation: string;
  department: string;
  state: string;
  district: string;
  roles: string[];
  demo_password?: string;
}

export interface RiskDistribution {
  low: number;
  medium: number;
  high: number;
  critical: number;
}

export interface SchemeStats {
  scheme_code: string;
  scheme_name: string;
  category: string;
  institutions_count: number;
  beneficiaries_count: number;
  active_inspections_count: number;
  critical_alerts_count: number;
}

export interface DashboardSummary {
  total_institutions: number;
  total_beneficiaries: number;
  active_inspections: number;
  completed_inspections: number;
  pending_ai_alerts: number;
  average_daily_attendance_pct: number;
  cctv_online_rate_pct: number;
  risk_distribution: RiskDistribution;
  schemes: SchemeStats[];
  recent_critical_alerts: any[];
  recent_inspections: any[];
}

export interface Institution {
  id: string;
  registration_code: string;
  name: string;
  institution_type: string;
  primary_scheme_id: string;
  primary_scheme_code?: string;
  primary_scheme_name?: string;
  state: string;
  district: string;
  sub_division?: string;
  address: string;
  pincode: string;
  latitude: number;
  longitude: number;
  geofence_radius_meters: number;
  contact_person_name: string;
  contact_phone: string;
  contact_email: string;
  registered_capacity: number;
  current_occupancy: number;
  cctv_streams_count: number;
  cctv_status: string;
  is_active: boolean;
  verification_status: string;
  current_risk_score: number;
  risk_level: string;
  last_inspected_at?: string;
  total_beneficiaries_count?: number;
  active_inspections_count?: number;
  unacknowledged_alerts_count?: number;
  created_at: string;
  updated_at: string;
}

export interface MonitoringRecord {
  id: string;
  institution_id: string;
  institution_name?: string;
  record_date: string;
  reported_beneficiaries_present: number;
  biometric_punch_count: number;
  staff_present_count: number;
  meals_served_count: number;
  cctv_uptime_percentage: number;
  geofence_status: string;
  telemetry_payload?: Record<string, any>;
  is_synthetic: boolean;
  created_at: string;
  updated_at?: string;
}

export interface AttendanceRecord {
  id: string;
  institution_id: string;
  institution_name?: string;
  beneficiary_id: string;
  beneficiary_name?: string;
  attendance_date: string;
  status: 'PRESENT' | 'ABSENT' | 'ON_LEAVE';
  verification_mode: string;
  is_synthetic: boolean;
  created_at: string;
}

export interface AttendanceSummary {
  institution_id: string;
  attendance_date: string;
  total_roster_count: number;
  present_count: number;
  absent_count: number;
  on_leave_count: number;
  attendance_percentage: number;
}

export interface Inspection {
  id: string;
  inspection_code: string;
  institution_id: string;
  institution_name?: string;
  institution_district?: string;
  institution_state?: string;
  origin_ai_alert_id?: string;
  priority: PriorityLevel;
  status: InspectionStatus;
  mandated_date: string;
  due_date: string;
  inspection_reason: string;
  special_instructions?: string;
  assigned_inspector_name?: string;
  assigned_inspector_id?: string;
  assigned_by_user_id: string;
  created_at: string;
  updated_at: string;
}

export interface InspectionAssignment {
  id: string;
  inspection_id: string;
  inspector_user_id: string;
  assigned_at: string;
  accepted_at?: string;
  arrived_at?: string;
  completed_at?: string;
  assigned_by_id: string;
  notes?: string;
  inspector_name?: string;
  inspector_email?: string;
  inspection_code?: string;
  inspection_status?: string;
  created_at: string;
}

export interface ChecklistItem {
  id: string;
  template_id: string;
  section_name: string;
  item_question: string;
  field_type: string;
  is_mandatory: boolean;
  guidance_notes?: string;
  order_index: number;
}

export interface ChecklistTemplate {
  id: string;
  name: string;
  scheme_category: string;
  version: number;
  is_active: boolean;
  items: ChecklistItem[];
}

export interface ChecklistSubmission {
  id: string;
  inspection_id: string;
  checklist_item_id: string;
  response_boolean?: boolean;
  response_value?: string;
  inspector_comment?: string;
  gps_latitude?: number;
  gps_longitude?: number;
  captured_at: string;
  item_question?: string;
  section_name?: string;
}

export interface EvidenceRecord {
  id: string;
  inspection_id: string;
  evidence_type: string;
  file_name: string;
  file_path_or_url: string;
  sha256_checksum: string;
  description: string;
  timestamp_captured: string;
  gps_latitude: number;
  gps_longitude: number;
  gps_accuracy_meters: number;
  geofence_verified: boolean;
  sync_status: string;
  sync_attempts: number;
  local_sqlite_id?: string;
  captured_by_user_id: string;
  created_at: string;
}

export interface InspectionReport {
  id: string;
  inspection_id: string;
  inspector_id: string;
  submission_timestamp: string;
  submitted_at?: string;
  institution_name?: string;
  physical_beneficiary_count: number;
  physical_headcount?: number;
  reported_headcount?: number;
  roster_discrepancy_count: number;
  cleanliness_score?: number;
  cleanliness_rating?: number;
  food_nutrition_score?: number;
  nutrition_rating?: number;
  infrastructure_condition_score?: number;
  infrastructure_rating?: number;
  inspector_summary: string;
  findings_summary?: string;
  overall_verdict: ReportVerdict;
  official_review_status: OfficialReviewStatus;
  status?: OfficialReviewStatus;
  reviewed_by_official_id?: string;
  official_decision_notes?: string;
  official_review_notes?: string;
  action_taken_type?: string;
  action_taken_at?: string;
  inspector_name?: string;
  inspection_code?: string;
  created_at: string;
}

export interface AIAnalysis {
  id: string;
  institution_id: string;
  institution_name?: string;
  institution_state?: string;
  institution_district?: string;
  analysis_timestamp: string;
  algorithm_used: string;
  dataset_window_days: number;
  risk_attention_score: number;
  severity_level: AnomalySeverity;
  statistical_divergence_score: number;
  potential_anomaly_flag: boolean;
  explainable_reason: string;
  recommended_action: string;
  requires_human_review: boolean;
  reviewed_by_user_id?: string;
  reviewed_at?: string;
  review_notes?: string;
  created_at: string;
}

export interface AIAlert {
  id: string;
  ai_analysis_id: string;
  institution_id: string;
  institution_name?: string;
  institution_state?: string;
  institution_district?: string;
  severity: AnomalySeverity;
  title: string;
  alert_summary: string;
  suggested_inspection_scope?: string;
  is_acknowledged: boolean;
  acknowledged_by?: string;
  acknowledged_at?: string;
  created_at: string;
}

export interface Notification {
  id: string;
  recipient_user_id: string;
  title: string;
  message: string;
  category: 'ALERT' | 'ASSIGNMENT' | 'REPORT_SUBMITTED' | 'SYSTEM';
  entity_reference_id?: string;
  is_read: boolean;
  created_at: string;
}

export interface AuditActivity {
  id: string;
  actor_user_id?: string;
  actor_name?: string;
  actor_email?: string;
  action: string;
  actor_role?: string;
  target_entity: string;
  entity_id?: string;
  ip_address?: string;
  user_agent?: string;
  details?: Record<string, any>;
  created_at: string;
}

export type AuditLogEntry = AuditActivity;

export interface Scheme {
  id: string;
  code: string;
  name: string;
  category: string;
  description?: string;
  is_active: boolean;
}

export interface Beneficiary {
  id: string;
  institution_id: string;
  first_name: string;
  last_name: string;
  registration_number: string;
  gender: string;
  enrollment_date: string;
  is_active: boolean;
}
