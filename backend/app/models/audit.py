import uuid
from datetime import datetime
from sqlalchemy import Column, String, DateTime, Text, ForeignKey
from sqlalchemy.orm import relationship
from backend.app.database import Base, GUID, JSONType

class AuditActivity(Base):
    __tablename__ = "audit_activity"

    id = Column(GUID, primary_key=True, default=uuid.uuid4)
    actor_user_id = Column(GUID, ForeignKey("users.id", ondelete="SET NULL"), nullable=True, index=True)
    action = Column(String(100), nullable=False)  # USER_LOGIN, INSPECTION_ASSIGNED, REPORT_FILED, etc.
    target_entity = Column(String(100), nullable=False)
    entity_id = Column(GUID, nullable=True)
    ip_address = Column(String(45), nullable=True)
    user_agent = Column(Text, nullable=True)
    details = Column(JSONType, nullable=True)
    created_at = Column(DateTime, default=datetime.utcnow, nullable=False, index=True)

    actor = relationship("User", foreign_keys=[actor_user_id])
