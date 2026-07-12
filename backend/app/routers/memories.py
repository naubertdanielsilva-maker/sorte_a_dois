from fastapi import APIRouter, Depends, HTTPException
from sqlmodel import Session, select

from app.database import get_session
from app.models import Achievement, Memory, PointsLog
from app.schemas import MemoryCreate, MemoryRead, MemoryUpdate
from app.services.couple_service import get_main_couple_id

router = APIRouter(prefix="/memories", tags=["MemÃ³rias"])


def unlock(
    session: Session,
    couple_id: int,
    code: str,
    title: str,
    description: str,
):
    existing = session.exec(
        select(Achievement).where(
            Achievement.couple_id == couple_id,
            Achievement.code == code,
        )
    ).first()

    if not existing:
        session.add(
            Achievement(
                couple_id=couple_id,
                code=code,
                title=title,
                description=description,
            )
        )


@router.post("/", response_model=MemoryRead)
def create_memory(data: MemoryCreate, session: Session = Depends(get_session)):
    couple_id = get_main_couple_id(session)
    payload = data.model_dump()
    payload["couple_id"] = couple_id

    memory = Memory(**payload)

    session.add(memory)
    session.add(
        PointsLog(
            couple_id=couple_id,
            user_id=data.created_by_user_id,
            points=15,
            reason="MemÃ³ria criada",
        )
    )

    unlock(
        session,
        couple_id,
        "first_memory",
        "Primeira memÃ³ria",
        "VocÃªs registraram a primeira memÃ³ria no aplicativo.",
    )

    session.commit()
    session.refresh(memory)
    return memory


@router.get("/couple/{couple_id}", response_model=list[MemoryRead])
def list_memories(couple_id: int, session: Session = Depends(get_session)):
    main_couple_id = get_main_couple_id(session)
    statement = (
        select(Memory)
        .where(Memory.couple_id == main_couple_id)
        .order_by(Memory.created_at.desc())
    )
    return session.exec(statement).all()


@router.patch("/{memory_id}", response_model=MemoryRead)
def update_memory(
    memory_id: int,
    data: MemoryUpdate,
    session: Session = Depends(get_session),
):
    couple_id = get_main_couple_id(session)
    memory = session.get(Memory, memory_id)

    if not memory or memory.couple_id != couple_id:
        raise HTTPException(status_code=404, detail="MemÃ³ria nÃ£o encontrada.")

    update_data = data.model_dump(exclude_unset=True)

    for key, value in update_data.items():
        setattr(memory, key, value)

    memory.couple_id = couple_id

    session.add(memory)
    session.commit()
    session.refresh(memory)
    return memory


@router.delete("/{memory_id}")
def delete_memory(memory_id: int, session: Session = Depends(get_session)):
    couple_id = get_main_couple_id(session)
    memory = session.get(Memory, memory_id)

    if not memory or memory.couple_id != couple_id:
        raise HTTPException(status_code=404, detail="MemÃ³ria nÃ£o encontrada.")

    session.delete(memory)
    session.commit()

    return {"mensagem": "MemÃ³ria excluÃ­da com sucesso."}