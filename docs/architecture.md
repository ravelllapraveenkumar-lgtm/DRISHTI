# DRISHTI System Architecture & Specifications
**SIH 2026 Problem ID: 26095**  
**Ministry of Social Justice and Empowerment (MoSJE)**

---

## 1. Architectural Scope & Subsystems

DRISHTI is built with clear architectural separation across five primary sub-systems:

```
┌────────────────────────────────────────────────────────────────────────┐
│                        FIELD CLIENT LAYER                              │
│  Flutter + Dart Inspector Mobile App (Offline-First SQLite Persistence)│
└──────────────────────────────────┬─────────────────────────────────────┘
                                   │ HTTPS / TLS (When Online)
                                   ▼
┌────────────────────────────────────────────────────────────────────────┐
│                        REST API GATEWAY                                │
│          Python + FastAPI Versioned REST Services (/api/v1/)           │
└───────┬──────────────────────────┬───────────────────────────┬─────────┘
        │                          │                           │
        ▼                          ▼                           ▼
┌───────────────┐          ┌───────────────┐           ┌─────────────────┐
│   DATABASE    │          │   AI ENGINE   │           │   DASHBOARD     │
│ PostgreSQL 16 │          │IsolationForest│           │ React 19 + Vite │
│ Normalized Rel│◄─────────┤Risk & Scorer  │           │ TypeScript App  │
│ 16 Rel Tables │          │Responsible AI │           │ MoSJE HQ Review │
└───────────────┘          └───────────────┘           └─────────────────┘
```

---

## 2. The 14-Step Closed-Loop Flow

1. **Institution Onboarding**: NGOs/Institutions register under MoSJE schemes (DDRS, AVYAY, NAPDDR, PM-DAKSH) with sanctioned quotas and geofence polygons.
2. **Monitoring Ingestion**: Institutions submit daily operational logs (biometric counts, meal tallies, CCTV heartbeats, staff rosters).
3. **Data Collection Pipeline**: REST API validates and normalizes ingestion timestamps into PostgreSQL `monitoring_records` and `attendance_records`.
4. **AI Anomaly Analysis**: Isolation Forest and rolling-window statistical divergence models analyze 14-to-30-day telemetry trends.
5. **Potential Anomaly Detection**: AI computes an Attention/Risk Score (0–100) and flags statistical deviations with explainable reasons.
6. **Responsible AI Guardrail**: System strictly prohibits automatic fraud determination. It classifies alerts into Low, Medium, High, or Critical, recommending verification.
7. **Human Verification & Triage**: MoSJE Ministry Officers examine the divergence explanation on the central dashboard.
8. **Inspection Assignment**: An unannounced or routine inspection order is digitally authorized and dispatched to a field inspector.
9. **Inspector Mobile Notification & Download**: Inspector mobile app pulls inspection assignment, checklist, and geofence bounds into local SQLite storage.
10. **Offline-First Field Work**: The inspector visits the site. Even without cell signal, the app verifies GPS against geofence, captures on-site photos/videos, and fills out the standardized checklist.
11. **Cryptographic Evidence Metadata**: Local SHA-256 hashes, GPS coordinates, timestamp, and accuracy meters are stored in the local SQLite evidence table.
12. **Network Restoration & Synchronization**: When mobile device reconnects to Wi-Fi/cellular, pending records are pushed via transactional sync endpoint (`/api/v1/inspections/sync`). Only confirmed backend responses mark local records as `SYNCED_SUCCESS`.
13. **Central Government Dashboard**: Live telemetry, submitted inspection reports, photos with geofence badges, and discrepancy metrics render in real-time.
14. **Official Review & Action**: MoSJE officers review field evidence, confirm physical headcounts versus portal declarations, and execute administrative decisions (grant sanction, warning, compliance audit).

---

## 3. Offline-First SQLite Protocol & Sync State Machine

In the inspector mobile app, local SQLite persistence uses five sync states:

```
[ LOCAL_PENDING ]
       │
       ▼ (Internet Detected & Sync Initiated)
[    SYNCING    ]
       │
       ├──► (200 OK Confirmed by Backend) ──► [ SYNCED_SUCCESS ]
       │
       └──► (Network Error / Timeout / 5xx) ──► [ SYNC_FAILED ]
                                                      │
                                                      ▼ (Backoff Scheduler)
                                              [ RETRY_QUEUED ]
```

**Sync Packet Contract**:
- Client transmits UUID, batch ID, checklist answers, evidence metadata records, and device diagnostic telemetry.
- Server validates that inspection ID matches the authenticated inspector.
- Server commits transaction to PostgreSQL and replies with `{ "status": "CONFIRMED", "synced_ids": [...] }`.
- Client changes local SQLite state to `SYNCED_SUCCESS`.

---

## 4. Responsible AI Formulation

- **Scoring Range**: 0 to 100
  - `0 - 24 (Low)`: Expected seasonal or random variance.
  - `25 - 49 (Medium)`: Minor anomaly (e.g. single day meal discrepancy).
  - `50 - 74 (High)`: Sustained divergence (e.g. flatlined attendance for 10 days).
  - `75 - 100 (Critical)`: Multi-factor divergence (geofence mismatch + CCTV offline + meal count deviation).
- **Mandatory Linguistic Constraint**:
  - `FORBIDDEN TERMS`: Fraudulent, Scam, Illegal, Bogus, Fake Beneficiary.
  - `MANDATORY PHRASING`: "Potential anomaly detected.", "Verification recommended.", "Human review required."
