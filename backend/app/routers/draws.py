import random
from datetime import datetime

from fastapi import APIRouter, Depends, HTTPException
from sqlmodel import Session, select

from app.database import get_session
from app.models import Raffle, RaffleItem, DrawHistory, PointsLog, Achievement

router = APIRouter(prefix="/draws", tags=["Sorteio"])


def unlock(session: Session, couple_id: int, code: str, title: str, description: str):
    existing = session.exec(
        select(Achievement).where(
            Achievement.couple_id == couple_id,
            Achievement.code == code
        )
    ).first()

    if not existing:
        session.add(Achievement(
            couple_id=couple_id,
            code=code,
            title=title,
            description=description
        ))


@router.post("/{raffle_id}")
def draw_item(
    raffle_id: int,
    user_id: int,
    session: Session = Depends(get_session)
):
    raffle = session.get(Raffle, raffle_id)

    if not raffle:
        raise HTTPException(status_code=404, detail="Sorteio não encontrado.")

    query = select(RaffleItem).where(RaffleItem.raffle_id == raffle_id)

    if not raffle.allow_repeat:
        query = query.where(RaffleItem.is_drawn == False)

    available_items = session.exec(query).all()

    if not available_items:
        raise HTTPException(
            status_code=400,
            detail="Não existem mais itens disponíveis. Faça o reset desse sorteio."
        )

    selected_item = random.choice(available_items)

    selected_item.is_drawn = True
    selected_item.drawn_at = datetime.utcnow()

    history = DrawHistory(
        raffle_id=raffle.id,
        item_id=selected_item.id,
        couple_id=raffle.couple_id,
        drawn_by_user_id=user_id
    )

    session.add(selected_item)
    session.add(history)
    session.add(PointsLog(
        couple_id=raffle.couple_id,
        user_id=user_id,
        points=5,
        reason=f"Sorteio realizado: {raffle.name}"
    ))

    unlock(
        session,
        raffle.couple_id,
        "first_draw",
        "Primeiro sorteio",
        "Vocês realizaram o primeiro sorteio."
    )

    session.commit()
    session.refresh(selected_item)

    return {
        "mensagem": "Sorteio realizado com sucesso!",
        "sorteado": selected_item
    }


@router.post("/{raffle_id}/reset")
def reset_draw(raffle_id: int, session: Session = Depends(get_session)):
    items = session.exec(
        select(RaffleItem).where(RaffleItem.raffle_id == raffle_id)
    ).all()

    for item in items:
        item.is_drawn = False
        item.drawn_at = None
        session.add(item)

    session.commit()

    return {
        "mensagem": "Sorteio resetado com sucesso.",
        "quantidade_itens_resetados": len(items)
    }


@router.get("/history/couple/{couple_id}")
def get_draw_history(couple_id: int, session: Session = Depends(get_session)):
    history = session.exec(
        select(DrawHistory).where(DrawHistory.couple_id == couple_id)
    ).all()

    return history
@router.get("/history-detailed/couple/{couple_id}")
def get_detailed_draw_history(couple_id: int, session: Session = Depends(get_session)):
    history = session.exec(
        select(DrawHistory).where(DrawHistory.couple_id == couple_id)
    ).all()

    result = []

    for h in history:
        raffle = session.get(Raffle, h.raffle_id)
        item = session.get(RaffleItem, h.item_id)

        result.append({
            "id": h.id,
            "raffle_name": raffle.name if raffle else "Sorteio removido",
            "item_title": item.title if item else "Item removido",
            "item_description": item.description if item else "",
            "drawn_at": h.drawn_at,
            "drawn_by_user_id": h.drawn_by_user_id
        })

    return result
