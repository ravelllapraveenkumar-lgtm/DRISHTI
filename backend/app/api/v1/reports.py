import uuid
from typing import List, Optional
from datetime import datetime
from fastapi import APIRouter, Depends, HTTPException, Query, status, Request
from sqlalchemy.orm import Session
from backend.app.database import get_db
from backend.app.models import InspectionReport, Inspection, User, Notification
from backend.app.schemas.report import (
    InspectionReportCreate, InspectionReportReview, InspectionReportResponse
)
from backend.app.schemas.common import PaginatedResponse
from backend.app.api.deps import get_current_user, require_roles, record_audit_log

router = APIRouter(prefix="/inspection-reports", tags=["Inspection Reports"])

def format_report(rep: InspectionReport) -> InspectionReportResponse:
    return InspectionReportResponse(
        id=rep.id,
        inspection_id=rep.inspection_id,
        inspector_id=rep.inspector_id,
        submission_timestamp=rep.submission_timestamp,
        physical_beneficiary_count=rep.physical_beneficiary_count,
        roster_discrepancy_count=rep.roster_discrepancy_count,
        cleanliness_score=rep.cleanliness_score,
        food_nutrition_score=rep.food_nutrition_score,
        infrastructure_condition_score=rep.infrastructure_condition_score,
        inspector_summary=rep.inspector_summary,
        overall_verdict=rep.overall_verdict,
        official_review_status=rep.official_review_status,
        reviewed_by_official_id=rep.reviewed_by_official_id,
        official_decision_notes=rep.official_decision_notes,
        action_taken_type=rep.action_taken_type,
        action_taken_at=rep.action_taken_at,
        created_at=rep.created_at,
        inspector_name=rep.inspector.full_name if rep.inspector else None,
        inspection_code=rep.inspection.inspection_code if rep.inspection else None
    )

@router.get("", response_model=PaginatedResponse[InspectionReportResponse])
def list_inspection_reports(
    review_status: Optional[str] = None,
    overall_verdict: Optional[str] = None,
    page: int = Query(1, ge=1),
    page_size: int = Query(20, ge=1, le=100),
    db: Session = Depends(get_db)
):
    """Lists submitted inspection reports."""
    query = db.query(InspectionReport)

    if review_status:
        query = query.filter(InspectionReport.official_review_status == review_status.upper())
    if overall_verdict:
        query = query.filter(InspectionReport.overall_verdict == overall_verdict.upper())

    total = query.count()
    offset = (page - 1) * page_size
    reports = query.order_by(InspectionReport.submission_timestamp.desc()).offset(offset).limit(page_size).all()

    items = [format_report(r) for r in reports]

    return PaginatedResponse(
        total=total,
        page=page,
        page_size=page_size,
        items=items
    )

@router.post("", response_model=InspectionReportResponse, status_code=status.HTTP_201_CREATED)
def submit_inspection_report(
    data: InspectionReportCreate,
    request: Request,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Submits the final comprehensive field inspection report."""
    insp = db.query(Inspection).filter(Inspection.id == data.inspection_id).first()
    if not insp:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Inspection not found")

    existing = db.query(InspectionReport).filter(InspectionReport.inspection_id == data.inspection_id).first()
    if existing:
        raise HTTPException(status_code=status.HTTP_409_CONFLICT, detail="Report already submitted for this inspection")

    report = InspectionReport(
        id=uuid.uuid4(),
        inspection_id=data.inspection_id,
        inspector_id=current_user.id,
        submission_timestamp=datetime.utcnow(),
        physical_beneficiary_count=data.physical_beneficiary_count,
        roster_discrepancy_count=data.roster_discrepancy_count,
        cleanliness_score=data.cleanliness_score,
        food_nutrition_score=data.food_nutrition_score,
        infrastructure_condition_score=data.infrastructure_condition_score,
        inspector_summary=data.inspector_summary,
        overall_verdict=data.overall_verdict.upper(),
        official_review_status="PENDING_OFFICIAL_REVIEW"
    )
    db.add(report)

    # Transition inspection status to SUBMITTED
    insp.status = "SUBMITTED"
    insp.updated_at = datetime.utcnow()

    # If institution exists, update last inspected date
    if insp.institution:
        insp.institution.last_inspected_at = datetime.utcnow()

    # Notify Ministry / District Officer
    notif = Notification(
        id=uuid.uuid4(),
        recipient_user_id=insp.assigned_by_user_id,
        title=f"Report Filed: {insp.inspection_code}",
        message=f"Inspector {current_user.full_name} submitted inspection report with verdict: {data.overall_verdict}.",
        category="REPORT_SUBMITTED",
        entity_reference_id=report.id
    )
    db.add(notif)

    db.commit()
    db.refresh(report)

    record_audit_log(
        db, current_user, "INSPECTION_REPORT_SUBMITTED", "inspection_reports", report.id,
        {"verdict": report.overall_verdict, "discrepancies": report.roster_discrepancy_count}, request
    )

    return format_report(report)

@router.get("/{id}", response_model=InspectionReportResponse)
def get_inspection_report(id: uuid.UUID, db: Session = Depends(get_db)):
    """Retrieves full details of a specific inspection report."""
    rep = db.query(InspectionReport).filter(InspectionReport.id == id).first()
    if not rep:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Inspection report not found")
    return format_report(rep)

@router.post("/{id}/review", response_model=InspectionReportResponse)
@router.patch("/{id}/review", response_model=InspectionReportResponse)
def review_inspection_report(
    id: uuid.UUID,
    review_data: InspectionReportReview,
    request: Request,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_roles(["SUPER_ADMIN", "MINISTRY_OFFICIAL", "DISTRICT_OFFICER"]))
):
    """Official reviews, accepts, or orders re-inspection on a submitted report."""
    rep = db.query(InspectionReport).filter(InspectionReport.id == id).first()
    if not rep:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Inspection report not found")

    rep.official_review_status = review_data.official_review_status.upper()
    rep.official_decision_notes = review_data.official_decision_notes
    rep.reviewed_by_official_id = current_user.id
    rep.action_taken_type = review_data.action_taken_type
    if review_data.action_taken_type:
        rep.action_taken_at = datetime.utcnow()
    rep.updated_at = datetime.utcnow()

    # If accepted, mark inspection approved
    if rep.official_review_status == "REVIEWED_ACCEPTED" and rep.inspection:
        rep.inspection.status = "APPROVED"
        rep.inspection.updated_at = datetime.utcnow()

    db.commit()
    db.refresh(rep)

    record_audit_log(
        db, current_user, "REPORT_OFFICIALLY_REVIEWED", "inspection_reports", rep.id,
        {"decision": rep.official_review_status, "action": rep.action_taken_type}, request
    )

    return format_report(rep)
