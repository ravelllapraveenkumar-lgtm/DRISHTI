from fastapi import APIRouter
from backend.app.api.v1 import (
    health, auth, institutions, monitoring, attendance,
    inspections, assignments, checklists, evidence,
    reports, dashboard, ai_analysis, ai_alerts,
    notifications, audit, schemes, beneficiaries
)

api_v1_router = APIRouter(prefix="/api/v1")

# Include all 14+ required endpoint groups
api_v1_router.include_router(health.router)
api_v1_router.include_router(auth.router)
api_v1_router.include_router(institutions.router)
api_v1_router.include_router(monitoring.router)
api_v1_router.include_router(attendance.router)
api_v1_router.include_router(inspections.router)
api_v1_router.include_router(assignments.router, prefix="/inspection-assignments")
api_v1_router.include_router(assignments.router, prefix="/assignments")
api_v1_router.include_router(checklists.router)
api_v1_router.include_router(evidence.router)
api_v1_router.include_router(reports.router)
api_v1_router.include_router(dashboard.router)
api_v1_router.include_router(ai_analysis.router)
api_v1_router.include_router(ai_alerts.router)
api_v1_router.include_router(notifications.router)
api_v1_router.include_router(audit.router)
api_v1_router.include_router(schemes.router)
api_v1_router.include_router(beneficiaries.router)
