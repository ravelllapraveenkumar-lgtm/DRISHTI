from typing import Optional
from uuid import UUID
from datetime import datetime
from pydantic import BaseModel, Field, ConfigDict

class EvidenceCreate(BaseModel):
    inspection_id: UUID
    evidence_type: str = Field(..., description="GEO_TAGGED_PHOTO, GEO_TAGGED_VIDEO, DOCUMENT_SCAN, AUDIO_INTERVIEW")
    file_name: str = Field(..., min_length=1, max_length=255)
    file_path_or_url: str = Field(..., min_length=1)
    sha256_checksum: str = Field(..., min_length=64, max_length=64, description="64-character hex SHA-256 hash")
    description: str = Field(..., min_length=2)
    timestamp_captured: datetime
    gps_latitude: float = Field(..., ge=-90.0, le=90.0)
    gps_longitude: float = Field(..., ge=-180.0, le=180.0)
    gps_accuracy_meters: float = Field(..., ge=0.0)
    local_sqlite_id: Optional[str] = None

class EvidenceResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: UUID
    inspection_id: UUID
    evidence_type: str
    file_name: str
    file_path_or_url: str
    sha256_checksum: str
    description: str
    timestamp_captured: datetime
    gps_latitude: float
    gps_longitude: float
    gps_accuracy_meters: float
    geofence_verified: bool
    sync_status: str
    sync_attempts: int
    local_sqlite_id: Optional[str] = None
    captured_by_user_id: UUID
    created_at: datetime
