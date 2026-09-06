# DRISHTI REST API v1 Specification
> **Base URL:** `/api/v1`  
> **Protocol:** HTTPS / TLS 1.3  
> **Auth:** Bearer JWT (HMAC-SHA256)

---

## 1. Authentication & Session
- **`POST /api/v1/auth/login`**
  - Authenticates MoSJE Officer, Inspector, or Institution Head.
  - Returns JWT token, user roles, and profile metadata.
- **`POST /api/v1/auth/demo-switch`**
  - Quickly switches between demo roles (Ministry Officer, Field Inspector, Institution Manager).
- **`GET /api/v1/auth/me`**
  - Validates active token and returns current user entity.

---

## 2. Institutions & Beneficiaries
- **`GET /api/v1/institutions`**
  - Query params: `scheme_id`, `state`, `district`, `min_risk_score`, `type`.
  - Returns paginated institutions with risk scores and coordinates.
- **`GET /api/v1/institutions/{id}`**
  - Detailed profile including telemetry trends and assigned schemes.
- **`GET /api/v1/institutions/{id}/beneficiaries`**
  - Roster of enrolled beneficiaries (masked identifiers).

---

## 3. Monitoring & Attendance Telemetry
- **`POST /api/v1/monitoring/records`**
  - Daily institution operational telemetry ingestion (attendance, meals, CCTV ping).
- **`GET /api/v1/monitoring/records/{institution_id}`**
  - Historical 30-day telemetry stream for time-series evaluation.
- **`POST /api/v1/attendance/batch`**
  - Batch biometric check-in log ingestion.
- **`GET /api/v1/attendance/stats/{institution_id}`**
  - Aggregated present vs absent distribution.

---

## 4. AI Engine: Analysis & Alerts
- **`POST /api/v1/ai/analyze/{institution_id}`**
  - Triggers on-demand Isolation Forest evaluation over 30-day window.
  - Returns calculated risk score (0–100), severity, and explainable reason.
- **`GET /api/v1/ai/alerts`**
  - Returns list of potential anomalies requiring human review.
- **`PATCH /api/v1/ai/alerts/{id}/acknowledge`**
  - Ministry official acknowledges alert and initiates/rejects inspection.

---

## 5. Inspections & Field Assignments
- **`GET /api/v1/inspections`**
  - Filter by status (`PENDING_DISPATCH`, `ASSIGNED`, `ON_SITE_ACTIVE`, `SYNCED`).
- **`POST /api/v1/inspections`**
  - Ministry officer creates an inspection mandate.
- **`POST /api/v1/inspection-assignments`**
  - Assigns inspection to a field inspector.
- **`GET /api/v1/inspection-assignments/my-assigned`**
  - Endpoint used by Inspector Mobile App to download active assignments.

---

## 6. Checklist & Evidence Metadata
- **`GET /api/v1/checklists/template/{scheme_category}`**
  - Retrieves standardized checklist questions for offline caching.
- **`POST /api/v1/evidence/upload`**
  - Receives evidence metadata (SHA-256 hash, GPS lat/long, accuracy, timestamp).
- **`POST /api/v1/inspections/sync`**
  - **Core Offline-First Transactional Sync Endpoint**:
    Receives complete mobile inspection package (checklist answers, evidence items, notes).
    Verifies cryptographic signatures and commits to PostgreSQL.

---

## 7. Inspection Reports & Administrative Actions
- **`POST /api/v1/reports`**
  - Submits final consolidated inspection report.
- **`GET /api/v1/reports/{inspection_id}`**
  - Fetches report details with inspector summary and physical headcount.
- **`PATCH /api/v1/reports/{id}/official-action`**
  - MoSJE Ministry official records final administrative verdict.

---

## 8. Dashboard Summaries & Audit
- **`GET /api/v1/dashboard/summary`**
  - Real-time KPI aggregates: total institutions, high-risk flagged count, ongoing inspections, pending offline syncs, attendance percentage.
- **`GET /api/v1/notifications`**
  - User-specific notifications.
- **`GET /api/v1/audit/activity`**
  - Immutable audit trail of all security-sensitive actions.
