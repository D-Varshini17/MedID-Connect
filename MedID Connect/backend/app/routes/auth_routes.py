from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from app.database import get_db
from app.models.user import User
from app.schemas.auth_schema import LoginRequest, MessageResponse, SignupRequest, TokenResponse
from app.schemas.user_schema import UserRead
from app.services.audit_service import write_audit_log
from app.services.auth_service import authenticate_user, issue_token, register_user
from app.utils.dependencies import get_current_user

router = APIRouter(prefix="/api/auth", tags=["auth"])


@router.post("/signup", response_model=TokenResponse, status_code=status.HTTP_201_CREATED)
def signup(payload: SignupRequest, db: Session = Depends(get_db)) -> TokenResponse:
    user = register_user(db, payload)
    write_audit_log(db, user.id, "signup", "user", str(user.id))
    db.commit()
    return TokenResponse(access_token=issue_token(user), user=UserRead.model_validate(user))


@router.post("/login", response_model=TokenResponse)
def login(payload: LoginRequest, db: Session = Depends(get_db)) -> TokenResponse:
    user = authenticate_user(db, payload.email, payload.password)
    if user is None:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid email or password")
    write_audit_log(db, user.id, "login", "user", str(user.id))
    db.commit()
    return TokenResponse(access_token=issue_token(user), user=UserRead.model_validate(user))


@router.get("/me", response_model=UserRead)
def me(current_user: User = Depends(get_current_user)) -> User:
    return current_user


@router.post("/logout", response_model=MessageResponse)
def logout(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> MessageResponse:
    write_audit_log(db, current_user.id, "logout", "user", str(current_user.id))
    db.commit()
    return MessageResponse(message="Logged out. Delete the client token to complete logout.")
