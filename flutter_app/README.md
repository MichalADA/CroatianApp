# Memory Palace — Flutter app

Klient mobilny (Android/iOS) i web dla API Pałacu Pamięci.

## Wymagania

- Flutter 3.19+ / Dart 3.3+
- Docker (opcjonalnie, do podglądu w przeglądarce)

## Konfiguracja

Adres API przekazywany jest przez `--dart-define=API_BASE_URL=...`.

Domyślne wartości (fallback w `AppConfig`):
- Android emulator → `http://10.0.2.2:8000`
- iOS symulator / desktop / web → `http://localhost:8000`

## Uruchomienie lokalne (dev-loop z hot reload)

**Rekomendowany workflow** — scripty w `scripts/` załatwiają całość:

```bash
# 0. Jednorazowo — sprawdź setup
./scripts/setup.sh

# 1. Android z emulatorem (najbliższe docelowego doświadczenia)
./scripts/dev-android.sh

# 2. Chrome (najszybszy do UI iteracji)
./scripts/dev-web.sh
```

Skrypty automatycznie:
- Startują backend w Dockerze (jeśli nie działa)
- Uruchamiają emulator (jeśli nie działa)
- Robią `pub get` + codegen
- Odpalają `flutter run` z odpowiednim `API_BASE_URL`

W terminalu podczas `flutter run`:
- `r` — **hot reload** (zmiany w kodzie widoczne w ~1s)
- `R` — hot restart (pełne przeładowanie stanu)
- `q` — zakończ

**Bez skryptów, ręcznie:**

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs

# Web
flutter run -d chrome --dart-define=API_BASE_URL=http://localhost:8000

# Android emulator (10.0.2.2 = localhost hosta z wnętrza emulatora)
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000

# iOS symulator
flutter run -d "iPhone 15" --dart-define=API_BASE_URL=http://localhost:8000

# Podpięty telefon przez USB
flutter run --dart-define=API_BASE_URL=http://<LAN-IP>:8000
```

## Pierwszy setup Android SDK / emulator (jednorazowo)

Jeśli `./scripts/setup.sh` mówi że brakuje Android toolchain:

1. Pobierz **Android Studio** — https://developer.android.com/studio
2. Uruchom, w kreatorze wybierz **Standard** (pobierze Android SDK + Emulator)
3. Zaakceptuj licencje:
   ```bash
   flutter doctor --android-licenses
   ```
4. Utwórz emulator:
   - Android Studio → **Tools → Device Manager → Create Virtual Device**
   - Wybierz **Pixel 7**
   - System image: **Android 14 (API 34)** — pobierze się przy pierwszym użyciu
   - Nazwij np. `Pixel_7` (bez spacji!)
5. Sprawdź:
   ```bash
   flutter emulators              # powinno pokazać Pixel_7
   flutter doctor                 # wszystkie ✓
   ```

## Build produkcyjny

```bash
# Android APK
flutter build apk --release --dart-define=API_BASE_URL=https://api.example.com

# iOS
flutter build ios --release --dart-define=API_BASE_URL=https://api.example.com

# Web
flutter build web --release --dart-define=API_BASE_URL=https://api.example.com
```

## Docker (web preview)

Z katalogu głównego projektu (`../`):

```bash
docker compose up -d --build
# Frontend: http://localhost:3000
# Backend:  http://localhost:8000
```

## Struktura

```
lib/
├── main.dart
├── app.dart                       # MaterialApp.router + theme
├── core/
│   ├── api/                       # Dio + interceptory
│   ├── auth/                      # AuthController + AuthState
│   ├── config/                    # AppConfig (base URL etc.)
│   ├── errors/                    # Failure + ErrorMapper
│   ├── router/                    # GoRouter + guards
│   ├── storage/                   # SecureStorage wrapper
│   ├── theme/                     # ColorScheme + text theme
│   └── widgets/                   # Wspólne widgety (AppButton, LoadingView...)
├── features/
│   ├── auth/                      # Login + Register
│   ├── dashboard/                 # Dashboard + statystyki
│   ├── languages/                 # Wybór języka
│   ├── rooms/                     # Room screen + words + verbs
│   ├── learning/                  # Sesja nauki + powtórki (SRS)
│   ├── sentences/                 # CRUD zdań
│   ├── games/                     # Matching, scramble, wisielec
│   ├── alphabet/                  # Alfabet + audio
│   └── profile/                   # Ustawienia (theme, avatar)
└── l10n/                          # Tłumaczenia (pl domyślnie)
```

Każdy feature: `data/` (API + DTO + repo impl), `domain/` (entity + repo interface), `presentation/` (providers + screens + widgets).

## Regeneracja modeli po zmianach

```bash
dart run build_runner watch --delete-conflicting-outputs
```
