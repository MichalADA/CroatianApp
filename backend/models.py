from sqlalchemy import Column, Integer, String, Date, DateTime, ForeignKey, Text
from sqlalchemy.sql import func
from database import AppBase, ContentBase


# ═══════════════════════════════════════════════════════════════════════════
# APP DB (jedna globalna): users, auth, ustawienia użytkownika
# ═══════════════════════════════════════════════════════════════════════════

class User(AppBase):
    __tablename__ = "users"
    id = Column(Integer, primary_key=True, index=True)
    username = Column(String, unique=True, nullable=False, index=True)
    email = Column(String, unique=True, nullable=False, index=True)
    password_hash = Column(String, nullable=False)
    # kod języka z languages.SUPPORTED — wybiera bazę contentową
    selected_language = Column(String(8), nullable=False, default="hr")
    # personalizacja UI
    theme = Column(String(8), nullable=False, default="dark")  # "dark" | "light"
    avatar = Column(String(64), nullable=True, default=None)   # nazwa pliku avatara albo emoji (back-compat)
    created_at = Column(DateTime, server_default=func.now())


# ═══════════════════════════════════════════════════════════════════════════
# CONTENT DB (per język): rooms, words, verbs, progress, sentences
# ═══════════════════════════════════════════════════════════════════════════

class Room(ContentBase):
    __tablename__ = "rooms"
    id = Column(Integer, primary_key=True, index=True)
    name = Column(String, nullable=False)
    description = Column(String)
    emoji = Column(String, default="🚪")
    color = Column(String, default="#e8c07d")


class Word(ContentBase):
    __tablename__ = "words"
    id = Column(Integer, primary_key=True, index=True)
    room_id = Column(Integer, ForeignKey("rooms.id"))
    croatian = Column(String, nullable=False)   # nazwa kolumny zostaje dla zgodności wstecz
    polish = Column(String, nullable=False)
    category = Column(String)
    difficulty = Column(Integer, default=1)
    example_hr = Column(Text)
    example_pl = Column(Text)


class Verb(ContentBase):
    __tablename__ = "verbs"
    id = Column(Integer, primary_key=True, index=True)
    room_id = Column(Integer, ForeignKey("rooms.id"))
    infinitive = Column(String, nullable=False)
    polish = Column(String, nullable=False)
    conj_ja = Column(String)
    conj_ti = Column(String)
    conj_on = Column(String)
    conj_mi = Column(String)
    conj_vi = Column(String)
    conj_oni = Column(String)
    example_hr = Column(Text)
    example_pl = Column(Text)


class Progress(ContentBase):
    """Postęp nauki. user_id wskazuje na User w app.db — bez FK, bo to
    osobna baza SQLite. Spójność pilnujemy w aplikacji."""
    __tablename__ = "progress"
    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, nullable=False, index=True)
    item_type = Column(String, nullable=False)  # "word" | "verb"
    item_id = Column(Integer, nullable=False)
    room_id = Column(Integer, ForeignKey("rooms.id"))
    status = Column(String, default="nowe")  # nowe|uczę się|znam|trudne|do powtórki
    next_review = Column(Date)
    last_reviewed = Column(Date)
    review_count = Column(Integer, default=0)


class Sentence(ContentBase):
    __tablename__ = "sentences"
    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, nullable=False, index=True)
    room_id = Column(Integer, ForeignKey("rooms.id"))
    text_hr = Column(Text, nullable=False)
    text_pl = Column(Text)
    note = Column(Text)
    status = Column(String, default="do sprawdzenia")
    created_at = Column(DateTime, server_default=func.now())


class SentenceWord(ContentBase):
    __tablename__ = "sentence_words"
    id = Column(Integer, primary_key=True)
    sentence_id = Column(Integer, ForeignKey("sentences.id"))
    word_id = Column(Integer, ForeignKey("words.id"))
