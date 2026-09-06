import uuid
from datetime import datetime
from sqlalchemy import Column, String, Boolean, DateTime, Date, Integer, Float, ForeignKey, UniqueConstraint
from sqlalchemy.orm import relationship, synonym
from backend.app.database import Base, GUID, JSONType

class MonitoringRecord(Base):
    __tablename__ = "monitoring_records"

    id = Column(GUID, primary_key=True, default=uuid.uuid4)
    institution_id = Column(GUID, ForeignKey("institutions.id", ondelete="CASCADE"), nullable=False, index=True)
    record_date = Column(Date, nullable=False, index=True)
    total_enrolled = Column(Integer, default=0, nullable=False)
    reported_beneficiaries_present = Column("present_beneficiaries", Integer, nullable=False)
    present_beneficiaries = synonym("reported_beneficiaries_present")
    biometric_punch_count = Column(Integer, default=0, nullable=False)
    staff_present_count = Column("present_staff", Integer, default=0, nullable=False)
    present_staff = synonym("staff_present_count")
    meals_served_count = Column(Integer, default=0, nullable=False)
    cctv_uptime_percentage = Column(Float, default=100.0, nullable=False)
    geofence_status = Column("gps_ping_status", String(50), default="MATCHED_GEOFENCE", nullable=False)
    gps_ping_status = synonym("geofence_status")
    telemetry_payload = Column("telemetry_metadata", JSONType, nullable=True)
    telemetry_metadata = synonym("telemetry_payload")
    is_synthetic = Column(Boolean, default=False, nullable=False)
    created_at = Column(DateTime, default=datetime.utcnow, nullable=False)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow, nullable=False)

    __table_args__ = (
        UniqueConstraint("institution_id", "record_date", name="unique_inst_daily_monitoring"),
    )

    institution = relationship("Institution", back_populates="monitoring_records")

class AttendanceRecord(Base):
    __tablename__ = "attendance_records"

    id = Column(GUID, primary_key=True, default=uuid.uuid4)
    institution_id = Column(GUID, ForeignKey("institutions.id", ondelete="CASCADE"), nullable=False, index=True)
    beneficiary_id = Column(GUID, ForeignKey("beneficiaries.id", ondelete="SET NULL"), nullable=True, index=True)
    attendance_date = Column(Date, nullable=False, index=True)
    check_in_time = Column(DateTime, nullable=True)
    check_out_time = Column(DateTime, nullable=True)
    status = Column(String(20), default="PRESENT", nullable=False)  # PRESENT, ABSENT, ON_LEAVE
    verification_mode = Column(String(50), default="BIOMETRIC_OR_SMART_PORTAL", nullable=False)
    is_synthetic = Column(Boolean, default=False, nullable=False)
    created_at = Column(DateTime, default=datetime.utcnow, nullable=False)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow, nullable=False)

    institution = relationship("Institution", back_populates="attendance_records")
    beneficiary = relationship("Beneficiary", back_populates="attendance_records")
