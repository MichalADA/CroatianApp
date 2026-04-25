"""Konfiguracja baz danych — model hybrydowy:

  /data/app.db                — users, auth, ustawienia globalne
  /data/languages/<code>.db   — content per język (rooms, words, verbs, progress, sentences)

Powód podziału: jeden user, wiele języków. Logowanie wspólne, content per język,
postęp i zdania per (user, język).
"""
import os
from sqlalchemy import create_engine
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker

# ─── Ścieżki ─────────────────────────────────────────────────────────────────
DATA_DIR = os.getenv("DATA_DIR", "/data")
APP_DB_PATH = os.getenv("APP_DB_PATH", os.path.join(DATA_DIR, "app.db"))
LANG_DB_DIR = os.getenv("LANG_DB_DIR", os.path.join(DATA_DIR, "languages"))
LEGACY_DB_PATH = os.getenv("DB_PATH", os.path.join(DATA_DIR, "chorwacki.db"))

os.makedirs(DATA_DIR, exist_ok=True)
os.makedirs(LANG_DB_DIR, exist_ok=True)


# ─── Bases ───────────────────────────────────────────────────────────────────
# Dwie oddzielne bazy = dwie hierarchie modeli, by nikt przypadkiem nie
# stworzył tabeli usera w bazie językowej (lub odwrotnie).
AppBase = declarative_base()
ContentBase = declarative_base()


# ─── App engine (users, auth, settings) ──────────────────────────────────────
app_engine = create_engine(
    f"sqlite:///{APP_DB_PATH}",
    connect_args={"check_same_thread": False},
)
AppSessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=app_engine)


# ─── Content engines (per język, lazy) ───────────────────────────────────────
_lang_engines: dict = {}
_lang_session_makers: dict = {}


def lang_db_path(lang: str) -> str:
    return os.path.join(LANG_DB_DIR, f"{lang}.db")


def get_lang_engine(lang: str):
    """Zwraca engine SQLAlchemy dla bazy danego języka. Tworzy ją (z pustym
    schematem) przy pierwszym użyciu — dzięki temu es/el działają od razu,
    tylko bez contentu."""
    if lang not in _lang_engines:
        path = lang_db_path(lang)
        eng = create_engine(
            f"sqlite:///{path}",
            connect_args={"check_same_thread": False},
        )
        ContentBase.metadata.create_all(bind=eng)
        _lang_engines[lang] = eng
        _lang_session_makers[lang] = sessionmaker(autocommit=False, autoflush=False, bind=eng)
    return _lang_engines[lang]


def get_lang_sessionmaker(lang: str):
    get_lang_engine(lang)
    return _lang_session_makers[lang]


def open_lang_session(lang: str):
    return get_lang_sessionmaker(lang)()


# ─── Wsteczna kompatybilność ─────────────────────────────────────────────────
# Stary kod (auth.py, narzędzia) odwoływał się do `Base`, `engine`, `SessionLocal`.
# Te aliasy wskazują na bazę aplikacyjną — bo to tu mieszkają teraz users.
Base = AppBase
engine = app_engine
SessionLocal = AppSessionLocal
