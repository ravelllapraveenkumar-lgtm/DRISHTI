import uuid
from datetime import datetime
from sqlalchemy import Column, String, Boolean, DateTime, Integer, Float, Text, ForeignKey
from sqlalchemy.orm import relationship
from backend.app.database import Base, GUID

class AIAnalysis(Base):
    __tablename__ = "ai_analyses"

    id = Column(GUID, primary_key=True, default=uuid.uuid4)
    institution_id = Column(GUID, ForeignKey("institutions.id", ondelete="CASCADE"), nullable=False, index=True)
    analysis_timestamp = Column(DateTime, default=datetime.utcnow, nullable=False, index=True)
    algorithm_used = Column(String(100), default="ISOLATION_FOREST_V1", nullable=False)
    dataset_window_days = Column(Integer, default=30, nullable=False)
    risk_attention_score = Column(Integer, nullable=False)  # 0 to 100
    severity_level = Column(String(20), nullable=False)  # LOW, MEDIUM, HIGH, CRITICAL
    statistical_divergence_score = Column(Float, nullable=False)
    potential_anomaly_flag = Column(Boolean, default=False, nullable=False)
    explainable_reason = Column(Text, nullable=False)
    recommended_action = Column(Text, nullable=False)
    requires_human_review = Column(Boolean, default=True, nullable=False)
    reviewed_by_user_id = Column(GUID, ForeignKey("users.id", ondelete="SET NULL"), nullable=True)
    reviewed_at = Column(DateTime, nullable=True)
    review_notes = Column(Text, nullable=True)
    created_at = Column(DateTime, default=datetime.utcnow, nullable=False)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow, nullable=False)

    institution = relationship("Institution", back_populates="ai_analyses")
    reviewer = relationship("User", foreign_keys=[reviewed_by_user_id])
    alerts = relationship("AIAlert", back_populates="analysis", cascade="all, delete-orphan")

class AIAlert(Base):
    __tablename__ = "ai_alerts"

    id = Column(GUID, primary_key=True, default=uuid.uuid4)
    ai_analysis_id = Column(GUID, ForeignKey("ai_analyses.id", ondelete="CASCADE"), nullable=False, index=True)
    institution_id = Column(GUID, ForeignKey("institutions.id", ondelete="CASCADE"), nullable=False, index=True)
    severity = Column(String(20), nullable=False, index=True)
    title = Column(String(255), nullable=False)
    alert_summary = Column(Text, nullable=False)
    suggested_inspection_scope = Column(Text, nullable=True)
    is_acknowledged = Column(Boolean, default=False, nullable=False, index=True)
    acknowledged_by = Column(GUID, ForeignKey("users.id", ondelete="SET NULL"), nullable=True)
    acknowledged_at = Column(DateTime, nullable=True)
    created_at = Column(DateTime, default=datetime.utcnow, nullable=False)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow, nullable=False)

    analysis = relationship("AIAnalysis", back_populates="alerts")
    institution = relationship("Institution", back_populates="ai_alerts")
    acknowledged_user = relationship("User", foreign_keys=[acknowledged_by])
    inspections = relationship("Inspection", back_populates="origin_alert")
