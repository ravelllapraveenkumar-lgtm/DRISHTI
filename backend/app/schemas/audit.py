from typing import Optional, Dict, Any
from uuid import UUID
from datetime import datetime
from pydantic import BaseModel, Field, ConfigDict

class AuditActivityCreate(BaseModel):
    actor_user_id: Optional[UUID] = None
    action: str = Field(..., min_length=2, max_length=100)
    target_entity: str = Field(..., min_length=2, max_length=100)
    entity_id: Optional[UUID] = None
    ip_address: Optional[str] = None
    user_agent: Optional[str] = None
    details: Optional[Dict[str, Any]] = None

class AuditActivityResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: UUID
    actor_user_id: Optional[UUID] = None
    action: str
    target_entity: str
    entity_id: Optional[UUID] = None
    ip_address: Optional[str] = None
    user_agent: Optional[str] = None
    details: Optional[Dict[str, Any]] = None
    created_at: datetime

    actor_name: Optional[str] = None
    actor_email: Optional[str] = None
