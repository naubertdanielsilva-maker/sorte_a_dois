from fastapi import APIRouter, Depends
from sqlmodel import Session, select

from app.database import get_session
from app.models import User, Couple, CoupleMember, Raffle, Memory, Wish

router = APIRouter(prefix="/debug", tags=["Debug"])


def get_or_create_main_couple(session: Session) -> Couple:
    couple = session.exec(select(Couple)).first()

    if couple:
        couple.name = "N & A"
        session.add(couple)
        session.commit()
        session.refresh(couple)
        return couple

    couple = Couple(name="N & A")
    session.add(couple)
    session.commit()
    session.refresh(couple)
    return couple


@router.get("/fix-shared-couple")
def fix_shared_couple(session: Session = Depends(get_session)):
    couple = get_or_create_main_couple(session)

    users = session.exec(select(User)).all()

    for user in users:
        existing = session.exec(
            select(CoupleMember).where(
                CoupleMember.user_id == user.id,
                CoupleMember.couple_id == couple.id,
            )
        ).first()

        if not existing:
            member = CoupleMember(
                user_id=user.id,
                couple_id=couple.id,
            )
            session.add(member)

    raffles = session.exec(select(Raffle)).all()
    for raffle in raffles:
        raffle.couple_id = couple.id
        session.add(raffle)

    memories = session.exec(select(Memory)).all()
    for memory in memories:
        memory.couple_id = couple.id
        session.add(memory)

    wishes = session.exec(select(Wish)).all()
    for wish in wishes:
        wish.couple_id = couple.id
        session.add(wish)

    session.commit()

    return {
        "message": "Todos os usuários e dados foram vinculados ao casal N & A.",
        "couple_id": couple.id,
        "users": len(users),
        "raffles": len(raffles),
        "memories": len(memories),
        "wishes": len(wishes),
    }


@router.get("/users")
def list_debug_users(session: Session = Depends(get_session)):
    users = session.exec(select(User)).all()
    couples = session.exec(select(Couple)).all()
    members = session.exec(select(CoupleMember)).all()

    return {
        "users": [
            {
                "id": user.id,
                "name": user.name,
                "email": user.email,
                "couples": [
                    {
                        "couple_id": member.couple_id,
                        "couple_name": next(
                            (c.name for c in couples if c.id == member.couple_id),
                            None,
                        ),
                    }
                    for member in members
                    if member.user_id == user.id
                ],
            }
            for user in users
        ],
        "couples": [
            {"id": couple.id, "name": couple.name}
            for couple in couples
        ],
    }