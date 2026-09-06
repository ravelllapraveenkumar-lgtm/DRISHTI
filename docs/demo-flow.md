# DRISHTI — SIH 2026 End-to-End Demonstration Walkthrough

**Problem Statement ID**: 26095 (Ministry of Social Justice and Empowerment - MoSJE)  
**Project Title**: DRISHTI — Smart Real-Time Monitoring & Inspection Mobile App  
**Status**: SIH 2026 Competition-Ready Prototype (Synthetic & Demonstration Data Only)

---

## The 27-Step End-to-End Closed-Loop Demonstration

```
  [1] Institution Profile Exists
             │
             ▼
  [2] Daily Telemetry Ingestion (Attendance, Meals, CCTV, Geofence)
             │
             ▼
  [3] Multi-Factor Telemetry Anomaly Appears (Biometric Flatline + CCTV Offline)
             │
             ▼
  [4] AI Engine Evaluates Telemetry Vector (Isolation Forest + Statistical Fallback)
             │
             ▼
  [5] Attention Score Computed (0–100 Bounded Scale)
             │
             ▼
  [6] AI Alert Spawned for High/Critical Risk (Score ≥ 50)
             │
             ▼
  [7] Government Official Views Advisory Alert on Central Dashboard
             │
             ▼
  [8] Human Verification & Review Status Confirmed Required
             │
             ▼
  [9] Official Authorizes & Mandates Unannounced Physical Field Inspection
             │
             ▼
 [10] Field Inspector Authenticates into Flutter Mobile App
             │
             ▼
 [11] Inspector Receives & Opens Assigned Inspection Mandate
             │
             ▼
 [12] Inspector Views Target Institution Metadata & Geofence Boundary
             │
             ▼
 [13] On-Site Geofence GPS Verification (< 50m Proximity Tolerance)
             │
             ▼
 [14] Inspector Completes Standardized Inspection Checklist
             │
             ▼
 [15] Cryptographic Geotagged Evidence Metadata Captured (SHA-256 Checksum + GPS)
             │
             ▼
 [16] Inspector Records Qualitative Field Observation Notes
             │
             ▼
 [17] Inspector Prepares On-Site Inspection Report (Headcount & Condition Scores)
             │
             ▼
 [18] Inspection Report Saved to Local Device Storage
             │
             ▼
 [19] Offline Operation Mode Verified (SQLite Local Persistence Buffer)
             │
             ▼
 [20] Report & Evidence Enqueued in Transactional Sync Queue (PENDING State)
             │
             ▼
 [21] Mobile Network Connectivity Restored
             │
             ▼
 [22] Transactional Synchronization Triggered (Parent-First Parent UUID Order)
             │
             ▼
 [23] FastAPI Backend Validates & Ingests Payload (/api/v1/inspections)
             │
             ▼
 [24] Authoritative PostgreSQL Database Persists Inspection & Evidence Records
             │
             ▼
 [25] Central Government Dashboard Retrieves Updated Inspection & Evidence Data
             │
             ▼
 [26] Senior Official Reviews Inspector Findings & Issues Final Decision
             │
             ▼
 [27] Immutable System Audit Trail Logged (/api/v1/audit-activity)
```

---

## Role Demonstration Credentials

| Role | Email | Access Scope |
| :--- | :--- | :--- |
| **Super Admin** | `admin@mosje.gov.in` | Full system governance, audit logs, AI analysis ingestion, user management |
| **Ministry Official** | `official@mosje.gov.in` | Dashboard summary, AI alert review, inspection authorization, scheme analytics |
| **District Officer** | `district.lucknow@mosje.gov.in` | Regional facility monitoring, inspector assignment dispatch |
| **Field Inspector** | `inspector.up01@mosje.gov.in` | Mobile application, assigned inspections, checklist execution, evidence submission |
| **Institution Admin** | `admin@prerna-vridh.org` | Institution profile management, daily attendance ingestion |

---

## Responsible AI Operational Policy

1. **Non-Punitive Advisory Role**: The AI engine strictly functions as an automated decision-support utility.
2. **Mandatory Wording Directive**: All outputs use non-punitive terminology:
   - *"Potential anomaly detected in attendance telemetry."*
   - *"Verification recommended. Human review required."*
   - *"Unverified attendance log pattern flagged for periodic inspection."*
3. **Forbidden Terminology**: Accusatory or defamatory phrasing (`fraud`, `corrupt`, `fake`, `guilty`, `criminal`, `misconduct`, `scam`) is strictly prohibited and validated via regex safeguard `assert_responsible_language()`.
