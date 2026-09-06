import uuid
from datetime import datetime
from sqlalchemy import Column, String, Boolean, DateTime, Date, ForeignKey
from sqlalchemy.orm import relationship, synonym
from backend.app.database import Base, GUID

class Beneficiary(Base):
    __tablename__ = "beneficiaries"

    id = Column(GUID, primary_key=True, default=uuid.uuid4)
    institution_id = Column(GUID, ForeignKey("institutions.id", ondelete="CASCADE"), nullable=False, index=True)
    scheme_id = Column(GUID, ForeignKey("projects_schemes.id", ondelete="RESTRICT"), nullable=False, index=True)
    identifier_masked = Column("masked_aadhaar_ref", String(50), nullable=False)
    masked_aadhaar_ref = synonym("identifier_masked")
    full_name = Column(String(255), nullable=False)
    gender = Column(String(20), nullable=False)
    date_of_birth = Column(Date, nullable=False)
    disability_type = Column("disability_category", String(100), nullable=True)
    disability_category = synonym("disability_type")
    admission_date = Column(Date, nullable=False)
    is_active = Column(Boolean, default=True, nullable=False)
    created_at = Column(DateTime, default=datetime.utcnow, nullable=False)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow, nullable=False)

    institution = relationship("Institution", back_populates="beneficiaries")
    scheme = relationship("ProjectScheme", back_populates="beneficiaries")
    attendance_records = relationship("AttendanceRecord", back_populates="beneficiary")
