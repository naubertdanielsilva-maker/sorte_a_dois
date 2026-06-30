from sqlmodel import Session, select

from app.models import User, Couple, CoupleMember


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


def ensure_user_in_main_couple(user: User, session: Session) -> Couple:
    couple = get_or_create_main_couple(session)

    existing = session.exec(
        select(CoupleMember).where(
            CoupleMember.user_id == user.id,
            CoupleMember.couple_id == couple.id,
        )
    ).first()

    if not existing:
        session.add(CoupleMember(user_id=user.id, couple_id=couple.id))
        session.commit()

    return couple


def get_main_couple_id(session: Session) -> int:
    return get_or_create_main_couple(session).id
