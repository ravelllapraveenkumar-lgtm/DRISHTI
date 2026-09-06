from typing import Optional, List
from uuid import UUID
from datetime import datetime
from pydantic import BaseModel, EmailStr, Field, ConfigDict

class InstitutionBase(BaseModel):
    registration_code: str = Field(..., min_length=3, max_length=100)
    name: str = Field(..., min_length=2, max_length=255)
    institution_type: str = Field(..., min_length=2, max_length=50)
    primary_scheme_id: UUID
    state: str = Field(..., min_length=2, max_length=100)
    district: str = Field(..., min_length=2, max_length=100)
    sub_division: Optional[str] = None
    address: str = Field(..., min_length=5)
    pincode: str = Field(..., min_length=6, max_length=10)
    latitude: float = Field(..., ge=-90.0, le=90.0)
    longitude: float = Field(..., ge=-180.0, le=180.0)
    geofence_radius_meters: int = Field(default=150, ge=10, le=5000)
    contact_person_name: str = Field(..., min_length=2)
    contact_phone: str = Field(..., min_length=5, max_length=20)
    contact_email: EmailStr
    registered_capacity: int = Field(default=50, ge=1)

class InstitutionCreate(InstitutionBase):
    pass

class InstitutionUpdate(BaseModel):
    name: Optional[str] = None
    institution_type: Optional[str] = None
    address: Optional[str] = None
    pincode: Optional[str] = None
    latitude: Optional[float] = Field(None, ge=-90.0, le=90.0)
    longitude: Optional[float] = Field(None, ge=-180.0, le=180.0)
    geofence_radius_meters: Optional[int] = Field(None, ge=10, le=5000)
    contact_person_name: Optional[str] = None
    contact_phone: Optional[str] = None
    contact_email: Optional[EmailStr] = None
    registered_capacity: Optional[int] = Field(None, ge=1)
    current_occupancy: Optional[int] = Field(None, ge=0)
    cctv_streams_count: Optional[int] = Field(None, ge=0)
    cctv_status: Optional[str] = None
    is_active: Optional[bool] = None
    verification_status: Optional[str] = None

class InstitutionResponse(InstitutionBase):
    model_config = ConfigDict(from_attributes=True)

    id: UUID
    current_occupancy: int
    cctv_streams_count: int
    cctv_status: str
    is_active: bool
    verification_status: str
    current_risk_score: int
    risk_level: str
    last_inspected_at: Optional[datetime] = None
    created_at: datetime
    updated_at: datetime

class InstitutionDetailResponse(InstitutionResponse):
    primary_scheme_code: Optional[str] = None
    primary_scheme_name: Optional[str] = None
    total_beneficiaries_count: int = 0
    active_inspections_count: int = 0
    unacknowledged_alerts_count: int = 0
