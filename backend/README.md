# DRISHTI Backend Architecture (Phase 2)

**Digital Real-Time Inspection & Scheme Holistic Tracking Infrastructure**
*Developed for Ministry of Social Justice and Empowerment (MoSJE) - SIH 2026 Problem ID 26095*

---

## 1. Overview
The DRISHTI backend is a high-performance Python FastAPI service powered by SQLAlchemy, Pydantic V2, and PostgreSQL (with automated development/test fallbacks). It provides 48 REST API endpoints covering all 14 mandatory operational domains.

## 2. Directory Structure
```
backend/
├── app/
│   ├── api/
│   │   ├── deps.py             # JWT authentication, RBAC, audit logging dependencies
│   │   └── v1/
│   │       ├── __init__.py      # API v1 router aggregator
│   │       ├── ai_alerts.py     # AI alert management & inspection triggering
│   │       ├── ai_analysis.py   # Statistical anomaly detection records
│   │       ├── assignments.py   # Inspector assignment dispatch & geofence tracking
│   │       ├── attendance.py    # Beneficiary daily attendance & biometric audits
│   │       ├── audit.py         # Platform-wide immutable audit trail
│   │       ├── auth.py          # JWT authentication, demo login, role switching
│   │       ├── beneficiaries.py # Beneficiary records with masked identifier
│   │       ├── checklists.py    # Template inspection questions & responses
│   │       ├── dashboard.py     # Executive aggregated metrics & risk distribution
│   │       ├── evidence.py      # Geotagged photos, videos & SHA-256 tamper checks
│   │       ├── health.py        # System and database health probes
│   │       ├── inspections.py   # Unannounced inspection scheduling & workflow
│   │       ├── institutions.py  # NGO / institution directory & geofence profiles
│   │       ├── monitoring.py    # Daily facility telemetry & occupancy logs
│   │       ├── notifications.py # Real-time user alert dispatch
│   │       ├── reports.py       # Inspection reports & official administrative reviews
│   │       └── schemes.py       # MoSJE flagship scheme definitions (DDRS, AVYAY, etc.)
│   ├── config.py                # Pydantic-Settings environment configuration
│   ├── database.py              # Dialect-aware SQLAlchemy engine & GUID/JSON types
│   ├── main.py                  # FastAPI entry point, CORS, and lifespan seeder
│   ├── models/                  # 16 domain models mapped to relational schema
│   ├── schemas/                 # Pydantic V2 request/response validation schemas
│   └── seed.py                  # Synthetic demonstration data seeder
├── tests/                       # Complete Pytest test suite (26 passing tests)
│   ├── conftest.py              # Test client, auth headers, and in-memory DB fixtures
│   ├── test_ai_and_dashboard.py
│   ├── test_assignments_and_workflow.py
│   ├── test_auth.py
│   ├── test_checklists_and_evidence.py
│   ├── test_health.py
│   ├── test_inspections.py
│   ├── test_institutions.py
│   ├── test_monitoring_attendance.py
│   └── test_reports.py
├── verify_backend.py            # Comprehensive 4-stage verification suite
└── requirements.txt             # Python dependencies
```

## 3. Implemented Endpoint Groups (All 14 Modules)
| Category | Endpoint Prefix | Key Operations |
|---|---|---|
| **1. Authentication & Demo** | `/api/v1/auth` | `/login`, `/demo-login`, `/demo-users`, `/me` |
| **2. Institutions** | `/api/v1/institutions` | Directory listing, filtering by state/district/scheme, registration, risk profiling |
| **3. Monitoring** | `/api/v1/monitoring` | Daily telemetry submissions (occupancy, meals, CCTV uptime) |
| **4. Attendance** | `/api/v1/attendance` | Attendance recording, daily summary calculations, discrepancy flags |
| **5. Inspections** | `/api/v1/inspections` | Inspection creation, status state machine transitions, dispatch |
| **6. Assignments** | `/api/v1/inspection-assignments` | Inspector assignment, acceptance, arrival timestamping |
| **7. Checklists** | `/api/v1/inspection-checklists` | Dynamic scheme checklist templates & geotagged answers |
| **8. Evidence Metadata** | `/api/v1/evidence` | SHA-256 tamper-proof checksums, offline sync tracking |
| **9. Inspection Reports** | `/api/v1/inspection-reports` | On-site report submission & official administrative review actions |
| **10. Dashboard Summary** | `/api/v1/dashboard/summary` | National MoSJE executive metrics, risk distribution, scheme breakdowns |
| **11. AI Analysis** | `/api/v1/ai-analyses` | Isolation Forest anomaly records & divergence metrics |
| **12. AI Alerts** | `/api/v1/ai-alerts` | High-risk alerts, auto-triggering unannounced inspections |
| **13. Notifications** | `/api/v1/notifications` | User inbox, mark-as-read, real-time alert notifications |
| **14. Audit Activity** | `/api/v1/audit-activity` | Immutable administrative audit log with IP and action tracking |
| **Auxiliary** | `/api/v1/schemes`, `/api/v1/beneficiaries`, `/health` | Flagship schemes, beneficiary roster, health probes |

## 4. Running Verification and Tests
```bash
# Run full verification suite (Syntax, Startup, DB, Tests)
python3 backend/verify_backend.py

# Run Pytest directly
pytest
```
