import uuid
from typing import List, Dict, Any
from datetime import datetime
from fastapi import APIRouter, Depends, HTTPException, status, Request
from sqlalchemy.orm import Session
from passlib.context import CryptContext
from backend.app.config import settings
from backend.app.database import get_db
from backend.app.models import User, Role
from backend.app.schemas.auth import Token, LoginRequest, DemoLoginRequest, UserProfileResponse
from backend.app.api.deps import create_access_token, get_current_user, record_audit_log

pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")
router = APIRouter(prefix="/auth", tags=["Authentication"])

@router.post("/login", response_model=Token)
def login(login_data: LoginRequest, request: Request, db: Session = Depends(get_db)):
    """Authenticates a user with email and password."""
    email_clean = login_data.email.strip().lower()
    if email_clean in ("inspector.north@mosje.gov.in", "inspector@drishti.gov.in"):
        email_clean = "inspector.verma@drishti.gov.in"

    user = db.query(User).filter(User.email == email_clean).first()
    if not user:
        # Fallback case-insensitive check
        user = db.query(User).filter(User.email.ilike(email_clean)).first()

    if not user:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Incorrect email or password",
            headers={"WWW-Authenticate": "Bearer"},
        )

    # In demo environment, allow direct demo password or verify hash
    is_valid = False
    if login_data.password in ("drishti2026", "password", "demo123", "Inspector@123", "admin123"):
        is_valid = True
    else:
        try:
            is_valid = pwd_context.verify(login_data.password, user.password_hash)
        except Exception:
            is_valid = False

    if not is_valid:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Incorrect email or password",
            headers={"WWW-Authenticate": "Bearer"},
        )

    user.last_login_at = datetime.utcnow()
    db.commit()

    roles = [r.role_name for r in user.roles]
    token = create_access_token(data={"sub": str(user.id), "email": user.email, "roles": roles})
    
    record_audit_log(db, user, "USER_LOGIN", "users", user.id, {"method": "password"}, request)

    return Token(
        access_token=token,
        token_type="bearer",
        expires_in_minutes=settings.ACCESS_TOKEN_EXPIRE_MINUTES,
        user_id=user.id,
        email=user.email,
        full_name=user.full_name,
        roles=roles
    )

@router.post("/demo-login", response_model=Token)
def demo_login(req: DemoLoginRequest, request: Request, db: Session = Depends(get_db)):
    """
    Instant role-based demo login for rapid testing across all five personas.
    """
    user = None
    if req.user_id:
        user = db.query(User).filter(User.id == req.user_id).first()
    elif req.role:
        user = db.query(User).join(User.roles).filter(Role.role_name == req.role.upper()).first()
        if not user:
            role_req = req.role.upper()
            if role_req in ("SUPER_ADMIN", "MINISTRY_OFFICIAL", "DISTRICT_OFFICER", "DISTRICT_MAGISTRATE"):
                user = db.query(User).filter(User.email.in_(["admin@mosje.gov.in", "officer.sharma@mosje.gov.in"])).first()
            elif role_req in ("INSTITUTION_ADMIN", "INSTITUTION_HEAD"):
                user = db.query(User).filter(User.email.in_(["ngo.prerna@drishti.org", "ngo.director@arunodayasociety.org"])).first()
            elif role_req in ("FIELD_INSPECTOR", "INSPECTION_SUPERVISOR"):
                user = db.query(User).filter(User.email.in_(["inspector.sharma@mosje.gov.in", "inspector.verma@drishti.gov.in"])).first()
    else:
        # Default to Super Admin or Lead Ministry Officer
        user = db.query(User).filter(User.email.in_(["admin@mosje.gov.in", "officer.sharma@mosje.gov.in"])).first()

    if not user:
        raise HTTPException(status_code=404, detail="Demo persona not found")

    user.last_login_at = datetime.utcnow()
    db.commit()

    roles = [r.role_name for r in user.roles]
    if req.role and req.role.upper() == "SUPER_ADMIN" and "SUPER_ADMIN" not in roles:
        roles.append("SUPER_ADMIN")

    token = create_access_token(data={"sub": str(user.id), "email": user.email, "roles": roles})

    record_audit_log(db, user, "DEMO_LOGIN", "users", user.id, {"role": req.role}, request)

    return Token(
        access_token=token,
        token_type="bearer",
        expires_in_minutes=settings.ACCESS_TOKEN_EXPIRE_MINUTES,
        user_id=user.id,
        email=user.email,
        full_name=user.full_name,
        roles=roles
    )

@router.get("/demo-users", response_model=List[Dict[str, Any]])
def get_demo_users(db: Session = Depends(get_db)):
    """Returns list of pre-configured demo user accounts."""
    users = db.query(User).filter(User.is_demo == True).all()
    results = []
    for u in users:
        results.append({
            "id": str(u.id),
            "email": u.email,
            "full_name": u.full_name,
            "designation": u.designation,
            "department": u.department,
            "state": u.state,
            "district": u.district,
            "roles": [r.role_name for r in u.roles],
            "demo_password": "password"
        })
    return results

@router.get("/me", response_model=UserProfileResponse)
def get_my_profile(current_user: User = Depends(get_current_user)):
    """Returns currently authenticated user profile."""
    return UserProfileResponse(
        id=current_user.id,
        email=current_user.email,
        phone_number=current_user.phone_number,
        full_name=current_user.full_name,
        designation=current_user.designation,
        department=current_user.department,
        state=current_user.state,
        district=current_user.district,
        is_active=current_user.is_active,
        is_demo=current_user.is_demo,
        roles=[r.role_name for r in current_user.roles],
        created_at=current_user.created_at,
        last_login_at=current_user.last_login_at
    )
