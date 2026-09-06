import uuid
from typing import List, Optional
from datetime import datetime
from fastapi import APIRouter, Depends, HTTPException, Query, status, Request
from sqlalchemy.orm import Session
from backend.app.database import get_db
from backend.app.models import Notification, User
from backend.app.schemas.notification import NotificationCreate, NotificationResponse
from backend.app.schemas.common import PaginatedResponse, MessageResponse
from backend.app.api.deps import get_current_user

router = APIRouter(prefix="/notifications", tags=["Notifications"])

@router.get("", response_model=PaginatedResponse[NotificationResponse])
def list_notifications(
    unread_only: bool = False,
    page: int = Query(1, ge=1),
    page_size: int = Query(20, ge=1, le=100),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Retrieves authenticated user's notifications."""
    query = db.query(Notification).filter(Notification.recipient_user_id == current_user.id)

    if unread_only:
        query = query.filter(Notification.is_read == False)

    total = query.count()
    offset = (page - 1) * page_size
    items = query.order_by(Notification.created_at.desc()).offset(offset).limit(page_size).all()

    return PaginatedResponse(
        total=total,
        page=page,
        page_size=page_size,
        items=items
    )

@router.patch("/{id}/read", response_model=NotificationResponse)
def mark_notification_as_read(
    id: uuid.UUID,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Marks a notification as read."""
    notif = db.query(Notification).filter(
        Notification.id == id,
        Notification.recipient_user_id == current_user.id
    ).first()
    if not notif:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Notification not found")

    notif.is_read = True
    notif.updated_at = datetime.utcnow()
    db.commit()
    db.refresh(notif)
    return notif

@router.post("/mark-all-read", response_model=MessageResponse)
def mark_all_notifications_read(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Marks all notifications for current user as read."""
    db.query(Notification).filter(
        Notification.recipient_user_id == current_user.id,
        Notification.is_read == False
    ).update({"is_read": True, "updated_at": datetime.utcnow()})
    db.commit()
    return MessageResponse(message="All notifications marked as read")

@router.post("", response_model=NotificationResponse, status_code=status.HTTP_201_CREATED)
def create_notification(
    data: NotificationCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Dispatches a system notification to a target user."""
    recipient = db.query(User).filter(User.id == data.recipient_user_id).first()
    if not recipient:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Recipient user not found")

    notif = Notification(
        id=uuid.uuid4(),
        recipient_user_id=data.recipient_user_id,
        title=data.title,
        message=data.message,
        category=data.category,
        entity_reference_id=data.entity_reference_id,
        is_read=False
    )
    db.add(notif)
    db.commit()
    db.refresh(notif)
    return notif
