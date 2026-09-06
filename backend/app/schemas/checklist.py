from typing import Optional, List
from uuid import UUID
from datetime import datetime
from pydantic import BaseModel, Field, ConfigDict

class ChecklistItemResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: UUID
    template_id: UUID
    section_name: str
    item_question: str
    field_type: str
    is_mandatory: bool
    guidance_notes: Optional[str] = None
    order_index: int

class ChecklistTemplateResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: UUID
    name: str
    scheme_category: str
    version: int
    is_active: bool
    items: List[ChecklistItemResponse] = []

class ChecklistSubmissionCreate(BaseModel):
    checklist_item_id: UUID
    response_boolean: Optional[bool] = None
    response_value: Optional[str] = None
    inspector_comment: Optional[str] = None
    gps_latitude: Optional[float] = Field(None, ge=-90.0, le=90.0)
    gps_longitude: Optional[float] = Field(None, ge=-180.0, le=180.0)

class ChecklistBatchSubmission(BaseModel):
    inspection_id: UUID
    items: List[ChecklistSubmissionCreate]

class ChecklistSubmissionResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: UUID
    inspection_id: UUID
    checklist_item_id: UUID
    response_boolean: Optional[bool] = None
    response_value: Optional[str] = None
    inspector_comment: Optional[str] = None
    gps_latitude: Optional[float] = None
    gps_longitude: Optional[float] = None
    captured_at: datetime

    item_question: Optional[str] = None
    section_name: Optional[str] = None
