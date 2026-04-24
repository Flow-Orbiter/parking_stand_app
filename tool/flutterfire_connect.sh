#!/usr/bin/env bash
# Generuje lib/firebase_options.dart, android/app/google-services.json, ios/Runner/GoogleService-Info.plist
# wymaga: w konsoli Firebase muszą istnieć aplikacje z tymi samymi identyfikatorami.
set -euo pipefail
cd "$(dirname "$0")/.."
export PATH="${PATH}:$HOME/.pub-cache/bin"

if ! command -v flutterfire >/dev/null 2>&1; then
  echo "Instalowanie FlutterFire CLI..."
  dart pub global activate flutterfire_cli
fi

if ! command -v firebase >/dev/null 2>&1; then
  echo "Brak Firebase CLI. Zainstaluj:  npm i -g firebase-tools"
  echo "Lub:  brew install firebase-cli  (zależnie od systemu)"
  exit 1
fi

if ! firebase projects:list >/dev/null 2>&1; then
  echo "Zaloguj się w Firebase (przeglądarka), potem uruchom ten skrypt ponownie:"
  echo "  firebase login"
  exit 1
fi

if [ -z "${1:-}" ]; then
  echo "Użycie:  ./tool/flutterfire_connect.sh <ID_PROJEKTU_FIREBASE>"
  echo "ID: Firebase Console → ustawienia (koło zębate) → Identyfikator projektu (np. moja-app-a1b2)"
  echo ""
  echo "Najpierw zaloguj konto dev (jednorazowo):  firebase login"
  echo "  (jeśli nie masz: npm i -g firebase-tools  albo: brew install firebase-cli )"
  exit 1
fi

PROJECT_ID="$1"

echo "Projekt: $PROJECT_ID  |  Android: com.floworbiter.baps  |  iOS: com.floworbiter.baps"
flutterfire configure \
  -p "$PROJECT_ID" \
  -y \
  --platforms=android,ios \
  --android-package-name=com.floworbiter.baps \
  --ios-bundle-id=com.floworbiter.baps \
  -f

echo ""
echo "OK. Ostatni krok iOS:  cd ios && pod install"
echo "Potem: flutter run"
