#!/usr/bin/env bash
# Interactive key setup for the factory. Safe to re-run: Enter keeps the current value.
#
#   factory/tools/setup-keys.sh
#
# Writes:
#   factory/tools/fastlane/.env   App Store Connect key, team, bundle prefix, review contact (gitignored, chmod 600)
#   ~/.appstoreconnect/*.p8       the private key file (chmod 600)
#   .env.local                    ANTHROPIC_API_KEY for the Guide page (gitignored)
#   GitHub repository secrets     DATABASE_URL, DATABASE_AUTH_TOKEN, IFTTT_WEBHOOK_KEY (all optional)
set -euo pipefail

root=$(cd "$(dirname "$0")/../.." && pwd)
envf="$root/factory/tools/fastlane/.env"
localf="$root/.env.local"
keydir="$HOME/.appstoreconnect"
mkdir -p "$keydir" && chmod 700 "$keydir"

bold() { printf '\033[1m%s\033[0m\n' "$*"; }
note() { printf '   %s\n' "$*"; }

# Load what is already there so Enter keeps it.
if [ -f "$envf" ]; then set -a; . "$envf"; set +a; fi

ask() { # ask VAR "prompt" [secret]
  local var=$1 prompt=$2 secret=${3:-} cur="${!var:-}" input
  if [ -n "$cur" ]; then
    if [ -n "$secret" ]; then prompt="$prompt [keep current]"; else prompt="$prompt [$cur]"; fi
  fi
  if [ -n "$secret" ]; then read -r -s -p "  $prompt: " input; echo; else read -r -p "  $prompt: " input; fi
  input="${input%\"}"; input="${input#\"}"; input="${input%\'}"; input="${input#\'}"
  if [ -n "$input" ]; then printf -v "$var" '%s' "$input"; fi
}

echo
bold "1. App Store Connect · needed to create app records, upload builds and submit"
note "App Store Connect → Users and Access → Integrations → App Store Connect API → Team keys."
note "Create a key with the App Manager role. Download the .p8 once; Apple never shows it again."
ask ASC_KEY_ID "Key ID (10 characters)"
ask ASC_ISSUER_ID "Issuer ID (UUID, shown above the key list)"
P8_SOURCE=""
ask P8_SOURCE "Path to the downloaded AuthKey_*.p8 (drag the file here; Enter to keep the stored one)"
if [ -n "$P8_SOURCE" ]; then
  src="${P8_SOURCE/#\~/$HOME}"
  [ -f "$src" ] || { echo "  no such file: $src"; exit 1; }
  dest="$keydir/AuthKey_${ASC_KEY_ID:-key}.p8"
  cp "$src" "$dest" && chmod 600 "$dest"
  ASC_KEY_PATH="$dest"
  note "stored at $dest"
fi
note "developer.apple.com → Account → Membership details → Team ID."
ask TEAM_ID "Team ID (10 characters)"
ask BUNDLE_PREFIX "Bundle id prefix for new apps, e.g. com.yourcompany"

echo
bold "2. App Review contact · required on every submission"
ask REVIEW_FIRST_NAME "First name"
ask REVIEW_LAST_NAME "Last name"
ask REVIEW_PHONE "Phone with country code, e.g. +40 7xx xxx xxx"
ask REVIEW_EMAIL "Email App Review may use"
ask SUPPORT_EMAIL "Public support email, shown on each app's support page"

umask 077
{
  echo "# Written by factory/tools/setup-keys.sh on $(date -u +%Y-%m-%dT%H:%MZ). Gitignored. Re-run the script to change."
  for k in ASC_KEY_ID ASC_ISSUER_ID ASC_KEY_PATH TEAM_ID BUNDLE_PREFIX REVIEW_FIRST_NAME REVIEW_LAST_NAME REVIEW_PHONE REVIEW_EMAIL SUPPORT_EMAIL; do
    printf '%s="%s"\n' "$k" "${!k:-}"
  done
} > "$envf"
chmod 600 "$envf"
note "wrote $envf"

echo
bold "3. Anthropic API key · optional, powers the Guide page on the intel site"
ANTHROPIC_API_KEY="$(grep -E '^ANTHROPIC_API_KEY=' "$localf" 2>/dev/null | cut -d= -f2- || true)"
ask ANTHROPIC_API_KEY "Anthropic API key (Enter to skip)" secret
if [ -n "${ANTHROPIC_API_KEY:-}" ]; then
  touch "$localf"
  if grep -qE '^ANTHROPIC_API_KEY=' "$localf"; then
    sed -i '' "s|^ANTHROPIC_API_KEY=.*|ANTHROPIC_API_KEY=$ANTHROPIC_API_KEY|" "$localf"
  else
    printf 'ANTHROPIC_API_KEY=%s\n' "$ANTHROPIC_API_KEY" >> "$localf"
  fi
  chmod 600 "$localf"
  note "wrote ANTHROPIC_API_KEY to .env.local (restart npm run dev)"
fi

echo
bold "4. GitHub Actions secrets · all optional"
note "The daily scout keeps its database in the Actions cache between runs. That is enough."
note "Turso makes the history durable and lets the local site share it. Skip unless you want that."
note "IFTTT is not used; the morning message is the Google Calendar event. Skip unless you have IFTTT Pro."
DATABASE_URL=""; DATABASE_AUTH_TOKEN=""; IFTTT_WEBHOOK_KEY=""
ask DATABASE_URL "Turso database URL, libsql://… (Enter to skip)"
if [ -n "$DATABASE_URL" ]; then ask DATABASE_AUTH_TOKEN "Turso auth token" secret; fi
ask IFTTT_WEBHOOK_KEY "IFTTT Webhooks key (Enter to skip)" secret
if command -v gh >/dev/null 2>&1 && gh auth status >/dev/null 2>&1; then
  for k in DATABASE_URL DATABASE_AUTH_TOKEN IFTTT_WEBHOOK_KEY; do
    v="${!k}"
    if [ -n "$v" ]; then (cd "$root" && gh secret set "$k" --body "$v" >/dev/null) && note "set GitHub secret $k"; fi
  done
else
  [ -n "$DATABASE_URL$IFTTT_WEBHOOK_KEY" ] && note "gh is not logged in; set the secrets at github.com → repo → Settings → Secrets → Actions"
fi

echo
bold "5. Checks"
ok=1
[ "${#ASC_KEY_ID}" -eq 10 ] || { note "✗ Key ID should be 10 characters"; ok=0; }
[[ "${ASC_ISSUER_ID:-}" =~ ^[0-9a-fA-F-]{36}$ ]] || { note "✗ Issuer ID should be a UUID"; ok=0; }
if [ -n "${ASC_KEY_PATH:-}" ] && [ -f "$ASC_KEY_PATH" ]; then
  head -1 "$ASC_KEY_PATH" | grep -q "BEGIN PRIVATE KEY" && note "✓ .p8 looks right" || { note "✗ $ASC_KEY_PATH does not look like a .p8"; ok=0; }
else
  note "✗ no .p8 stored; run again and give the path"; ok=0
fi
[ "${#TEAM_ID}" -eq 10 ] || { note "✗ Team ID should be 10 characters"; ok=0; }
[[ "${BUNDLE_PREFIX:-}" =~ ^[a-zA-Z][a-zA-Z0-9.-]+$ ]] || { note "✗ bundle prefix looks off"; ok=0; }
if security find-identity -v -p codesigning 2>/dev/null | grep -q "Apple Distribution"; then
  note "✓ Apple Distribution certificate in keychain"
else
  note "· no Apple Distribution certificate yet; fastlane creates one on the first upload"
fi
if [ -n "${SUPPORT_EMAIL:-}" ]; then
  for f in "$root"/sites/*/support/index.html; do
    [ -f "$f" ] && grep -q SUPPORT_EMAIL_TBD "$f" && sed -i '' "s|SUPPORT_EMAIL_TBD|$SUPPORT_EMAIL|g" "$f" && note "filled support email in ${f#$root/}"
  done
fi
[ "$ok" -eq 1 ] && bold "Ready. Next: /ship <slug>, which runs fastlane create → beta → release." || bold "Fix the items marked ✗ and run the script again."
