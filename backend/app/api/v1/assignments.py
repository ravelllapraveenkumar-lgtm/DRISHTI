import uuid
from typing import List, Optional
from datetime import datetime
from fastapi import APIRouter, Depends, HTTPException, status, Request
from sqlalchemy.orm import Session
from backend.app.database import get_db
from backend.app.models import Inspection, InspectionAssignment, User, Notification
from backend.app.schemas.assignment import AssignmentCreate, AssignmentUpdate, AssignmentResponse
from backend.app.api.deps import get_current_user, require_roles, record_audit_log

router = APIRouter(tags=["Inspection Assignments"])

def format_assignment(assign: InspectionAssignment) -> AssignmentResponse:
    return AssignmentResponse(
        id=assign.id,
        inspection_id=assign.inspection_id,
        inspector_user_id=assign.inspector_user_id,
        assigned_at=assign.assigned_at,
        accepted_at=assign.accepted_at,
        arrived_at=assign.arrived_at,
        completed_at=assign.completed_at,
        assigned_by_id=assign.assigned_by_id,
        notes=assign.notes,
        created_at=assign.created_at,
        inspector_name=assign.inspector.full_name if assign.inspector else None,
        inspector_email=assign.inspector.email if assign.inspector else None,
        inspection_code=assign.inspection.inspection_code if assign.inspection else None,
        inspection_status=assign.inspection.status if assign.inspection else None
    )

@router.get("", response_model=List[AssignmentResponse])
def list_assignments(
    inspection_id: Optional[uuid.UUID] = None,
    inspector_id: Optional[uuid.UUID] = None,
    db: Session = Depends(get_db)
):
    """Lists inspection assignments."""
    query = db.query(InspectionAssignment)
    if inspection_id:
        query = query.filter(InspectionAssignment.inspection_id == inspection_id)
    if inspector_id:
        query = query.filter(InspectionAssignment.inspector_user_id == inspector_id)

    assignments = query.order_by(InspectionAssignment.assigned_at.desc()).all()
    return [format_assignment(a) for a in assignments]

@router.post("", response_model=AssignmentResponse, status_code=status.HTTP_201_CREATED)
def create_assignment(
    data: AssignmentCreate,
    request: Request,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_roles(["SUPER_ADMIN", "MINISTRY_OFFICIAL", "DISTRICT_OFFICER"]))
):
    """Assigns an inspector to an inspection."""
    insp = db.query(Inspection).filter(Inspection.id == data.inspection_id).first()
    if not insp:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Inspection not found")

    inspector = db.query(User).filter(User.id == data.inspector_user_id).first()
    if not inspector:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Inspector not found")

    # Check for duplicate
    existing = db.query(InspectionAssignment).filter(
        InspectionAssignment.inspection_id == data.inspection_id,
        InspectionAssignment.inspector_user_id == data.inspector_user_id
    ).first()
    if existing:
        raise HTTPException(status_code=status.HTTP_409_CONFLICT, detail="Inspector already assigned to this inspection")

    assignment = InspectionAssignment(
        id=uuid.uuid4(),
        inspection_id=data.inspection_id,
        inspector_user_id=data.inspector_user_id,
        assigned_at=datetime.utcnow(),
        assigned_by_id=current_user.id,
        notes=data.notes
    )
    db.add(assignment)

    # Update inspection status to ASSIGNED
    insp.status = "ASSIGNED"
    insp.updated_at = datetime.utcnow()

    # Create notification for inspector
    notif = Notification(
        id=uuid.uuid4(),
        recipient_user_id=data.inspector_user_id,
        title=f"Inspection Assigned: {insp.inspection_code}",
        message=f"You have been assigned to inspection {insp.inspection_code}.",
        category="ASSIGNMENT",
        entity_reference_id=insp.id
    )
    db.add(notif)

    db.commit()
    db.refresh(assignment)

    record_audit_log(db, current_user, "INSPECTOR_ASSIGNED", "inspection_assignments", assignment.id, {"inspection_code": insp.inspection_code}, request)

    return format_assignment(assignment)

@router.get("/inspector/{inspector_id}", response_model=List[AssignmentResponse])
def get_inspector_assignments(inspector_id: uuid.UUID, db: Session = Depends(get_db)):
    """Lists all past and present assignments for an inspector."""
    assignments = db.query(InspectionAssignment).filter(
        InspectionAssignment.inspector_user_id == inspector_id
    ).order_by(InspectionAssignment.assigned_at.desc()).all()
    return [format_assignment(a) for a in assignments]

@router.get("/{id}", response_model=AssignmentResponse)
def get_assignment(id: uuid.UUID, db: Session = Depends(get_db)):
    """Retrieves specific assignment record."""
    assign = db.query(InspectionAssignment).filter(InspectionAssignment.id == id).first()
    if not assign:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Assignment not found")
    return format_assignment(assign)

@router.post("/{id}/accept", response_model=AssignmentResponse)
@router.patch("/{id}/accept", response_model=AssignmentResponse)
def accept_assignment(
    id: uuid.UUID,
    request: Request,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Inspector marks assignment as accepted."""
    assign = db.query(InspectionAssignment).filter(InspectionAssignment.id == id).first()
    if not assign:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Assignment not found")

    assign.accepted_at = datetime.utcnow()
    assign.updated_at = datetime.utcnow()
    db.commit()
    db.refresh(assign)

    record_audit_log(db, current_user, "ASSIGNMENT_ACCEPTED", "inspection_assignments", assign.id, None, request)

    return format_assignment(assign)

@router.post("/{id}/arrive", response_model=AssignmentResponse)
@router.patch("/{id}/arrive", response_model=AssignmentResponse)
def mark_arrival(
    id: uuid.UUID,
    request: Request,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Inspector marks on-site arrival at institution."""
    assign = db.query(InspectionAssignment).filter(InspectionAssignment.id == id).first()
    if not assign:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Assignment not found")

    assign.arrived_at = datetime.utcnow()
    if assign.inspection:
        assign.inspection.status = "IN_PROGRESS"
        assign.inspection.updated_at = datetime.utcnow()

    db.commit()
    db.refresh(assign)

    record_audit_log(db, current_user, "INSPECTOR_ARRIVED_ONSITE", "inspection_assignments", assign.id, None, request)

    return format_assignment(assign)
