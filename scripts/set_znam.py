import sys
sys.path.insert(0, '/app')

from database import AppSessionLocal, open_lang_session
import models
from datetime import date

USERNAME = "michal"
LANG = "hr"
ROOM_ID = 1  # zmień jeśli chcesz inny pokój, albo ustaw na None żeby ustawić wszystkie

app_db = AppSessionLocal()
user = app_db.query(models.User).filter(models.User.username == USERNAME).first()
if not user:
    print(f" Nie znaleziono usera '{USERNAME}'")
    sys.exit(1)
print(f" User: {user.username} (id={user.id})")

content_db = open_lang_session(LANG)

words_q = content_db.query(models.Word)
verbs_q = content_db.query(models.Verb)
if ROOM_ID is not None:
    words_q = words_q.filter(models.Word.room_id == ROOM_ID)
    verbs_q = verbs_q.filter(models.Verb.room_id == ROOM_ID)

words = words_q.all()
verbs = verbs_q.all()

count = 0
for w in words:
    prog = content_db.query(models.Progress).filter(
        models.Progress.user_id == user.id,
        models.Progress.room_id == w.room_id,
        models.Progress.item_type == "word",
        models.Progress.item_id == w.id,
    ).first()
    if prog:
        prog.status = "znam"
        prog.next_review = date(2099, 1, 1)
    else:
        content_db.add(models.Progress(
            user_id=user.id, room_id=w.room_id,
            item_type="word", item_id=w.id,
            status="znam", next_review=date(2099, 1, 1),
        ))
    count += 1

for v in verbs:
    prog = content_db.query(models.Progress).filter(
        models.Progress.user_id == user.id,
        models.Progress.room_id == v.room_id,
        models.Progress.item_type == "verb",
        models.Progress.item_id == v.id,
    ).first()
    if prog:
        prog.status = "znam"
        prog.next_review = date(2099, 1, 1)
    else:
        content_db.add(models.Progress(
            user_id=user.id, room_id=v.room_id,
            item_type="verb", item_id=v.id,
            status="znam", next_review=date(2099, 1, 1),
        ))
    count += 1

content_db.commit()
print(f"✅ Ustawiono 'znam' dla {count} elementów (pokój {ROOM_ID or 'wszystkie'})")