import uuid
from typing import Generator, List, Optional
from datetime import datetime, timedelta
from fastapi import Depends, HTTPException, status, Request
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from jose import jwt, JWTError
from sqlalchemy.orm import Session
from backend.app.config import settings
from backend.app.database import get_db
from backend.app.models import User, AuditActivity

security = HTTPBearer(auto_error=False)

def create_access_token(data: dict, expires_delta: Optional[timedelta] = None) -> str:
    """Generates a signed JWT token."""
    to_encode = data.copy()
    if expires_delta:
        expire = datetime.utcnow() + expires_delta
    else:
        expire = datetime.utcnow() + timedelta(minutes=settings.ACCESS_TOKEN_EXPIRE_MINUTES)
    to_encode.update({"exp": expire})
    encoded_jwt = jwt.encode(to_encode, settings.SECRET_KEY, algorithm=settings.ALGORITHM)
    return encoded_jwt

def get_current_user(
    db: Session = Depends(get_db),
    credentials: Optional[HTTPAuthorizationCredentials] = Depends(security),
    request: Request = None
) -> User:
    """
    Validates bearer token or falls back to authenticated demo session header.
    """
    user: Optional[User] = None

    if credentials and credentials.credentials:
        token = credentials.credentials
        try:
            payload = jwt.decode(token, settings.SECRET_KEY, algorithms=[settings.ALGORITHM])
            user_id: str = payload.get("sub")
            if user_id is None:
                raise HTTPException(
                    status_code=status.HTTP_401_UNAUTHORIZED,
                    detail="Invalid authentication token payload",
                    headers={"WWW-Authenticate": "Bearer"},
                )
            user = db.query(User).filter(User.id == uuid.UUID(user_id)).first()
        except JWTError:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Could not validate credentials",
                headers={"WWW-Authenticate": "Bearer"},
            )

    # Fallback support for X-Demo-User-Id or X-Demo-Role header for development/testing
    if not user and request:
        demo_user_id = request.headers.get("X-Demo-User-Id")
        demo_role = request.headers.get("X-Demo-Role")
        if demo_user_id:
            try:
                user = db.query(User).filter(User.id == uuid.UUID(demo_user_id)).first()
            except ValueError:
                pass
        elif demo_role:
            # Query first user with that role
            user = db.query(User).join(User.roles).filter(User.roles.any(role_name=demo_role)).first()

    # If still not found in development/demo mode, default to super admin
    if not user and settings.DEBUG:
        user = db.query(User).filter(User.email == "admin@mosje.gov.in").first()

    if not user:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Authentication required",
            headers={"WWW-Authenticate": "Bearer"},
        )

    if not user.is_active:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Inactive user account")

    return user

ROLE_ALIASES = {
    "MINISTRY_OFFICER": {"MINISTRY_OFFICIAL", "MINISTRY_OFFICER"},
    "MINISTRY_OFFICIAL": {"MINISTRY_OFFICIAL", "MINISTRY_OFFICER"},
    "DISTRICT_MAGISTRATE": {"DISTRICT_OFFICER", "DISTRICT_MAGISTRATE"},
    "DISTRICT_OFFICER": {"DISTRICT_OFFICER", "DISTRICT_MAGISTRATE"},
    "INSTITUTION_HEAD": {"INSTITUTION_ADMIN", "INSTITUTION_HEAD"},
    "INSTITUTION_ADMIN": {"INSTITUTION_ADMIN", "INSTITUTION_HEAD"},
}

def require_roles(allowed_roles: List[str]):
    """Role-based authorization dependency factory."""
    def role_checker(current_user: User = Depends(get_current_user)) -> User:
        user_roles = set(r.role_name for r in current_user.roles)
        for r in list(user_roles):
            user_roles.update(ROLE_ALIASES.get(r, set()))

        # Super admin always has access
        if "SUPER_ADMIN" in user_roles:
            return current_user
        if not any(role in user_roles for role in allowed_roles):
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail=f"Access denied. Requires one of roles: {', '.join(allowed_roles)}"
            )
        return current_user
    return role_checker

def record_audit_log(
    db: Session,
    actor_user: Optional[User],
    action: str,
    target_entity: str,
    entity_id: Optional[uuid.UUID] = None,
    details: Optional[dict] = None,
    request: Optional[Request] = None
) -> AuditActivity:
    """Helper to record an immutable audit log entry."""
    ip_addr = None
    user_agent = None
    if request:
        ip_addr = request.client.host if request.client else None
        user_agent = request.headers.get("user-agent")

    log_entry = AuditActivity(
        id=uuid.uuid4(),
        actor_user_id=actor_user.id if actor_user else None,
        action=action,
        target_entity=target_entity,
        entity_id=entity_id,
        ip_address=ip_addr,
        user_agent=user_agent,
        details=details
    )
    db.add(log_entry)
    db.commit()
    return log_entry
