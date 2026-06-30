from fastapi import APIRouter, Depends, HTTPException
from sqlmodel import Session, select

from app.database import get_session
from app.models import Raffle, RaffleItem
from app.schemas import RaffleCreate, RaffleRead, RaffleUpdate
from app.services.couple_service import get_main_couple_id

router = APIRouter(prefix="/raffles", tags=["Sorteios"])


@router.post("/", response_model=RaffleRead)
def create_raffle(data: RaffleCreate, session: Session = Depends(get_session)):
    payload = data.dict()
    payload["couple_id"] = get_main_couple_id(session)

    raffle = Raffle(**payload)
    session.add(raffle)
    session.commit()
    session.refresh(raffle)
    return raffle


@router.get("/", response_model=list[RaffleRead])
def list_raffles(session: Session = Depends(get_session)):
    couple_id = get_main_couple_id(session)
    return session.exec(select(Raffle).where(Raffle.couple_id == couple_id)).all()


@router.get("/{raffle_id}", response_model=RaffleRead)
def get_raffle(raffle_id: int, session: Session = Depends(get_session)):
    couple_id = get_main_couple_id(session)
    raffle = session.get(Raffle, raffle_id)

    if not raffle or raffle.couple_id != couple_id:
        raise HTTPException(status_code=404, detail="Sorteio não encontrado.")

    return raffle


@router.patch("/{raffle_id}", response_model=RaffleRead)
def update_raffle(raffle_id: int, data: RaffleUpdate, session: Session = Depends(get_session)):
    couple_id = get_main_couple_id(session)
    raffle = session.get(Raffle, raffle_id)

    if not raffle or raffle.couple_id != couple_id:
        raise HTTPException(status_code=404, detail="Sorteio não encontrado.")

    update_data = data.dict(exclude_unset=True)
    update_data.pop("couple_id", None)

    for key, value in update_data.items():
        setattr(raffle, key, value)

    raffle.couple_id = couple_id

    session.add(raffle)
    session.commit()
    session.refresh(raffle)

    return raffle


@router.delete("/{raffle_id}")
def delete_raffle(raffle_id: int, session: Session = Depends(get_session)):
    couple_id = get_main_couple_id(session)
    raffle = session.get(Raffle, raffle_id)

    if not raffle or raffle.couple_id != couple_id:
        raise HTTPException(status_code=404, detail="Sorteio não encontrado.")

    items = session.exec(select(RaffleItem).where(RaffleItem.raffle_id == raffle_id)).all()

    for item in items:
        session.delete(item)

    session.delete(raffle)
    session.commit()

    return {"mensagem": "Sorteio e itens vinculados excluídos com sucesso."}
