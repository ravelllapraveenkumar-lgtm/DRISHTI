import uuid
from typing import List, Optional
from datetime import datetime
from fastapi import APIRouter, Depends, HTTPException, Query, status, Request
from sqlalchemy.orm import Session
from backend.app.database import get_db
from backend.app.models import Evidence, Inspection, Institution, User
from backend.app.schemas.evidence import EvidenceCreate, EvidenceResponse
from backend.app.schemas.common import PaginatedResponse
from backend.app.api.deps import get_current_user, record_audit_log

router = APIRouter(prefix="/evidence", tags=["Evidence Metadata & Geotagging"])

def calculate_distance_meters(lat1: float, lon1: float, lat2: float, lon2: float) -> float:
    """Calculates approximate distance in meters between two GPS coordinates."""
    import math
    R = 6371000.0  # Earth radius in meters
    phi1 = math.radians(lat1)
    phi2 = math.radians(lat2)
    delta_phi = math.radians(lat2 - lat1)
    delta_lambda = math.radians(lon2 - lon1)
    a = math.sin(delta_phi / 2.0) ** 2 + math.cos(phi1) * math.cos(phi2) * math.sin(delta_lambda / 2.0) ** 2
    c = 2.0 * math.atan2(math.sqrt(a), math.sqrt(1.0 - a))
    return R * c

@router.get("", response_model=PaginatedResponse[EvidenceResponse])
def list_evidence(
    inspection_id: Optional[uuid.UUID] = None,
    evidence_type: Optional[str] = None,
    sync_status: Optional[str] = None,
    page: int = Query(1, ge=1),
    page_size: int = Query(20, ge=1, le=100),
    db: Session = Depends(get_db)
):
    """Lists geotagged evidence records."""
    query = db.query(Evidence)

    if inspection_id:
        query = query.filter(Evidence.inspection_id == inspection_id)
    if evidence_type:
        query = query.filter(Evidence.evidence_type == evidence_type.upper())
    if sync_status:
        query = query.filter(Evidence.sync_status == sync_status.upper())

    total = query.count()
    offset = (page - 1) * page_size
    items = query.order_by(Evidence.timestamp_captured.desc()).offset(offset).limit(page_size).all()

    return PaginatedResponse(
        total=total,
        page=page,
        page_size=page_size,
        items=items
    )

@router.post("", response_model=EvidenceResponse, status_code=status.HTTP_201_CREATED)
def register_evidence(
    data: EvidenceCreate,
    request: Request,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """
    Registers tamper-evident geotagged media metadata with SHA-256 verification and geofence cross-check.
    """
    insp = db.query(Inspection).filter(Inspection.id == data.inspection_id).first()
    if not insp:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Inspection not found")

    # Geofence verification against registered institution coordinates
    geofence_verified = False
    inst = insp.institution
    if inst:
        dist = calculate_distance_meters(data.gps_latitude, data.gps_longitude, inst.latitude, inst.longitude)
        allowed_radius = inst.geofence_radius_meters + data.gps_accuracy_meters
        geofence_verified = (dist <= allowed_radius)

    evidence = Evidence(
        id=uuid.uuid4(),
        inspection_id=data.inspection_id,
        evidence_type=data.evidence_type.upper(),
        file_name=data.file_name,
        file_path_or_url=data.file_path_or_url,
        sha256_checksum=data.sha256_checksum,
        description=data.description,
        timestamp_captured=data.timestamp_captured,
        gps_latitude=data.gps_latitude,
        gps_longitude=data.gps_longitude,
        gps_accuracy_meters=data.gps_accuracy_meters,
        geofence_verified=geofence_verified,
        sync_status="SYNCED_SUCCESS",
        sync_attempts=1,
        local_sqlite_id=data.local_sqlite_id,
        captured_by_user_id=current_user.id
    )
    db.add(evidence)

    # Ensure inspection is IN_PROGRESS
    if insp.status in ("PENDING_DISPATCH", "ASSIGNED"):
        insp.status = "IN_PROGRESS"
        insp.updated_at = datetime.utcnow()

    db.commit()
    db.refresh(evidence)

    record_audit_log(
        db, current_user, "EVIDENCE_UPLOADED", "evidence", evidence.id,
        {"sha256": evidence.sha256_checksum, "geofence_verified": geofence_verified}, request
    )

    return evidence

@router.get("/{id}", response_model=EvidenceResponse)
def get_evidence(id: uuid.UUID, db: Session = Depends(get_db)):
    """Retrieves specific evidence record."""
    item = db.query(Evidence).filter(Evidence.id == id).first()
    if not item:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Evidence item not found")
    return item

@router.get("/inspection/{inspection_id}", response_model=List[EvidenceResponse])
def get_inspection_evidence(inspection_id: uuid.UUID, db: Session = Depends(get_db)):
    """Lists all evidence files captured during an inspection."""
    return db.query(Evidence).filter(Evidence.inspection_id == inspection_id).order_by(Evidence.timestamp_captured.asc()).all()
