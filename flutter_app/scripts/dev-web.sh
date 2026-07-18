#!/bin/bash
# Uruchamia dev-stack dla weba: backend w Dockerze + Flutter web w Chrome z hot reload.
# Szybsze niż emulator Android — do quick check UI. Do sprawdzenia natywnego
# zachowania i tak potrzebujesz dev-android.sh.

set -e

API_BASE_URL="${API_BASE_URL:-http://localhost:8000}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FLUTTER_APP_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
PROJECT_ROOT="$(cd "$FLUTTER_APP_DIR/.." && pwd)"

cd "$PROJECT_ROOT"

if ! docker compose ps backend --status running --quiet | grep -q .; then
  echo "▶ Uruchamiam backend…"
  docker compose up -d backend
else
  echo "✓ Backend już działa"
fi

cd "$FLUTTER_APP_DIR"

flutter pub get
dart run build_runner build --delete-conflicting-outputs

echo "▶ flutter run -d chrome (hot reload przez 'r' w terminalu)…"
exec flutter run -d chrome --dart-define=API_BASE_URL="$API_BASE_URL"
