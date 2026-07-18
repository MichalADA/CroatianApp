#!/bin/bash
# Weryfikacja setupu — sprawdza czy masz wszystko co potrzebne do dev-loopu.
# Nie instaluje nic sam; tylko mówi, czego brakuje i jak to zainstalować.

set -e

echo "════════════════════════════════════════════════════════"
echo "  Sprawdzanie środowiska Flutter dev"
echo "════════════════════════════════════════════════════════"

miss=0

check() {
  local name="$1"; local cmd="$2"; local install="$3"
  if command -v "$cmd" >/dev/null 2>&1; then
    echo "  ✓ $name"
  else
    echo "  ✗ $name — BRAK. Zainstaluj: $install"
    miss=$((miss+1))
  fi
}

check "Flutter SDK"    flutter "sudo snap install flutter --classic   # albo pobierz z https://docs.flutter.dev/get-started/install"
check "Dart"           dart    "(instaluje się razem z Flutter)"
check "Docker"         docker  "sudo apt install docker.io docker-compose-v2"
check "adb"            adb     "sudo apt install android-tools-adb   # albo przez Android Studio SDK"

echo ""
if [ $miss -gt 0 ]; then
  echo "✗ Brakuje $miss narzędzi. Zainstaluj powyższe, potem uruchom ten skrypt ponownie."
  exit 1
fi

echo "── flutter doctor ────────────────────────────────────"
flutter doctor

echo ""
echo "── AVD-y (emulatory Androida) ─────────────────────────"
flutter emulators || true

echo ""
echo "════════════════════════════════════════════════════════"
echo "  Jeśli flutter doctor pokazał ✗ przy 'Android toolchain':"
echo "    1. Zainstaluj Android Studio (https://developer.android.com/studio)"
echo "    2. flutter doctor --android-licenses"
echo ""
echo "  Jeśli brak AVD:"
echo "    1. Uruchom Android Studio → Tools → Device Manager"
echo "    2. Create Virtual Device → Pixel 7 → wybierz Android 14 (API 34)"
echo "    3. Nazwij np. 'Pixel_7' (bez spacji!)"
echo ""
echo "  Potem uruchamiaj dev-loop przez:"
echo "    ./flutter_app/scripts/dev-android.sh"
echo "════════════════════════════════════════════════════════"
