import uuid
from typing import List, Optional
from fastapi import APIRouter, Depends, Query
from sqlalchemy.orm import Session
from backend.app.database import get_db
from backend.app.models import AuditActivity
from backend.app.schemas.audit import AuditActivityResponse
from backend.app.schemas.common import PaginatedResponse
from backend.app.api.deps import require_roles

router = APIRouter(prefix="/audit-activity", tags=["Audit Logs"])

def format_audit(a: AuditActivity) -> AuditActivityResponse:
    return AuditActivityResponse(
        id=a.id,
        actor_user_id=a.actor_user_id,
        action=a.action,
        target_entity=a.target_entity,
        entity_id=a.entity_id,
        ip_address=a.ip_address,
        user_agent=a.user_agent,
        details=a.details,
        created_at=a.created_at,
        actor_name=a.actor.full_name if a.actor else "System",
        actor_email=a.actor.email if a.actor else "system@drishti.gov.in"
    )

@router.get("", response_model=PaginatedResponse[AuditActivityResponse])
def list_audit_activities(
    action: Optional[str] = None,
    target_entity: Optional[str] = None,
    page: int = Query(1, ge=1),
    page_size: int = Query(25, ge=1, le=100),
    db: Session = Depends(get_db),
    _user = Depends(require_roles(["SUPER_ADMIN", "MINISTRY_OFFICIAL"]))
):
    """Retrieves immutable audit trail of actions taken across the platform."""
    query = db.query(AuditActivity)

    if action:
        query = query.filter(AuditActivity.action == action.upper())
    if target_entity:
        query = query.filter(AuditActivity.target_entity == target_entity.lower())

    total = query.count()
    offset = (page - 1) * page_size
    items = query.order_by(AuditActivity.created_at.desc()).offset(offset).limit(page_size).all()

    return PaginatedResponse(
        total=total,
        page=page,
        page_size=page_size,
        items=[format_audit(i) for i in items]
    )

@router.get("/recent", response_model=List[AuditActivityResponse])
def get_recent_audit_logs(
    limit: int = Query(20, ge=1, le=50),
    db: Session = Depends(get_db),
    _user = Depends(require_roles(["SUPER_ADMIN", "MINISTRY_OFFICIAL"]))
):
    """Retrieves top N recent audit logs for security oversight."""
    items = db.query(AuditActivity).order_by(AuditActivity.created_at.desc()).limit(limit).all()
    return [format_audit(i) for i in items]
