from fastapi import APIRouter, Depends, HTTPException
from sqlmodel import Session, select

from app.database import get_session
from app.models import User, Couple, CoupleMember
from app.schemas import UserCreate, UserRead, UserUpdate
from app.security import hash_password, require_admin

router = APIRouter(prefix="/users", tags=["Usuários"])


def get_or_create_default_couple(session: Session) -> Couple:
    couple = session.exec(select(Couple)).first()

    if couple:
        return couple

    couple = Couple(
        name="N & A",
    )

    session.add(couple)
    session.commit()
    session.refresh(couple)

    return couple


@router.post("/", response_model=UserRead)
def create_user(user_data: UserCreate, session: Session = Depends(get_session)):
    existing_user = session.exec(
        select(User).where(User.email == user_data.email)
    ).first()

    if existing_user:
        raise HTTPException(status_code=400, detail="E-mail já cadastrado.")

    user = User(
        name=user_data.name,
        email=user_data.email,
        password=hash_password(user_data.password),
    )

    session.add(user)
    session.commit()
    session.refresh(user)

    couple = get_or_create_default_couple(session)

    existing_member = session.exec(
        select(CoupleMember).where(
            CoupleMember.user_id == user.id,
            CoupleMember.couple_id == couple.id,
        )
    ).first()

    if not existing_member:
        member = CoupleMember(
            user_id=user.id,
            couple_id=couple.id,
        )
        session.add(member)
        session.commit()

    return user


@router.get("/", response_model=list[UserRead])
def list_users(
    session: Session = Depends(get_session),
    admin_user: User = Depends(require_admin)
):
    return session.exec(select(User)).all()


@router.patch("/{user_id}", response_model=UserRead)
def update_user(
    user_id: int,
    user_data: UserUpdate,
    session: Session = Depends(get_session),
    admin_user: User = Depends(require_admin)
):
    user = session.get(User, user_id)

    if not user:
        raise HTTPException(status_code=404, detail="Usuário não encontrado.")

    if user_data.email and user_data.email != user.email:
        existing_user = session.exec(
            select(User).where(User.email == user_data.email)
        ).first()

        if existing_user:
            raise HTTPException(status_code=400, detail="Este e-mail já está em uso.")

        user.email = user_data.email

    if user_data.name:
        user.name = user_data.name

    if user_data.password:
        user.password = hash_password(user_data.password)

    session.add(user)
    session.commit()
    session.refresh(user)

    return user