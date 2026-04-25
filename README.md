# 🌍 Pałac Pamięci — wielojęzyczna aplikacja do nauki

Aplikacja do nauki języków metodą pałacu pamięci. Obecnie obsługuje:

- 🇭🇷 **chorwacki (hr)** — 100 słów + 100 czasowników
- 🇪🇸 **hiszpański (es)** — pusty (do uzupełnienia)
- 🇬🇷 **grecki (el)** — pusty (do uzupełnienia)

## Wymagania

- Docker Desktop (lub Docker + Docker Compose)

## Uruchomienie

```bash
docker compose up -d --build
docker compose logs -f          # opcjonalnie
```

| Serwis   | URL                          |
|----------|------------------------------|
| Frontend | http://localhost:3000        |
| API      | http://localhost:8000        |
| API docs | http://localhost:8000/docs   |

Pierwsze konto testowe: `test` / `test` (auto-tworzone przy starcie).

## Architektura baz (model hybrydowy)

```
/data/
├── app.db                    # users + auth + selected_language (jedno konto = wiele języków)
├── languages/
│   ├── hr.db                 # rooms, words, verbs, progress, sentences (chorwacki)
│   ├── es.db                 # pusty content (hiszpański)
│   └── el.db                 # pusty content (grecki)
├── chorwacki.db.bak.YYYYMMDD_HHMMSS    # backup ze starej monolitycznej bazy (tylko po migracji)
└── chorwacki.db.migrated.YYYYMMDD_HHMMSS
```

**Dlaczego tak**: jeden user, wiele języków. Logowanie wspólne. Postęp i zdania
liczą się per (user, język) — nauka chorwackiego nie miesza się z hiszpańskim.
Każdy język to osobny plik SQLite — łatwo dodawać/eksportować/backupować.

### Wybór języka

`User.selected_language` (kolumna w `app.db`) decyduje, którą bazę contentową
serwer otwiera dla zalogowanego usera. Domyślna wartość: `"hr"`.

Frontend pokazuje switcher języka w prawym górnym rogu — po przełączeniu
wywoływane jest `POST /me/language` i strona się przeładowuje.

## Struktura projektu

```
chorwacki/
├── backend/
│   ├── main.py             # FastAPI: endpointy + startup migracja
│   ├── models.py           # SQLAlchemy: User (AppBase), Room/Word/... (ContentBase)
│   ├── database.py         # engine'y: app + per-language (lazy)
│   ├── languages.py        # rejestr obsługiwanych języków
│   ├── migration.py        # split chorwacki.db → app.db + languages/hr.db
│   ├── auth.py             # JWT (HS256), bcrypt, current_user
│   ├── schemas.py          # Pydantic
│   ├── seed.py             # seed contentu hr (uruchamiany tylko przy pustej hr.db)
│   ├── requirements.txt
│   └── Dockerfile
├── frontend/
│   ├── static/
│   │   ├── index.html              # strona główna (pokoje + switcher języka)
│   │   ├── css/style.css
│   │   ├── js/api.js               # klient API + token + auth
│   │   └── pages/
│   │       ├── login.html          # logowanie + rejestracja
│   │       └── room.html           # widok pokoju (Nauka, Słownik, Czasowniki, …)
│   ├── nginx.conf
│   └── Dockerfile
├── docker-compose.yml
└── README.md
```

## Migracja ze starej monolitycznej bazy

Jeśli masz w volumie `db-data` plik `/data/chorwacki.db` z poprzedniej wersji
(jedna baza dla wszystkiego), po pierwszym starcie nowego backendu **automatycznie**:

1. Tworzy się **backup** `/data/chorwacki.db.bak.YYYYMMDD_HHMMSS` (kopia 1:1).
2. `users` przenoszone do `/data/app.db` (z domyślnym `selected_language='hr'`).
3. `rooms`, `words`, `verbs`, `progress`, `sentences` przenoszone do
   `/data/languages/hr.db`.
4. Stara baza zmienia nazwę na `/data/chorwacki.db.migrated.YYYYMMDD_HHMMSS`,
   żeby nie była otwierana ponownie.

Migracja jest **idempotentna** — drugi start nic nie robi. **Nic nie jest
kasowane** — zarówno backup, jak i zmieniona stara baza zostają w volumie.

### Co jeśli coś pójdzie nie tak

Plik backupu zawsze istnieje. Żeby cofnąć:

```bash
docker compose down
docker run --rm -v <projekt>_db-data:/data alpine sh -c '\
  cd /data && \
  mv app.db app.db.broken && \
  rm -rf languages && \
  cp chorwacki.db.bak.* chorwacki.db'
docker compose up -d --build
```

(Po cofnięciu wrócisz do starej, monolitycznej bazy — ale bez nowych funkcji
hybrydowych.)

## Endpointy API

### Auth (publiczne)
| Metoda | Endpoint              | Opis                              |
|--------|-----------------------|-----------------------------------|
| POST   | `/auth/register`      | Utwórz konto (`username`, `email`, `password`) |
| POST   | `/auth/login`         | Zaloguj (`identifier` = email lub username + `password`) |
| GET    | `/health`             | Health check (bez auth)           |

### Auth (Bearer token w `Authorization`)
| Metoda | Endpoint              | Opis                              |
|--------|-----------------------|-----------------------------------|
| GET    | `/auth/me`            | Aktualnie zalogowany user (z `selected_language`) |

### Języki
| Metoda | Endpoint              | Opis                              |
|--------|-----------------------|-----------------------------------|
| GET    | `/languages`          | Lista wszystkich obsługiwanych języków + flagi `has_content` / `is_current` |
| GET    | `/me/language`        | Aktualnie wybrany język usera     |
| POST   | `/me/language`        | Zmień język (`{"language": "es"}`) |

### Content (zależy od `selected_language` aktualnego usera)
| Metoda | Endpoint                         | Opis                          |
|--------|----------------------------------|-------------------------------|
| GET    | `/rooms`                         | Lista pokoi w aktualnym języku (puste = 0 wyników) |
| GET    | `/rooms/{id}`                    | Pojedynczy pokój              |
| GET    | `/rooms/{id}/words`              | Słowa w pokoju                |
| GET    | `/rooms/{id}/verbs`              | Czasowniki                    |
| GET    | `/rooms/{id}/reviews`            | Słowa do powtórki dziś        |
| GET    | `/rooms/{id}/learning-session`   | Kolejka kart sesji nauki      |
| GET    | `/rooms/{id}/sentences`          | Zdania użytkownika            |
| POST   | `/sentences`                     | Dodaj zdanie                  |
| DELETE | `/sentences/{id}`                | Usuń zdanie                   |
| POST   | `/progress`                      | Aktualizuj postęp             |
| POST   | `/progress/start`                | Zacznij uczyć się słowa       |
| GET    | `/dashboard`                     | Statystyki bieżącego języka   |

## Jak dodać nowy język

1. Otwórz `backend/languages.py` i dopisz wpis:
   ```python
   "de": {
       "code": "de",
       "name": "Niemiecki",
       "title": "Niemiecki od podstaw",
       "flag": "🇩🇪",
   },
   ```
2. Restart backendu (`docker compose up -d --build backend`).
3. Pusta baza `/data/languages/de.db` utworzy się automatycznie ze schematem
   contentu. Wystarczy ją wypełnić — własnym seedem albo importem.

## System powtórek (Spaced Repetition)

| Odpowiedź | Status      | Następna powtórka |
|-----------|-------------|-------------------|
| Nie wiem  | trudne      | +1 dzień          |
| Prawie    | uczę się    | +3 dni            |
| Wiem      | znam        | +7 dni            |

## Zatrzymanie

```bash
docker compose down            # zatrzymaj
docker compose down -v         # zatrzymaj i USUŃ wszystkie dane (też app.db i bazy językowe!)
```
