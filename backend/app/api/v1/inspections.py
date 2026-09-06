import uuid
from typing import List, Optional
from datetime import datetime, date
from fastapi import APIRouter, Depends, HTTPException, Query, status, Request
from sqlalchemy.orm import Session
from sqlalchemy import or_
from backend.app.database import get_db
from backend.app.models import (
    Inspection, InspectionAssignment, Institution, User, AIAlert, Notification
)
from backend.app.schemas.inspection import (
    InspectionCreate, InspectionUpdate, InspectionStatusUpdate, InspectionResponse
)
from backend.app.schemas.common import PaginatedResponse
from backend.app.api.deps import get_current_user, require_roles, record_audit_log

router = APIRouter(prefix="/inspections", tags=["Inspections"])

def format_inspection_response(insp: Inspection) -> InspectionResponse:
    assigned_name = None
    assigned_id = None
    if insp.assignments:
        first_assign = insp.assignments[0]
        assigned_id = first_assign.inspector_user_id
        if first_assign.inspector:
            assigned_name = first_assign.inspector.full_name

    return InspectionResponse(
        id=insp.id,
        inspection_code=insp.inspection_code,
        institution_id=insp.institution_id,
        origin_ai_alert_id=insp.origin_ai_alert_id,
        priority=insp.priority,
        status=insp.status,
        mandated_date=insp.mandated_date,
        due_date=insp.due_date,
        inspection_reason=insp.inspection_reason,
        special_instructions=insp.special_instructions,
        assigned_by_user_id=insp.assigned_by_user_id,
        created_at=insp.created_at,
        updated_at=insp.updated_at,
        institution_name=insp.institution.name if insp.institution else None,
        institution_district=insp.institution.district if insp.institution else None,
        institution_state=insp.institution.state if insp.institution else None,
        assigned_inspector_name=assigned_name,
        assigned_inspector_id=assigned_id
    )

@router.get("", response_model=PaginatedResponse[InspectionResponse])
def list_inspections(
    status_filter: Optional[str] = Query(None, alias="status"),
    priority: Optional[str] = None,
    institution_id: Optional[uuid.UUID] = None,
    inspector_id: Optional[uuid.UUID] = None,
    page: int = Query(1, ge=1),
    page_size: int = Query(20, ge=1, le=100),
    db: Session = Depends(get_db)
):
    """Lists inspections with filter options."""
    query = db.query(Inspection)

    if status_filter:
        query = query.filter(Inspection.status == status_filter.upper())
    if priority:
        query = query.filter(Inspection.priority == priority.upper())
    if institution_id:
        query = query.filter(Inspection.institution_id == institution_id)
    if inspector_id:
        query = query.join(Inspection.assignments).filter(InspectionAssignment.inspector_user_id == inspector_id)

    total = query.count()
    offset = (page - 1) * page_size
    inspections = query.order_by(Inspection.created_at.desc()).offset(offset).limit(page_size).all()

    items = [format_inspection_response(i) for i in inspections]

    return PaginatedResponse(
        total=total,
        page=page,
        page_size=page_size,
        items=items
    )

@router.post("", response_model=InspectionResponse, status_code=status.HTTP_201_CREATED)
def create_inspection(
    data: InspectionCreate,
    request: Request,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_roles(["SUPER_ADMIN", "MINISTRY_OFFICIAL", "DISTRICT_OFFICER"]))
):
    """Creates a new mandated inspection and optionally assigns an inspector immediately."""
    inst = db.query(Institution).filter(Institution.id == data.institution_id).first()
    if not inst:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Institution not found")

    # Generate sequential unique inspection code
    current_year = datetime.utcnow().year
    count_today = db.query(Inspection).count() + 1
    code = f"INSP-{current_year}-{inst.state[:2].upper()}-{count_today:04d}"

    new_status = "ASSIGNED" if data.inspector_user_id else "PENDING_DISPATCH"

    inspection = Inspection(
        id=uuid.uuid4(),
        inspection_code=code,
        institution_id=data.institution_id,
        origin_ai_alert_id=data.origin_ai_alert_id,
        priority=data.priority.upper(),
        status=new_status,
        mandated_date=data.mandated_date,
        due_date=data.due_date,
        inspection_reason=data.inspection_reason,
        special_instructions=data.special_instructions,
        assigned_by_user_id=current_user.id
    )
    db.add(inspection)
    db.flush()

    # Assign inspector if provided
    if data.inspector_user_id:
        inspector = db.query(User).filter(User.id == data.inspector_user_id).first()
        if not inspector:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Inspector user not found")

        assignment = InspectionAssignment(
            id=uuid.uuid4(),
            inspection_id=inspection.id,
            inspector_user_id=inspector.id,
            assigned_at=datetime.utcnow(),
            assigned_by_id=current_user.id,
            notes=data.special_instructions
        )
        db.add(assignment)

        # Notify inspector
        notif = Notification(
            id=uuid.uuid4(),
            recipient_user_id=inspector.id,
            title=f"New Inspection Assigned: {inst.name}",
            message=f"Mandated inspection {code} at {inst.name} is due by {data.due_date}.",
            category="ASSIGNMENT",
            entity_reference_id=inspection.id
        )
        db.add(notif)

    db.commit()
    db.refresh(inspection)

    record_audit_log(db, current_user, "INSPECTION_CREATED", "inspections", inspection.id, {"code": code}, request)

    return format_inspection_response(inspection)

@router.get("/{id}", response_model=InspectionResponse)
def get_inspection(id: uuid.UUID, db: Session = Depends(get_db)):
    """Fetches full inspection details."""
    insp = db.query(Inspection).filter(Inspection.id == id).first()
    if not insp:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Inspection not found")
    return format_inspection_response(insp)

@router.put("/{id}", response_model=InspectionResponse)
def update_inspection(
    id: uuid.UUID,
    data: InspectionUpdate,
    request: Request,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_roles(["SUPER_ADMIN", "MINISTRY_OFFICIAL", "DISTRICT_OFFICER"]))
):
    """Updates inspection parameters (priority, due date, instructions)."""
    insp = db.query(Inspection).filter(Inspection.id == id).first()
    if not insp:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Inspection not found")

    update_dict = data.dict(exclude_unset=True)
    for k, v in update_dict.items():
        setattr(insp, k, v)

    insp.updated_at = datetime.utcnow()
    db.commit()
    db.refresh(insp)

    record_audit_log(db, current_user, "INSPECTION_UPDATED", "inspections", insp.id, update_dict, request)

    return format_inspection_response(insp)

@router.patch("/{id}/status", response_model=InspectionResponse)
def update_inspection_status(
    id: uuid.UUID,
    data: InspectionStatusUpdate,
    request: Request,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Updates lifecycle state of an inspection."""
    insp = db.query(Inspection).filter(Inspection.id == id).first()
    if not insp:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Inspection not found")

    valid_statuses = ["PENDING_DISPATCH", "ASSIGNED", "IN_PROGRESS", "SUBMITTED", "APPROVED", "CLOSED"]
    if data.status.upper() not in valid_statuses:
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail=f"Invalid status '{data.status}'. Must be one of: {', '.join(valid_statuses)}"
        )

    old_status = insp.status
    insp.status = data.status.upper()
    insp.updated_at = datetime.utcnow()

    # Update institution last inspected date if approved/submitted
    if insp.status in ("SUBMITTED", "APPROVED"):
        if insp.institution:
            insp.institution.last_inspected_at = datetime.utcnow()

    db.commit()
    db.refresh(insp)

    record_audit_log(
        db, current_user, "INSPECTION_STATUS_CHANGED", "inspections", insp.id,
        {"from": old_status, "to": insp.status, "notes": data.notes}, request
    )

    return format_inspection_response(insp)
