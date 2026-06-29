from fastapi import APIRouter, Depends, HTTPException
from sqlmodel import Session, select

from app.database import get_session
from app.models import User
from app.schemas import LoginRequest, TokenRead, UserRead
from app.security import verify_password, create_access_token, get_current_user

router = APIRouter(prefix="/auth", tags=["Login"])


@router.post("/login", response_model=TokenRead)
def login(data: LoginRequest, session: Session = Depends(get_session)):
    user = session.exec(select(User).where(User.email == data.email)).first()

    if not user or not verify_password(data.password, user.password):
        raise HTTPException(status_code=401, detail="E-mail ou senha inválidos.")

    token = create_access_token({"sub": str(user.id)})

    return {
        "access_token": token,
        "token_type": "bearer",
        "user": user
    }


@router.get("/me", response_model=UserRead)
def me(current_user: User = Depends(get_current_user)):
    return current_user