from fastapi import APIRouter, Depends
from sqlmodel import Session, select, func

from app.database import get_session
from app.models import Achievement, PointsLog

router = APIRouter(prefix="/achievements", tags=["Conquistas"])


@router.get("/couple/{couple_id}")
def list_achievements(couple_id: int, session: Session = Depends(get_session)):
    return session.exec(
        select(Achievement).where(Achievement.couple_id == couple_id)
    ).all()


@router.get("/points/couple/{couple_id}")
def get_points(couple_id: int, session: Session = Depends(get_session)):
    logs = session.exec(
        select(PointsLog).where(PointsLog.couple_id == couple_id)
    ).all()

    total = sum(log.points for log in logs)

    return {
        "total_points": total,
        "logs": logs
    }
