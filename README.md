# DRISHTI: Smart Real-Time Monitoring & Inspection Platform
> **Smart India Hackathon (SIH) 2026**  
> **Problem Statement ID:** 26095  
> **Title:** Smart Real-Time Monitoring & Inspection Mobile App  
> **Target Organization:** Ministry of Social Justice and Empowerment (MoSJE), Government of India  
> **Status:** Prototype Implementation (Synthetic & Demo Data Only)

---

## 1. Executive Summary & Objective

**DRISHTI** is a unified, accountable, and transparent monitoring and inspection platform engineered for institutions, NGOs, residential rehabilitation centers, and vocational training units supported under various flagship schemes of the **Ministry of Social Justice and Empowerment (MoSJE)** (e.g., DDRS, AVYAY, PM-DAKSH, NAPDDR).

The objective is to eliminate ghost beneficiaries, verify physical infrastructure, monitor daily attendance without invasive surveillance, flag statistical anomalies using machine learning, and dispatch field inspectors with an **offline-first, GPS-tagged, cryptographic evidence-gathering mobile application**.

---

## 2. The Core Closed-Loop Workflow

```
[ MoSJE Supported Institution ]
           │
           ▼
[ Daily Monitoring & Biometric/Portal Attendance ]
           │
           ▼
[ Data Collection Ingestion Engine (/api/v1/monitoring) ]
           │
           ▼
[ AI Anomaly Detection & Attention Scoring Engine (0-100) ]
           │
           ▼ (Potential anomaly detected)
[ MoSJE Human Verification & Triage (Ministry Official) ]
           │
           ▼ (Inspection Approved & Assigned)
[ Inspection Assignment to Field Inspector (/api/v1/inspection-assignments) ]
           │
           ▼
[ Inspector Mobile App (Offline-First SQLite Cache) ]
           │
           ▼
[ On-Site Geofenced GPS Verification (< 50m tolerance) ]
           │
           ▼
[ Tamper-Resistant Photo & Video Evidence Metadata Capture ]
           │
           ▼
[ Standardized Digital Checklist & On-Site Inspection Report ]
           │
           ▼ (Online Connectivity Restored)
[ Secure Synchronization & PostgreSQL Ingestion (/api/v1/inspections) ]
           │
           ▼
[ Central Government Monitoring Dashboard (React + Vite + TypeScript) ]
           │
           ▼
[ Official Review, Evidence Audit & Administrative Decision/Action ]
```

---

## 3. Strict Responsible AI Principles (MoSJE Compliance)

> ⚠️ **CRITICAL ETHICAL DIRECTIVE:**  
> The DRISHTI AI engine **NEVER** declares fraud, guilt, or criminal non-compliance automatically.
>
> 1. All automated outputs are strictly categorized as **Attention/Risk Indicators (0–100)**:
>    - **Low (0–24):** Normal operational variance.
>    - **Medium (25–49):** Minor statistical drift; routine periodic review recommended.
>    - **High (50–74):** Significant divergence detected; supervisory verification recommended.
>    - **Critical (75–100):** High irregularity or discrepancy; prioritized human review and on-site physical inspection recommended.
> 2. Mandatory Human-in-the-Loop: Automated alerts use transparent, explainable phrasing (e.g., *"Potential anomaly detected in attendance trend. Verification recommended. Human review required."*).
> 3. Final administrative, financial, or legal decisions belong solely to authorized MoSJE officials.

---

## 4. Multi-Component Repository Structure

```
DRISHTI/
├── mobile/                  # Flutter + Dart Mobile Application (Offline-first, SQLite)
│   ├── lib/
│   │   ├── data/local/      # SQLite helper, offline sync queue
│   │   ├── models/          # Inspection, checklist, evidence models
│   │   └── screens/         # Inspector auth, assignments, camera, sync status
│   └── pubspec.yaml
├── dashboard/ (src/)        # MoSJE Central Monitoring Dashboard (React 19 + TypeScript + Vite)
│   ├── components/          # Navigation, live map, AI alerts, evidence review
│   ├── types/               # TypeScript interfaces & enums
│   └── data/                # Synthetic datasets clearly labeled
├── backend/                 # Python + FastAPI RESTful backend (/api/v1/)
│   ├── app/
│   │   ├── api/v1/          # Versioned REST endpoints
│   │   ├── core/            # Config, JWT authentication, security
│   │   ├── db/              # SQLAlchemy models, session management
│   │   └── schemas/         # Pydantic validation schemas
│   └── requirements.txt
├── ai/                      # Machine Learning Anomaly Detection Engine
│   ├── models/              # Isolation Forest & baseline anomaly models
│   ├── anomaly_engine.py    # Feature extraction, scoring & explainability
│   └── synthetic_generator.py # Synthetic attendance & monitoring data generator
├── database/                # PostgreSQL Database definitions
│   ├── schema.sql           # Normalized DDL with UUID primary keys & foreign keys
│   └── seeds/               # Synthetic MoSJE demo seed data
├── docs/                    # Technical & architectural specifications
│   ├── architecture.md      # Detailed system design & offline protocol
│   └── api_v1_specification.md # RESTful OpenAPI 3.0 specification
├── docker-compose.yml       # Container orchestration (PostgreSQL, Backend, Dashboard, AI)
├── .env.example             # Documented environment variables
├── README.md                # Master project documentation
└── .gitignore
```

---

## 5. Technology Stack

| Layer | Primary Technology | Purpose |
|---|---|---|
| **Field Mobile Client** | Flutter + Dart (v3.x) | Cross-platform offline mobile app for field inspectors |
| **Local Device DB** | SQLite (`sqflite`) | Offline-first encrypted cache with transaction-safe sync queue |
| **Central Dashboard** | React 19 + TypeScript + Vite + Tailwind CSS | MoSJE real-time situational dashboard & inspection review |
| **Backend API** | Python 3.11 + FastAPI + Pydantic v2 | High-throughput asynchronous REST API (`/api/v1/`) |
| **Central Database** | PostgreSQL 16 with UUID-OSSP | Normalized relational storage with strict relational integrity |
| **AI Anomaly Engine** | Python, NumPy, Pandas, Scikit-learn | Isolation Forest anomaly detection & explainability generator |
| **Containerization** | Docker & Docker Compose | Uniform reproducible local and server deployment |

---

## 6. Synthetic Data & Safety Notice

This application uses strictly synthetic, programmatically generated mock data for educational and hackathon demonstration purposes. No connection to live government servers, active CCTV feeds, or confidential citizen records exists in this prototype.
