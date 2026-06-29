from fastapi import APIRouter, Depends, HTTPException
from sqlmodel import Session, select

from app.database import get_session
from app.models import Raffle, RaffleItem
from app.schemas import RaffleCreate, RaffleRead, RaffleUpdate

router = APIRouter(prefix="/raffles", tags=["Sorteios"])


@router.post("/", response_model=RaffleRead)
def create_raffle(data: RaffleCreate, session: Session = Depends(get_session)):
    raffle = Raffle(**data.dict())
    session.add(raffle)
    session.commit()
    session.refresh(raffle)
    return raffle


@router.get("/", response_model=list[RaffleRead])
def list_raffles(session: Session = Depends(get_session)):
    return session.exec(select(Raffle)).all()


@router.get("/{raffle_id}", response_model=RaffleRead)
def get_raffle(raffle_id: int, session: Session = Depends(get_session)):
    raffle = session.get(Raffle, raffle_id)

    if not raffle:
        raise HTTPException(status_code=404, detail="Sorteio não encontrado.")

    return raffle


@router.patch("/{raffle_id}", response_model=RaffleRead)
def update_raffle(
    raffle_id: int,
    data: RaffleUpdate,
    session: Session = Depends(get_session)
):
    raffle = session.get(Raffle, raffle_id)

    if not raffle:
        raise HTTPException(status_code=404, detail="Sorteio não encontrado.")

    update_data = data.dict(exclude_unset=True)

    for key, value in update_data.items():
        setattr(raffle, key, value)

    session.add(raffle)
    session.commit()
    session.refresh(raffle)

    return raffle


@router.delete("/{raffle_id}")
def delete_raffle(raffle_id: int, session: Session = Depends(get_session)):
    raffle = session.get(Raffle, raffle_id)

    if not raffle:
        raise HTTPException(status_code=404, detail="Sorteio não encontrado.")

    items = session.exec(
        select(RaffleItem).where(RaffleItem.raffle_id == raffle_id)
    ).all()

    for item in items:
        session.delete(item)

    session.delete(raffle)
    session.commit()

    return {"mensagem": "Sorteio e itens vinculados excluídos com sucesso."}
