import uuid
from typing import List, Optional
from fastapi import APIRouter, Depends, HTTPException, Query, status, Request
from sqlalchemy.orm import Session
from sqlalchemy import or_
from backend.app.database import get_db
from backend.app.models import Beneficiary, Institution, ProjectScheme, User
from backend.app.schemas.beneficiary import BeneficiaryCreate, BeneficiaryResponse
from backend.app.schemas.common import PaginatedResponse
from backend.app.api.deps import get_current_user, require_roles, record_audit_log

router = APIRouter(prefix="/beneficiaries", tags=["Beneficiaries"])

@router.get("", response_model=PaginatedResponse[BeneficiaryResponse])
def list_beneficiaries(
    institution_id: Optional[uuid.UUID] = None,
    scheme_id: Optional[uuid.UUID] = None,
    search: Optional[str] = None,
    page: int = Query(1, ge=1),
    page_size: int = Query(25, ge=1, le=100),
    db: Session = Depends(get_db)
):
    """Lists registered beneficiaries with masked PII and search filter."""
    query = db.query(Beneficiary).filter(Beneficiary.is_active == True)

    if institution_id:
        query = query.filter(Beneficiary.institution_id == institution_id)
    if scheme_id:
        query = query.filter(Beneficiary.scheme_id == scheme_id)
    if search:
        query = query.filter(
            or_(
                Beneficiary.full_name.ilike(f"%{search}%"),
                Beneficiary.identifier_masked.ilike(f"%{search}%")
            )
        )

    total = query.count()
    offset = (page - 1) * page_size
    items = query.order_by(Beneficiary.created_at.desc()).offset(offset).limit(page_size).all()

    return PaginatedResponse(
        total=total,
        page=page,
        page_size=page_size,
        items=items
    )

@router.post("", response_model=BeneficiaryResponse, status_code=status.HTTP_201_CREATED)
def create_beneficiary(
    data: BeneficiaryCreate,
    request: Request,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_roles(["SUPER_ADMIN", "MINISTRY_OFFICIAL", "DISTRICT_OFFICER", "INSTITUTION_ADMIN"]))
):
    """Enrolls a beneficiary into an institution."""
    inst = db.query(Institution).filter(Institution.id == data.institution_id).first()
    if not inst:
        raise HTTPException(status_code=404, detail="Institution not found")

    scheme = db.query(ProjectScheme).filter(ProjectScheme.id == data.scheme_id).first()
    if not scheme:
        raise HTTPException(status_code=404, detail="Scheme not found")

    ben = Beneficiary(
        id=uuid.uuid4(),
        **data.model_dump(),
        is_active=True
    )
    db.add(ben)
    db.commit()
    db.refresh(ben)

    record_audit_log(db, current_user, "BENEFICIARY_ENROLLED", "beneficiaries", ben.id, {"name": ben.full_name}, request)

    return ben

@router.get("/{id}", response_model=BeneficiaryResponse)
def get_beneficiary(id: uuid.UUID, db: Session = Depends(get_db)):
    """Retrieves specific beneficiary record."""
    ben = db.query(Beneficiary).filter(Beneficiary.id == id).first()
    if not ben:
        raise HTTPException(status_code=404, detail="Beneficiary not found")
    return ben
