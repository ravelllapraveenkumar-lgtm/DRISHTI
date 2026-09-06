from typing import Optional
from uuid import UUID
from datetime import datetime
from pydantic import BaseModel, ConfigDict

class AssignmentCreate(BaseModel):
    inspection_id: UUID
    inspector_user_id: UUID
    notes: Optional[str] = None

class AssignmentUpdate(BaseModel):
    notes: Optional[str] = None
    accepted_at: Optional[datetime] = None
    arrived_at: Optional[datetime] = None
    completed_at: Optional[datetime] = None

class AssignmentResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: UUID
    inspection_id: UUID
    inspector_user_id: UUID
    assigned_at: datetime
    accepted_at: Optional[datetime] = None
    arrived_at: Optional[datetime] = None
    completed_at: Optional[datetime] = None
    assigned_by_id: UUID
    notes: Optional[str] = None
    created_at: datetime

    inspector_name: Optional[str] = None
    inspector_email: Optional[str] = None
    inspection_code: Optional[str] = None
    inspection_status: Optional[str] = None
