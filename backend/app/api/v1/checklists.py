import uuid
from typing import List, Optional
from datetime import datetime
from fastapi import APIRouter, Depends, HTTPException, status, Request
from sqlalchemy.orm import Session
from backend.app.database import get_db
from backend.app.models import (
    ChecklistTemplate, ChecklistItem, InspectionChecklist, Inspection, User
)
from backend.app.schemas.checklist import (
    ChecklistTemplateResponse, ChecklistSubmissionCreate, ChecklistBatchSubmission,
    ChecklistSubmissionResponse, ChecklistItemResponse
)
from backend.app.api.deps import get_current_user, record_audit_log

router = APIRouter(prefix="/inspection-checklists", tags=["Inspection Checklists"])

@router.get("/templates", response_model=List[ChecklistTemplateResponse])
def get_checklist_templates(db: Session = Depends(get_db)):
    """Retrieves all active inspection checklist templates with ordered questions."""
    templates = db.query(ChecklistTemplate).filter(ChecklistTemplate.is_active == True).all()
    return templates

@router.get("/items", response_model=List[ChecklistItemResponse])
def get_checklist_items(template_id: Optional[uuid.UUID] = None, db: Session = Depends(get_db)):
    """Retrieves all checklist questions optionally filtered by template."""
    query = db.query(ChecklistItem)
    if template_id:
        query = query.filter(ChecklistItem.template_id == template_id)
    return query.order_by(ChecklistItem.order_index.asc()).all()

@router.get("/inspection/{inspection_id}", response_model=List[ChecklistSubmissionResponse])
def get_inspection_checklists(inspection_id: uuid.UUID, db: Session = Depends(get_db)):
    """Retrieves submitted checklist answers for an inspection."""
    responses = db.query(InspectionChecklist).filter(
        InspectionChecklist.inspection_id == inspection_id
    ).all()

    results = []
    for r in responses:
        results.append(ChecklistSubmissionResponse(
            id=r.id,
            inspection_id=r.inspection_id,
            checklist_item_id=r.checklist_item_id,
            response_boolean=r.response_boolean,
            response_value=r.response_value,
            inspector_comment=r.inspector_comment,
            gps_latitude=r.gps_latitude,
            gps_longitude=r.gps_longitude,
            captured_at=r.captured_at,
            item_question=r.checklist_item.item_question if r.checklist_item else None,
            section_name=r.checklist_item.section_name if r.checklist_item else None
        ))
    return results

@router.post("", response_model=List[ChecklistSubmissionResponse], status_code=status.HTTP_201_CREATED)
@router.post("/batch", response_model=List[ChecklistSubmissionResponse], status_code=status.HTTP_201_CREATED)
def submit_checklist_responses(
    batch: ChecklistBatchSubmission,
    request: Request,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Submits answers for inspection checklist items with optional GPS coordinates."""
    insp = db.query(Inspection).filter(Inspection.id == batch.inspection_id).first()
    if not insp:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Inspection not found")

    saved_responses = []
    for item_data in batch.items:
        # Check item exists
        item = db.query(ChecklistItem).filter(ChecklistItem.id == item_data.checklist_item_id).first()
        if not item:
            continue

        existing = db.query(InspectionChecklist).filter(
            InspectionChecklist.inspection_id == batch.inspection_id,
            InspectionChecklist.checklist_item_id == item_data.checklist_item_id
        ).first()

        if existing:
            existing.response_boolean = item_data.response_boolean
            existing.response_value = item_data.response_value
            existing.inspector_comment = item_data.inspector_comment
            existing.gps_latitude = item_data.gps_latitude
            existing.gps_longitude = item_data.gps_longitude
            existing.captured_at = datetime.utcnow()
            existing.updated_at = datetime.utcnow()
            record = existing
        else:
            record = InspectionChecklist(
                id=uuid.uuid4(),
                inspection_id=batch.inspection_id,
                checklist_item_id=item_data.checklist_item_id,
                response_boolean=item_data.response_boolean,
                response_value=item_data.response_value,
                inspector_comment=item_data.inspector_comment,
                gps_latitude=item_data.gps_latitude,
                gps_longitude=item_data.gps_longitude,
                captured_at=datetime.utcnow()
            )
            db.add(record)

        saved_responses.append(record)

    # Transition inspection status to IN_PROGRESS if pending/assigned
    if insp.status in ("PENDING_DISPATCH", "ASSIGNED"):
        insp.status = "IN_PROGRESS"
        insp.updated_at = datetime.utcnow()

    db.commit()

    record_audit_log(
        db, current_user, "CHECKLIST_SUBMITTED", "inspection_checklists", insp.id,
        {"items_count": len(saved_responses)}, request
    )

    results = []
    for r in saved_responses:
        db.refresh(r)
        results.append(ChecklistSubmissionResponse(
            id=r.id,
            inspection_id=r.inspection_id,
            checklist_item_id=r.checklist_item_id,
            response_boolean=r.response_boolean,
            response_value=r.response_value,
            inspector_comment=r.inspector_comment,
            gps_latitude=r.gps_latitude,
            gps_longitude=r.gps_longitude,
            captured_at=r.captured_at,
            item_question=r.checklist_item.item_question if r.checklist_item else None,
            section_name=r.checklist_item.section_name if r.checklist_item else None
        ))
    return results
