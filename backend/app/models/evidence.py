import uuid
from datetime import datetime
from sqlalchemy import Column, String, Boolean, DateTime, Integer, Float, Text, ForeignKey
from sqlalchemy.orm import relationship
from backend.app.database import Base, GUID

class Evidence(Base):
    __tablename__ = "evidence"

    id = Column(GUID, primary_key=True, default=uuid.uuid4)
    inspection_id = Column(GUID, ForeignKey("inspections.id", ondelete="CASCADE"), nullable=False, index=True)
    evidence_type = Column(String(50), nullable=False)  # GEO_TAGGED_PHOTO, GEO_TAGGED_VIDEO, DOCUMENT_SCAN, AUDIO_INTERVIEW
    file_name = Column(String(255), nullable=False)
    file_path_or_url = Column(Text, nullable=False)
    sha256_checksum = Column(String(64), nullable=False, index=True)
    description = Column(Text, nullable=False)
    timestamp_captured = Column(DateTime, nullable=False)
    gps_latitude = Column(Float, nullable=False)
    gps_longitude = Column(Float, nullable=False)
    gps_accuracy_meters = Column(Float, nullable=False)
    geofence_verified = Column(Boolean, default=False, nullable=False)
    sync_status = Column(String(50), default="SYNCED_SUCCESS", nullable=False, index=True)  # PENDING_UPLOAD, UPLOADING, SYNCED_SUCCESS, SYNC_FAILED
    sync_attempts = Column(Integer, default=1, nullable=False)
    local_sqlite_id = Column(String(100), nullable=True)
    captured_by_user_id = Column(GUID, ForeignKey("users.id", ondelete="RESTRICT"), nullable=False, index=True)
    created_at = Column(DateTime, default=datetime.utcnow, nullable=False)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow, nullable=False)

    inspection = relationship("Inspection", back_populates="evidence")
    captured_by_user = relationship("User", foreign_keys=[captured_by_user_id])
