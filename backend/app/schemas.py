from typing import Optional
from datetime import datetime
from sqlmodel import SQLModel


class LoginRequest(SQLModel):
    email: str
    password: str


class UserCreate(SQLModel):
    name: str
    email: str
    password: str


class UserUpdate(SQLModel):
    name: Optional[str] = None
    email: Optional[str] = None
    password: Optional[str] = None


class UserRead(SQLModel):
    id: int
    name: str
    email: str
    created_at: datetime


class CoupleCreate(SQLModel):
    name: str
    start_date: Optional[datetime] = None


class CoupleRead(SQLModel):
    id: int
    name: str
    start_date: Optional[datetime]
    created_at: datetime


class RaffleCreate(SQLModel):
    couple_id: int
    name: str
    description: Optional[str] = None
    icon: Optional[str] = None
    color: Optional[str] = None
    allow_repeat: bool = False
    created_by_user_id: int


class RaffleRead(SQLModel):
    id: int
    couple_id: int
    name: str
    description: Optional[str]
    icon: Optional[str]
    color: Optional[str]
    allow_repeat: bool
    created_by_user_id: int
    created_at: datetime


class RaffleUpdate(SQLModel):
    name: Optional[str] = None
    description: Optional[str] = None
    icon: Optional[str] = None
    color: Optional[str] = None
    allow_repeat: Optional[bool] = None


class RaffleItemCreate(SQLModel):
    raffle_id: int
    title: str
    description: Optional[str] = None
    is_secret: bool = False
    created_by_user_id: int


class RaffleItemRead(SQLModel):
    id: int
    raffle_id: int
    title: str
    description: Optional[str]
    is_secret: bool
    created_by_user_id: int
    is_drawn: bool
    drawn_at: Optional[datetime]
    is_completed: bool
    completed_at: Optional[datetime]
    rating: Optional[int]
    comment: Optional[str]
    created_at: datetime


class RaffleItemUpdate(SQLModel):
    title: Optional[str] = None
    description: Optional[str] = None
    is_secret: Optional[bool] = None


class RaffleItemComplete(SQLModel):
    rating: Optional[int] = None
    comment: Optional[str] = None


class StatsRead(SQLModel):
    total_raffles: int
    total_items: int
    total_drawn_items: int
    total_completed_items: int
    completion_percentage: float


class MemoryCreate(SQLModel):
    couple_id: int
    title: str
    description: Optional[str] = None
    photo_url: Optional[str] = None
    rating: Optional[int] = None
    latitude: Optional[float] = None
    longitude: Optional[float] = None
    place_name: Optional[str] = None
    created_by_user_id: int


class MemoryRead(SQLModel):
    id: int
    couple_id: int
    title: str
    description: Optional[str]
    photo_url: Optional[str]
    rating: Optional[int]
    latitude: Optional[float]
    longitude: Optional[float]
    place_name: Optional[str]
    created_by_user_id: int
    created_at: datetime
class TokenRead(SQLModel):
    access_token: str
    token_type: str = "bearer"
    user: UserRead
class WishCreate(SQLModel):
    couple_id: int
    title: str
    description: Optional[str] = None
    category: Optional[str] = "Geral"
    created_by_user_id: int


class WishRead(SQLModel):
    id: int
    couple_id: int
    title: str
    description: Optional[str] = None
    category: Optional[str] = None
    created_by_user_id: int
    created_at: datetime