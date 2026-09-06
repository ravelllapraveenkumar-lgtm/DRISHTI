from typing import Optional
from uuid import UUID
from datetime import date, datetime
from pydantic import BaseModel, Field, ConfigDict

class AttendanceRecordBase(BaseModel):
    institution_id: UUID
    beneficiary_id: UUID
    attendance_date: date
    status: str = Field(default="PRESENT", description="PRESENT, ABSENT, ON_LEAVE")
    verification_mode: str = Field(default="BIOMETRIC_OR_SMART_PORTAL")

class AttendanceRecordCreate(AttendanceRecordBase):
    pass

class AttendanceRecordResponse(AttendanceRecordBase):
    model_config = ConfigDict(from_attributes=True)

    id: UUID
    is_synthetic: bool
    created_at: datetime

class AttendanceSummaryResponse(BaseModel):
    institution_id: UUID
    attendance_date: date
    total_roster_count: int
    present_count: int
    absent_count: int
    on_leave_count: int
    attendance_percentage: float
