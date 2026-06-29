from datetime import datetime
from fastapi import APIRouter, Depends, HTTPException
from sqlmodel import Session, select

from app.database import get_session
from app.models import RaffleItem
from app.schemas import RaffleItemCreate, RaffleItemRead, RaffleItemUpdate, RaffleItemComplete

router = APIRouter(prefix="/items", tags=["Itens"])


@router.post("/", response_model=RaffleItemRead)
def create_item(data: RaffleItemCreate, session: Session = Depends(get_session)):
    item = RaffleItem(**data.dict())

    session.add(item)
    session.commit()
    session.refresh(item)

    return item


@router.get("/raffle/{raffle_id}", response_model=list[RaffleItemRead])
def list_items_by_raffle(raffle_id: int, session: Session = Depends(get_session)):
    return session.exec(
        select(RaffleItem).where(RaffleItem.raffle_id == raffle_id)
    ).all()


@router.patch("/{item_id}", response_model=RaffleItemRead)
def update_item(
    item_id: int,
    data: RaffleItemUpdate,
    session: Session = Depends(get_session)
):
    item = session.get(RaffleItem, item_id)

    if not item:
        raise HTTPException(status_code=404, detail="Item não encontrado.")

    update_data = data.dict(exclude_unset=True)

    for key, value in update_data.items():
        setattr(item, key, value)

    session.add(item)
    session.commit()
    session.refresh(item)

    return item


@router.patch("/{item_id}/complete", response_model=RaffleItemRead)
def complete_item(
    item_id: int,
    data: RaffleItemComplete,
    session: Session = Depends(get_session)
):
    item = session.get(RaffleItem, item_id)

    if not item:
        raise HTTPException(status_code=404, detail="Item não encontrado.")

    item.is_completed = True
    item.completed_at = datetime.utcnow()
    item.rating = data.rating
    item.comment = data.comment

    from app.models import Raffle, PointsLog, Achievement

    raffle = session.get(Raffle, item.raffle_id)

    if raffle:
        session.add(PointsLog(
            couple_id=raffle.couple_id,
            user_id=item.created_by_user_id,
            points=10,
            reason=f"Item concluído: {item.title}"
        ))

        existing = session.exec(
            select(Achievement).where(
                Achievement.couple_id == raffle.couple_id,
                Achievement.code == "first_completed"
            )
        ).first()

        if not existing:
            session.add(Achievement(
                couple_id=raffle.couple_id,
                code="first_completed",
                title="Primeira aventura concluída",
                description="Vocês concluíram o primeiro item sorteado."
            ))
    session.add(item)
    session.commit()
    session.refresh(item)

    return item


@router.patch("/{item_id}/undo-complete", response_model=RaffleItemRead)
def undo_complete_item(item_id: int, session: Session = Depends(get_session)):
    item = session.get(RaffleItem, item_id)

    if not item:
        raise HTTPException(status_code=404, detail="Item não encontrado.")

    item.is_completed = False
    item.completed_at = None
    item.rating = None
    item.comment = None

    session.add(item)
    session.commit()
    session.refresh(item)

    return item


@router.delete("/{item_id}")
def delete_item(item_id: int, session: Session = Depends(get_session)):
    item = session.get(RaffleItem, item_id)

    if not item:
        raise HTTPException(status_code=404, detail="Item não encontrado.")

    session.delete(item)
    session.commit()

    return {"mensagem": "Item excluído com sucesso."}
