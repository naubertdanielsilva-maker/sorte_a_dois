from datetime import datetime

from fastapi import APIRouter, Depends, HTTPException
from sqlmodel import Session, select

from app.database import get_session
from app.models import Achievement, DrawHistory, PointsLog, Raffle, RaffleItem
from app.schemas import (
    RaffleItemComplete,
    RaffleItemCreate,
    RaffleItemRead,
    RaffleItemUpdate,
)
from app.services.couple_service import get_main_couple_id

router = APIRouter(prefix="/items", tags=["Itens"])


def get_valid_raffle(
    raffle_id: int,
    session: Session,
) -> Raffle:
    couple_id = get_main_couple_id(session)
    raffle = session.get(Raffle, raffle_id)

    if not raffle or raffle.couple_id != couple_id:
        raise HTTPException(status_code=404, detail="Sorteio nÃ£o encontrado.")

    return raffle


def get_valid_item(
    item_id: int,
    session: Session,
) -> tuple[RaffleItem, Raffle]:
    item = session.get(RaffleItem, item_id)

    if not item:
        raise HTTPException(status_code=404, detail="Item nÃ£o encontrado.")

    raffle = get_valid_raffle(item.raffle_id, session)
    return item, raffle


@router.post("/", response_model=RaffleItemRead)
def create_item(
    data: RaffleItemCreate,
    session: Session = Depends(get_session),
):
    get_valid_raffle(data.raffle_id, session)

    item = RaffleItem(**data.model_dump())
    session.add(item)
    session.commit()
    session.refresh(item)
    return item


@router.get("/raffle/{raffle_id}", response_model=list[RaffleItemRead])
def list_items_by_raffle(
    raffle_id: int,
    session: Session = Depends(get_session),
):
    get_valid_raffle(raffle_id, session)

    statement = (
        select(RaffleItem)
        .where(RaffleItem.raffle_id == raffle_id)
        .order_by(RaffleItem.created_at.desc())
    )
    return session.exec(statement).all()


@router.patch("/{item_id}", response_model=RaffleItemRead)
def update_item(
    item_id: int,
    data: RaffleItemUpdate,
    session: Session = Depends(get_session),
):
    item, _ = get_valid_item(item_id, session)
    update_data = data.model_dump(exclude_unset=True)

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
    session: Session = Depends(get_session),
):
    item, raffle = get_valid_item(item_id, session)

    item.is_completed = True
    item.completed_at = datetime.utcnow()
    item.rating = data.rating
    item.comment = data.comment

    session.add(
        PointsLog(
            couple_id=raffle.couple_id,
            user_id=item.created_by_user_id,
            points=10,
            reason=f"Item concluÃ­do: {item.title}",
        )
    )

    existing = session.exec(
        select(Achievement).where(
            Achievement.couple_id == raffle.couple_id,
            Achievement.code == "first_completed",
        )
    ).first()

    if not existing:
        session.add(
            Achievement(
                couple_id=raffle.couple_id,
                code="first_completed",
                title="Primeira aventura concluÃ­da",
                description="VocÃªs concluÃ­ram o primeiro item sorteado.",
            )
        )

    session.add(item)
    session.commit()
    session.refresh(item)
    return item


@router.patch("/{item_id}/undo-complete", response_model=RaffleItemRead)
def undo_complete_item(
    item_id: int,
    session: Session = Depends(get_session),
):
    item, _ = get_valid_item(item_id, session)

    item.is_completed = False
    item.completed_at = None
    item.rating = None
    item.comment = None

    session.add(item)
    session.commit()
    session.refresh(item)
    return item


@router.delete("/{item_id}")
def delete_item(
    item_id: int,
    session: Session = Depends(get_session),
):
    item, _ = get_valid_item(item_id, session)

    histories = session.exec(
        select(DrawHistory).where(DrawHistory.item_id == item_id)
    ).all()

    for history in histories:
        session.delete(history)

    session.delete(item)
    session.commit()

    return {"mensagem": "Item excluÃ­do com sucesso."}