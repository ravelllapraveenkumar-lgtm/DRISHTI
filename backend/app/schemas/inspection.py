from typing import Optional, List
from uuid import UUID
from datetime import date, datetime
from pydantic import BaseModel, Field, ConfigDict

class InspectionBase(BaseModel):
    institution_id: UUID
    origin_ai_alert_id: Optional[UUID] = None
    priority: str = Field(default="ROUTINE", description="ROUTINE, URGENT, EMERGENCY")
    mandated_date: date
    due_date: date
    inspection_reason: str = Field(..., min_length=5)
    special_instructions: Optional[str] = None

class InspectionCreate(InspectionBase):
    inspector_user_id: Optional[UUID] = None

class InspectionUpdate(BaseModel):
    priority: Optional[str] = None
    due_date: Optional[date] = None
    inspection_reason: Optional[str] = None
    special_instructions: Optional[str] = None

class InspectionStatusUpdate(BaseModel):
    status: str = Field(..., description="PENDING_DISPATCH, ASSIGNED, IN_PROGRESS, SUBMITTED, APPROVED, CLOSED")
    notes: Optional[str] = None

class InspectionResponse(InspectionBase):
    model_config = ConfigDict(from_attributes=True)

    id: UUID
    inspection_code: str
    status: str
    assigned_by_user_id: UUID
    created_at: datetime
    updated_at: datetime

    institution_name: Optional[str] = None
    institution_district: Optional[str] = None
    institution_state: Optional[str] = None
    assigned_inspector_name: Optional[str] = None
    assigned_inspector_id: Optional[UUID] = None
