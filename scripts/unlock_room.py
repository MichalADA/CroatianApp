#!/usr/bin/env python3
"""
Odblokuj pokój dla użytkownika — oznacz wszystkie słowa i czasowniki jako "znam".

Użycie:
    python scripts/unlock_room.py --user-id 1 --room-id 3
    python scripts/unlock_room.py --user-id 1 --room-id 3 --lang hr
    python scripts/unlock_room.py --user-id 1 --all-rooms
    python scripts/unlock_room.py --list-users

Opcje:
    --user-id    ID użytkownika (wymagane, chyba że --list-users)
    --room-id    ID pokoju do odblokowania
    --all-rooms  Odblokuj wszystkie pokoje naraz
    --lang       Kod języka (domyślnie: hr)
    --dry-run    Pokaż co zostałoby zmienione, bez zapisu
    --list-users Wylistuj dostępnych użytkowników
"""

import argparse
import os
import sys
from datetime import date

# Dodaj katalog backend do ścieżki
sys.path.insert(0, os.path.join(os.path.dirname(__file__), "..", "backend"))

from database import AppSessionLocal, open_lang_session
import models


def list_users():
    db = AppSessionLocal()
    try:
        users = db.query(models.User).order_by(models.User.id).all()
        if not users:
            print("Brak użytkowników w bazie.")
            return
        print(f"{'ID':<6} {'Login':<20} {'Email':<30} {'Język'}")
        print("-" * 65)
        for u in users:
            print(f"{u.id:<6} {u.username:<20} {u.email:<30} {u.selected_language}")
    finally:
        db.close()


def unlock_room(user_id: int, room_id: int, lang: str, dry_run: bool):
    content_db = open_lang_session(lang)
    try:
        room = content_db.query(models.Room).filter(models.Room.id == room_id).first()
        if not room:
            print(f"❌ Pokój {room_id} nie istnieje w bazie języka '{lang}'.")
            return 0

        words = content_db.query(models.Word).filter(models.Word.room_id == room_id).all()
        verbs = content_db.query(models.Verb).filter(models.Verb.room_id == room_id).all()

        today = date.today()
        updated = 0
        created = 0

        items = [("word", w.id) for w in words] + [("verb", v.id) for v in verbs]

        for item_type, item_id in items:
            existing = (
                content_db.query(models.Progress)
                .filter_by(user_id=user_id, item_type=item_type, item_id=item_id)
                .first()
            )
            if existing:
                if existing.status != "znam":
                    if not dry_run:
                        existing.status = "znam"
                        existing.last_reviewed = today
                        existing.next_review = today
                    updated += 1
            else:
                if not dry_run:
                    content_db.add(
                        models.Progress(
                            user_id=user_id,
                            item_type=item_type,
                            item_id=item_id,
                            room_id=room_id,
                            status="znam",
                            last_reviewed=today,
                            next_review=today,
                            review_count=1,
                        )
                    )
                created += 1

        if not dry_run:
            content_db.commit()

        prefix = "[DRY-RUN] " if dry_run else ""
        print(
            f"{prefix}✅ Pokój {room_id} ({room.name}) — "
            f"{len(words)} słów + {len(verbs)} czasowników | "
            f"nowe: {created}, zaktualizowane: {updated}"
        )
        return created + updated

    finally:
        content_db.close()


def main():
    parser = argparse.ArgumentParser(description="Odblokuj pokój dla użytkownika")
    parser.add_argument("--user-id", type=int, help="ID użytkownika")
    parser.add_argument("--room-id", type=int, help="ID pokoju")
    parser.add_argument("--all-rooms", action="store_true", help="Odblokuj wszystkie pokoje")
    parser.add_argument("--lang", default="hr", help="Kod języka (domyślnie: hr)")
    parser.add_argument("--dry-run", action="store_true", help="Tylko podgląd, bez zapisu")
    parser.add_argument("--list-users", action="store_true", help="Wylistuj użytkowników")
    args = parser.parse_args()

    if args.list_users:
        list_users()
        return

    if not args.user_id:
        parser.error("Podaj --user-id (lub użyj --list-users żeby zobaczyć dostępnych użytkowników)")

    if not args.room_id and not args.all_rooms:
        parser.error("Podaj --room-id lub --all-rooms")

    app_db = AppSessionLocal()
    try:
        user = app_db.query(models.User).filter(models.User.id == args.user_id).first()
        if not user:
            print(f"❌ Użytkownik ID={args.user_id} nie istnieje.")
            sys.exit(1)
        print(f"👤 Użytkownik: {user.username} (ID={user.id}), język: {args.lang}")
    finally:
        app_db.close()

    if args.dry_run:
        print("🔍 Tryb podglądu (dry-run) — nic nie zostanie zapisane.\n")

    if args.all_rooms:
        content_db = open_lang_session(args.lang)
        try:
            rooms = content_db.query(models.Room).order_by(models.Room.id).all()
        finally:
            content_db.close()

        total = 0
        for room in rooms:
            total += unlock_room(args.user_id, room.id, args.lang, args.dry_run)
        print(f"\n🏆 Łącznie przetworzono {total} wpisów.")
    else:
        unlock_room(args.user_id, args.room_id, args.lang, args.dry_run)


if __name__ == "__main__":
    main()
