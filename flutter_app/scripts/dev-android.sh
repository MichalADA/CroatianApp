#!/bin/bash
# Uruchamia dev-stack: backend w Dockerze + emulator Android + Flutter z hot reload.
# Zatrzymaj Ctrl+C — emulator zostanie odpalony w tle, żeby nie startować za każdym razem.

set -e

# ─── Konfig ──────────────────────────────────────────────────────────────────
# Nazwa AVD; jak masz inną, zmień. Utwórz AVD w Android Studio → Device Manager.
AVD_NAME="${AVD_NAME:-Pixel_7}"

# API_BASE_URL — Android emulator używa 10.0.2.2 do dotarcia do hosta (localhost hosta).
API_BASE_URL="${API_BASE_URL:-http://10.0.2.2:8000}"

# ─── Ścieżki ─────────────────────────────────────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FLUTTER_APP_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
PROJECT_ROOT="$(cd "$FLUTTER_APP_DIR/.." && pwd)"

cd "$PROJECT_ROOT"

# ─── 1. Backend w Dockerze ───────────────────────────────────────────────────
if ! docker compose ps backend --status running --quiet | grep -q .; then
  echo "▶ Uruchamiam backend w Dockerze…"
  docker compose up -d backend
else
  echo "✓ Backend już działa"
fi

# ─── 2. Emulator ─────────────────────────────────────────────────────────────
if ! adb devices | grep -q "emulator-.*device$"; then
  echo "▶ Uruchamiam emulator $AVD_NAME (w tle)…"
  # Sprawdź czy AVD istnieje
  if ! flutter emulators | grep -q "$AVD_NAME"; then
    echo "✗ AVD '$AVD_NAME' nie istnieje. Utwórz w Android Studio → Device Manager."
    echo "  Dostępne AVD:"
    flutter emulators
    exit 1
  fi
  flutter emulators --launch "$AVD_NAME" &
  echo "  Czekam aż emulator wystartuje…"
  adb wait-for-device
  # Poczekaj aż system Android w pełni się załaduje.
  until [ "$(adb shell getprop sys.boot_completed 2>/dev/null | tr -d '\r')" = "1" ]; do
    sleep 2
    echo -n "."
  done
  echo ""
  echo "✓ Emulator gotowy"
else
  echo "✓ Emulator już działa"
fi

# ─── 3. Flutter run ──────────────────────────────────────────────────────────
cd "$FLUTTER_APP_DIR"

echo "▶ flutter pub get…"
flutter pub get

echo "▶ Codegen (freezed / json_serializable)…"
dart run build_runner build --delete-conflicting-outputs

echo "▶ flutter run (hot reload przez 'r' w terminalu, 'q' aby zakończyć)…"
echo "  API_BASE_URL = $API_BASE_URL"
exec flutter run --dart-define=API_BASE_URL="$API_BASE_URL"
