import uuid
from typing import List, Optional
from datetime import date, datetime
from fastapi import APIRouter, Depends, HTTPException, Query, status, Request
from sqlalchemy.orm import Session
from backend.app.database import get_db
from backend.app.models import AttendanceRecord, Beneficiary, Institution, User
from backend.app.schemas.attendance import AttendanceRecordCreate, AttendanceRecordResponse, AttendanceSummaryResponse
from backend.app.schemas.common import PaginatedResponse
from backend.app.api.deps import get_current_user, require_roles, record_audit_log

router = APIRouter(prefix="/attendance", tags=["Attendance Records"])

@router.get("", response_model=PaginatedResponse[AttendanceRecordResponse])
def list_attendance_records(
    institution_id: Optional[uuid.UUID] = None,
    beneficiary_id: Optional[uuid.UUID] = None,
    attendance_date: Optional[date] = None,
    status_filter: Optional[str] = None,
    page: int = Query(1, ge=1),
    page_size: int = Query(50, ge=1, le=100),
    db: Session = Depends(get_db)
):
    """Retrieves paginated individual attendance records."""
    query = db.query(AttendanceRecord)

    if institution_id:
        query = query.filter(AttendanceRecord.institution_id == institution_id)
    if beneficiary_id:
        query = query.filter(AttendanceRecord.beneficiary_id == beneficiary_id)
    if attendance_date:
        query = query.filter(AttendanceRecord.attendance_date == attendance_date)
    if status_filter:
        query = query.filter(AttendanceRecord.status == status_filter.upper())

    total = query.count()
    offset = (page - 1) * page_size
    records = query.order_by(AttendanceRecord.attendance_date.desc()).offset(offset).limit(page_size).all()

    return PaginatedResponse(
        total=total,
        page=page,
        page_size=page_size,
        items=records
    )

@router.post("", response_model=AttendanceRecordResponse, status_code=status.HTTP_201_CREATED)
def record_attendance(
    data: AttendanceRecordCreate,
    request: Request,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_roles(["SUPER_ADMIN", "MINISTRY_OFFICIAL", "DISTRICT_OFFICER", "INSTITUTION_ADMIN"]))
):
    """Records attendance for a registered beneficiary."""
    ben = db.query(Beneficiary).filter(Beneficiary.id == data.beneficiary_id).first()
    if not ben:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Beneficiary not found")

    existing = db.query(AttendanceRecord).filter(
        AttendanceRecord.institution_id == data.institution_id,
        AttendanceRecord.beneficiary_id == data.beneficiary_id,
        AttendanceRecord.attendance_date == data.attendance_date
    ).first()

    if existing:
        existing.status = data.status
        existing.verification_mode = data.verification_mode
        existing.updated_at = datetime.utcnow()
        record = existing
    else:
        record = AttendanceRecord(
            id=uuid.uuid4(),
            **data.model_dump(),
            is_synthetic=False
        )
        db.add(record)

    db.commit()
    db.refresh(record)

    return record

@router.get("/summary", response_model=AttendanceSummaryResponse)
def get_attendance_summary(
    institution_id: uuid.UUID,
    attendance_date: Optional[date] = None,
    db: Session = Depends(get_db)
):
    """Returns aggregated attendance metrics for an institution on a given date."""
    target_date = attendance_date or date.today()

    total_roster = db.query(Beneficiary).filter(
        Beneficiary.institution_id == institution_id,
        Beneficiary.is_active == True
    ).count()

    records = db.query(AttendanceRecord).filter(
        AttendanceRecord.institution_id == institution_id,
        AttendanceRecord.attendance_date == target_date
    ).all()

    present_count = sum(1 for r in records if r.status == "PRESENT")
    absent_count = sum(1 for r in records if r.status == "ABSENT")
    on_leave_count = sum(1 for r in records if r.status == "ON_LEAVE")

    pct = 0.0
    if total_roster > 0:
        pct = round((present_count / total_roster) * 100, 2)

    return AttendanceSummaryResponse(
        institution_id=institution_id,
        attendance_date=target_date,
        total_roster_count=total_roster,
        present_count=present_count,
        absent_count=absent_count,
        on_leave_count=on_leave_count,
        attendance_percentage=pct
    )
