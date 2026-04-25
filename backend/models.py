from sqlalchemy import Column, Integer, String, Date, DateTime, ForeignKey, Text
from sqlalchemy.sql import func
from database import Base


class Room(Base):
    __tablename__ = "rooms"
    id = Column(Integer, primary_key=True, index=True)
    name = Column(String, nullable=False)
    description = Column(String)
    emoji = Column(String, default="🚪")
    color = Column(String, default="#e8c07d")


class Word(Base):
    __tablename__ = "words"
    id = Column(Integer, primary_key=True, index=True)
    room_id = Column(Integer, ForeignKey("rooms.id"))
    croatian = Column(String, nullable=False)
    polish = Column(String, nullable=False)
    category = Column(String)
    difficulty = Column(Integer, default=1)
    example_hr = Column(Text)
    example_pl = Column(Text)


class Verb(Base):
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


class Progress(Base):
    __tablename__ = "progress"
    id = Column(Integer, primary_key=True, index=True)
    item_type = Column(String, nullable=False)  # "word" | "verb"
    item_id = Column(Integer, nullable=False)
    room_id = Column(Integer, ForeignKey("rooms.id"))
    status = Column(String, default="nowe")  # nowe|uczę się|znam|trudne|do powtórki
    next_review = Column(Date)
    last_reviewed = Column(Date)
    review_count = Column(Integer, default=0)


class Sentence(Base):
    __tablename__ = "sentences"
    id = Column(Integer, primary_key=True, index=True)
    room_id = Column(Integer, ForeignKey("rooms.id"))
    text_hr = Column(Text, nullable=False)
    text_pl = Column(Text)
    note = Column(Text)
    status = Column(String, default="do sprawdzenia")  # poprawne|do sprawdzenia|trudne
    created_at = Column(DateTime, server_default=func.now())


class SentenceWord(Base):
    __tablename__ = "sentence_words"
    id = Column(Integer, primary_key=True)
    sentence_id = Column(Integer, ForeignKey("sentences.id"))
    word_id = Column(Integer, ForeignKey("words.id"))
