/**
 * DRISHTI: Synthetic Demo Dataset (MoSJE Schemes)
 * Notice: ALL DATA IN THIS FILE IS STRICTLY SYNTHETIC AND ARTIFICIALLY GENERATED
 * FOR DEMO & SIH 2026 TESTING. IT DOES NOT CONTAIN REAL CITIZEN DATA.
 */

import {
  Institution,
  AIAlert,
  AIAnalysis,
  Inspection,
  ChecklistItem,
  EvidenceMetadata,
  InspectionReport,
  AuditLog
} from '../types/drishti';

export const SYNTHETIC_INSTITUTIONS: Institution[] = [
  {
    id: 'inst-001',
    registrationCode: 'MOSJE-DL-DDRS-019',
    name: 'Arunodaya Special School & Rehab Center',
    type: 'DDRS_CENTER',
    schemeId: 'scheme-ddrs',
    schemeName: 'Deendayal Disabled Rehabilitation Scheme',
    state: 'Delhi',
    district: 'South Delhi',
    address: 'Sector 4, R.K. Puram, Institutional Area, New Delhi',
    latitude: 28.5672,
    longitude: 77.1856,
    geofenceRadiusMeters: 100,
    contactPerson: 'Pooja Narang',
    contactPhone: '+91 99887 76655',
    sanctionedCapacity: 80,
    activeBeneficiaries: 74,
    currentRiskScore: 18,
    isActive: true
  },
  {
    id: 'inst-002',
    registrationCode: 'MOSJE-UP-AVYAY-042',
    name: 'Shanti Sadan Senior Citizens Home',
    type: 'OLD_AGE_HOME_AVYAY',
    schemeId: 'scheme-avyay',
    schemeName: 'Atal Vayo Abhyuday Yojana',
    state: 'Uttar Pradesh',
    district: 'Lucknow',
    address: 'Plot 18, Gomti Nagar Extension, Lucknow',
    latitude: 26.8521,
    longitude: 80.9984,
    geofenceRadiusMeters: 100,
    contactPerson: 'Rameshwar Dayal',
    contactPhone: '+91 94551 12233',
    sanctionedCapacity: 60,
    activeBeneficiaries: 58,
    currentRiskScore: 72,
    isActive: true
  },
  {
    id: 'inst-003',
    registrationCode: 'MOSJE-HR-NAPDDR-088',
    name: 'Nai Disha Integrated Addiction Rehab Center (IRCA)',
    type: 'NASHA_MUKTI_KENDRA_NAPDDR',
    schemeId: 'scheme-napddr',
    schemeName: 'National Action Plan for Drug Demand Reduction',
    state: 'Haryana',
    district: 'Gurugram',
    address: 'Old Railway Road, Near Civil Hospital, Gurugram',
    latitude: 28.4595,
    longitude: 77.0266,
    geofenceRadiusMeters: 100,
    contactPerson: 'Dr. Harpreet Chawla',
    contactPhone: '+91 97114 45566',
    sanctionedCapacity: 40,
    activeBeneficiaries: 39,
    currentRiskScore: 85,
    isActive: true
  },
  {
    id: 'inst-004',
    registrationCode: 'MOSJE-MP-DAKSH-011',
    name: 'Pratibha Skill Empowerment Hub',
    type: 'SKILL_DEVELOPMENT_PM_DAKSH',
    schemeId: 'scheme-daksh',
    schemeName: 'PM-DAKSH Skill Development',
    state: 'Madhya Pradesh',
    district: 'Bhopal',
    address: 'Industrial Area, Govindpura, Bhopal',
    latitude: 23.2599,
    longitude: 77.4126,
    geofenceRadiusMeters: 120,
    contactPerson: 'Suresh Kulkarni',
    contactPhone: '+91 98270 01122',
    sanctionedCapacity: 120,
    activeBeneficiaries: 115,
    currentRiskScore: 34,
    isActive: true
  }
];

export const SYNTHETIC_AI_ALERTS: AIAlert[] = [
  {
    id: 'alert-001',
    institutionId: 'inst-002',
    institutionName: 'Shanti Sadan Senior Citizens Home',
    severity: 'HIGH',
    title: 'Potential anomaly detected: Attendance vs Ration Log Variance',
    summary: 'Potential anomaly detected. Verification recommended. Discrepancy observed between claimed resident roster (58 residents) and dietary intake logs over the last 14 days.',
    suggestedScope: 'Verify physical resident presence, kitchen inventory, and medicine register.',
    isAcknowledged: false,
    timestamp: '2026-09-04 14:30 IST'
  },
  {
    id: 'alert-002',
    institutionId: 'inst-003',
    institutionName: 'Nai Disha Integrated Addiction Rehab Center (IRCA)',
    severity: 'CRITICAL',
    title: 'Potential anomaly detected: Geofence Offset & Telemetry Gap',
    summary: 'Potential anomaly detected. Verification recommended. In-patient telemetry reflects repeated coordinate pings 1.8km outside the approved geofence perimeter along with CCTV heartbeat dropouts.',
    suggestedScope: 'Urgent unannounced physical inspection of in-patient wards, attendance biometric station, and counselor rosters.',
    isAcknowledged: true,
    timestamp: '2026-09-04 11:15 IST'
  }
];

export const SYNTHETIC_INSPECTIONS: Inspection[] = [
  {
    id: 'insp-101',
    inspectionCode: 'INSP-2026-GGM-002',
    institutionId: 'inst-003',
    institutionName: 'Nai Disha Integrated Addiction Rehab Center (IRCA)',
    originAlertId: 'alert-002',
    priority: 'URGENT',
    status: 'ON_SITE_ACTIVE',
    mandatedDate: '2026-09-05',
    dueDate: '2026-09-06',
    inspectionReason: 'Surprise physical audit following AI divergence alert on geofence offset and patient attendance.',
    assignedInspectorId: 'user-insp-01',
    assignedInspectorName: 'Anjali Verma (Badge: INSP-DL-2026-88)',
    specialInstructions: 'Verify physical bed occupancy and match with counselor attendance records.'
  },
  {
    id: 'insp-102',
    inspectionCode: 'INSP-2026-LKO-001',
    institutionId: 'inst-002',
    institutionName: 'Shanti Sadan Senior Citizens Home',
    originAlertId: 'alert-001',
    priority: 'HIGH',
    status: 'ASSIGNED',
    mandatedDate: '2026-09-05',
    dueDate: '2026-09-07',
    inspectionReason: 'Headcount audit to verify discrepancy in resident dietary records.',
    assignedInspectorId: 'user-insp-02',
    assignedInspectorName: 'Vikram Singh (Badge: INSP-UP-2026-14)',
    specialInstructions: 'Inspect food storage, kitchen logbook, and doctor visit register.'
  }
];

export const SYNTHETIC_CHECKLIST: ChecklistItem[] = [
  {
    id: 'chk-01',
    section: 'Geographic Boundary',
    question: 'Does the physical site match the registered geo-coordinates within the 100m geofence perimeter?',
    isMandatory: true,
    response: true,
    comment: 'Verified on-site GPS matches center gate.'
  },
  {
    id: 'chk-02',
    section: 'Physical Headcount',
    question: 'Does physical headcount match the biometric daily portal submission?',
    isMandatory: true,
    response: false,
    comment: 'Only 22 patients physically present during unannounced roll call out of 39 reported.'
  },
  {
    id: 'chk-03',
    section: 'Infrastructure & Safety',
    question: 'Are barrier-free ramps, functional clean toilets, and fire safety systems in place?',
    isMandatory: true,
    response: true,
    comment: 'Fire extinguishers active; ramps installed.'
  },
  {
    id: 'chk-04',
    section: 'Dietary & Medical',
    question: 'Are daily meal logs and psychiatric doctor visitation logs up to date?',
    isMandatory: true,
    response: false,
    comment: 'Last doctor visit recorded 24 days ago.'
  }
];

export const SYNTHETIC_EVIDENCE: EvidenceMetadata[] = [
  {
    id: 'evi-001',
    inspectionId: 'insp-101',
    type: 'GEO_TAGGED_PHOTO',
    fileName: 'front_gate_signboard.jpg',
    fileUrl: 'https://images.unsplash.com/photo-1582560475093-ba66accbc424?w=600&auto=format&fit=crop&q=80',
    sha256Checksum: '8f434346648f6b96df89dda901c5176b10a6d83961dd3c1ac88b59b2dc327aa4',
    description: 'Entrance gate with MoSJE grant acknowledgement signboard.',
    timestamp: '2026-09-05 10:14 IST',
    latitude: 28.45952,
    longitude: 77.02663,
    accuracyMeters: 4.2,
    geofenceVerified: true,
    syncStatus: 'SYNCED_SUCCESS'
  },
  {
    id: 'evi-002',
    inspectionId: 'insp-101',
    type: 'GEO_TAGGED_PHOTO',
    fileName: 'dormitory_headcount.jpg',
    fileUrl: 'https://images.unsplash.com/photo-1519494026892-80bbd2d6fd0d?w=600&auto=format&fit=crop&q=80',
    sha256Checksum: 'a7c93608103d778d91beec184d0b16a49c9586146ff7ff96706e2da55ec843f8',
    description: 'In-patient dormitory ward inspection showing vacant beds.',
    timestamp: '2026-09-05 10:28 IST',
    latitude: 28.45951,
    longitude: 77.02661,
    accuracyMeters: 3.8,
    geofenceVerified: true,
    syncStatus: 'SYNCED_SUCCESS'
  }
];

export const SYNTHETIC_AUDIT_LOGS: AuditLog[] = [
  {
    id: 'audit-001',
    timestamp: '2026-09-05 10:35 IST',
    actorName: 'Anjali Verma',
    actorRole: 'FIELD_INSPECTOR',
    action: 'OFFLINE_EVIDENCE_SYNC',
    targetEntity: 'EvidenceMetadata (evi-001, evi-002)',
    details: 'Synced 2 geotagged evidence records and 4 checklist responses from local SQLite cache.'
  },
  {
    id: 'audit-002',
    timestamp: '2026-09-04 15:00 IST',
    actorName: 'Dr. Rajesh Sharma',
    actorRole: 'MINISTRY_OFFICER',
    action: 'INSPECTION_ASSIGNED',
    targetEntity: 'Inspection (INSP-2026-GGM-002)',
    details: 'Authorized unannounced on-site verification based on AI Critical anomaly alert alert-002.'
  },
  {
    id: 'audit-003',
    timestamp: '2026-09-04 11:15 IST',
    actorName: 'AI Engine (IsolationForest_v1)',
    actorRole: 'SUPER_ADMIN',
    action: 'ANOMALY_EVALUATION',
    targetEntity: 'Institution (inst-003)',
    details: 'Calculated Risk Score: 85 (CRITICAL). Flagged geofence offset and CCTV dropouts.'
  }
];
