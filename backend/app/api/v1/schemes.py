import uuid
from typing import List
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from backend.app.database import get_db
from backend.app.models import ProjectScheme
from backend.app.schemas.scheme import SchemeResponse

router = APIRouter(prefix="/schemes", tags=["Project Schemes"])

@router.get("", response_model=List[SchemeResponse])
def list_schemes(db: Session = Depends(get_db)):
    """Lists all national flagship schemes monitored under DRISHTI (DDRS, AVYAY, NAPDDR, PM-DAKSH)."""
    return db.query(ProjectScheme).filter(ProjectScheme.is_active == True).order_by(ProjectScheme.code.asc()).all()

@router.get("/{id}", response_model=SchemeResponse)
def get_scheme(id: uuid.UUID, db: Session = Depends(get_db)):
    """Retrieves scheme details."""
    scheme = db.query(ProjectScheme).filter(ProjectScheme.id == id).first()
    if not scheme:
        raise HTTPException(status_code=404, detail="Scheme not found")
    return scheme
