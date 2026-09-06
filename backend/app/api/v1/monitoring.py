import uuid
from typing import List, Optional
from datetime import date, datetime
from fastapi import APIRouter, Depends, HTTPException, Query, status, Request
from sqlalchemy.orm import Session
from backend.app.database import get_db
from backend.app.models import MonitoringRecord, Institution, User
from backend.app.schemas.monitoring import MonitoringRecordCreate, MonitoringRecordResponse
from backend.app.schemas.common import PaginatedResponse
from backend.app.api.deps import get_current_user, require_roles, record_audit_log

router = APIRouter(prefix="/monitoring", tags=["Monitoring & Telemetry"])

@router.get("", response_model=PaginatedResponse[MonitoringRecordResponse])
@router.get("/records", response_model=PaginatedResponse[MonitoringRecordResponse])
def list_monitoring_records(
    institution_id: Optional[uuid.UUID] = None,
    start_date: Optional[date] = None,
    end_date: Optional[date] = None,
    page: int = Query(1, ge=1),
    page_size: int = Query(20, ge=1, le=100),
    db: Session = Depends(get_db)
):
    """Retrieves paginated monitoring and sensor telemetry logs."""
    query = db.query(MonitoringRecord)

    if institution_id:
        query = query.filter(MonitoringRecord.institution_id == institution_id)
    if start_date:
        query = query.filter(MonitoringRecord.record_date >= start_date)
    if end_date:
        query = query.filter(MonitoringRecord.record_date <= end_date)

    total = query.count()
    offset = (page - 1) * page_size
    records = query.order_by(MonitoringRecord.record_date.desc()).offset(offset).limit(page_size).all()

    return PaginatedResponse(
        total=total,
        page=page,
        page_size=page_size,
        items=records
    )

@router.post("", response_model=MonitoringRecordResponse, status_code=status.HTTP_201_CREATED)
def create_monitoring_record(
    data: MonitoringRecordCreate,
    request: Request,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_roles(["SUPER_ADMIN", "MINISTRY_OFFICIAL", "DISTRICT_OFFICER", "INSTITUTION_ADMIN"]))
):
    """Ingests daily operational and biometric telemetry for an institution."""
    inst = db.query(Institution).filter(Institution.id == data.institution_id).first()
    if not inst:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Institution with ID '{data.institution_id}' not found"
        )

    # Check for existing record on date
    existing = db.query(MonitoringRecord).filter(
        MonitoringRecord.institution_id == data.institution_id,
        MonitoringRecord.record_date == data.record_date
    ).first()

    if existing:
        # Update existing
        for k, v in data.model_dump().items():
            setattr(existing, k, v)
        existing.updated_at = datetime.utcnow()
        record = existing
    else:
        record = MonitoringRecord(
            id=uuid.uuid4(),
            **data.model_dump(),
            is_synthetic=False
        )
        db.add(record)

    # Update institution current occupancy
    inst.current_occupancy = data.reported_beneficiaries_present
    inst.updated_at = datetime.utcnow()

    db.commit()
    db.refresh(record)

    record_audit_log(db, current_user, "MONITORING_TELEMETRY_LOGGED", "monitoring_records", record.id, {"date": str(data.record_date)}, request)

    return record

@router.get("/{id}", response_model=MonitoringRecordResponse)
def get_monitoring_record(id: uuid.UUID, db: Session = Depends(get_db)):
    """Retrieves specific telemetry record."""
    record = db.query(MonitoringRecord).filter(MonitoringRecord.id == id).first()
    if not record:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Monitoring record not found")
    return record

@router.get("/institution/{institution_id}", response_model=List[MonitoringRecordResponse])
def get_institution_monitoring_history(
    institution_id: uuid.UUID,
    limit: int = Query(30, ge=1, le=180),
    db: Session = Depends(get_db)
):
    """Retrieves recent daily telemetry history for a specific institution."""
    records = db.query(MonitoringRecord).filter(
        MonitoringRecord.institution_id == institution_id
    ).order_by(MonitoringRecord.record_date.desc()).limit(limit).all()
    return records
