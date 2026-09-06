"""
DRISHTI Backend Comprehensive Verification Script
Verifies:
1. Syntax & Module imports
2. FastAPI Startup & OpenAPI schema generation
3. Database connectivity and table verification
4. Full route coverage across all 14 required modules
5. Execution of pytest test suite
"""

import sys
import os
import subprocess
from datetime import datetime

# Ensure project root is in sys.path
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), "..")))

def print_header(title: str):
    print("\n" + "=" * 75)
    print(f"  {title}")
    print("=" * 75)

def verify_modules():
    print_header("1. SYNTAX & MODULE IMPORT VERIFICATION")
    modules = [
        "backend.app.config",
        "backend.app.database",
        "backend.app.models",
        "backend.app.schemas",
        "backend.app.seed",
        "backend.app.api.deps",
        "backend.app.api.v1.auth",
        "backend.app.api.v1.institutions",
        "backend.app.api.v1.monitoring",
        "backend.app.api.v1.attendance",
        "backend.app.api.v1.inspections",
        "backend.app.api.v1.assignments",
        "backend.app.api.v1.checklists",
        "backend.app.api.v1.evidence",
        "backend.app.api.v1.reports",
        "backend.app.api.v1.dashboard",
        "backend.app.api.v1.ai_analysis",
        "backend.app.api.v1.ai_alerts",
        "backend.app.api.v1.notifications",
        "backend.app.api.v1.audit",
        "backend.app.api.v1.schemes",
        "backend.app.api.v1.beneficiaries",
        "backend.app.main"
    ]
    for mod in modules:
        __import__(mod)
        print(f"  [OK] Successfully imported {mod}")
    print("  All 23 backend modules imported cleanly without syntax or dependency errors.")

def verify_api_startup():
    print_header("2. API STARTUP & OPENAPI VERIFICATION")
    from backend.app.main import app
    print(f"  Application Title:       {app.title}")
    print(f"  Application Version:     {app.version}")
    print(f"  API Documentation Route: {app.docs_url}")
    print(f"  OpenAPI JSON Route:      {app.openapi_url}")

    openapi = app.openapi()
    paths = openapi.get("paths", {})
    print(f"  Total Registered Paths:  {len(paths)}")
    assert len(paths) >= 14, "Must have at least 14 route paths"

    # Verify all 14 required categories exist in OpenAPI paths
    required_path_prefixes = [
        ("auth", "/api/v1/auth/"),
        ("institutions", "/api/v1/institutions"),
        ("monitoring", "/api/v1/monitoring"),
        ("attendance", "/api/v1/attendance"),
        ("inspections", "/api/v1/inspections"),
        ("inspection_assignments", "/api/v1/inspection-assignments"),
        ("inspection_checklist", "/api/v1/inspection-checklists"),
        ("evidence_metadata", "/api/v1/evidence"),
        ("inspection_reports", "/api/v1/inspection-reports"),
        ("dashboard_summary", "/api/v1/dashboard/summary"),
        ("ai_analysis", "/api/v1/ai-analyses"),
        ("ai_alerts", "/api/v1/ai-alerts"),
        ("notifications", "/api/v1/notifications"),
        ("audit_activity", "/api/v1/audit-activity")
    ]

    for category, prefix in required_path_prefixes:
        matched = [p for p in paths if p.startswith(prefix)]
        assert matched, f"Missing routes for required category: {category}"
        print(f"  [OK] Category '{category}' -> Found {len(matched)} endpoints ({matched[0]}...)")

def verify_db_connectivity():
    print_header("3. DATABASE CONNECTIVITY & PERSISTENCE VERIFICATION")
    from backend.app.database import engine, Base, SessionLocal
    from backend.app.seed import seed_database_if_empty
    from sqlalchemy import inspect

    # Create tables and test connectivity
    Base.metadata.create_all(bind=engine)
    inspector = inspect(engine)
    tables = inspector.get_table_names()
    print(f"  Database Engine: {engine.url}")
    print(f"  Total Tables Created: {len(tables)}")
    print(f"  Sample Tables: {', '.join(tables[:8])}...")

    # Verify seeding
    with SessionLocal() as db:
        seed_database_if_empty(db)

    print("  [OK] Database connectivity, schema tables, and synthetic seed state verified.")

def run_tests():
    print_header("4. PYTEST TEST SUITE EXECUTION")
    res = subprocess.run([sys.executable, "-m", "pytest", "backend/tests", "-v", "--tb=line"], capture_output=True, text=True)
    print(res.stdout)
    if res.returncode != 0:
        print(res.stderr)
        sys.exit(res.returncode)
    print("  [OK] All backend test suites passed successfully!")

def main():
    start_time = datetime.now()
    print_header("DRISHTI PHASE 2: FASTAPI BACKEND VERIFICATION SUITE")
    print(f"Timestamp: {start_time.isoformat()}")

    verify_modules()
    verify_api_startup()
    verify_db_connectivity()
    run_tests()

    duration = (datetime.now() - start_time).total_seconds()
    print_header("DRISHTI PHASE 2: VERIFICATION COMPLETE - 100% PASSING")
    print(f"Duration: {duration:.2f} seconds\n")

if __name__ == "__main__":
    main()
