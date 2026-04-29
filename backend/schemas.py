from pydantic import BaseModel, EmailStr, field_validator
from typing import Optional
from datetime import date, datetime


# ─── AUTH ────────────────────────────────────────────────────────────────────

class RegisterIn(BaseModel):
    username: str
    email: EmailStr
    password: str

    @field_validator("username")
    @classmethod
    def username_rules(cls, v: str) -> str:
        v = v.strip()
        if len(v) < 3:
            raise ValueError("Nazwa użytkownika musi mieć min. 3 znaki")
        if len(v) > 32:
            raise ValueError("Nazwa użytkownika max 32 znaki")
        return v

    @field_validator("password")
    @classmethod
    def password_rules(cls, v: str) -> str:
        if len(v) < 4:
            raise ValueError("Hasło musi mieć min. 4 znaki")
        return v


class LoginIn(BaseModel):
    # Logowanie po username albo email — jedno z tych pól musi być podane.
    identifier: str  # username lub email
    password: str


class TokenOut(BaseModel):
    access_token: str
    token_type: str = "bearer"


class UserOut(BaseModel):
    id: int
    username: str
    email: EmailStr
    selected_language: str = "hr"
    theme: str = "dark"
    avatar: Optional[str] = None
    created_at: Optional[datetime]
    class Config: from_attributes = True


# ─── LANGUAGES ───────────────────────────────────────────────────────────────

class LanguageOut(BaseModel):
    code: str
    name: str
    title: str
    flag: str
    has_content: bool = False
    is_current: bool = False


class LanguageSelectIn(BaseModel):
    language: str


# ─── USER SETTINGS ───────────────────────────────────────────────────────────

class SettingsIn(BaseModel):
    theme: Optional[str] = None   # "dark" | "light"
    avatar: Optional[str] = None  # emoji / krótki tekst; "" = wyczyść


# ─── DATA ────────────────────────────────────────────────────────────────────

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
    is_locked: bool = False
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
    text_pl: Optional[str] = None
    note: Optional[str] = None
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
