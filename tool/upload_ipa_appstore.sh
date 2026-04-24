#!/usr/bin/env bash
# Upload IPA do App Store Connect / TestFlight (App Store Connect API).
#
# Klucz .p8 (NIE commituj do git – jest w .gitignore):
#   App Store Connect → Users and Access → Integrations → App Store Connect API → Generuj klucz
#   Zapisz jako:  AuthKey_XUZA3R348N.p8 (Key ID musi być w nazwie pliku)
#
# Umieść plik w jednym z miejsc (skrypt skopiuje do ./private_keys/ jeśli trzeba):
#   mdm_sport/AuthKey_XUZA3R348N.p8   (katalog główny projektu — OK)
#   mdm_sport/private_keys/AuthKey_XUZA3R348N.p8
#   albo  ~/.private_keys/AuthKey_XUZA3R348N.p8
#   albo  ~/.appstoreconnect/private_keys/AuthKey_XUZA3R348N.p8
#
# Stałe z Twojego projektu (nadpisz przez env jeśli trzeba):
#   APPSTORE_ISSUER_ID, APPSTORE_KEY_ID
# App Store Connect: aplikacja Apple ID 6739493118 (to nie jest Bundle ID).

set -euo pipefail
cd "$(dirname "$0")/.."

ISSUER_ID="${APPSTORE_ISSUER_ID:-462d3996-7007-4a5f-ab0c-a891650f4a65}"
KEY_ID="${APPSTORE_KEY_ID:-XUZA3R348N}"
KEY_NAME="AuthKey_${KEY_ID}.p8"

echo "==> flutter build ipa (release; wersja z pubspec.yaml)"
flutter build ipa --release

IPA=$(ls -1 build/ios/ipa/*.ipa 2>/dev/null | head -1)
if [[ -z "${IPA:-}" || ! -f "$IPA" ]]; then
  echo "Brak .ipa w build/ios/ipa/" >&2
  exit 1
fi
echo "==> IPA: $IPA"

resolve_key() {
  local root="$(pwd)/${KEY_NAME}"
  local here="$(pwd)/private_keys/${KEY_NAME}"
  local a="$HOME/.private_keys/${KEY_NAME}"
  local b="$HOME/.appstoreconnect/private_keys/${KEY_NAME}"
  if [[ -f "$root" ]]; then echo "$root"; return 0; fi
  if [[ -f "$here" ]]; then echo "$here"; return 0; fi
  if [[ -f "$a" ]]; then echo "$a"; return 0; fi
  if [[ -f "$b" ]]; then echo "$b"; return 0; fi
  return 1
}

if ! KSRC=$(resolve_key); then
  echo "Brak pliku ${KEY_NAME}. Wgraj klucz API z App Store Connect do np.:" >&2
  echo "  $(pwd)/${KEY_NAME}  lub  $(pwd)/private_keys/${KEY_NAME}" >&2
  exit 1
fi
mkdir -p private_keys
if [[ "$KSRC" != "$(pwd)/private_keys/${KEY_NAME}" ]]; then
  cp "$KSRC" "private_keys/${KEY_NAME}"
  echo "==> Używam klucza skopiowanego do private_keys/${KEY_NAME}"
fi

echo "==> xcrun altool --upload-app (Key ID=$KEY_ID, Issuer=$ISSUER_ID)"
# Jeśli system zgłosi że altool jest wycofany, wgraj ten sam plik .ipa w aplikacji Transporter.
xcrun altool --upload-app --type ios -f "$IPA" --apiKey "$KEY_ID" --apiIssuer "$ISSUER_ID"

echo "==> OK. TestFlight: App Store Connect → aplikacja (Apple ID 6739493118) → TestFlight."
