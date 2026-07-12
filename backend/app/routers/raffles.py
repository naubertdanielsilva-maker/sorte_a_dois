from fastapi import APIRouter, Depends, HTTPException
from sqlmodel import Session, select

from app.database import get_session
from app.models import DrawHistory, Raffle, RaffleItem
from app.schemas import RaffleCreate, RaffleRead, RaffleUpdate
from app.services.couple_service import get_main_couple_id

router = APIRouter(prefix="/raffles", tags=["Sorteios"])


@router.post("/", response_model=RaffleRead)
def create_raffle(data: RaffleCreate, session: Session = Depends(get_session)):
    payload = data.model_dump()
    payload["couple_id"] = get_main_couple_id(session)

    raffle = Raffle(**payload)
    session.add(raffle)
    session.commit()
    session.refresh(raffle)
    return raffle


@router.get("/", response_model=list[RaffleRead])
def list_raffles(session: Session = Depends(get_session)):
    couple_id = get_main_couple_id(session)
    statement = (
        select(Raffle)
        .where(Raffle.couple_id == couple_id)
        .order_by(Raffle.created_at.desc())
    )
    return session.exec(statement).all()


@router.get("/{raffle_id}", response_model=RaffleRead)
def get_raffle(raffle_id: int, session: Session = Depends(get_session)):
    couple_id = get_main_couple_id(session)
    raffle = session.get(Raffle, raffle_id)

    if not raffle or raffle.couple_id != couple_id:
        raise HTTPException(status_code=404, detail="Sorteio não encontrado.")

    return raffle


@router.patch("/{raffle_id}", response_model=RaffleRead)
def update_raffle(
    raffle_id: int,
    data: RaffleUpdate,
    session: Session = Depends(get_session),
):
    couple_id = get_main_couple_id(session)
    raffle = session.get(Raffle, raffle_id)

    if not raffle or raffle.couple_id != couple_id:
        raise HTTPException(status_code=404, detail="Sorteio não encontrado.")

    update_data = data.model_dump(exclude_unset=True)

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

    histories = session.exec(
        select(DrawHistory).where(DrawHistory.raffle_id == raffle_id)
    ).all()

    for history in histories:
        session.delete(history)

    items = session.exec(
        select(RaffleItem).where(RaffleItem.raffle_id == raffle_id)
    ).all()

    for item in items:
        session.delete(item)

    session.delete(raffle)
    session.commit()

    return {"mensagem": "Sorteio e itens vinculados excluídos com sucesso."}