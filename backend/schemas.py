from pydantic import BaseModel
from typing import Optional
from datetime import date, datetime


class RoomOut(BaseModel):
    id: int
    name: str
    description: Optional[str]
    emoji: Optional[str]
    color: Optional[str]
    word_count: int = 0
    verb_count: int = 0
    known_count: int = 0
    due_today: int = 0
    class Config: from_attributes = True


class WordOut(BaseModel):
    id: int
    room_id: int
    croatian: str
    polish: str
    category: Optional[str]
    difficulty: Optional[int]
    example_hr: Optional[str]
    example_pl: Optional[str]
    status: str = "nowe"
    next_review: Optional[date]
    class Config: from_attributes = True


class VerbOut(BaseModel):
    id: int
    room_id: int
    infinitive: str
    polish: str
    conj_ja: Optional[str]
    conj_ti: Optional[str]
    conj_on: Optional[str]
    conj_mi: Optional[str]
    conj_vi: Optional[str]
    conj_oni: Optional[str]
    example_hr: Optional[str]
    example_pl: Optional[str]
    status: str = "nowe"
    next_review: Optional[date]
    class Config: from_attributes = True


class ProgressIn(BaseModel):
    item_type: str
    item_id: int
    room_id: int
    answer: str  # "nie wiem" | "prawie" | "wiem"


class StartLearning(BaseModel):
    item_type: str
    item_id: int
    room_id: int


class ProgressOut(BaseModel):
    id: int
    item_type: str
    item_id: int
    room_id: int
    status: str
    next_review: Optional[date]
    review_count: int
    class Config: from_attributes = True


class SentenceIn(BaseModel):
    room_id: int
    text_hr: str
    text_pl: Optional[str]
    note: Optional[str]
    status: Optional[str] = "do sprawdzenia"


class SentenceOut(BaseModel):
    id: int
    room_id: int
    text_hr: str
    text_pl: Optional[str]
    note: Optional[str]
    status: str
    created_at: Optional[datetime]
    class Config: from_attributes = True
