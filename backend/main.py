from fastapi import FastAPI, HTTPException, Depends
from fastapi.middleware.cors import CORSMiddleware
from sqlalchemy.orm import Session
from datetime import date, timedelta
from typing import Optional, List

import models, schemas, database, languages, migration
from auth import (
    hash_password, verify_password, create_token, get_current_user,
)

app = FastAPI(title="Pałac Pamięci API", version="3.0.0")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)


# ═══════════════════════════════════════════════════════════════════════════
# DEPENDENCIES
# ═══════════════════════════════════════════════════════════════════════════

def get_app_db():
    """Sesja bazy aplikacyjnej (users, ustawienia)."""
    db = database.AppSessionLocal()
    try:
        yield db
    finally:
        db.close()


def get_content_db(user: models.User = Depends(get_current_user)):
    """Sesja bazy contentowej dla aktualnego języka usera. Każdy chroniony
    endpoint contentu używa tego — tu jest cała magia 'jeden user, wiele baz'."""
    lang = user.selected_language or languages.DEFAULT_LANGUAGE
    if not languages.is_supported(lang):
        lang = languages.DEFAULT_LANGUAGE
    db = database.open_lang_session(lang)
    try:
        yield db
    finally:
        db.close()


# ═══════════════════════════════════════════════════════════════════════════
# STARTUP: migracja, seed contentu hr, konto testowe
# ═══════════════════════════════════════════════════════════════════════════

@app.on_event("startup")
def startup():
    # 1) Jeśli jest stara monolityczna baza /data/chorwacki.db i nie ma jeszcze
    #    /data/app.db — rozdziel ją na app.db + languages/hr.db (z backupem).
    info = migration.run_legacy_split_migration()
    if info["ran"]:
        print(f"📦 Migracja: backup={info['backup']}, "
              f"users={info['users_copied']}, tabele={info['tables_copied']}")

    # 2) Schemat app.db (gdyby świeża instalacja)
    database.AppBase.metadata.create_all(bind=database.app_engine)
    migration.ensure_selected_language_column()
    migration.ensure_user_settings_columns()

    # 3) Bazy contentowe dla wszystkich obsługiwanych języków
    for code in languages.codes():
        database.get_lang_engine(code)
        migration.ensure_user_id_columns_in_lang_db(code)

    # 4) Seed contentu hr — tylko jeśli baza hr.db jest pusta (świeża instalka)
    hr_session = database.open_lang_session("hr")
    try:
        if hr_session.query(models.Room).count() == 0:
            import seed
            seed.run(hr_session)
    finally:
        hr_session.close()

    # 5) Konto testowe w app.db
    app_session = database.AppSessionLocal()
    try:
        user = app_session.query(models.User).filter(models.User.username == "test").first()
        if not user:
            user = models.User(
                username="test",
                email="test@test.com",
                password_hash=hash_password("test"),
                selected_language="hr",
            )
            app_session.add(user)
            app_session.commit()
    finally:
        app_session.close()


# ═══════════════════════════════════════════════════════════════════════════
# HEALTH
# ═══════════════════════════════════════════════════════════════════════════

@app.get("/health")
def health():
    return {"ok": True}


# ═══════════════════════════════════════════════════════════════════════════
# AUTH
# ═══════════════════════════════════════════════════════════════════════════

@app.post("/auth/register", response_model=schemas.TokenOut)
def register(payload: schemas.RegisterIn, db: Session = Depends(get_app_db)):
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
        selected_language=languages.DEFAULT_LANGUAGE,
    )
    db.add(user)
    db.commit()
    db.refresh(user)
    return schemas.TokenOut(access_token=create_token(user.id))


@app.post("/auth/login", response_model=schemas.TokenOut)
def login(payload: schemas.LoginIn, db: Session = Depends(get_app_db)):
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


# ═══════════════════════════════════════════════════════════════════════════
# USER SETTINGS (theme, avatar — drobne ustawienia per user)
# ═══════════════════════════════════════════════════════════════════════════

VALID_THEMES = {"dark", "light"}


@app.patch("/me/settings", response_model=schemas.UserOut)
def update_settings(payload: schemas.SettingsIn,
                    db: Session = Depends(get_app_db),
                    user: models.User = Depends(get_current_user)):
    fresh = db.query(models.User).filter(models.User.id == user.id).first()
    if not fresh:
        raise HTTPException(404, "Użytkownik nie istnieje")

    if payload.theme is not None:
        if payload.theme not in VALID_THEMES:
            raise HTTPException(400, f"Nieprawidłowy motyw — dozwolone: {sorted(VALID_THEMES)}")
        fresh.theme = payload.theme

    if payload.avatar is not None:
        # Pusty string = usuń własny avatar (wróć do inicjału z username).
        # Limit 16 znaków — wystarczy na pojedynczy emoji (max 4 bajty) albo kilka liter.
        avatar = (payload.avatar or "").strip()[:16]
        fresh.avatar = avatar or None

    db.commit()
    db.refresh(fresh)
    return fresh


# ═══════════════════════════════════════════════════════════════════════════
# LANGUAGES
# ═══════════════════════════════════════════════════════════════════════════

def _language_has_content(code: str) -> bool:
    sess = database.open_lang_session(code)
    try:
        return sess.query(models.Room).count() > 0
    finally:
        sess.close()


@app.get("/languages", response_model=List[schemas.LanguageOut])
def list_languages(user: models.User = Depends(get_current_user)):
    out = []
    for code in languages.codes():
        meta = languages.info(code)
        out.append(schemas.LanguageOut(
            code=meta["code"],
            name=meta["name"],
            title=meta["title"],
            flag=meta["flag"],
            has_content=_language_has_content(code),
            is_current=(code == user.selected_language),
        ))
    return out


@app.get("/me/language")
def get_my_language(user: models.User = Depends(get_current_user)):
    meta = languages.info(user.selected_language)
    return {
        "code": meta["code"],
        "name": meta["name"],
        "title": meta["title"],
        "flag": meta["flag"],
        "has_content": _language_has_content(meta["code"]),
    }


@app.post("/me/language")
def set_my_language(payload: schemas.LanguageSelectIn,
                    db: Session = Depends(get_app_db),
                    user: models.User = Depends(get_current_user)):
    if not languages.is_supported(payload.language):
        raise HTTPException(400, f"Nieobsługiwany język: {payload.language}")
    # user pochodzi z get_current_user (z innej sesji); pobierz na świeżo
    fresh = db.query(models.User).filter(models.User.id == user.id).first()
    if not fresh:
        raise HTTPException(404, "Użytkownik nie istnieje")
    fresh.selected_language = payload.language
    db.commit()
    db.refresh(fresh)
    meta = languages.info(fresh.selected_language)
    return {
        "code": meta["code"],
        "name": meta["name"],
        "title": meta["title"],
        "flag": meta["flag"],
        "has_content": _language_has_content(meta["code"]),
    }


# ═══════════════════════════════════════════════════════════════════════════
# ROOMS (content)
# ═══════════════════════════════════════════════════════════════════════════

def _room_stats(content_db: Session, room: models.Room, user_id: int) -> schemas.RoomOut:
    word_count = content_db.query(models.Word).filter(models.Word.room_id == room.id).count()
    verb_count = content_db.query(models.Verb).filter(models.Verb.room_id == room.id).count()
    known = content_db.query(models.Progress).filter(
        models.Progress.user_id == user_id,
        models.Progress.room_id == room.id,
        models.Progress.status == "znam",
    ).count()
    due_today = content_db.query(models.Progress).filter(
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
def get_rooms(content_db: Session = Depends(get_content_db),
              user: models.User = Depends(get_current_user)):
    rooms = content_db.query(models.Room).order_by(models.Room.id).all()
    return [_room_stats(content_db, r, user.id) for r in rooms]


@app.get("/rooms/{room_id}", response_model=schemas.RoomOut)
def get_room(room_id: int,
             content_db: Session = Depends(get_content_db),
             user: models.User = Depends(get_current_user)):
    room = content_db.query(models.Room).filter(models.Room.id == room_id).first()
    if not room:
        raise HTTPException(404, "Room not found")
    return _room_stats(content_db, room, user.id)


# ═══════════════════════════════════════════════════════════════════════════
# WORDS
# ═══════════════════════════════════════════════════════════════════════════

@app.get("/rooms/{room_id}/words", response_model=List[schemas.WordOut])
def get_words(room_id: int, q: Optional[str] = None, category: Optional[str] = None,
              content_db: Session = Depends(get_content_db),
              user: models.User = Depends(get_current_user)):
    query = content_db.query(models.Word).filter(models.Word.room_id == room_id)
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
        prog = content_db.query(models.Progress).filter(
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
def get_word_categories(room_id: int,
                        content_db: Session = Depends(get_content_db),
                        user: models.User = Depends(get_current_user)):
    cats = content_db.query(models.Word.category).filter(
        models.Word.room_id == room_id
    ).distinct().all()
    return [c[0] for c in cats if c[0]]


# ═══════════════════════════════════════════════════════════════════════════
# VERBS
# ═══════════════════════════════════════════════════════════════════════════

@app.get("/rooms/{room_id}/verbs", response_model=List[schemas.VerbOut])
def get_verbs(room_id: int, q: Optional[str] = None,
              content_db: Session = Depends(get_content_db),
              user: models.User = Depends(get_current_user)):
    query = content_db.query(models.Verb).filter(models.Verb.room_id == room_id)
    if q:
        like = f"%{q}%"
        query = query.filter(
            (models.Verb.infinitive.ilike(like)) | (models.Verb.polish.ilike(like))
        )
    verbs = query.order_by(models.Verb.id).all()
    result = []
    for v in verbs:
        prog = content_db.query(models.Progress).filter(
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


# ═══════════════════════════════════════════════════════════════════════════
# REVIEWS / LEARNING SESSION / PROGRESS
# ═══════════════════════════════════════════════════════════════════════════

@app.get("/rooms/{room_id}/reviews")
def get_reviews(room_id: int,
                content_db: Session = Depends(get_content_db),
                user: models.User = Depends(get_current_user)):
    today = date.today()
    progs = content_db.query(models.Progress).filter(
        models.Progress.user_id == user.id,
        models.Progress.room_id == room_id,
        models.Progress.next_review <= today,
        models.Progress.status != "nowe",
    ).all()
    items = []
    for p in progs:
        if p.item_type == "word":
            w = content_db.query(models.Word).filter(models.Word.id == p.item_id).first()
            if w:
                items.append({"type": "word", "id": w.id, "croatian": w.croatian,
                              "polish": w.polish, "category": w.category,
                              "status": p.status, "progress_id": p.id})
        else:
            v = content_db.query(models.Verb).filter(models.Verb.id == p.item_id).first()
            if v:
                items.append({"type": "verb", "id": v.id, "croatian": v.infinitive,
                              "polish": v.polish, "status": p.status, "progress_id": p.id,
                              "conj_ja": v.conj_ja, "conj_ti": v.conj_ti,
                              "conj_on": v.conj_on, "conj_mi": v.conj_mi,
                              "conj_vi": v.conj_vi, "conj_oni": v.conj_oni})
    return {"items": items, "count": len(items)}


@app.get("/rooms/{room_id}/learning-session")
def get_learning_session(room_id: int, limit: int = 20, new_limit: int = 5,
                         content_db: Session = Depends(get_content_db),
                         user: models.User = Depends(get_current_user)):
    """Kolejka kart sesji nauki. Priorytet: do powtórki dziś → trudne →
    uczę się → nowe. Per (user, język)."""
    today = date.today()

    def serialize(item_type, item_id, status):
        if item_type == "word":
            w = content_db.query(models.Word).filter(models.Word.id == item_id).first()
            if not w:
                return None
            return {
                "type": "word", "id": w.id, "croatian": w.croatian,
                "polish": w.polish, "category": w.category, "status": status,
            }
        else:
            v = content_db.query(models.Verb).filter(models.Verb.id == item_id).first()
            if not v:
                return None
            return {
                "type": "verb", "id": v.id, "croatian": v.infinitive,
                "polish": v.polish, "status": status,
                "conj_ja": v.conj_ja, "conj_ti": v.conj_ti, "conj_on": v.conj_on,
                "conj_mi": v.conj_mi, "conj_vi": v.conj_vi, "conj_oni": v.conj_oni,
            }

    items = []
    seen = set()

    # 1) do powtórki na dziś
    for p in content_db.query(models.Progress).filter(
        models.Progress.user_id == user.id,
        models.Progress.room_id == room_id,
        models.Progress.next_review <= today,
        models.Progress.status != "nowe",
    ).order_by(models.Progress.next_review).all():
        key = (p.item_type, p.item_id)
        if key in seen: continue
        s = serialize(p.item_type, p.item_id, p.status)
        if s: seen.add(key); items.append(s)

    # 2) trudne (jeszcze nie dodane)
    for p in content_db.query(models.Progress).filter(
        models.Progress.user_id == user.id,
        models.Progress.room_id == room_id,
        models.Progress.status == "trudne",
    ).all():
        key = (p.item_type, p.item_id)
        if key in seen: continue
        s = serialize(p.item_type, p.item_id, p.status)
        if s: seen.add(key); items.append(s)

    # 3) uczę się (jeszcze nie dodane)
    for p in content_db.query(models.Progress).filter(
        models.Progress.user_id == user.id,
        models.Progress.room_id == room_id,
        models.Progress.status == "uczę się",
    ).all():
        key = (p.item_type, p.item_id)
        if key in seen: continue
        s = serialize(p.item_type, p.item_id, p.status)
        if s: seen.add(key); items.append(s)

    # 4) nowe — bez progresu lub status=nowe
    if len(items) < limit:
        all_progress = content_db.query(models.Progress).filter(
            models.Progress.user_id == user.id,
            models.Progress.room_id == room_id,
            models.Progress.status != "nowe",
        ).all()
        excluded_word_ids = {p.item_id for p in all_progress if p.item_type == "word"}
        excluded_verb_ids = {p.item_id for p in all_progress if p.item_type == "verb"}

        new_words_q = content_db.query(models.Word).filter(models.Word.room_id == room_id)
        if excluded_word_ids:
            new_words_q = new_words_q.filter(~models.Word.id.in_(excluded_word_ids))
        budget = min(new_limit, limit - len(items))
        for w in new_words_q.order_by(models.Word.id).limit(budget).all():
            items.append({
                "type": "word", "id": w.id, "croatian": w.croatian,
                "polish": w.polish, "category": w.category, "status": "nowe",
            })

        if len(items) < limit:
            new_verbs_q = content_db.query(models.Verb).filter(models.Verb.room_id == room_id)
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


REVIEW_DAYS = {"nie wiem": 1, "prawie": 3, "wiem": 7}
STATUS_MAP = {"nie wiem": "uczę się", "prawie": "uczę się", "wiem": "znam"}


@app.post("/progress", response_model=schemas.ProgressOut)
def update_progress(payload: schemas.ProgressIn,
                    content_db: Session = Depends(get_content_db),
                    user: models.User = Depends(get_current_user)):
    today = date.today()
    days = REVIEW_DAYS.get(payload.answer, 1)
    new_status = STATUS_MAP.get(payload.answer, "uczę się")
    if payload.answer == "nie wiem":
        new_status = "trudne"

    prog = content_db.query(models.Progress).filter(
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
        content_db.add(prog)
    content_db.commit()
    content_db.refresh(prog)
    return prog


@app.post("/progress/start")
def start_learning(payload: schemas.StartLearning,
                   content_db: Session = Depends(get_content_db),
                   user: models.User = Depends(get_current_user)):
    today = date.today()
    existing = content_db.query(models.Progress).filter(
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
        content_db.add(prog)
        content_db.commit()
    return {"ok": True}


# ═══════════════════════════════════════════════════════════════════════════
# SENTENCES
# ═══════════════════════════════════════════════════════════════════════════

@app.get("/rooms/{room_id}/sentences", response_model=List[schemas.SentenceOut])
def get_sentences(room_id: int,
                  content_db: Session = Depends(get_content_db),
                  user: models.User = Depends(get_current_user)):
    sentences = content_db.query(models.Sentence).filter(
        models.Sentence.user_id == user.id,
        models.Sentence.room_id == room_id,
    ).order_by(models.Sentence.created_at.desc()).all()
    return sentences


@app.post("/sentences", response_model=schemas.SentenceOut)
def create_sentence(payload: schemas.SentenceIn,
                    content_db: Session = Depends(get_content_db),
                    user: models.User = Depends(get_current_user)):
    s = models.Sentence(
        user_id=user.id,
        room_id=payload.room_id,
        text_hr=payload.text_hr,
        text_pl=payload.text_pl,
        note=payload.note,
        status=payload.status or "do sprawdzenia",
    )
    content_db.add(s)
    content_db.commit()
    content_db.refresh(s)
    return s


@app.delete("/sentences/{sentence_id}")
def delete_sentence(sentence_id: int,
                    content_db: Session = Depends(get_content_db),
                    user: models.User = Depends(get_current_user)):
    s = content_db.query(models.Sentence).filter(
        models.Sentence.id == sentence_id,
        models.Sentence.user_id == user.id,
    ).first()
    if not s:
        raise HTTPException(404)
    content_db.delete(s)
    content_db.commit()
    return {"ok": True}


# ═══════════════════════════════════════════════════════════════════════════
# DASHBOARD
# ═══════════════════════════════════════════════════════════════════════════

@app.get("/dashboard")
def get_dashboard(content_db: Session = Depends(get_content_db),
                  user: models.User = Depends(get_current_user)):
    total_words = content_db.query(models.Word).count()
    total_verbs = content_db.query(models.Verb).count()
    known = content_db.query(models.Progress).filter(
        models.Progress.user_id == user.id,
        models.Progress.status == "znam",
    ).count()
    learning = content_db.query(models.Progress).filter(
        models.Progress.user_id == user.id,
        models.Progress.status == "uczę się",
    ).count()
    hard = content_db.query(models.Progress).filter(
        models.Progress.user_id == user.id,
        models.Progress.status == "trudne",
    ).count()
    due = content_db.query(models.Progress).filter(
        models.Progress.user_id == user.id,
        models.Progress.next_review <= date.today(),
        models.Progress.status != "nowe",
    ).count()
    recent_sentences = content_db.query(models.Sentence).filter(
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
