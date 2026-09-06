import uuid
from typing import List, Optional
from datetime import datetime
from fastapi import APIRouter, Depends, HTTPException, Query, status, Request
from sqlalchemy.orm import Session
from sqlalchemy import or_
from backend.app.database import get_db
from backend.app.models import Institution, ProjectScheme, Beneficiary, Inspection, AIAlert, User
from backend.app.schemas.institution import InstitutionCreate, InstitutionUpdate, InstitutionResponse, InstitutionDetailResponse
from backend.app.schemas.common import PaginatedResponse
from backend.app.api.deps import get_current_user, require_roles, record_audit_log

router = APIRouter(prefix="/institutions", tags=["Institutions"])

@router.get("", response_model=PaginatedResponse[InstitutionResponse])
def list_institutions(
    state: Optional[str] = None,
    district: Optional[str] = None,
    scheme_id: Optional[uuid.UUID] = None,
    risk_level: Optional[str] = None,
    institution_type: Optional[str] = None,
    search: Optional[str] = None,
    page: int = Query(1, ge=1),
    page_size: int = Query(20, ge=1, le=100),
    db: Session = Depends(get_db)
):
    """Retrieves paginated list of registered institutions with multi-criteria filters."""
    query = db.query(Institution)

    if state:
        query = query.filter(Institution.state.ilike(f"%{state}%"))
    if district:
        query = query.filter(Institution.district.ilike(f"%{district}%"))
    if scheme_id:
        query = query.filter(Institution.primary_scheme_id == scheme_id)
    if risk_level:
        query = query.filter(Institution.risk_level == risk_level.upper())
    if institution_type:
        query = query.filter(Institution.institution_type == institution_type.upper())
    if search:
        query = query.filter(
            or_(
                Institution.name.ilike(f"%{search}%"),
                Institution.registration_code.ilike(f"%{search}%"),
                Institution.contact_person_name.ilike(f"%{search}%")
            )
        )

    total = query.count()
    offset = (page - 1) * page_size
    items = query.order_by(Institution.current_risk_score.desc(), Institution.name.asc()).offset(offset).limit(page_size).all()

    return PaginatedResponse(
        total=total,
        page=page,
        page_size=page_size,
        items=items
    )

@router.post("", response_model=InstitutionResponse, status_code=status.HTTP_201_CREATED)
def create_institution(
    data: InstitutionCreate,
    request: Request,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_roles(["SUPER_ADMIN", "MINISTRY_OFFICIAL", "DISTRICT_OFFICER"]))
):
    """Registers a new institution under a sanctioned scheme."""
    # Check duplicate code
    existing = db.query(Institution).filter(Institution.registration_code == data.registration_code).first()
    if existing:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail=f"Institution with registration code '{data.registration_code}' already exists"
        )

    # Check scheme exists
    scheme = db.query(ProjectScheme).filter(ProjectScheme.id == data.primary_scheme_id).first()
    if not scheme:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Scheme with ID '{data.primary_scheme_id}' not found"
        )

    institution = Institution(
        id=uuid.uuid4(),
        registration_code=data.registration_code,
        name=data.name,
        institution_type=data.institution_type,
        primary_scheme_id=data.primary_scheme_id,
        state=data.state,
        district=data.district,
        sub_division=data.sub_division,
        address=data.address,
        pincode=data.pincode,
        latitude=data.latitude,
        longitude=data.longitude,
        geofence_radius_meters=data.geofence_radius_meters,
        contact_person_name=data.contact_person_name,
        contact_phone=data.contact_phone,
        contact_email=data.contact_email,
        registered_capacity=data.registered_capacity,
        current_occupancy=0,
        cctv_streams_count=0,
        cctv_status="OPERATIONAL",
        is_active=True,
        verification_status="VERIFIED_REGISTERED",
        current_risk_score=0,
        risk_level="LOW"
    )
    db.add(institution)
    db.commit()
    db.refresh(institution)

    record_audit_log(db, current_user, "INSTITUTION_REGISTERED", "institutions", institution.id, {"code": institution.registration_code}, request)

    return institution

@router.get("/{id}", response_model=InstitutionDetailResponse)
def get_institution(id: uuid.UUID, db: Session = Depends(get_db)):
    """Fetches detailed profile of an institution including active inspections and alerts."""
    inst = db.query(Institution).filter(Institution.id == id).first()
    if not inst:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Institution not found")

    total_beneficiaries = db.query(Beneficiary).filter(Beneficiary.institution_id == id, Beneficiary.is_active == True).count()
    active_inspections = db.query(Inspection).filter(
        Inspection.institution_id == id,
        Inspection.status.in_(["ASSIGNED", "IN_PROGRESS", "PENDING_DISPATCH"])
    ).count()
    unacknowledged_alerts = db.query(AIAlert).filter(
        AIAlert.institution_id == id,
        AIAlert.is_acknowledged == False
    ).count()

    detail = InstitutionDetailResponse.model_validate(inst)
    if inst.primary_scheme:
        detail.primary_scheme_code = inst.primary_scheme.code
        detail.primary_scheme_name = inst.primary_scheme.name
    detail.total_beneficiaries_count = total_beneficiaries
    detail.active_inspections_count = active_inspections
    detail.unacknowledged_alerts_count = unacknowledged_alerts

    return detail

@router.put("/{id}", response_model=InstitutionResponse)
def update_institution(
    id: uuid.UUID,
    data: InstitutionUpdate,
    request: Request,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_roles(["SUPER_ADMIN", "MINISTRY_OFFICIAL", "DISTRICT_OFFICER", "INSTITUTION_ADMIN"]))
):
    """Updates institution information."""
    inst = db.query(Institution).filter(Institution.id == id).first()
    if not inst:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Institution not found")

    update_dict = data.dict(exclude_unset=True)
    for k, v in update_dict.items():
        setattr(inst, k, v)

    inst.updated_at = datetime.utcnow()
    db.commit()
    db.refresh(inst)

    record_audit_log(db, current_user, "INSTITUTION_UPDATED", "institutions", inst.id, update_dict, request)

    return inst
