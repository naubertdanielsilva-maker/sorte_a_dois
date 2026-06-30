from fastapi import APIRouter, Depends, HTTPException
from sqlmodel import Session, select

from app.database import get_session
from app.models import User, Couple, CoupleMember
from app.schemas import LoginRequest
from app.security import verify_password, create_access_token

router = APIRouter(prefix="/auth", tags=["Auth"])


def get_or_create_default_couple(session: Session) -> Couple:
    couple = session.exec(select(Couple)).first()

    if couple:
        return couple

    couple = Couple(name="N & A")
    session.add(couple)
    session.commit()
    session.refresh(couple)

    return couple


def ensure_user_has_couple(user: User, session: Session) -> Couple:
    existing_member = session.exec(
        select(CoupleMember).where(CoupleMember.user_id == user.id)
    ).first()

    if existing_member:
        return session.get(Couple, existing_member.couple_id)

    couple = get_or_create_default_couple(session)

    member = CoupleMember(
        user_id=user.id,
        couple_id=couple.id,
    )

    session.add(member)
    session.commit()

    return couple


@router.post("/login")
def login(data: LoginRequest, session: Session = Depends(get_session)):
    user = session.exec(
        select(User).where(User.email == data.email)
    ).first()

    if not user:
        raise HTTPException(status_code=401, detail="E-mail ou senha inválidos.")

    if not verify_password(data.password, user.password):
        raise HTTPException(status_code=401, detail="E-mail ou senha inválidos.")

    ensure_user_has_couple(user, session)

    token = create_access_token({"sub": str(user.id)})

    return {
        "access_token": token,
        "token_type": "bearer",
        "user": {
            "id": user.id,
            "name": user.name,
            "email": user.email,
        },
    }