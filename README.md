# 🇭🇷 Chorwacki od podstaw

Aplikacja do nauki języka chorwackiego metodą pałacu pamięci.

## Wymagania

- Docker Desktop (lub Docker + Docker Compose)

## Uruchomienie

```bash
# Sklonuj lub rozpakuj projekt
cd chorwacki

# Zbuduj i uruchom
docker compose up -d --build

# Sprawdź logi (opcjonalnie)
docker compose logs -f
```

## Adresy

| Serwis   | URL                          |
|----------|------------------------------|
| Frontend | http://localhost:3000        |
| API      | http://localhost:8000        |
| API docs | http://localhost:8000/docs   |

## Struktura projektu

```
chorwacki/
├── backend/
│   ├── main.py          # FastAPI endpoints
│   ├── models.py        # SQLAlchemy modele
│   ├── schemas.py       # Pydantic schematy
│   ├── database.py      # Konfiguracja SQLite
│   ├── seed.py          # Dane startowe (100 słów + 100 cz.)
│   ├── requirements.txt
│   └── Dockerfile
├── frontend/
│   ├── static/
│   │   ├── index.html       # Strona główna — 4 pokoje
│   │   ├── css/style.css    # Globalny styl
│   │   ├── js/api.js        # Klient API
│   │   └── pages/room.html  # Widok pokoju
│   ├── nginx.conf
│   └── Dockerfile
├── docker-compose.yml
└── README.md
```

## Pokoje pałacu pamięci

| Pokój | Nazwa     | Zawartość                    |
|-------|-----------|------------------------------|
| 1     | Korytarz  | 100 słów + 100 czasowników   |
| 2     | Kuchnia   | miejsce na 200 słów          |
| 3     | Salon     | miejsce na 300 słów          |
| 4     | Biblioteka| miejsce na 400 słów          |

## API Endpoints

| Metoda | Endpoint                      | Opis                        |
|--------|-------------------------------|-----------------------------|
| GET    | /rooms                        | Lista pokoi ze statystykami |
| GET    | /rooms/{id}/words             | Słowa w pokoju              |
| GET    | /rooms/{id}/verbs             | Czasowniki w pokoju         |
| GET    | /rooms/{id}/reviews           | Słowa do powtórki dziś      |
| POST   | /progress                     | Aktualizuj postęp           |
| POST   | /progress/start               | Zacznij uczyć się słowa     |
| GET    | /rooms/{id}/sentences         | Zdania w pokoju             |
| POST   | /sentences                    | Dodaj zdanie                |
| DELETE | /sentences/{id}               | Usuń zdanie                 |
| GET    | /dashboard                    | Statystyki globalne         |

## System powtórek (Spaced Repetition)

| Odpowiedź | Status      | Następna powtórka |
|-----------|-------------|-------------------|
| Nie wiem  | trudne      | +1 dzień          |
| Prawie    | uczę się    | +3 dni            |
| Wiem      | znam        | +7 dni            |

## Zatrzymanie

```bash
docker compose down        # zatrzymaj kontenery
docker compose down -v     # zatrzymaj i usuń bazę danych
```
