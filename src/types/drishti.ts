/**
 * DRISHTI: Core Domain Type Definitions
 * SIH 2026 Problem ID: 26095 (Ministry of Social Justice and Empowerment)
 */

export type UserRole =
  | 'SUPER_ADMIN'
  | 'MINISTRY_OFFICER'
  | 'DISTRICT_MAGISTRATE'
  | 'INSPECTION_SUPERVISOR'
  | 'FIELD_INSPECTOR'
  | 'INSTITUTION_HEAD';

export type InstitutionType =
  | 'DDRS_CENTER'               // Deendayal Disabled Rehabilitation Scheme
  | 'OLD_AGE_HOME_AVYAY'       // Atal Vayo Abhyuday Yojana
  | 'NASHA_MUKTI_KENDRA_NAPDDR' // National Action Plan for Drug Demand Reduction
  | 'SKILL_DEVELOPMENT_PM_DAKSH'// PM-DAKSH Vocational Centers
  | 'SPECIAL_SCHOOL'
  | 'HALFWAY_HOME';

export type SchemeCategory =
  | 'DISABILITY_EMPOWERMENT'
  | 'SENIOR_CITIZENS'
  | 'SUBSTANCE_REHABILITATION'
  | 'SC_OBC_DEVELOPMENT'
  | 'VOCATIONAL_SKILLS';

export type AnomalySeverity = 'LOW' | 'MEDIUM' | 'HIGH' | 'CRITICAL';

export type InspectionStatus =
  | 'PENDING_DISPATCH'
  | 'ASSIGNED'
  | 'INSPECTOR_EN_ROUTE'
  | 'ON_SITE_ACTIVE'
  | 'COMPLETED_OFFLINE'
  | 'SYNCED'
  | 'UNDER_MINISTRY_REVIEW'
  | 'CLOSED_ACTION_TAKEN';

export type PriorityLevel = 'ROUTINE' | 'MEDIUM' | 'HIGH' | 'URGENT';

export type EvidenceType =
  | 'GEO_TAGGED_PHOTO'
  | 'GEO_TAGGED_VIDEO'
  | 'BENEFICIARY_VOICE_NOTE'
  | 'INFRASTRUCTURE_AUDIT_IMAGE'
  | 'REGISTER_SCAN';

export type SyncStatus =
  | 'LOCAL_PENDING'
  | 'SYNCING'
  | 'SYNCED_SUCCESS'
  | 'SYNC_FAILED'
  | 'RETRY_QUEUED';

export type ReportVerdict =
  | 'SATISFACTORY'
  | 'MINOR_NON_COMPLIANCE'
  | 'MAJOR_DEFICIENCIES_DETECTED'
  | 'PHYSICAL_DISCREPANCY_CONFIRMED'
  | 'RECOMMENDED_GRANT_PAUSE';

export interface User {
  id: string;
  email: string;
  fullName: string;
  role: UserRole;
  badgeNumber?: string;
  phoneNumber: string;
  isActive: boolean;
}

export interface Scheme {
  id: string;
  code: string;
  name: string;
  category: SchemeCategory;
  sanctionedBudget: number;
  annualTargetBeneficiaries: number;
}

export interface Institution {
  id: string;
  registrationCode: string;
  name: string;
  type: InstitutionType;
  schemeId: string;
  schemeName: string;
  state: string;
  district: string;
  address: string;
  latitude: number;
  longitude: number;
  geofenceRadiusMeters: number;
  contactPerson: string;
  contactPhone: string;
  sanctionedCapacity: number;
  activeBeneficiaries: number;
  currentRiskScore: number; // 0-100
  isActive: boolean;
}

export interface DailyMonitoringRecord {
  id: string;
  institutionId: string;
  date: string;
  enrolledBeneficiaries: number;
  presentBeneficiaries: number;
  presentStaff: number;
  mealsServed: number;
  cctvUptimePercentage: number;
  geofenceMatch: boolean;
}

export interface AIAnalysis {
  id: string;
  institutionId: string;
  institutionName: string;
  timestamp: string;
  riskAttentionScore: number; // 0 to 100
  severity: AnomalySeverity;
  statisticalDivergenceScore: number;
  potentialAnomalyFlag: boolean;
  explainableReason: string;
  recommendedAction: string;
  requiresHumanReview: boolean;
}

export interface AIAlert {
  id: string;
  institutionId: string;
  institutionName: string;
  severity: AnomalySeverity;
  title: string;
  summary: string;
  suggestedScope: string;
  isAcknowledged: boolean;
  timestamp: string;
}

export interface Inspection {
  id: string;
  inspectionCode: string;
  institutionId: string;
  institutionName: string;
  originAlertId?: string;
  priority: PriorityLevel;
  status: InspectionStatus;
  mandatedDate: string;
  dueDate: string;
  inspectionReason: string;
  assignedInspectorId?: string;
  assignedInspectorName?: string;
  specialInstructions?: string;
}

export interface ChecklistItem {
  id: string;
  section: string;
  question: string;
  isMandatory: boolean;
  response?: boolean;
  comment?: string;
}

export interface EvidenceMetadata {
  id: string;
  inspectionId: string;
  type: EvidenceType;
  fileName: string;
  fileUrl: string;
  sha256Checksum: string;
  description: string;
  timestamp: string;
  latitude: number;
  longitude: number;
  accuracyMeters: number;
  geofenceVerified: boolean;
  syncStatus: SyncStatus;
}

export interface InspectionReport {
  id: string;
  inspectionId: string;
  inspectorName: string;
  submissionTimestamp: string;
  physicalHeadcount: number;
  rosterDiscrepancyCount: number;
  cleanlinessScore: number; // 1-10
  foodNutritionScore: number; // 1-10
  infrastructureScore: number; // 1-10
  inspectorSummary: string;
  verdict: ReportVerdict;
  officialReviewStatus: 'PENDING_OFFICIAL_REVIEW' | 'REVIEWED_ACTION_TAKEN';
  officialNotes?: string;
}

export interface AuditLog {
  id: string;
  timestamp: string;
  actorName: string;
  actorRole: UserRole;
  action: string;
  targetEntity: string;
  details: string;
}
