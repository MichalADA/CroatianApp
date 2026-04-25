from fastapi import FastAPI, HTTPException, Depends
from fastapi.middleware.cors import CORSMiddleware
from sqlalchemy import text, inspect
from sqlalchemy.orm import Session
from datetime import date, timedelta
from typing import Optional, List

import models, schemas, database
from auth import (
    hash_password, verify_password, create_token, get_current_user,
)

app = FastAPI(title="Chorwacki od podstaw API", version="2.0.0")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

database.Base.metadata.create_all(bind=database.engine)


def get_db():
    db = database.SessionLocal()
    try:
        yield db
    finally:
        db.close()


# ─── STARTUP: migracja, seed danych, seed konta testowego ──────────────────

def _migrate_user_id_columns():
    """SQLite ALTER TABLE — dodaj user_id do tabel, jeśli go jeszcze nie ma.
    Idempotentne, bezpieczne na istniejących bazach."""
    inspector = inspect(database.engine)
    for table in ("progress", "sentences"):
        if not inspector.has_table(table):
            continue
        cols = {c["name"] for c in inspector.get_columns(table)}
        if "user_id" not in cols:
            with database.engine.begin() as conn:
                conn.execute(text(f"ALTER TABLE {table} ADD COLUMN user_id INTEGER"))


def _ensure_test_user(db: Session) -> models.User:
    """Tworzy konto testowe (test/test) jeśli nie istnieje. Zwraca usera."""
    user = db.query(models.User).filter(models.User.username == "test").first()
    if user:
        return user
    user = models.User(
        username="test",
        email="test@test.com",
        password_hash=hash_password("test"),
    )
    db.add(user)
    db.commit()
    db.refresh(user)
    return user


def _backfill_user_id(db: Session, default_user_id: int):
    """Wszystkie wiersze progress/sentences bez user_id przypisz do konta testowego."""
    db.execute(
        text("UPDATE progress SET user_id = :uid WHERE user_id IS NULL"),
        {"uid": default_user_id},
    )
    db.execute(
        text("UPDATE sentences SET user_id = :uid WHERE user_id IS NULL"),
        {"uid": default_user_id},
    )
    db.commit()


@app.on_event("startup")
def startup():
    _migrate_user_id_columns()
    db = database.SessionLocal()
    try:
        if db.query(models.Room).count() == 0:
            import seed
            seed.run(db)
        test_user = _ensure_test_user(db)
        _backfill_user_id(db, test_user.id)
    finally:
        db.close()


# ─── HEALTH ─────────────────────────────────────────────────────────────────

@app.get("/health")
def health():
    return {"ok": True}


# ─── AUTH ───────────────────────────────────────────────────────────────────

@app.post("/auth/register", response_model=schemas.TokenOut)
def register(payload: schemas.RegisterIn, db: Session = Depends(get_db)):
    username = payload.username.strip()
    email = payload.email.lower().strip()

    if db.query(models.User).filter(models.User.username == username).first():
        raise HTTPException(400, "Nazwa użytkownika jest już zajęta")
    if db.query(models.User).filter(models.User.email == email).first():
        raise HTTPException(400, "Konto z tym e-mailem już istnieje")

    user = models.User(
        username=username,
        email=email,
        password_hash=hash_password(payload.password),
    )
    db.add(user)
    db.commit()
    db.refresh(user)
    return schemas.TokenOut(access_token=create_token(user.id))


@app.post("/auth/login", response_model=schemas.TokenOut)
def login(payload: schemas.LoginIn, db: Session = Depends(get_db)):
    ident = payload.identifier.strip()
    user = db.query(models.User).filter(
        (models.User.email == ident.lower()) | (models.User.username == ident)
    ).first()
    if not user or not verify_password(payload.password, user.password_hash):
        raise HTTPException(401, "Nieprawidłowy login lub hasło")
    return schemas.TokenOut(access_token=create_token(user.id))


@app.get("/auth/me", response_model=schemas.UserOut)
def me(user: models.User = Depends(get_current_user)):
    return user


# ─── ROOMS ──────────────────────────────────────────────────────────────────

def _room_stats(db: Session, room: models.Room, user_id: int) -> schemas.RoomOut:
    word_count = db.query(models.Word).filter(models.Word.room_id == room.id).count()
    verb_count = db.query(models.Verb).filter(models.Verb.room_id == room.id).count()
    known = db.query(models.Progress).filter(
        models.Progress.user_id == user_id,
        models.Progress.room_id == room.id,
        models.Progress.status == "znam",
    ).count()
    due_today = db.query(models.Progress).filter(
        models.Progress.user_id == user_id,
        models.Progress.room_id == room.id,
        models.Progress.next_review <= date.today(),
        models.Progress.status != "nowe",
    ).count()
    return schemas.RoomOut(
        id=room.id, name=room.name, description=room.description,
        emoji=room.emoji, color=room.color,
        word_count=word_count, verb_count=verb_count,
        known_count=known, due_today=due_today,
    )


@app.get("/rooms", response_model=List[schemas.RoomOut])
def get_rooms(db: Session = Depends(get_db),
              user: models.User = Depends(get_current_user)):
    rooms = db.query(models.Room).order_by(models.Room.id).all()
    return [_room_stats(db, r, user.id) for r in rooms]


@app.get("/rooms/{room_id}", response_model=schemas.RoomOut)
def get_room(room_id: int, db: Session = Depends(get_db),
             user: models.User = Depends(get_current_user)):
    room = db.query(models.Room).filter(models.Room.id == room_id).first()
    if not room:
        raise HTTPException(404, "Room not found")
    return _room_stats(db, room, user.id)


# ─── WORDS ──────────────────────────────────────────────────────────────────

@app.get("/rooms/{room_id}/words", response_model=List[schemas.WordOut])
def get_words(room_id: int, q: Optional[str] = None, category: Optional[str] = None,
              db: Session = Depends(get_db),
              user: models.User = Depends(get_current_user)):
    query = db.query(models.Word).filter(models.Word.room_id == room_id)
    if q:
        like = f"%{q}%"
        query = query.filter(
            (models.Word.croatian.ilike(like)) | (models.Word.polish.ilike(like))
        )
    if category and category != "wszystkie":
        query = query.filter(models.Word.category == category)
    words = query.order_by(models.Word.id).all()
    result = []
    for w in words:
        prog = db.query(models.Progress).filter(
            models.Progress.user_id == user.id,
            models.Progress.item_type == "word",
            models.Progress.item_id == w.id,
        ).first()
        result.append(schemas.WordOut(
            id=w.id, room_id=w.room_id, croatian=w.croatian, polish=w.polish,
            category=w.category, difficulty=w.difficulty,
            example_hr=w.example_hr, example_pl=w.example_pl,
            status=prog.status if prog else "nowe",
            next_review=prog.next_review if prog else None,
        ))
    return result


@app.get("/rooms/{room_id}/words/categories")
def get_word_categories(room_id: int, db: Session = Depends(get_db),
                        user: models.User = Depends(get_current_user)):
    cats = db.query(models.Word.category).filter(
        models.Word.room_id == room_id
    ).distinct().all()
    return [c[0] for c in cats if c[0]]


# ─── VERBS ──────────────────────────────────────────────────────────────────

@app.get("/rooms/{room_id}/verbs", response_model=List[schemas.VerbOut])
def get_verbs(room_id: int, q: Optional[str] = None, db: Session = Depends(get_db),
              user: models.User = Depends(get_current_user)):
    query = db.query(models.Verb).filter(models.Verb.room_id == room_id)
    if q:
        like = f"%{q}%"
        query = query.filter(
            (models.Verb.infinitive.ilike(like)) | (models.Verb.polish.ilike(like))
        )
    verbs = query.order_by(models.Verb.id).all()
    result = []
    for v in verbs:
        prog = db.query(models.Progress).filter(
            models.Progress.user_id == user.id,
            models.Progress.item_type == "verb",
            models.Progress.item_id == v.id,
        ).first()
        result.append(schemas.VerbOut(
            id=v.id, room_id=v.room_id, infinitive=v.infinitive, polish=v.polish,
            conj_ja=v.conj_ja, conj_ti=v.conj_ti, conj_on=v.conj_on,
            conj_mi=v.conj_mi, conj_vi=v.conj_vi, conj_oni=v.conj_oni,
            example_hr=v.example_hr, example_pl=v.example_pl,
            status=prog.status if prog else "nowe",
            next_review=prog.next_review if prog else None,
        ))
    return result


# ─── REVIEWS ────────────────────────────────────────────────────────────────

@app.get("/rooms/{room_id}/reviews")
def get_reviews(room_id: int, db: Session = Depends(get_db),
                user: models.User = Depends(get_current_user)):
    today = date.today()
    progs = db.query(models.Progress).filter(
        models.Progress.user_id == user.id,
        models.Progress.room_id == room_id,
        models.Progress.next_review <= today,
        models.Progress.status != "nowe",
    ).all()
    items = []
    for p in progs:
        if p.item_type == "word":
            w = db.query(models.Word).filter(models.Word.id == p.item_id).first()
            if w:
                items.append({"type": "word", "id": w.id, "croatian": w.croatian,
                              "polish": w.polish, "category": w.category,
                              "status": p.status, "progress_id": p.id})
        else:
            v = db.query(models.Verb).filter(models.Verb.id == p.item_id).first()
            if v:
                items.append({"type": "verb", "id": v.id, "croatian": v.infinitive,
                              "polish": v.polish, "status": p.status, "progress_id": p.id,
                              "conj_ja": v.conj_ja, "conj_ti": v.conj_ti,
                              "conj_on": v.conj_on, "conj_mi": v.conj_mi,
                              "conj_vi": v.conj_vi, "conj_oni": v.conj_oni})
    return {"items": items, "count": len(items)}


# ─── LEARNING SESSION (flashcards) ──────────────────────────────────────────

@app.get("/rooms/{room_id}/learning-session")
def get_learning_session(room_id: int, limit: int = 20, new_limit: int = 5,
                         db: Session = Depends(get_db),
                         user: models.User = Depends(get_current_user)):
    """
    Buduje kolejkę kart na sesję nauki w priorytecie:
      1. słowa do powtórki na dziś (status != nowe, next_review <= dziś)
      2. słowa trudne (status = trudne, jeszcze nie w kolejce)
      3. słowa w trakcie nauki (status = uczę się, jeszcze nie w kolejce)
      4. nowe słowa / czasowniki (brak progresu lub status = nowe)
    Per-user — filtruje po user_id zalogowanego użytkownika.
    """
    today = date.today()

    def serialize(item_type, item_id, status):
        if item_type == "word":
            w = db.query(models.Word).filter(models.Word.id == item_id).first()
            if not w:
                return None
            return {
                "type": "word", "id": w.id, "croatian": w.croatian,
                "polish": w.polish, "category": w.category, "status": status,
            }
        else:
            v = db.query(models.Verb).filter(models.Verb.id == item_id).first()
            if not v:
                return None
            return {
                "type": "verb", "id": v.id, "croatian": v.infinitive,
                "polish": v.polish, "status": status,
                "conj_ja": v.conj_ja, "conj_ti": v.conj_ti, "conj_on": v.conj_on,
                "conj_mi": v.conj_mi, "conj_vi": v.conj_vi, "conj_oni": v.conj_oni,
            }

    items = []
    seen = set()  # (type, id)

    # 1) do powtórki na dziś
    due = db.query(models.Progress).filter(
        models.Progress.user_id == user.id,
        models.Progress.room_id == room_id,
        models.Progress.next_review <= today,
        models.Progress.status != "nowe",
    ).order_by(models.Progress.next_review).all()
    for p in due:
        key = (p.item_type, p.item_id)
        if key in seen:
            continue
        s = serialize(p.item_type, p.item_id, p.status)
        if s:
            seen.add(key)
            items.append(s)

    # 2) trudne (jeszcze nie dodane)
    hard = db.query(models.Progress).filter(
        models.Progress.user_id == user.id,
        models.Progress.room_id == room_id,
        models.Progress.status == "trudne",
    ).all()
    for p in hard:
        key = (p.item_type, p.item_id)
        if key in seen:
            continue
        s = serialize(p.item_type, p.item_id, p.status)
        if s:
            seen.add(key)
            items.append(s)

    # 3) uczę się (jeszcze nie dodane)
    learning = db.query(models.Progress).filter(
        models.Progress.user_id == user.id,
        models.Progress.room_id == room_id,
        models.Progress.status == "uczę się",
    ).all()
    for p in learning:
        key = (p.item_type, p.item_id)
        if key in seen:
            continue
        s = serialize(p.item_type, p.item_id, p.status)
        if s:
            seen.add(key)
            items.append(s)

    # 4) nowe słowa (i czasowniki) — bez progresu LUB ze statusem "nowe"
    if len(items) < limit:
        all_progress = db.query(models.Progress).filter(
            models.Progress.user_id == user.id,
            models.Progress.room_id == room_id,
            models.Progress.status != "nowe",
        ).all()
        excluded_word_ids = {p.item_id for p in all_progress if p.item_type == "word"}
        excluded_verb_ids = {p.item_id for p in all_progress if p.item_type == "verb"}

        new_words_q = db.query(models.Word).filter(models.Word.room_id == room_id)
        if excluded_word_ids:
            new_words_q = new_words_q.filter(~models.Word.id.in_(excluded_word_ids))
        budget = min(new_limit, limit - len(items))
        for w in new_words_q.order_by(models.Word.id).limit(budget).all():
            items.append({
                "type": "word", "id": w.id, "croatian": w.croatian,
                "polish": w.polish, "category": w.category, "status": "nowe",
            })

        if len(items) < limit:
            new_verbs_q = db.query(models.Verb).filter(models.Verb.room_id == room_id)
            if excluded_verb_ids:
                new_verbs_q = new_verbs_q.filter(~models.Verb.id.in_(excluded_verb_ids))
            budget = min(new_limit, limit - len(items))
            for v in new_verbs_q.order_by(models.Verb.id).limit(budget).all():
                items.append({
                    "type": "verb", "id": v.id, "croatian": v.infinitive,
                    "polish": v.polish, "status": "nowe",
                    "conj_ja": v.conj_ja, "conj_ti": v.conj_ti, "conj_on": v.conj_on,
                    "conj_mi": v.conj_mi, "conj_vi": v.conj_vi, "conj_oni": v.conj_oni,
                })

    items = items[:limit]
    return {"items": items, "count": len(items)}


# ─── PROGRESS ───────────────────────────────────────────────────────────────

REVIEW_DAYS = {"nie wiem": 1, "prawie": 3, "wiem": 7}
STATUS_MAP = {"nie wiem": "uczę się", "prawie": "uczę się", "wiem": "znam"}


@app.post("/progress", response_model=schemas.ProgressOut)
def update_progress(payload: schemas.ProgressIn, db: Session = Depends(get_db),
                    user: models.User = Depends(get_current_user)):
    today = date.today()
    days = REVIEW_DAYS.get(payload.answer, 1)
    new_status = STATUS_MAP.get(payload.answer, "uczę się")
    if payload.answer == "nie wiem":
        new_status = "trudne"

    prog = db.query(models.Progress).filter(
        models.Progress.user_id == user.id,
        models.Progress.item_type == payload.item_type,
        models.Progress.item_id == payload.item_id,
    ).first()

    if prog:
        prog.status = new_status
        prog.next_review = today + timedelta(days=days)
        prog.last_reviewed = today
        prog.review_count += 1
    else:
        prog = models.Progress(
            user_id=user.id,
            item_type=payload.item_type,
            item_id=payload.item_id,
            room_id=payload.room_id,
            status=new_status,
            next_review=today + timedelta(days=days),
            last_reviewed=today,
            review_count=1,
        )
        db.add(prog)
    db.commit()
    db.refresh(prog)
    return prog


@app.post("/progress/start")
def start_learning(payload: schemas.StartLearning, db: Session = Depends(get_db),
                   user: models.User = Depends(get_current_user)):
    today = date.today()
    existing = db.query(models.Progress).filter(
        models.Progress.user_id == user.id,
        models.Progress.item_type == payload.item_type,
        models.Progress.item_id == payload.item_id,
    ).first()
    if not existing:
        prog = models.Progress(
            user_id=user.id,
            item_type=payload.item_type,
            item_id=payload.item_id,
            room_id=payload.room_id,
            status="uczę się",
            next_review=today,
            last_reviewed=today,
            review_count=0,
        )
        db.add(prog)
        db.commit()
    return {"ok": True}


# ─── SENTENCES ──────────────────────────────────────────────────────────────

@app.get("/rooms/{room_id}/sentences", response_model=List[schemas.SentenceOut])
def get_sentences(room_id: int, db: Session = Depends(get_db),
                  user: models.User = Depends(get_current_user)):
    sentences = db.query(models.Sentence).filter(
        models.Sentence.user_id == user.id,
        models.Sentence.room_id == room_id,
    ).order_by(models.Sentence.created_at.desc()).all()
    return sentences


@app.post("/sentences", response_model=schemas.SentenceOut)
def create_sentence(payload: schemas.SentenceIn, db: Session = Depends(get_db),
                    user: models.User = Depends(get_current_user)):
    s = models.Sentence(
        user_id=user.id,
        room_id=payload.room_id,
        text_hr=payload.text_hr,
        text_pl=payload.text_pl,
        note=payload.note,
        status=payload.status or "do sprawdzenia",
    )
    db.add(s)
    db.commit()
    db.refresh(s)
    return s


@app.delete("/sentences/{sentence_id}")
def delete_sentence(sentence_id: int, db: Session = Depends(get_db),
                    user: models.User = Depends(get_current_user)):
    s = db.query(models.Sentence).filter(
        models.Sentence.id == sentence_id,
        models.Sentence.user_id == user.id,
    ).first()
    if not s:
        raise HTTPException(404)
    db.delete(s)
    db.commit()
    return {"ok": True}


# ─── DASHBOARD ──────────────────────────────────────────────────────────────

@app.get("/dashboard")
def get_dashboard(db: Session = Depends(get_db),
                  user: models.User = Depends(get_current_user)):
    total_words = db.query(models.Word).count()
    total_verbs = db.query(models.Verb).count()
    known = db.query(models.Progress).filter(
        models.Progress.user_id == user.id,
        models.Progress.status == "znam",
    ).count()
    learning = db.query(models.Progress).filter(
        models.Progress.user_id == user.id,
        models.Progress.status == "uczę się",
    ).count()
    hard = db.query(models.Progress).filter(
        models.Progress.user_id == user.id,
        models.Progress.status == "trudne",
    ).count()
    due = db.query(models.Progress).filter(
        models.Progress.user_id == user.id,
        models.Progress.next_review <= date.today(),
        models.Progress.status != "nowe",
    ).count()
    recent_sentences = db.query(models.Sentence).filter(
        models.Sentence.user_id == user.id,
    ).order_by(models.Sentence.created_at.desc()).limit(5).all()
    return {
        "total_words": total_words,
        "total_verbs": total_verbs,
        "known": known,
        "learning": learning,
        "hard": hard,
        "due_today": due,
        "recent_sentences": [{"id": s.id, "text_hr": s.text_hr, "text_pl": s.text_pl,
                              "room_id": s.room_id} for s in recent_sentences],
    }
