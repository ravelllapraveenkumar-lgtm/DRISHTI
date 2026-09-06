# Render CORS Startup Fix & Configuration Report — DRISHTI Backend

## 1. Exact Root Cause
- **Component**: `pydantic_settings` / `pydantic.BaseSettings` field source decoding during FastAPI startup.
- **Mechanism**: In `backend/app/config.py`, `CORS_ORIGINS` and `BACKEND_CORS_ORIGINS` were annotated strictly as `List[str]`. 
- When an environment variable is loaded for a strictly complex type (`List[str]`), `pydantic_settings` executes `decode_complex_value(value)` via `json.loads(value)` *before* any field validator is reached.
- On Render, when `CORS_ORIGINS` was set to `*` or comma-separated URLs (e.g. `https://drishti-dashboard.onrender.com`), `json.loads("*")` failed immediately with:
  ```
  json.decoder.JSONDecodeError: Expecting value: line 1 column 1 (char 0)
  pydantic_settings.exceptions.SettingsError: error parsing value for field "CORS_ORIGINS" from source "EnvSettingsSource"
  ```

---

## 2. Files Changed
1. `backend/app/config.py`:
   - Updated type annotations for `CORS_ORIGINS` and `BACKEND_CORS_ORIGINS` to `Union[List[str], str]`.
   - Enhanced the `@field_validator("CORS_ORIGINS", "BACKEND_CORS_ORIGINS", mode="before")` to safely handle raw wildcard string `*`, comma-separated origins, JSON string arrays (`["..."]`), and Python lists without triggering pre-validation JSON decoding failures.
2. `backend/tests/test_cors_config.py`:
   - Added automated unit tests covering default origins, wildcard `*`, single URL, comma-separated URLs, JSON-encoded array strings, and FastAPI `/health` endpoint verification under wildcard CORS.
3. `docs/render_cors_startup_fix_report.md`:
   - Created this technical diagnosis, fix, and operational report.

---

## 3. Exact Behavior of `CORS_ORIGINS` Before and After

| Input Value in Environment Variable | Behavior Before Fix | Behavior After Fix |
|---|---|---|
| `CORS_ORIGINS=*` | Crashed with `JSONDecodeError` in `pydantic_settings` | Successfully parsed to `["*"]` |
| `CORS_ORIGINS=https://drishti-dashboard.onrender.com` | Crashed with `JSONDecodeError` | Successfully parsed to `["https://drishti-dashboard.onrender.com"]` |
| `CORS_ORIGINS=https://app1.com, https://app2.com` | Crashed with `JSONDecodeError` | Successfully parsed to `["https://app1.com", "https://app2.com"]` |
| `CORS_ORIGINS=["https://app1.com"]` | Parsed as JSON array | Parsed as JSON array |
| Unset (default) | Loaded 6 default localhost/star origins | Loaded 6 default localhost/star origins |

---

## 4. Tests Executed & Verification Results

### A. Python Backend & Anomaly AI Test Suite
- **Command**: `python -m pytest backend/tests/ ai/tests/ -q`
- **Result**: **56/56 tests PASSED**
  - `backend/tests/test_cors_config.py`: 6/6 passed (covering all CORS permutations and health check)
  - `backend/tests/test_ai_and_dashboard.py`: 4/4 passed
  - `backend/tests/test_assignments_and_workflow.py`: 2/2 passed
  - `backend/tests/test_auth.py`: 6/6 passed
  - `backend/tests/test_checklists_and_evidence.py`: 3/3 passed
  - `backend/tests/test_e2e_full_integration.py`: 1/1 passed
  - `backend/tests/test_health.py`: 3/3 passed
  - `backend/tests/test_inspections.py`: 3/3 passed
  - `backend/tests/test_institutions.py`: 4/4 passed
  - `backend/tests/test_monitoring_attendance.py`: 2/2 passed
  - `backend/tests/test_reports.py`: 1/1 passed
  - `ai/tests/`: 21/21 passed

### B. Flutter Mobile Test Suite
- **Command**: `flutter test` (in `mobile/`)
- **Result**: **9/9 tests PASSED**
  - Haversine geofence calculation tests
  - SHA-256 tamper-evident cryptographic hash tests
  - Offline SQLite data model serialization & server ID separation tests
  - Widget smoke tests

### C. Live FastAPI & Database Health Endpoint Checks
- Fast verification with simulated `CORS_ORIGINS=*` and active database connection verified:
  - `GET /health` -> `200 OK` (`status: healthy`, `app_name: DRISHTI`)
  - `GET /api/v1/health/db` -> `200 OK` (`status: healthy`, `database: sqlite`, `tables_count: 19`, `connection: connected`)
  - PostgreSQL connection string normalization (`postgres://` to `postgresql://`) intact.

---

## 5. Render Environment-Variable Guidance
In your Render Dashboard for the `drishti-backend` Web Service:
- **`CORS_ORIGINS`**:
  - For initial verification: `*`
  - Once your Vite dashboard service URL is created: `https://<your-dashboard-name>.onrender.com,http://localhost:5173,http://localhost:3000`
- **`DATABASE_URL`**:
  - `Internal Database URL` from your Render PostgreSQL instance.
- **`SECRET_KEY`**:
  - Secure random 32+ character string.
- **`ENVIRONMENT`**:
  - `production`

---

## 6. Remaining Manual Render Actions
1. If your Render backend service previously failed, trigger a **Manual Deploy > Deploy Latest Commit** (or wait for the automatic GitHub webhook build).
2. Verify in Render Web Service logs that FastAPI starts cleanly:
   ```
   INFO:     Started server process
   INFO:     Waiting for application startup.
   INFO:     Database schema validated successfully.
   INFO:     Application startup complete.
   INFO:     Uvicorn running on http://0.0.0.0:10000
   ```
3. Test the public URL `/health` endpoint once deployed.
