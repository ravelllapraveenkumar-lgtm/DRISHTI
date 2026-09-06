import uuid
from datetime import datetime
from sqlalchemy import Column, String, Boolean, DateTime, Integer, Float, Text, ForeignKey, UniqueConstraint
from sqlalchemy.orm import relationship
from backend.app.database import Base, GUID

class ChecklistTemplate(Base):
    __tablename__ = "checklist_templates"

    id = Column(GUID, primary_key=True, default=uuid.uuid4)
    name = Column(String(255), nullable=False)
    scheme_category = Column(String(50), nullable=False)
    version = Column(Integer, default=1, nullable=False)
    is_active = Column(Boolean, default=True, nullable=False)
    created_at = Column(DateTime, default=datetime.utcnow, nullable=False)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow, nullable=False)

    items = relationship("ChecklistItem", back_populates="template", cascade="all, delete-orphan")

class ChecklistItem(Base):
    __tablename__ = "checklist_items"

    id = Column(GUID, primary_key=True, default=uuid.uuid4)
    template_id = Column(GUID, ForeignKey("checklist_templates.id", ondelete="CASCADE"), nullable=False, index=True)
    section_name = Column(String(100), nullable=False)
    item_question = Column(Text, nullable=False)
    field_type = Column(String(50), default="BOOLEAN_PASS_FAIL", nullable=False)
    is_mandatory = Column(Boolean, default=True, nullable=False)
    guidance_notes = Column(Text, nullable=True)
    order_index = Column(Integer, default=0, nullable=False)
    created_at = Column(DateTime, default=datetime.utcnow, nullable=False)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow, nullable=False)

    template = relationship("ChecklistTemplate", back_populates="items")
    responses = relationship("InspectionChecklist", back_populates="checklist_item")

class InspectionChecklist(Base):
    __tablename__ = "inspection_checklists"

    id = Column(GUID, primary_key=True, default=uuid.uuid4)
    inspection_id = Column(GUID, ForeignKey("inspections.id", ondelete="CASCADE"), nullable=False, index=True)
    checklist_item_id = Column(GUID, ForeignKey("checklist_items.id", ondelete="RESTRICT"), nullable=False, index=True)
    response_boolean = Column(Boolean, nullable=True)
    response_value = Column(Text, nullable=True)
    inspector_comment = Column(Text, nullable=True)
    gps_latitude = Column(Float, nullable=True)
    gps_longitude = Column(Float, nullable=True)
    captured_at = Column(DateTime, default=datetime.utcnow, nullable=False)
    created_at = Column(DateTime, default=datetime.utcnow, nullable=False)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow, nullable=False)

    __table_args__ = (
        UniqueConstraint("inspection_id", "checklist_item_id", name="unique_inspection_checklist_item"),
    )

    inspection = relationship("Inspection", back_populates="checklists")
    checklist_item = relationship("ChecklistItem", back_populates="responses")
