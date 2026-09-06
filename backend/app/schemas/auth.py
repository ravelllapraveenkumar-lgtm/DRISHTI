from typing import List, Optional
from uuid import UUID
from datetime import datetime
from pydantic import BaseModel, EmailStr, Field, ConfigDict

class Token(BaseModel):
    access_token: str
    token_type: str = "bearer"
    expires_in_minutes: int
    user_id: UUID
    email: str
    full_name: str
    roles: List[str]

class LoginRequest(BaseModel):
    email: EmailStr
    password: str = Field(..., min_length=1)

class DemoLoginRequest(BaseModel):
    role: Optional[str] = Field(None, description="One of: SUPER_ADMIN, MINISTRY_OFFICIAL, DISTRICT_OFFICER, FIELD_INSPECTOR, INSTITUTION_ADMIN")
    user_id: Optional[UUID] = None

class RoleResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: UUID
    role_name: str
    display_name: str
    description: Optional[str] = None

class UserProfileResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: UUID
    email: str
    phone_number: Optional[str] = None
    full_name: str
    designation: Optional[str] = None
    department: Optional[str] = None
    state: Optional[str] = None
    district: Optional[str] = None
    is_active: bool
    is_demo: bool
    roles: List[str]
    created_at: datetime
    last_login_at: Optional[datetime] = None
