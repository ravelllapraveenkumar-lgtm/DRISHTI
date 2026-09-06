import uuid
from datetime import datetime
from sqlalchemy import Column, String, Boolean, DateTime, Text, Integer, Float, ForeignKey
from sqlalchemy.orm import relationship, synonym
from backend.app.database import Base, GUID

class Institution(Base):
    __tablename__ = "institutions"

    id = Column(GUID, primary_key=True, default=uuid.uuid4)
    registration_code = Column(String(100), unique=True, nullable=False, index=True)
    name = Column(String(255), nullable=False, index=True)
    institution_type = Column(String(50), nullable=False)  # NGO_AIDED, REHABILITATION_CENTER, etc.
    primary_scheme_id = Column(GUID, ForeignKey("projects_schemes.id", ondelete="RESTRICT"), nullable=False)
    state = Column(String(100), nullable=False, index=True)
    district = Column(String(100), nullable=False, index=True)
    sub_division = Column(String(100), nullable=True)
    address = Column(Text, nullable=False)
    pincode = Column(String(10), nullable=False)
    latitude = Column(Float, nullable=False)
    longitude = Column(Float, nullable=False)
    geofence_radius_meters = Column(Integer, default=150, nullable=False)
    contact_person_name = Column(String(255), nullable=False)
    contact_phone = Column(String(20), nullable=False)
    contact_email = Column(String(255), nullable=False)
    registered_capacity = Column("sanctioned_capacity", Integer, default=50, nullable=False)
    sanctioned_capacity = synonym("registered_capacity")
    current_occupancy = Column("active_beneficiary_count", Integer, default=0, nullable=False)
    active_beneficiary_count = synonym("current_occupancy")
    cctv_streams_count = Column(Integer, default=0, nullable=False)
    cctv_status = Column(String(50), default="OPERATIONAL", nullable=False)
    is_active = Column(Boolean, default=True, nullable=False)
    verification_status = Column(String(50), default="VERIFIED_REGISTERED", nullable=False)
    current_risk_score = Column(Integer, default=0, nullable=False)
    risk_level = Column(String(20), default="LOW", nullable=False)
    last_inspected_at = Column(DateTime, nullable=True)
    created_at = Column(DateTime, default=datetime.utcnow, nullable=False)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow, nullable=False)

    primary_scheme = relationship("ProjectScheme", back_populates="institutions")
    beneficiaries = relationship("Beneficiary", back_populates="institution")
    monitoring_records = relationship("MonitoringRecord", back_populates="institution")
    attendance_records = relationship("AttendanceRecord", back_populates="institution")
    ai_analyses = relationship("AIAnalysis", back_populates="institution")
    ai_alerts = relationship("AIAlert", back_populates="institution")
    inspections = relationship("Inspection", back_populates="institution")
