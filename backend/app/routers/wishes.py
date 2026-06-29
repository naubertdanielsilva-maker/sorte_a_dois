from fastapi import APIRouter, Depends, HTTPException
from sqlmodel import Session, select

from app.database import get_session
from app.models import Wish
from app.schemas import WishCreate, WishRead

router = APIRouter(prefix="/wishes", tags=["wishes"])


@router.get("/couple/{couple_id}", response_model=list[WishRead])
def list_wishes(couple_id: int, session: Session = Depends(get_session)):
    statement = select(Wish).where(Wish.couple_id == couple_id).order_by(Wish.created_at.desc())
    return session.exec(statement).all()


@router.post("/", response_model=WishRead)
def create_wish(wish_data: WishCreate, session: Session = Depends(get_session)):
    wish = Wish(**wish_data.model_dump())
    session.add(wish)
    session.commit()
    session.refresh(wish)
    return wish


@router.delete("/{wish_id}")
def delete_wish(wish_id: int, session: Session = Depends(get_session)):
    wish = session.get(Wish, wish_id)

    if not wish:
        raise HTTPException(status_code=404, detail="Desejo não encontrado.")

    session.delete(wish)
    session.commit()

    return {"message": "Desejo removido com sucesso."}