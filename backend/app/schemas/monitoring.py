from typing import Optional, Dict, Any
from uuid import UUID
from datetime import date, datetime
from pydantic import BaseModel, Field, ConfigDict

class MonitoringRecordBase(BaseModel):
    institution_id: UUID
    record_date: date
    reported_beneficiaries_present: int = Field(..., ge=0)
    biometric_punch_count: int = Field(..., ge=0)
    staff_present_count: int = Field(default=0, ge=0)
    meals_served_count: int = Field(default=0, ge=0)
    cctv_uptime_percentage: float = Field(default=100.0, ge=0.0, le=100.0)
    geofence_status: str = Field(default="MATCHED_GEOFENCE")
    telemetry_payload: Optional[Dict[str, Any]] = None

class MonitoringRecordCreate(MonitoringRecordBase):
    pass

class MonitoringRecordResponse(MonitoringRecordBase):
    model_config = ConfigDict(from_attributes=True)

    id: UUID
    is_synthetic: bool
    created_at: datetime
    updated_at: datetime
