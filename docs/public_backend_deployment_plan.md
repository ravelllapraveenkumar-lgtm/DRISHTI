# DRISHTI Public Backend & PostgreSQL Cloud Deployment Plan
> **Target System:** Ministry of Social Justice & Empowerment (MoSJE) Monitoring & Inspection Platform  
> **Hackathon Reference:** Smart India Hackathon (SIH 2026) | Problem Statement ID: 26095  
> **Status:** Deployment Plan & Cloud Preparation (Not Yet Deployed)  
> **Authoritative Database:** Cloud PostgreSQL 16+ (Remote Hosted)

---

## 1. Current Backend Architecture

The DRISHTI backend is implemented as an asynchronous REST API built with **Python 3.11+ / FastAPI** and **SQLAlchemy 2.0 ORM**.

```
                         [ Public Internet / Clients ]
                         ├── Web Dashboard (React 19 / Vite)
                         └── Mobile Client (Flutter / SQLite Offline Sync)
                                      │
                                      ▼ HTTPS
                         [ Cloud Reverse Proxy / Load Balancer ]
                                      │ (PORT Dynamic Mapping)
                                      ▼
             ┌─────────────────────────────────────────────────────────┐
             │            FastAPI Application Server (Uvicorn)         │
             │─────────────────────────────────────────────────────────│
             │ • Root Health Check: /health                            │
             │ • Database Health Check: /api/v1/health/db              │
             │ • API Documentation: /api/v1/docs (Swagger/OpenAPI)     │
             │ • Core Routers: Auth (JWT/RBAC), Institutions,          │
             │   Monitoring, Attendance, Inspections, Assignments,     │
             │   Checklists, Evidence, Reports, Dashboard, AI Alerts   │
             │ • Global Lifespan Seeder: Auto-seeds baseline data      │
             └─────────────────────────────────────────────────────────┘
                                      │
                                      ▼ SQLAlchemy 2.0 (psycopg2)
                         [ Managed PostgreSQL 16 Database ]
                           (19 Normalized Tables, UUID v4, FKs)
```

- **Entrypoint:** `backend.app.main:app`
- **Application Framework:** FastAPI 0.110+ with Pydantic v2 data validation schemas.
- **Dependency Isolation:** Can run standalone on bare-metal VMs, cloud native buildpacks (e.g. Render, Railway, Heroku), or containerized via Docker.
- **Authentication & RBAC:** OAuth2 Password Bearer with JWT (HS256) enforcing role-based access for `ADMIN`, `MOSJE_OFFICER`, and `FIELD_INSPECTOR`.

---

## 2. Current PostgreSQL Architecture

The database layer uses normalized relational schema design targeting PostgreSQL 16+ with UUID v4 primary keys and strict referential integrity.

- **Authoritative Data Store:** PostgreSQL 16+ (remote managed service on cloud).
- **Logical Schema Entities (19 Tables):**
  1. `users` — Ministry administrators, state officials, inspectors
  2. `schemes` — Flagship MoSJE schemes (DDRS, AVYAY, NAPDDR, PM-DAKSH)
  3. `institutions` — Beneficiary centers, hostels, vocational training centers
  4. `beneficiaries` — Registered scheme beneficiaries
  5. `attendance_logs` — Daily beneficiary attendance logs
  6. `monitoring_records` — Institutional telemetry, food logs, biometric logs
  7. `inspections` — Scheduled and unannounced inspection mandates
  8. `inspection_assignments` — Inspector dispatch & assignment workflows
  9. `checklist_templates` — Standardized MoSJE inspection questionnaires
  10. `checklist_items` — Sectioned criteria & questions
  11. `checklist_responses` — Submitted verification answers
  12. `evidence_records` — Geotagged, timestamped photo & metadata records
  13. `inspection_reports` — Consolidated inspector findings & grade scores
  14. `report_reviews` — Official triage & administrative decision logs
  15. `ai_analyses` — Statistical anomaly scores & feature divergence
  16. `ai_alerts` — Attention indicators generated for human review
  17. `notifications` — Role-based system alerts & push feeds
  18. `audit_logs` — Immutable tamper-evident activity trails
  19. `sync_queue_items` — Server-side record of offline client syncs
- **Compatibility Views:** 4 unified views (`v_inspection_reports_full`, `v_evidence_metadata_summary`, `v_checklist_submissions`, `v_scheme_institution_overview`).
- **SQLite Role:** Mobile client offline local cache and developer unit testing fallback only.

---

## 3. Required Cloud Services

To host DRISHTI publicly for hackathon demonstration and remote testing, the following cloud resources are required:

| Resource Type | Specification / Requirements | Purpose |
|---|---|---|
| **Web Service (Compute)** | Linux container runtime or Python 3.11 environment (512MB–1GB RAM, 0.5–1 CPU) | Runs FastAPI backend via Uvicorn |
| **Managed Relational DB** | Managed PostgreSQL 15 or 16 (1GB–5GB storage, SSL enabled) | Primary authoritative database storage |
| **Static / Web Hosting (Optional)** | Static web CDN (Vercel / Netlify / Render Static) | Hosts the React 19 central monitoring dashboard |
| **Object Storage (Future Phase)** | S3-compatible bucket (AWS S3 / Cloudflare R2) | Long-term binary storage for full-resolution photo evidence |

---

## 4. Required Environment Variables

> ⚠️ **SECURITY NOTICE:** Only variable names are documented below. Secret keys and passwords must never be stored in source control.

### Core Backend & Database Configuration
- `DATABASE_URL` — Full connection string to managed PostgreSQL (e.g., `postgresql://<user>:<password>@<host>:<port>/<dbname>`).
- `PORT` — Assigned dynamically by the cloud platform (e.g. 10000 on Render, 8000 on Fly.io/Railway).
- `ENVIRONMENT` — Deployment tier (set to `production` or `staging`).
- `DEBUG` — Boolean toggle for debug logs (set to `false` in production).
- `LOG_LEVEL` — Logging verbosity level (`INFO` recommended).

### Security & Token Generation
- `SECRET_KEY` — High-entropy cryptographic random string (min 32 characters) for signing JWT auth tokens.
- `ALGORITHM` — Token signing algorithm (defaults to `HS256`).
- `ACCESS_TOKEN_EXPIRE_MINUTES` — Token validity window in minutes (e.g., `1440` for 24 hours).

### API Routing & CORS
- `API_V1_STR` — Versioned prefix path (set to `/api/v1`).
- `CORS_ORIGINS` — Comma-separated or JSON list of allowed origins (e.g. `*` for initial open testing, or specific frontend dashboard URLs).

### AI Anomaly Parameters
- `AI_ANOMALY_THRESHOLD` — Baseline threshold for generating high attention alerts (default: `0.65`).

---

## 5. Required Database Migration / Seed Procedure

DRISHTI features a zero-touch automated bootstrap sequence:

### Automatic Seeding on Startup
1. When the FastAPI application starts, the `lifespan` handler executes:
   - `Base.metadata.create_all(bind=engine)` — Automatically creates all 19 relational tables, indexes, and constraints if they do not already exist.
   - `seed_database_if_empty(db)` — Detects if institutions and admin accounts are present; if empty, automatically seeds 5 demo institutions, 4 schemes, pre-populated users (Admin, Officer, Inspector), and baseline checklists.

### Manual SQL DDL Execution (Optional / Direct Postgres CLI)
If manual execution against cloud PostgreSQL is preferred:
```bash
# 1. Apply Schema DDL
psql "$DATABASE_URL" -f database/schema.sql

# 2. Apply Synthetic Seed Data
psql "$DATABASE_URL" -f database/seeds/synthetic_seed.sql
```

---

## 6. Backend Start Command

### Cloud Buildpack (Render / Railway / Heroku):
```bash
uvicorn backend.app.main:app --host 0.0.0.0 --port $PORT
```

### Direct Python Command (Dynamic Port Fallback):
```bash
python -m uvicorn backend.app.main:app --host 0.0.0.0 --port ${PORT:-8000}
```

### Docker Container:
```bash
docker run -p 8000:8000 -e DATABASE_URL="postgresql://..." drishti-backend
```

---

## 7. Health-Check Endpoints

Cloud container orchestrators and load balancers should be configured with these probes:

- **Liveness Probe:**
  - **URL:** `GET /health`
  - **Expected Status:** `200 OK`
  - **Expected JSON Payload:**
    ```json
    {
      "status": "healthy",
      "app_name": "DRISHTI",
      "version": "1.0.0",
      "environment": "production"
    }
    ```

- **Database Readiness Probe:**
  - **URL:** `GET /api/v1/health/db`
  - **Expected Status:** `200 OK`
  - **Expected JSON Payload:**
    ```json
    {
      "status": "healthy",
      "database": "postgresql",
      "tables_count": 19,
      "connection": "connected",
      "detail": "Successfully queried database. Active tables: 19"
    }
    ```

---

## 8. CORS Requirements

For the web dashboard and mobile app to communicate with the cloud backend:
- Allow HTTP methods: `GET`, `POST`, `PUT`, `PATCH`, `DELETE`, `OPTIONS`
- Allow HTTP headers: `Authorization`, `Content-Type`, `Accept`, `X-Requested-With`
- The backend config includes wildcard `*` by default for demonstration environments, ensuring Flutter mobile clients and localhost/cloud web dashboards can connect seamlessly without CORS rejections.

---

## 9. AI Runtime Requirements

- The AI Anomaly Engine in `ai/` uses **Scikit-learn**, **NumPy**, and **Pandas** with deterministic feature extractors (Isolation Forest).
- The pre-trained model artifact is located at `ai/artifacts/isolation_forest.joblib`.
- For the prototype deployment, the FastAPI backend exposes `/api/v1/ai-analyses` and `/api/v1/ai-alerts` directly, allowing the anomaly scoring service to submit alerts and telemetry directly into the database.

---

## 10. Recommended Cloud Deployment Providers

For beginner-friendly, fast, and stable deployment of the DRISHTI prototype, the top recommendations are:

### Option 1: Render.com (Highly Recommended)
- **Why:** Offers managed PostgreSQL and Web Service in one dashboard, native GitHub repo integration, automatic HTTPS certificates, and built-in health check monitoring.
- **Setup Effort:** 10–15 minutes.

### Option 2: Railway.app
- **Why:** Zero-configuration PostgreSQL provisioning with single-click link to FastAPI GitHub repository, instantaneous environment variable injection.
- **Setup Effort:** 5–10 minutes.

### Option 3: Fly.io / Koyeb
- **Why:** Deploy directly from `backend/Dockerfile` with low-latency global edge routing.

---

## 11. Exact Next Deployment Steps (When Ready)

1. **Step 1 — Create Managed PostgreSQL Instance:**
   - In Render/Railway/Supabase, create a new PostgreSQL 16 database named `drishti_db`.
   - Copy the External / Internal Connection String (`DATABASE_URL`).

2. **Step 2 — Create Web Service:**
   - Connect the GitHub repository `https://github.com/ravelllapraveenkumar-lgtm/DRISHTI.git`.
   - Set Root Directory to repository root `.`.
   - Set Build Command: `pip install -r backend/requirements.txt`
   - Set Start Command: `uvicorn backend.app.main:app --host 0.0.0.0 --port $PORT`

3. **Step 3 — Configure Environment Variables:**
   - Add `DATABASE_URL`, `SECRET_KEY`, `ENVIRONMENT=production`, `DEBUG=false`.

4. **Step 4 — Trigger Initial Deployment & Validate:**
   - Deploy web service.
   - Test `https://<YOUR_APP_URL>/health` and `https://<YOUR_APP_URL>/api/v1/docs`.
   - Verify database table initialization via `https://<YOUR_APP_URL>/api/v1/health/db`.

---

## 12. Risks and Limitations

1. **Free-tier Inactivity Sleep:** Free-tier compute instances on Render/Koyeb spin down after 15 minutes of inactivity; the initial cold start can take 30–50 seconds.
2. **Ephemeral File Storage:** On-disk evidence images uploaded directly to the filesystem will reset on container restart if persistent volumes or external object storage (S3) are not configured.
3. **Database Connection Limits:** Free managed databases usually have a limit of 20–50 concurrent connections; SQLAlchemy connection pooling is set with `pool_pre_ping=True` to manage connections cleanly.
