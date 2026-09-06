from typing import Optional
from uuid import UUID
from datetime import datetime
from pydantic import BaseModel, Field, ConfigDict

class InspectionReportCreate(BaseModel):
    inspection_id: UUID
    physical_beneficiary_count: int = Field(..., ge=0)
    roster_discrepancy_count: int = Field(default=0, ge=0)
    cleanliness_score: Optional[int] = Field(None, ge=1, le=10)
    food_nutrition_score: Optional[int] = Field(None, ge=1, le=10)
    infrastructure_condition_score: Optional[int] = Field(None, ge=1, le=10)
    inspector_summary: str = Field(..., min_length=10)
    overall_verdict: str = Field(..., description="COMPLIANT, MINOR_NON_COMPLIANCE, CRITICAL_IRREGULARITIES, SHOW_CAUSE_RECOMMENDED")

class InspectionReportReview(BaseModel):
    official_review_status: str = Field(..., description="REVIEWED_ACCEPTED, ACTION_INITIATED, RE_INSPECTION_ORDERED")
    official_decision_notes: str = Field(..., min_length=5)
    action_taken_type: Optional[str] = None

class InspectionReportResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: UUID
    inspection_id: UUID
    inspector_id: UUID
    submission_timestamp: datetime
    physical_beneficiary_count: int
    roster_discrepancy_count: int
    cleanliness_score: Optional[int] = None
    food_nutrition_score: Optional[int] = None
    infrastructure_condition_score: Optional[int] = None
    inspector_summary: str
    overall_verdict: str
    official_review_status: str
    reviewed_by_official_id: Optional[UUID] = None
    official_decision_notes: Optional[str] = None
    action_taken_type: Optional[str] = None
    action_taken_at: Optional[datetime] = None
    created_at: datetime

    inspector_name: Optional[str] = None
    inspection_code: Optional[str] = None
