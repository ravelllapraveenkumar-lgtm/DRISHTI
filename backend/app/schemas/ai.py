from typing import Optional, List
from uuid import UUID
from datetime import datetime
from pydantic import BaseModel, Field, ConfigDict

class AIAnalysisCreate(BaseModel):
    institution_id: UUID
    algorithm_used: str = Field(default="ISOLATION_FOREST_V1")
    dataset_window_days: int = Field(default=30, ge=1)
    risk_attention_score: int = Field(..., ge=0, le=100)
    severity_level: str = Field(..., description="LOW, MEDIUM, HIGH, CRITICAL")
    statistical_divergence_score: float = Field(..., ge=0.0)
    potential_anomaly_flag: bool = Field(default=True)
    explainable_reason: str = Field(..., min_length=10)
    recommended_action: str = Field(..., min_length=5)
    requires_human_review: bool = Field(default=True)

class AIAnalysisResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: UUID
    institution_id: UUID
    analysis_timestamp: datetime
    algorithm_used: str
    dataset_window_days: int
    risk_attention_score: int
    severity_level: str
    statistical_divergence_score: float
    potential_anomaly_flag: bool
    explainable_reason: str
    recommended_action: str
    requires_human_review: bool
    reviewed_by_user_id: Optional[UUID] = None
    reviewed_at: Optional[datetime] = None
    review_notes: Optional[str] = None
    created_at: datetime

    institution_name: Optional[str] = None
    institution_state: Optional[str] = None
    institution_district: Optional[str] = None

class AIAlertResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: UUID
    ai_analysis_id: UUID
    institution_id: UUID
    severity: str
    title: str
    alert_summary: str
    suggested_inspection_scope: Optional[str] = None
    is_acknowledged: bool
    acknowledged_by: Optional[UUID] = None
    acknowledged_at: Optional[datetime] = None
    created_at: datetime

    institution_name: Optional[str] = None
    institution_state: Optional[str] = None
    institution_district: Optional[str] = None

class AlertAcknowledgeRequest(BaseModel):
    action_note: Optional[str] = None
    create_inspection: bool = False
    priority: Optional[str] = Field("URGENT", description="ROUTINE, URGENT, EMERGENCY")
