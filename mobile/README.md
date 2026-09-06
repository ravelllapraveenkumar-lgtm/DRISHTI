# DRISHTI Field Inspector Mobile App
> **Ministry of Social Justice and Empowerment (MoSJE) — Government of India**  
> **Framework:** Flutter 3.x + Dart (Android / Cross-Platform)  
> **Local Persistence:** SQLite (`sqflite` v2) with Offline-First Queuing  
> **Backend Integration:** DRISHTI FastAPI REST API + PostgreSQL + RBAC  

---

## 1. Architectural Overview

The DRISHTI Field Inspector mobile client provides an **offline-first field execution engine** designed for inspectors operating in areas with zero or intermittent cellular connectivity. All inspection workflows—from geofence arrival and sectional checklists to tamper-evident media registration, field notes, and consolidated report drafting—persist locally in SQLite before queuing into an outbox synchronization state machine.

```
┌────────────────────────────────────────────────────────────────────────┐
│                          FLUTTER PRESENTATION                          │
│  - LoginScreen (MoSJE Official & 1-Click Inspector Demo Login)         │
│  - DashboardScreen (Cached Metrics, Priority Filters, Assignment Feed) │
│  - InspectionDetailScreen (Geofence Arrival & 5-Stage Workspace Hub)   │
│  - ChecklistScreen (Sectional Questions, Yes/No/Remarks, Geotagging)   │
│  - EvidenceScreen (Camera/Gallery, SHA-256 Hashes, Geofence Tags)      │
│  - NotesScreen (Observations, Deficiencies, Follow-up Directives)      │
│  - ReportSubmissionScreen (Headcounts, Scores 1-10, Summary, Verdict)  │
│  - SyncQueueScreen (Outbox Queue Monitor, Error Inspector, Retry All)  │
│  - SettingsScreen (Target Host Config, Live Health Ping Diagnostic)    │
└───────────────────────────────────┬────────────────────────────────────┘
                                    │
                                    ▼
┌────────────────────────────────────────────────────────────────────────┐
│                      SERVICE & PROVIDER STATE LAYER                    │
│  - AuthProvider & InspectionsProvider & InspectionDetailProvider       │
│  - LocationService (Haversine Distance, Geofence Validation, Accuracy) │
│  - EvidenceService (SHA-256 Cryptographic Checksums, Tamper Metadata)  │
│  - SyncManager (Atomic Dependency Ordering: Insp -> Chk -> Ev -> Rep)  │
└───────────────────────────────────┬────────────────────────────────────┘
                                    │
                                    ▼
┌────────────────────────────────────────────────────────────────────────┐
│                     LOCAL SQLITE OFFLINE PERSISTENCE                   │
│  - local_inspections (Target coordinates, mandated dates, AI alerts)   │
│  - local_checklist_templates & local_checklist_items (Offline cache)   │
│  - local_checklist_responses (Per-item answers & comments)             │
│  - local_evidence (Local file path, SHA-256 hash, Geotag, Accuracy)    │
│  - local_notes (Field observations & critical deficiency tags)         │
│  - local_reports (Beneficiary counts, ratings, overall verdict)        │
│  - local_sync_queue (PENDING -> SYNCING -> SYNCED / FAILED)            │
│  - local_user_session (Cached session tokens for offline auth)         │
└───────────────────────────────────┬────────────────────────────────────┘
                                    │
                   HTTP/REST (Bearer Token + JSON Payload)
                                    ▼
┌────────────────────────────────────────────────────────────────────────┐
│                   EXISTING DRISHTI FASTAPI BACKEND                     │
│  - POST  /api/v1/auth/login & /demo-login                              │
│  - GET   /api/v1/inspection-assignments/inspector/{id}                │
│  - PATCH /api/v1/inspections/{id}/status                               │
│  - GET   /api/v1/inspection-checklists/templates                       │
│  - POST  /api/v1/inspection-checklists (Batch atomic submission)       │
│  - POST  /api/v1/evidence (SHA-256 metadata registration)              │
│  - POST  /api/v1/inspection-reports (Consolidated field reports)       │
└────────────────────────────────────────────────────────────────────────┘
```

---

## 2. Directory Structure

```
mobile/
├── pubspec.yaml                 # Dependencies (http, sqflite, crypto, geolocator, provider)
├── analysis_options.yaml        # Flutter linter configuration
├── README.md                    # System architecture & deployment guide
├── lib/
│   ├── main.dart                # App entry point, MultiProvider setup, theme
│   ├── core/
│   │   ├── constants/
│   │   │   ├── api_endpoints.dart  # FastAPI endpoint URL mappings
│   │   │   ├── app_colors.dart     # High-contrast MoSJE government theme
│   │   │   └── app_strings.dart    # Responsible AI phrasing & offline notices
│   │   ├── errors/
│   │   │   └── app_exception.dart  # Network, Auth, Geofence, and Sync exceptions
│   │   ├── network/
│   │   │   └── api_client.dart     # Centralized HTTP client with Bearer auth
│   │   └── utils/
│   │       ├── geo_calculator.dart # Haversine distance & geofence validation
│   │       └── hash_util.dart      # SHA-256 cryptographic checksums
│   ├── data/
│   │   ├── local/
│   │   │   ├── sqlite_schema.dart  # Version 2 SQLite schema with 9 tables
│   │   │   └── database_helper.dart# Database CRUD operations & migrations
│   │   └── remote/
│   │       ├── auth_api_service.dart
│   │       ├── inspection_api_service.dart
│   │       ├── checklist_api_service.dart
│   │       ├── evidence_api_service.dart
│   │       └── report_api_service.dart
│   ├── models/
│   │   ├── assignment_model.dart
│   │   ├── checklist_model.dart
│   │   ├── evidence_model.dart
│   │   ├── inspection_model.dart
│   │   ├── institution_model.dart
│   │   ├── note_model.dart
│   │   ├── report_model.dart
│   │   ├── sync_queue_item.dart
│   │   └── user_model.dart
│   ├── providers/
│   │   ├── auth_provider.dart
│   │   ├── inspection_detail_provider.dart
│   │   └── inspections_provider.dart
│   ├── screens/
│   │   ├── login_screen.dart
│   │   ├── dashboard_screen.dart
│   │   ├── inspection_detail_screen.dart
│   │   ├── checklist_screen.dart
│   │   ├── evidence_screen.dart
│   │   ├── notes_screen.dart
│   │   ├── report_submission_screen.dart
│   │   ├── sync_queue_screen.dart
│   │   └── settings_screen.dart
│   ├── services/
│   │   ├── evidence_service.dart
│   │   ├── location_service.dart
│   │   └── sync_manager.dart
│   └── widgets/
│       ├── ai_anomaly_card.dart
│       ├── geofence_status_card.dart
│       ├── government_header.dart
│       └── sync_status_badge.dart
└── test/
    ├── geo_calculator_test.dart
    ├── hash_util_test.dart
    └── model_serialization_test.dart
```

---

## 3. Strict Synchronization & Dependency Ordering

1. **Server UUID vs. Local Client ID**:
   - Every local entity has an auto-generated client ID (e.g. `local_1234`, `ev_5678`).
   - Child records (Checklists, Evidence, Reports) reference the parent inspection's server UUID (`server_id`).
   - When a parent inspection is fetched or created, its real server UUID is cascaded down to all pending child records before synchronization.
2. **Dependency Pipeline**:
   - Order: `STATUS_UPDATE` -> `CHECKLIST_BATCH` -> `EVIDENCE` -> `REPORT`.
   - Child records are held in `PENDING` state until the parent inspection server UUID is confirmed.
   - An operation is **never** marked `SYNCED` unless the server returns HTTP `200` or `201`.
   - Failed operations retain their original payload and last error message, allowing safe retry.

---

## 4. Evidence Integrity (Tamper-Resistant SHA-256)

- Media files are processed through Dart's standard `crypto` library to calculate a 64-character lowercase hexadecimal digest.
- The checksum is attached alongside device GPS coordinates (`latitude`, `longitude`, `accuracy_meters`) and UTC capture timestamp.
- **Prototype Storage Compliance**: In accordance with DRISHTI prototype requirements, media metadata is registered on the backend via `/api/v1/evidence` while binary files remain securely on the device's local file system.

---

## 5. Responsible AI Advisory Phrasing

Adheres to government AI ethics directives:
- Phrasing: *"Potential anomaly detected"*, *"Attention score"*, *"Verification recommended"*.
- AI scores serve as advisory risk indicators to focus inspector attention; final conclusions are determined exclusively by physical inspector verification and statutory findings.
