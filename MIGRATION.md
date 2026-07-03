# Migracja Memory Palace → Flutter

Podsumowanie migracji frontendu z HTML/CSS/JS do Fluttera z zachowaniem
istniejącego backendu FastAPI.

## 🏗️ Architektura

- **Clean Architecture** (data + domain + presentation per feature)
- **Feature-first** — każdy moduł żyje w `lib/features/<name>/`
- **State + DI**: Riverpod 2 (Providers + StateNotifier)
- **Routing**: GoRouter z auth guards (przez `refreshListenable`)
- **HTTP**: Dio z `AuthInterceptor` (Bearer + auto-logout na 401)
- **Modele**: Freezed + json_serializable (codegen)
- **Persystencja tokena**: flutter_secure_storage (Keychain / EncryptedSharedPreferences)

```
flutter_app/lib/
├── main.dart                      # entry + ProviderScope overrides
├── app.dart                       # MaterialApp.router + theme
├── core/
│   ├── api/{dio_client, auth_interceptor}
│   ├── auth/{auth_controller, auth_state}
│   ├── config/app_config           # API_BASE_URL z env
│   ├── errors/{failure, error_mapper}
│   ├── router/{app_router, routes}
│   ├── storage/secure_storage
│   ├── theme/{app_theme, app_colors, theme_controller}
│   └── widgets/{splash, loading, error, empty}
└── features/
    ├── auth/                       # login + register
    ├── dashboard/                  # main screen + stats
    ├── languages/                  # language switcher
    ├── rooms/                      # rooms + words + verbs
    ├── learning/                   # flashcards + SRS reviews
    ├── sentences/                  # CRUD zdań
    ├── games/                      # matching + scramble
    ├── alphabet/                   # HR alphabet + audio
    └── profile/                    # settings (theme + logout)
```

## 📦 Zależności (`pubspec.yaml`)

| Kategoria | Pakiet |
|---|---|
| State/DI | `flutter_riverpod`, `riverpod_annotation` |
| Routing | `go_router` |
| HTTP | `dio` |
| Storage | `flutter_secure_storage`, `shared_preferences` |
| Modele | `freezed_annotation`, `json_annotation` |
| UI | `google_fonts`, `cached_network_image` |
| Audio | `audioplayers` |
| Codegen | `build_runner`, `freezed`, `json_serializable`, `riverpod_generator` |

## 🔌 Integracja z API

Backend zostaje bez zmian (FastAPI + hybrydowy SQLite: `app.db` + `languages/*.db`).

Wszystkie endpointy zmapowane w Flutter:

| Backend endpoint | Flutter warstwa |
|---|---|
| `POST /auth/register`, `/auth/login` | `AuthApi`, `AuthRepository` |
| `GET /auth/me`, `PATCH /me/settings` | `AuthApi` |
| `GET /languages`, `GET/POST /me/language` | `LanguagesApi`, `LanguagesRepository` |
| `GET /rooms`, `GET /rooms/{id}` | `RoomsApi`, `RoomsRepository` |
| `GET /rooms/{id}/words[?q&category]` + `/categories` | `WordsApi`, `WordsRepository` |
| `GET /rooms/{id}/verbs?q` | `WordsApi.verbs()` |
| `GET /rooms/{id}/learning-session`, `/reviews` | `LearningApi`, `LearningRepository` |
| `POST /progress`, `/progress/start` | `LearningRepository.submitAnswer()` |
| `GET /rooms/{id}/sentences`, `POST /sentences`, `DELETE /sentences/{id}` | `SentencesRepository` |
| `GET /dashboard` | `DashboardApi`, `DashboardRepository` |

Backend zwraca `snake_case`, Flutter DTO są `camelCase` — mapping robimy w
warstwie `Api` (bez modyfikacji backendu). Przykład: `croatian` z backendu →
`targetWord` w modelu `Word` — nazwy pola żyją niezależnie od języka.

## 🚀 Uruchomienie

### Docker (web preview)

```bash
docker compose up -d --build
```

- Frontend: http://localhost:3000
- API: http://localhost:8000

### Lokalny dev (mobile/desktop)

```bash
cd flutter_app
flutter pub get
dart run build_runner build --delete-conflicting-outputs

# Android emulator (mapped host)
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000

# iOS symulator
flutter run --dart-define=API_BASE_URL=http://localhost:8000
```

### Buildy produkcyjne

```bash
flutter build apk --release --dart-define=API_BASE_URL=https://api.example.com
flutter build ios --release --dart-define=API_BASE_URL=https://api.example.com
flutter build web --release --dart-define=API_BASE_URL=https://api.example.com
```

## ✅ Zmapowane funkcjonalności

- [x] Login / Register / auto-logout na 401
- [x] Dashboard: statystyki, siatka pokoi, blokowanie sekwencyjne, ostatnie zdania
- [x] Language switcher (hr/es/el) z synchronizacją na backend
- [x] Rooms → Nauka / Słownik / Czasowniki / Powtórki / Zdania / Gry (bottom nav)
- [x] Search + kategorie w słowniku, search w czasownikach
- [x] Sesja nauki (flashcards): reveal, przykłady, koniugacje verbs, SRS z 3 przyciskami, summary
- [x] Powtórki dzienne z tym samym flashcard viewem
- [x] Sentences: lista + modal do dodawania + delete
- [x] Games: Dopasowanie (matching pairs), Rozsypanka (letter scramble)
- [x] Alfabet chorwacki: 30 liter + audio (audioplayers z assets) + zasady wymowy
- [x] Ustawienia: motyw dark/light z synchronizacją, logout
- [x] Docker Compose: backend + Flutter web frontend (multi-stage build)

## 📋 TODO / kolejne kroki

### Niezbędne przed pierwszym uruchomieniem
- [ ] `cd flutter_app && flutter pub get`
- [ ] `dart run build_runner build --delete-conflicting-outputs` — generuje pliki `*.freezed.dart` i `*.g.dart`
- [ ] Skopiować assety z `frontend/static/audio/hr/alphabet/*.mp3` do `flutter_app/assets/audio/hr/alphabet/` (jeśli chcesz audio alfabetu)
- [ ] Skopiować `frontend/static/img/rooms/*.jpg` do `flutter_app/assets/images/rooms/` (jeśli chcesz obrazki pokoi)
- [ ] Wygenerować platform folders: `flutter create --platforms=android,ios,web --org com.memorypalace .` (jeśli chcesz Android/iOS)

### Znane ograniczenia obecnej implementacji
- **Wisielec** (3. gra z oryginału) — nie zaimplementowany, do dodania w `games_tab.dart`
- **Room images** — placeholder emoji zamiast obrazków (aktualnie backend zwraca `emoji`, ale zostały użyte klasyczne assety w oryginale)
- **Codegen** — pliki `*.freezed.dart` i `*.g.dart` nie są commitowane (są w `.gitignore`), trzeba wygenerować lokalnie
- **Tab „Progres"** — pominięty w RoomScreen (można dodać jako 7. bottom nav, lub zintegrować z Dashboard)
- **i18n** — struktura `l10n/` przygotowana, ale nie ma jeszcze plików ARB (aplikacja jest po polsku hardcoded)

### Rozszerzenia w przyszłości (architektura gotowa)
- **Offline mode**: dodać cache Isar/Drift w warstwie repository — struktura już rozdzielona (`Repository` vs `Api`)
- **AI tutor**: nowy feature `features/tutor/` z osobnym endpointem, wpięcie do Room bottom nav
- **Speech recognition**: pakiet `speech_to_text`, integracja z LearningTab (odpowiedź głosem)
- **Pronunciation scoring**: `whisper.cpp` bindings lub backend endpoint
- **Cloud sync**: JWT już jest, wystarczy zamienić `sqlite` w backendzie na `postgres` (lub SQLite w chmurze)
- **Premium subscriptions**: `in_app_purchase` pakiet, nowy feature `features/subscription/`
- **Push notifications**: `firebase_messaging`, nowy provider `NotificationsService` w core
- **Achievements + statistics**: rozszerzyć DashboardSummary i dodać nowy ekran
- **Kolejne języki**: dodać wpis w backendowym `languages.py`, Flutter podchwytuje automatycznie
- **Web version**: już działa przez Docker (`http://localhost:3000`)

## 🏛️ Struktura Clean Architecture — jak dodać nowy feature

1. Utwórz `features/<name>/`:
   ```
   data/
     ├── models/         # DTO + freezed
     ├── <name>_api.dart # Dio calls (endpoint mapping)
     └── <name>_repository.dart
   domain/
     ├── entities/       # Immutable freezed entities
     └── <name>_repository.dart  # (opcjonalny interface)
   presentation/
     ├── <name>_screen.dart
     ├── providers/      # Riverpod
     └── widgets/
   ```

2. Zarejestruj providery:
   ```dart
   final myApiProvider = Provider((ref) => MyApi(ref.watch(dioProvider)));
   final myRepositoryProvider = Provider((ref) => MyRepository(ref.watch(myApiProvider)));
   ```

3. Dodaj route w `core/router/app_router.dart` i konstantę w `routes.dart`.

## 🔒 Bezpieczeństwo

- JWT trzymany w `flutter_secure_storage` (Keychain iOS / EncryptedSharedPreferences Android)
- Automatyczne dołączanie `Authorization: Bearer` przez `AuthInterceptor`
- Auto-logout na 401 (interceptor czyści token + `AuthController.handleUnauthorized()`)
- Brak wrażliwych danych w kodzie (API_BASE_URL przez `--dart-define`)
- Web: sekret nie trafia na klienta (JWT tworzy backend, klient tylko trzyma)

## 🧪 Testowanie (do dopisania)

Zależności `mocktail` + `flutter_test` już są w `pubspec.yaml`. Sugerowana strategia:

- **Repository tests**: mockuj `Api`, weryfikuj mapowanie i przekazywanie do `ErrorMapper`
- **Controller tests**: mockuj `Repository`, weryfikuj przejścia stanów
- **Widget tests**: golden tests dla ekranów logowania, dashboardu, flashcard
- **Integration**: `patrol` lub `flutter_driver` dla flow login → dashboard → nauka

## 📞 Komunikacja Docker

Kontener Flutter (nginx) → backend (FastAPI):
- Wewnątrz sieci Docker: `http://backend:8000` (Docker DNS)
- Ale ponieważ Flutter web jest _client-side_, request idzie z **przeglądarki** (nie z kontenera nginx)
- Dlatego `API_BASE_URL` musi być publicznym adresem widocznym z przeglądarki (`http://localhost:8000` w dev)

W produkcji ustaw:
```bash
API_BASE_URL=https://api.example.com docker compose up -d --build
```

## 🌍 Docelowa wizja

Architektura jest przygotowana na skalowanie do **komercyjnego produktu**:
- Nowe języki bez zmian w kliencie (backend rozpoznaje)
- Offline-first z minimalnym redesignem (repository pattern gotowy)
- Feature toggling przez Riverpod providers
- Multi-tenant przez rozszerzenie backend `User.tenant_id` (bez wpływu na klienta)
- Web + Android + iOS z jednego kodu
