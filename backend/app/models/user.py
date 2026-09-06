import uuid
from datetime import datetime
from sqlalchemy import Column, String, Boolean, DateTime, ForeignKey, Text, Table
from sqlalchemy.orm import relationship, synonym
from backend.app.database import Base, GUID

class UserRole(Base):
    __tablename__ = "user_roles"

    user_id = Column(GUID, ForeignKey("users.id", ondelete="CASCADE"), primary_key=True)
    role_id = Column(GUID, ForeignKey("roles.id", ondelete="CASCADE"), primary_key=True)
    assigned_at = Column(DateTime, default=datetime.utcnow, nullable=False)

class Role(Base):
    __tablename__ = "roles"

    id = Column(GUID, primary_key=True, default=uuid.uuid4)
    role_name = Column(String(50), unique=True, nullable=False)
    display_name = Column(String(100), nullable=True)
    description = Column(Text, nullable=False)
    created_at = Column(DateTime, default=datetime.utcnow, nullable=False)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow, nullable=False)

    users = relationship("User", secondary="user_roles", back_populates="roles")

class User(Base):
    __tablename__ = "users"

    id = Column(GUID, primary_key=True, default=uuid.uuid4)
    email = Column(String(255), unique=True, nullable=False, index=True)
    phone_number = Column(String(20), unique=True, nullable=False)
    password_hash = Column("hashed_password", String(255), nullable=False)
    hashed_password = synonym("password_hash")
    full_name = Column(String(255), nullable=False)
    badge_number = Column(String(100), nullable=True)
    designation = Column(String(100), nullable=True)
    department = Column(String(150), nullable=True)
    state = Column(String(100), nullable=True)
    district = Column(String(100), nullable=True)
    is_active = Column(Boolean, default=True, nullable=False)
    is_verified = Column(Boolean, default=True, nullable=False)
    is_demo = Column(Boolean, default=False, nullable=False)
    last_login_at = Column(DateTime, nullable=True)
    created_at = Column(DateTime, default=datetime.utcnow, nullable=False)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow, nullable=False)

    roles = relationship("Role", secondary="user_roles", back_populates="users")
    inspection_assignments = relationship("InspectionAssignment", foreign_keys="InspectionAssignment.inspector_user_id", back_populates="inspector")
    reports_submitted = relationship("InspectionReport", foreign_keys="InspectionReport.inspector_id", back_populates="inspector")
    notifications = relationship("Notification", back_populates="recipient")

