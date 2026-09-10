#!/usr/bin/env bash
# Put push credentials back after claude-code-action has run.
#
# The action strips the header actions/checkout installed, embeds its own GitHub App token
# in the remote URL, and revokes that token in its post-step. Every push the job makes after
# the agent step then fails with "Invalid username or token" — which is how a full build's
# worth of commits was lost on the first real run. Call this once, right after the agent.
set -euo pipefail

: "${GITHUB_TOKEN:?GITHUB_TOKEN is not set; pass secrets.GITHUB_TOKEN in env}"
: "${GITHUB_REPOSITORY:?}"

git config --local --unset-all http.https://github.com/.extraheader 2>/dev/null || true
git remote set-url origin "https://x-access-token:${GITHUB_TOKEN}@github.com/${GITHUB_REPOSITORY}.git"

# Prove it, cheaply, so a broken token fails here with a clear message rather than at the
# push after an hour of work.
git ls-remote --exit-code --heads origin "${FACTORY_BRANCH:-${GITHUB_REF_NAME:-main}}" >/dev/null
echo "push credentials restored for ${GITHUB_REPOSITORY}"
