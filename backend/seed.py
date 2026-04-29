import json
import os
import models

ROOMS = [
    {"id": 1, "name": "Korytarz", "description": "Pierwszy krok w nauce. 100 słów i 100 czasowników — fundament języka chorwackiego.", "emoji": "🚪", "color": "#e8c07d"},
    {"id": 2, "name": "Kuchnia", "description": "Kolejny etap nauki. 200 nowych słów związanych z codziennym życiem.", "emoji": "🍳", "color": "#7dc5e8"},
    {"id": 3, "name": "Salon", "description": "Zaawansowane słownictwo. 300 słów do swobodnej rozmowy.", "emoji": "🛋️", "color": "#7de8a8"},
    {"id": 4, "name": "Sypialnia", "description": "Emocje, relacje i życie prywatne. 300 słów.", "emoji": "🛏️", "color": "#e89f7d"},
    {"id": 5, "name": "Biblioteka", "description": "Mistrzostwo języka. 400 słów na najwyższym poziomie.", "emoji": "📚", "color": "#c07de8"},
    {"id": 6, "name": "Miasto", "description": "Język prawdziwego życia. 600 słów do poruszania się po świecie.", "emoji": "🏙️", "color": "#7d9fe8"},
]

DATA_DIR = os.path.join(os.path.dirname(__file__), "data")


def _load_json(room_id: int) -> dict | None:
    path = os.path.join(DATA_DIR, f"room{room_id}_data.json")
    if not os.path.exists(path):
        return None
    with open(path, encoding="utf-8") as f:
        return json.load(f)


def _seed_room(db, room_id: int, data: dict):
    words = data.get("words", [])
    verbs = data.get("verbs", [])

    for w in words:
        db.add(models.Word(
            room_id=room_id,
            croatian=w["croatian"],
            polish=w["polish"],
            category=w["category"],
            difficulty=w.get("difficulty", 1),
        ))

    for v in verbs:
        db.add(models.Verb(
            room_id=room_id,
            infinitive=v["infinitive"],
            polish=v["polish"],
            conj_ja=v["conj_ja"],
            conj_ti=v["conj_ti"],
            conj_on=v["conj_on"],
            conj_mi=v["conj_mi"],
            conj_vi=v["conj_vi"],
            conj_oni=v["conj_oni"],
        ))

    print(f"✅ Pokój {room_id}: {len(words)} słów, {len(verbs)} czasowników.")


def run_incremental(db):
    """
    Seed bezpieczny przy każdym restarcie.
    - Dodaje brakujące pokoje (z ROOMS).
    - Dla każdego pokoju ładuje dane z data/roomN_data.json
      TYLKO jeśli pokój jest jeszcze pusty (brak słów I brak czasowników).
    - Jeśli chcesz wymusić przeładowanie pokoju — użyj run_force(db, room_id).
    """
    # 1) Pokoje
    existing_ids = {r.id for r in db.query(models.Room).all()}
    for r in ROOMS:
        if r["id"] not in existing_ids:
            db.add(models.Room(**r))
            print(f"🏠 Dodano pokój {r['id']}: {r['name']}")
    db.flush()

    # 2) Treści per pokój
    for room in ROOMS:
        room_id = room["id"]

        data = _load_json(room_id)
        if data is None:
            print(f"⚠️  Pokój {room_id}: brak pliku data/room{room_id}_data.json, pomijam.")
            continue

        has_words = db.query(models.Word).filter(models.Word.room_id == room_id).count() > 0
        has_verbs = db.query(models.Verb).filter(models.Verb.room_id == room_id).count() > 0

        if has_words and has_verbs:
            print(f"⏭️  Pokój {room_id}: już ma dane, pomijam.")
            continue

        _seed_room(db, room_id, data)

    db.commit()
    print("✅ Seed zakończony.")


def run_force(db, room_id: int):
    """
    Wymuś przeładowanie konkretnego pokoju.
    Usuwa wszystkie słowa i czasowniki z danego pokoju i ładuje je na nowo z JSON.
    Uwaga: ID rekordów się zmienią — progress użytkowników może stracić powiązanie.
    """
    data = _load_json(room_id)
    if data is None:
        print(f"❌ Brak pliku data/room{room_id}_data.json")
        return

    deleted_words = db.query(models.Word).filter(models.Word.room_id == room_id).delete()
    deleted_verbs = db.query(models.Verb).filter(models.Verb.room_id == room_id).delete()
    print(f"🗑️  Pokój {room_id}: usunięto {deleted_words} słów i {deleted_verbs} czasowników.")

    _seed_room(db, room_id, data)
    db.commit()
    print(f"✅ Pokój {room_id}: przeładowany.")


def run(db):
    """Alias dla starych wywołań — zachowana kompatybilność."""
    run_incremental(db)