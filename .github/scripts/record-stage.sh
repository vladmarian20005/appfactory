#!/usr/bin/env bash
# Record a stage's outcome in apps/<slug>/state.json and push it.
#
#   record-stage.sh <slug> <stage> ok|fail
#
# Safe to call from parallel matrix legs. Two apps verifying at once write different files,
# so a rejected push rebases cleanly; the retry loop is there for that and nothing else.
#
# A failure to push is a warning, not an error. The stage result is a convenience for the
# next stage, and losing it costs a re-run — failing the job over it would throw away work
# that actually succeeded.
set -euo pipefail

slug=${1:?usage: record-stage.sh <slug> <stage> ok|fail}
stage=${2:?}
status=${3:?}

case "$status" in ok|fail) ;; *) echo "record-stage.sh: status must be ok or fail" >&2; exit 1 ;; esac

.github/scripts/state.sh "$slug" stage "$stage" "$status"

git config user.name "factory"
git config user.email "factory@users.noreply.github.com"
git add "apps/$slug/state.json"
if git diff --cached --quiet; then
  echo "state unchanged"
  exit 0
fi
git commit -q -m "$slug: $stage $status"

branch="${GITHUB_REF_NAME:-$(git rev-parse --abbrev-ref HEAD)}"
for attempt in 1 2 3 4 5; do
  if git push -q origin "HEAD:$branch" 2>/dev/null; then
    echo "recorded $stage=$status for $slug"
    exit 0
  fi
  # Someone else pushed between our fetch and our push. Ours touches one file nobody else
  # is touching, so a rebase resolves it.
  sleep $(( RANDOM % 5 + attempt ))
  git pull --rebase -q origin "$branch" || {
    echo "::warning::could not rebase onto $branch; $slug's $stage result was not recorded"
    exit 0
  }
done
echo "::warning::could not push $slug's $stage result after 5 attempts"
