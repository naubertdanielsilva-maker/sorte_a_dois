from fastapi import APIRouter, Depends, HTTPException
from sqlmodel import Session, select

from app.database import get_session
from app.models import Wish
from app.schemas import WishCreate, WishRead
from app.services.couple_service import get_main_couple_id

router = APIRouter(prefix="/wishes", tags=["wishes"])


@router.get("/couple/{couple_id}", response_model=list[WishRead])
def list_wishes(couple_id: int, session: Session = Depends(get_session)):
    main_couple_id = get_main_couple_id(session)
    statement = (
        select(Wish)
        .where(Wish.couple_id == main_couple_id)
        .order_by(Wish.created_at.desc())
    )
    return session.exec(statement).all()


@router.post("/", response_model=WishRead)
def create_wish(wish_data: WishCreate, session: Session = Depends(get_session)):
    main_couple_id = get_main_couple_id(session)
    payload = wish_data.model_dump()
    payload["couple_id"] = main_couple_id

    wish = Wish(**payload)
    session.add(wish)
    session.commit()
    session.refresh(wish)
    return wish


@router.delete("/{wish_id}")
def delete_wish(wish_id: int, session: Session = Depends(get_session)):
    main_couple_id = get_main_couple_id(session)
    wish = session.get(Wish, wish_id)

    if not wish or wish.couple_id != main_couple_id:
        raise HTTPException(status_code=404, detail="Desejo não encontrado.")

    session.delete(wish)
    session.commit()

    return {"message": "Desejo removido com sucesso."}
