from typing import Optional
from uuid import UUID
from datetime import date, datetime
from pydantic import BaseModel, ConfigDict

class SchemeResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: UUID
    code: str
    name: str
    category: str
    description: Optional[str] = None
    launch_date: Optional[date] = None
    nodal_ministry: str
    sanctioned_budget: float
    guidelines_url: Optional[str] = None
    is_active: bool
    created_at: datetime
