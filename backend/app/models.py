from datetime import datetime
from typing import Optional
from sqlmodel import SQLModel, Field


class User(SQLModel, table=True):
    id: Optional[int] = Field(default=None, primary_key=True)
    name: str
    email: str = Field(index=True, unique=True)
    password: str
    created_at: datetime = Field(default_factory=datetime.utcnow)


class Couple(SQLModel, table=True):
    id: Optional[int] = Field(default=None, primary_key=True)
    name: str
    start_date: Optional[datetime] = None
    created_at: datetime = Field(default_factory=datetime.utcnow)


class CoupleMember(SQLModel, table=True):
    id: Optional[int] = Field(default=None, primary_key=True)
    couple_id: int = Field(foreign_key="couple.id")
    user_id: int = Field(foreign_key="user.id")


class Raffle(SQLModel, table=True):
    id: Optional[int] = Field(default=None, primary_key=True)
    couple_id: int = Field(foreign_key="couple.id")
    name: str
    description: Optional[str] = None
    icon: Optional[str] = None
    color: Optional[str] = None
    allow_repeat: bool = False
    created_by_user_id: int = Field(foreign_key="user.id")
    created_at: datetime = Field(default_factory=datetime.utcnow)


class RaffleItem(SQLModel, table=True):
    id: Optional[int] = Field(default=None, primary_key=True)
    raffle_id: int = Field(foreign_key="raffle.id")
    title: str
    description: Optional[str] = None
    is_secret: bool = False
    created_by_user_id: int = Field(foreign_key="user.id")
    is_drawn: bool = False
    drawn_at: Optional[datetime] = None
    is_completed: bool = False
    completed_at: Optional[datetime] = None
    rating: Optional[int] = None
    comment: Optional[str] = None
    created_at: datetime = Field(default_factory=datetime.utcnow)


class DrawHistory(SQLModel, table=True):
    id: Optional[int] = Field(default=None, primary_key=True)
    raffle_id: int = Field(foreign_key="raffle.id")
    item_id: int = Field(foreign_key="raffleitem.id")
    couple_id: int = Field(foreign_key="couple.id")
    drawn_by_user_id: int = Field(foreign_key="user.id")
    drawn_at: datetime = Field(default_factory=datetime.utcnow)


class PointsLog(SQLModel, table=True):
    id: Optional[int] = Field(default=None, primary_key=True)
    couple_id: int = Field(foreign_key="couple.id")
    user_id: Optional[int] = Field(default=None, foreign_key="user.id")
    points: int
    reason: str
    created_at: datetime = Field(default_factory=datetime.utcnow)


class Achievement(SQLModel, table=True):
    id: Optional[int] = Field(default=None, primary_key=True)
    couple_id: int = Field(foreign_key="couple.id")
    code: str
    title: str
    description: Optional[str] = None
    unlocked_at: datetime = Field(default_factory=datetime.utcnow)


class Memory(SQLModel, table=True):
    id: Optional[int] = Field(default=None, primary_key=True)
    couple_id: int = Field(foreign_key="couple.id")
    title: str
    description: Optional[str] = None
    photo_url: Optional[str] = None
    rating: Optional[int] = None
    latitude: Optional[float] = None
    longitude: Optional[float] = None
    place_name: Optional[str] = None
    created_by_user_id: int = Field(foreign_key="user.id")
    created_at: datetime = Field(default_factory=datetime.utcnow)
class Wish(SQLModel, table=True):
    id: Optional[int] = Field(default=None, primary_key=True)
    couple_id: int = Field(foreign_key="couple.id")
    title: str
    description: Optional[str] = None
    category: Optional[str] = "Geral"
    created_by_user_id: int = Field(foreign_key="user.id")
    created_at: datetime = Field(default_factory=datetime.utcnow)