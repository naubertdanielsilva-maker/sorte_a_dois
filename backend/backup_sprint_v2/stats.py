from fastapi import APIRouter, Depends
from sqlmodel import Session, select

from app.database import get_session
from app.models import Raffle, RaffleItem
from app.schemas import StatsRead

router = APIRouter(prefix="/stats", tags=["Estatísticas"])


@router.get("/couple/{couple_id}", response_model=StatsRead)
def get_couple_stats(couple_id: int, session: Session = Depends(get_session)):
    raffles = session.exec(
        select(Raffle).where(Raffle.couple_id == couple_id)
    ).all()

    raffle_ids = [raffle.id for raffle in raffles]

    if not raffle_ids:
        return StatsRead(
            total_raffles=0,
            total_items=0,
            total_drawn_items=0,
            total_completed_items=0,
            completion_percentage=0
        )

    items = session.exec(
        select(RaffleItem).where(RaffleItem.raffle_id.in_(raffle_ids))
    ).all()

    total_items = len(items)
    total_drawn_items = len([item for item in items if item.is_drawn])
    total_completed_items = len([item for item in items if item.is_completed])

    completion_percentage = 0

    if total_items > 0:
        completion_percentage = round((total_completed_items / total_items) * 100, 2)

    return StatsRead(
        total_raffles=len(raffles),
        total_items=total_items,
        total_drawn_items=total_drawn_items,
        total_completed_items=total_completed_items,
        completion_percentage=completion_percentage
    )
