from fastapi import FastAPI, HTTPException, Depends
from fastapi.middleware.cors import CORSMiddleware
from sqlalchemy.orm import Session
from datetime import date, timedelta
from typing import Optional, List
import models, schemas, database

app = FastAPI(title="Chorwacki od podstaw API", version="1.0.0")

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


@app.on_event("startup")
def startup():
    db = database.SessionLocal()
    try:
        if db.query(models.Room).count() == 0:
            import seed
            seed.run(db)
    finally:
        db.close()


# ─── ROOMS ──────────────────────────────────────────────────────────────────

@app.get("/rooms", response_model=List[schemas.RoomOut])
def get_rooms(db: Session = Depends(get_db)):
    rooms = db.query(models.Room).order_by(models.Room.id).all()
    result = []
    for room in rooms:
        word_count = db.query(models.Word).filter(models.Word.room_id == room.id).count()
        verb_count = db.query(models.Verb).filter(models.Verb.room_id == room.id).count()
        known = db.query(models.Progress).filter(
            models.Progress.room_id == room.id,
            models.Progress.status == "znam"
        ).count()
        due_today = db.query(models.Progress).filter(
            models.Progress.room_id == room.id,
            models.Progress.next_review <= date.today(),
            models.Progress.status != "nowe"
        ).count()
        result.append(schemas.RoomOut(
            id=room.id,
            name=room.name,
            description=room.description,
            emoji=room.emoji,
            color=room.color,
            word_count=word_count,
            verb_count=verb_count,
            known_count=known,
            due_today=due_today,
        ))
    return result


@app.get("/rooms/{room_id}", response_model=schemas.RoomOut)
def get_room(room_id: int, db: Session = Depends(get_db)):
    room = db.query(models.Room).filter(models.Room.id == room_id).first()
    if not room:
        raise HTTPException(404, "Room not found")
    word_count = db.query(models.Word).filter(models.Word.room_id == room_id).count()
    verb_count = db.query(models.Verb).filter(models.Verb.room_id == room_id).count()
    known = db.query(models.Progress).filter(
        models.Progress.room_id == room_id,
        models.Progress.status == "znam"
    ).count()
    due_today = db.query(models.Progress).filter(
        models.Progress.room_id == room_id,
        models.Progress.next_review <= date.today(),
        models.Progress.status != "nowe"
    ).count()
    return schemas.RoomOut(
        id=room.id, name=room.name, description=room.description,
        emoji=room.emoji, color=room.color,
        word_count=word_count, verb_count=verb_count,
        known_count=known, due_today=due_today,
    )


# ─── WORDS ──────────────────────────────────────────────────────────────────

@app.get("/rooms/{room_id}/words", response_model=List[schemas.WordOut])
def get_words(room_id: int, q: Optional[str] = None, category: Optional[str] = None,
              db: Session = Depends(get_db)):
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
            models.Progress.item_type == "word",
            models.Progress.item_id == w.id
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
def get_word_categories(room_id: int, db: Session = Depends(get_db)):
    cats = db.query(models.Word.category).filter(
        models.Word.room_id == room_id
    ).distinct().all()
    return [c[0] for c in cats if c[0]]


# ─── VERBS ──────────────────────────────────────────────────────────────────

@app.get("/rooms/{room_id}/verbs", response_model=List[schemas.VerbOut])
def get_verbs(room_id: int, q: Optional[str] = None, db: Session = Depends(get_db)):
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
            models.Progress.item_type == "verb",
            models.Progress.item_id == v.id
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
def get_reviews(room_id: int, db: Session = Depends(get_db)):
    today = date.today()
    progs = db.query(models.Progress).filter(
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


# ─── PROGRESS ───────────────────────────────────────────────────────────────

REVIEW_DAYS = {"nie wiem": 1, "prawie": 3, "wiem": 7}
STATUS_MAP = {"nie wiem": "uczę się", "prawie": "uczę się", "wiem": "znam"}


@app.post("/progress", response_model=schemas.ProgressOut)
def update_progress(payload: schemas.ProgressIn, db: Session = Depends(get_db)):
    today = date.today()
    days = REVIEW_DAYS.get(payload.answer, 1)
    new_status = STATUS_MAP.get(payload.answer, "uczę się")
    if payload.answer == "nie wiem":
        new_status = "trudne"

    prog = db.query(models.Progress).filter(
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
def start_learning(payload: schemas.StartLearning, db: Session = Depends(get_db)):
    today = date.today()
    existing = db.query(models.Progress).filter(
        models.Progress.item_type == payload.item_type,
        models.Progress.item_id == payload.item_id,
    ).first()
    if not existing:
        prog = models.Progress(
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
def get_sentences(room_id: int, db: Session = Depends(get_db)):
    sentences = db.query(models.Sentence).filter(
        models.Sentence.room_id == room_id
    ).order_by(models.Sentence.created_at.desc()).all()
    return sentences


@app.post("/sentences", response_model=schemas.SentenceOut)
def create_sentence(payload: schemas.SentenceIn, db: Session = Depends(get_db)):
    s = models.Sentence(
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
def delete_sentence(sentence_id: int, db: Session = Depends(get_db)):
    s = db.query(models.Sentence).filter(models.Sentence.id == sentence_id).first()
    if not s:
        raise HTTPException(404)
    db.delete(s)
    db.commit()
    return {"ok": True}


# ─── DASHBOARD ──────────────────────────────────────────────────────────────

@app.get("/dashboard")
def get_dashboard(db: Session = Depends(get_db)):
    total_words = db.query(models.Word).count()
    total_verbs = db.query(models.Verb).count()
    known = db.query(models.Progress).filter(models.Progress.status == "znam").count()
    learning = db.query(models.Progress).filter(models.Progress.status == "uczę się").count()
    hard = db.query(models.Progress).filter(models.Progress.status == "trudne").count()
    due = db.query(models.Progress).filter(
        models.Progress.next_review <= date.today(),
        models.Progress.status != "nowe",
    ).count()
    recent_sentences = db.query(models.Sentence).order_by(
        models.Sentence.created_at.desc()
    ).limit(5).all()
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
