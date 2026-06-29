from fastapi import APIRouter, Depends
from sqlmodel import Session, select

from app.database import get_session
from app.models import Couple
from app.schemas import CoupleCreate, CoupleRead

router = APIRouter(prefix="/couples", tags=["Casal"])


@router.post("/", response_model=CoupleRead)
def create_couple(couple_data: CoupleCreate, session: Session = Depends(get_session)):
    couple = Couple(
        name=couple_data.name,
        start_date=couple_data.start_date
    )

    session.add(couple)
    session.commit()
    session.refresh(couple)

    return couple


@router.get("/", response_model=list[CoupleRead])
def list_couples(session: Session = Depends(get_session)):
    couples = session.exec(select(Couple)).all()
    return couples
