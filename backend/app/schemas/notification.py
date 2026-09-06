from typing import Optional
from uuid import UUID
from datetime import datetime
from pydantic import BaseModel, Field, ConfigDict

class NotificationCreate(BaseModel):
    recipient_user_id: UUID
    title: str = Field(..., min_length=2, max_length=255)
    message: str = Field(..., min_length=2)
    category: str = Field(default="ALERT", description="ALERT, ASSIGNMENT, REPORT_SUBMITTED, SYSTEM")
    entity_reference_id: Optional[UUID] = None

class NotificationResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: UUID
    recipient_user_id: UUID
    title: str
    message: str
    category: str
    entity_reference_id: Optional[UUID] = None
    is_read: bool
    created_at: datetime
