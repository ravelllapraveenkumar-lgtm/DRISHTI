import uuid
from datetime import datetime
from sqlalchemy import Column, String, DateTime, Date, Text, ForeignKey, UniqueConstraint
from sqlalchemy.orm import relationship
from backend.app.database import Base, GUID

class Inspection(Base):
    __tablename__ = "inspections"

    id = Column(GUID, primary_key=True, default=uuid.uuid4)
    inspection_code = Column(String(100), unique=True, nullable=False, index=True)
    institution_id = Column(GUID, ForeignKey("institutions.id", ondelete="CASCADE"), nullable=False, index=True)
    origin_ai_alert_id = Column(GUID, ForeignKey("ai_alerts.id", ondelete="SET NULL"), nullable=True, index=True)
    priority = Column(String(20), default="ROUTINE", nullable=False, index=True)  # ROUTINE, URGENT, EMERGENCY
    status = Column(String(50), default="PENDING_DISPATCH", nullable=False, index=True)  # PENDING_DISPATCH, ASSIGNED, IN_PROGRESS, SUBMITTED, APPROVED, CLOSED
    mandated_date = Column(Date, nullable=False)
    due_date = Column(Date, nullable=False)
    inspection_reason = Column(Text, nullable=False)
    special_instructions = Column(Text, nullable=True)
    assigned_by_user_id = Column(GUID, ForeignKey("users.id", ondelete="RESTRICT"), nullable=False)
    created_at = Column(DateTime, default=datetime.utcnow, nullable=False)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow, nullable=False)

    institution = relationship("Institution", back_populates="inspections")
    origin_alert = relationship("AIAlert", back_populates="inspections")
    assigned_by_user = relationship("User", foreign_keys=[assigned_by_user_id])
    assignments = relationship("InspectionAssignment", back_populates="inspection", cascade="all, delete-orphan")
    checklists = relationship("InspectionChecklist", back_populates="inspection", cascade="all, delete-orphan")
    evidence = relationship("Evidence", back_populates="inspection", cascade="all, delete-orphan")
    report = relationship("InspectionReport", back_populates="inspection", uselist=False, cascade="all, delete-orphan")

class InspectionAssignment(Base):
    __tablename__ = "inspection_assignments"

    id = Column(GUID, primary_key=True, default=uuid.uuid4)
    inspection_id = Column(GUID, ForeignKey("inspections.id", ondelete="CASCADE"), nullable=False, index=True)
    inspector_user_id = Column(GUID, ForeignKey("users.id", ondelete="RESTRICT"), nullable=False, index=True)
    assigned_at = Column(DateTime, default=datetime.utcnow, nullable=False)
    accepted_at = Column(DateTime, nullable=True)
    arrived_at = Column(DateTime, nullable=True)
    completed_at = Column(DateTime, nullable=True)
    assigned_by_id = Column(GUID, ForeignKey("users.id", ondelete="RESTRICT"), nullable=False)
    notes = Column(Text, nullable=True)
    created_at = Column(DateTime, default=datetime.utcnow, nullable=False)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow, nullable=False)

    __table_args__ = (
        UniqueConstraint("inspection_id", "inspector_user_id", name="unique_inspection_assignment"),
    )

    inspection = relationship("Inspection", back_populates="assignments")
    inspector = relationship("User", foreign_keys=[inspector_user_id], back_populates="inspection_assignments")
    assigned_by = relationship("User", foreign_keys=[assigned_by_id])
