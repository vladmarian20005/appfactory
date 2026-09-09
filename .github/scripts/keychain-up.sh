#!/usr/bin/env bash
# Import the Apple Distribution identity into a throwaway keychain on this runner.
#
#   .github/scripts/keychain-up.sh          # create and import
#   .github/scripts/keychain-down.sh        # destroy (always run it, even on failure)
#
# Env: DIST_CERT_P12_BASE64, DIST_CERT_PASSWORD, KEYCHAIN_PASSWORD.
#
# Why a .p12 rather than fastlane's `cert` action: on a fresh runner `cert` finds no matching
# private key and creates a NEW distribution certificate every run. Apple allows 3 per team,
# so the 4th run fails permanently and needs a browser to clean up. The identity is created
# once, on a laptop, by `fastlane certs`.
set -euo pipefail

: "${DIST_CERT_P12_BASE64:?missing. Create the identity with 'fastlane certs' then run tools/push-secrets.sh}"
: "${DIST_CERT_PASSWORD:?missing}"
: "${KEYCHAIN_PASSWORD:?missing}"

KEYCHAIN="${RUNNER_TEMP:-/tmp}/factory.keychain-db"
P12="${RUNNER_TEMP:-/tmp}/dist.p12"

security create-keychain -p "$KEYCHAIN_PASSWORD" "$KEYCHAIN"
# Default is a 5-minute idle lock, which expires in the middle of a long archive and turns
# codesign into a hang. 6 hours, and no auto-lock on sleep.
security set-keychain-settings -lut 21600 "$KEYCHAIN"
security unlock-keychain -p "$KEYCHAIN_PASSWORD" "$KEYCHAIN"

printf '%s' "$DIST_CERT_P12_BASE64" | base64 --decode > "$P12"
security import "$P12" -k "$KEYCHAIN" -P "$DIST_CERT_PASSWORD" \
  -T /usr/bin/codesign -T /usr/bin/security -T /usr/bin/productsign -f pkcs12
rm -f "$P12"

# Without this, codesign blocks on a GUI prompt that nobody can answer and the job runs to
# its timeout with no error message.
security set-key-partition-list -S apple-tool:,apple:,codesign: -s -k "$KEYCHAIN_PASSWORD" "$KEYCHAIN" >/dev/null

# Append to the search list, never replace it: dropping the System keychain breaks the
# Apple WWDR chain and every signature fails validation.
existing=$(security list-keychains -d user | sed 's/[",]//g' | xargs)
# shellcheck disable=SC2086
security list-keychains -d user -s "$KEYCHAIN" $existing
security default-keychain -s "$KEYCHAIN"

if ! security find-identity -v -p codesigning "$KEYCHAIN" | grep -q "Apple Distribution"; then
  echo "::error::No 'Apple Distribution' identity in the keychain after import."
  echo "The .p12 in DIST_CERT_P12_BASE64 probably has no private key. Export it WITH the key,"
  echo "or regenerate it with 'fastlane certs' on a laptop."
  security find-identity -v -p codesigning "$KEYCHAIN" || true
  exit 1
fi

echo "Distribution identity ready:"
security find-identity -v -p codesigning "$KEYCHAIN" | sed 's/^/  /'
