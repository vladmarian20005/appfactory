#!/usr/bin/env bash
# Publish the credentials this repo's workflows need as GitHub Actions secrets.
#
#   tools/push-secrets.sh [--repo owner/name] [--dry-run]
#
# Reads tools/fastlane/.env (written by tools/setup-keys.sh) so nothing is retyped, and
# reads the .p8 from ASC_KEY_PATH. Re-runnable: every value is overwritten in place.
#
# This repo is public. That is safe for Actions secrets — GitHub withholds them from runs
# triggered by pull requests from forks, and every workflow that touches them is
# workflow_dispatch or workflow_run, which an outsider cannot trigger. It is NOT safe to
# commit any of these files, which is why .gitignore covers .env, *.p8 and *.p12.
set -euo pipefail

repo="vladmarian20005/appfactory"
dry=0
while [ $# -gt 0 ]; do
  case "$1" in
    --repo) repo=$2; shift 2 ;;
    --dry-run) dry=1; shift ;;
    *) echo "unknown option: $1" >&2; exit 1 ;;
  esac
done

root=$(cd "$(dirname "$0")/.." && pwd)
envf="$root/tools/fastlane/.env"
[ -f "$envf" ] || { echo "No $envf. Run tools/setup-keys.sh first." >&2; exit 1; }

set -a; . "$envf"; set +a

ok=0
missing=()

put() { # put NAME VALUE
  local name=$1 value=$2
  if [ -z "$value" ]; then missing+=("$name"); return; fi
  if [ "$dry" = 1 ]; then
    echo "  would set $name (${#value} chars)"
  else
    gh secret set "$name" --repo "$repo" --body "$value" >/dev/null
    echo "  set $name"
  fi
  ok=$((ok + 1))
}

echo "Publishing secrets to $repo"

# ── App Store Connect ─────────────────────────────────────────────────────────
put ASC_KEY_ID       "${ASC_KEY_ID:-}"
put ASC_ISSUER_ID    "${ASC_ISSUER_ID:-}"
put APPLE_TEAM_ID    "${TEAM_ID:-}"
put BUNDLE_PREFIX    "${BUNDLE_PREFIX:-}"

# The key file's contents, not its path: a runner has no ~/.appstoreconnect.
if [ -n "${ASC_KEY_PATH:-}" ] && [ -f "$ASC_KEY_PATH" ]; then
  put ASC_KEY_P8 "$(cat "$ASC_KEY_PATH")"
else
  missing+=("ASC_KEY_P8 (ASC_KEY_PATH is unset or the file is gone)")
fi

# ── App Review contact ────────────────────────────────────────────────────────
put REVIEW_FIRST_NAME "${REVIEW_FIRST_NAME:-}"
put REVIEW_LAST_NAME  "${REVIEW_LAST_NAME:-}"
put REVIEW_PHONE      "${REVIEW_PHONE:-}"
put REVIEW_EMAIL      "${REVIEW_EMAIL:-}"
put SUPPORT_EMAIL     "${SUPPORT_EMAIL:-}"

# ── Signing ───────────────────────────────────────────────────────────────────
# The distribution identity. `fastlane certs` creates it and writes the .p12; set
# DIST_CERT_P12 to that path, or export one from Keychain Access.
if [ -n "${DIST_CERT_P12:-}" ] && [ -f "$DIST_CERT_P12" ]; then
  put DIST_CERT_P12_BASE64 "$(base64 -i "$DIST_CERT_P12")"
  put DIST_CERT_PASSWORD   "${DIST_CERT_PASSWORD:-}"
else
  missing+=("DIST_CERT_P12_BASE64 (set DIST_CERT_P12=/path/to/dist.p12 in $envf)")
fi

# A throwaway password for the temporary keychain each runner builds and destroys.
if [ "$dry" = 0 ] && ! gh secret list --repo "$repo" 2>/dev/null | grep -q '^KEYCHAIN_PASSWORD'; then
  put KEYCHAIN_PASSWORD "$(openssl rand -base64 24)"
fi

echo
echo "$ok secret(s) published."
if [ ${#missing[@]} -gt 0 ]; then
  echo
  echo "Still missing — the pipeline cannot sign or submit without these:"
  printf '  · %s\n' "${missing[@]}"
fi

cat <<'NOTE'

Two secrets this script cannot derive:

  CLAUDE_CODE_OAUTH_TOKEN   the agentic build and fix stages. Generate with:
                              claude setup-token
                            then: gh secret set CLAUDE_CODE_OAUTH_TOKEN --repo <repo>
                            It bills your Claude subscription rather than the API.

  SITE_REPO_TOKEN           lets app-pages push the generated privacy and support pages to
                            starhiveconcept-site, which Cloudflare Pages then deploys.
                            A fine-grained PAT, contents:write, that repository only.
NOTE
