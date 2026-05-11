from sqlalchemy.orm import Session

from app.models.advanced import Notification


def create_notification(
    db: Session,
    user_id: int,
    title: str,
    body: str,
    category: str,
    priority: str = "normal",
    payload: dict | None = None,
) -> Notification:
    notification = Notification(
        user_id=user_id,
        title=title,
        body=body,
        category=category,
        priority=priority,
        payload=payload or {},
    )
    db.add(notification)
    db.flush()
    # FCM send belongs here in production after storing device tokens and
    # validating notification consent. This scaffold persists the event only.
    return notification
