import uuid
from datetime import datetime
from sqlalchemy import Column, String, DateTime, Integer, Text, ForeignKey
from sqlalchemy.orm import relationship
from backend.app.database import Base, GUID

class InspectionReport(Base):
    __tablename__ = "inspection_reports"

    id = Column(GUID, primary_key=True, default=uuid.uuid4)
    inspection_id = Column(GUID, ForeignKey("inspections.id", ondelete="CASCADE"), unique=True, nullable=False)
    inspector_id = Column(GUID, ForeignKey("users.id", ondelete="RESTRICT"), nullable=False, index=True)
    submission_timestamp = Column(DateTime, default=datetime.utcnow, nullable=False)
    physical_beneficiary_count = Column(Integer, nullable=False)
    roster_discrepancy_count = Column(Integer, default=0, nullable=False)
    cleanliness_score = Column(Integer, nullable=True)  # 1 to 10
    food_nutrition_score = Column(Integer, nullable=True)  # 1 to 10
    infrastructure_condition_score = Column(Integer, nullable=True)  # 1 to 10
    inspector_summary = Column(Text, nullable=False)
    overall_verdict = Column(String(50), nullable=False)  # COMPLIANT, MINOR_NON_COMPLIANCE, CRITICAL_IRREGULARITIES, SHOW_CAUSE_RECOMMENDED
    official_review_status = Column(String(50), default="PENDING_OFFICIAL_REVIEW", nullable=False)  # PENDING_OFFICIAL_REVIEW, REVIEWED_ACCEPTED, ACTION_INITIATED, RE_INSPECTION_ORDERED
    reviewed_by_official_id = Column(GUID, ForeignKey("users.id", ondelete="SET NULL"), nullable=True, index=True)
    official_decision_notes = Column(Text, nullable=True)
    action_taken_type = Column(String(100), nullable=True)
    action_taken_at = Column(DateTime, nullable=True)
    created_at = Column(DateTime, default=datetime.utcnow, nullable=False)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow, nullable=False)

    inspection = relationship("Inspection", back_populates="report")
    inspector = relationship("User", foreign_keys=[inspector_id], back_populates="reports_submitted")
    reviewed_by_official = relationship("User", foreign_keys=[reviewed_by_official_id])
