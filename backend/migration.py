"""Jednorazowa migracja z monolitycznej /data/chorwacki.db do modelu hybrydowego:

  /data/app.db                — users (+ selected_language)
  /data/languages/hr.db       — rooms/words/verbs/progress/sentences

Funkcja `run_legacy_split_migration` jest idempotentna i bezpieczna:
- jeśli app.db już istnieje, NIE rusza niczego (zakładamy że migracja
  już się wydarzyła albo świeża instalacja),
- przed jakimkolwiek dotknięciem starej bazy robi kopię zapasową
  (chorwacki.db.bak.YYYYMMDD_HHMMSS),
- po pomyślnej migracji zmienia nazwę starej bazy na *.migrated, żeby
  nie myliła w przyszłości.
"""
from __future__ import annotations

import os
import shutil
import sqlite3
from datetime import datetime

import database


def _has_table(conn: sqlite3.Connection, schema: str, table: str) -> bool:
    sql = f"SELECT name FROM {schema}.sqlite_master WHERE type='table' AND name=?"
    return conn.execute(sql, (table,)).fetchone() is not None


def _columns(conn: sqlite3.Connection, schema: str, table: str) -> list[str]:
    return [r[1] for r in conn.execute(f"PRAGMA {schema}.table_info({table})")]


def run_legacy_split_migration() -> dict:
    """Zwraca dict z tym co zrobiono — przydatne do logowania na starcie."""
    legacy = database.LEGACY_DB_PATH
    app_db = database.APP_DB_PATH
    hr_db = database.lang_db_path("hr")

    info = {
        "ran": False,
        "legacy_present": os.path.exists(legacy),
        "app_db_present": os.path.exists(app_db),
        "backup": None,
        "tables_copied": [],
        "users_copied": 0,
    }

    # Migrujemy tylko gdy stara baza istnieje i nowej jeszcze nie ma.
    if not info["legacy_present"]:
        return info
    if info["app_db_present"]:
        return info

    # 1) BACKUP starej bazy
    ts = datetime.now().strftime("%Y%m%d_%H%M%S")
    backup_path = f"{legacy}.bak.{ts}"
    shutil.copy2(legacy, backup_path)
    info["backup"] = backup_path

    # 2) Schematy nowych baz
    database.AppBase.metadata.create_all(bind=database.app_engine)
    database.get_lang_engine("hr")  # tworzy hr.db ze schematem ContentBase

    # 3) Kopiowanie danych przez ATTACH DATABASE
    src = sqlite3.connect(legacy)
    try:
        src.execute("ATTACH DATABASE ? AS app", (app_db,))
        src.execute("ATTACH DATABASE ? AS hr", (hr_db,))

        # USERS → app.db (z dorzuconym selected_language='hr')
        if _has_table(src, "main", "users"):
            cols_main = set(_columns(src, "main", "users"))
            cols_app = set(_columns(src, "app", "users"))
            # bierzemy część wspólną kolumn
            common = [c for c in ("id", "username", "email", "password_hash", "created_at")
                      if c in cols_main and c in cols_app]
            cols_csv = ", ".join(common)
            sel_csv = ", ".join(common + (["'hr'"] if "selected_language" in cols_app else []))
            target_cols = cols_csv + (", selected_language" if "selected_language" in cols_app else "")
            src.execute(
                f"INSERT OR IGNORE INTO app.users ({target_cols}) "
                f"SELECT {sel_csv} FROM main.users"
            )
            info["users_copied"] = src.execute("SELECT COUNT(*) FROM app.users").fetchone()[0]

        # CONTENT → hr.db
        for table in ("rooms", "words", "verbs", "progress", "sentences", "sentence_words"):
            if not _has_table(src, "main", table):
                continue
            if not _has_table(src, "hr", table):
                continue
            cols_main = _columns(src, "main", table)
            cols_hr = set(_columns(src, "hr", table))
            common = [c for c in cols_main if c in cols_hr]
            if not common:
                continue
            cols_csv = ", ".join(common)
            src.execute(
                f"INSERT OR IGNORE INTO hr.{table} ({cols_csv}) "
                f"SELECT {cols_csv} FROM main.{table}"
            )
            info["tables_copied"].append(table)

        src.commit()
    finally:
        src.close()

    # 4) Stara baza out of the way — żeby nikt jej nie otwierał później
    migrated_path = f"{legacy}.migrated.{ts}"
    os.rename(legacy, migrated_path)
    info["legacy_renamed_to"] = migrated_path
    info["ran"] = True
    return info


def ensure_user_id_columns_in_lang_db(lang: str) -> None:
    """SQLite ALTER TABLE — dorzuć user_id do progress/sentences w bazie języka,
    gdyby tabele już istniały z poprzedniej (jeszcze starszej) wersji bez user_id."""
    from sqlalchemy import inspect, text
    eng = database.get_lang_engine(lang)
    insp = inspect(eng)
    for table in ("progress", "sentences"):
        if not insp.has_table(table):
            continue
        cols = {c["name"] for c in insp.get_columns(table)}
        if "user_id" not in cols:
            with eng.begin() as conn:
                conn.execute(text(f"ALTER TABLE {table} ADD COLUMN user_id INTEGER"))


def ensure_selected_language_column() -> None:
    """ALTER TABLE users ADD COLUMN selected_language jeśli brak."""
    from sqlalchemy import inspect, text
    insp = inspect(database.app_engine)
    if not insp.has_table("users"):
        return
    cols = {c["name"] for c in insp.get_columns("users")}
    if "selected_language" not in cols:
        with database.app_engine.begin() as conn:
            conn.execute(text(
                "ALTER TABLE users ADD COLUMN selected_language VARCHAR(8) NOT NULL DEFAULT 'hr'"
            ))


def ensure_user_settings_columns() -> None:
    """ALTER TABLE users ADD COLUMN theme/avatar jeśli brak."""
    from sqlalchemy import inspect, text
    insp = inspect(database.app_engine)
    if not insp.has_table("users"):
        return
    cols = {c["name"] for c in insp.get_columns("users")}
    with database.app_engine.begin() as conn:
        if "theme" not in cols:
            conn.execute(text(
                "ALTER TABLE users ADD COLUMN theme VARCHAR(8) NOT NULL DEFAULT 'dark'"
            ))
        if "avatar" not in cols:
            conn.execute(text("ALTER TABLE users ADD COLUMN avatar VARCHAR(16)"))
