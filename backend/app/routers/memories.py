from fastapi import APIRouter, Depends, HTTPException
from sqlmodel import Session, select

from app.database import get_session
from app.models import Memory, PointsLog, Achievement
from app.schemas import MemoryCreate, MemoryRead
from app.services.couple_service import get_main_couple_id

router = APIRouter(prefix="/memories", tags=["Memórias"])


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


@router.post("/", response_model=MemoryRead)
def create_memory(data: MemoryCreate, session: Session = Depends(get_session)):
    couple_id = get_main_couple_id(session)
    payload = data.dict()
    payload["couple_id"] = couple_id

    memory = Memory(**payload)

    session.add(memory)
    session.add(PointsLog(
        couple_id=couple_id,
        user_id=data.created_by_user_id,
        points=15,
        reason="Memória criada"
    ))

    unlock(
        session,
        couple_id,
        "first_memory",
        "Primeira memória",
        "Vocês registraram a primeira memória no aplicativo."
    )

    session.commit()
    session.refresh(memory)

    return memory


@router.get("/couple/{couple_id}", response_model=list[MemoryRead])
def list_memories(couple_id: int, session: Session = Depends(get_session)):
    main_couple_id = get_main_couple_id(session)
    return session.exec(
        select(Memory).where(Memory.couple_id == main_couple_id)
    ).all()


@router.delete("/{memory_id}")
def delete_memory(memory_id: int, session: Session = Depends(get_session)):
    couple_id = get_main_couple_id(session)
    memory = session.get(Memory, memory_id)

    if not memory or memory.couple_id != couple_id:
        raise HTTPException(status_code=404, detail="Memória não encontrada.")

    session.delete(memory)
    session.commit()

    return {"mensagem": "Memória excluída com sucesso."}
