import uuid
from datetime import datetime
from sqlalchemy import Column, String, Boolean, DateTime, Text, Numeric, Date, Integer
from sqlalchemy.orm import relationship
from backend.app.database import Base, GUID

class ProjectScheme(Base):
    __tablename__ = "projects_schemes"

    id = Column(GUID, primary_key=True, default=uuid.uuid4)
    code = Column(String(50), unique=True, nullable=False, index=True)
    name = Column(String(255), nullable=False)
    category = Column(String(50), nullable=False)  # DDRS, SENIOR_CITIZENS_AVYAY, NAPDDR, etc.
    description = Column(Text, nullable=True)
    launch_date = Column(Date, nullable=True)
    nodal_ministry = Column(String(255), default="Ministry of Social Justice and Empowerment", nullable=False)
    sanctioned_budget = Column(Numeric(15, 2), default=0.00, nullable=False)
    annual_target_beneficiaries = Column(Integer, default=0, nullable=False)
    guidelines_url = Column(String(500), nullable=True)
    is_active = Column(Boolean, default=True, nullable=False)
    created_at = Column(DateTime, default=datetime.utcnow, nullable=False)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow, nullable=False)

    institutions = relationship("Institution", back_populates="primary_scheme")
    beneficiaries = relationship("Beneficiary", back_populates="scheme")
