#!/usr/bin/env bash
# Record a stage's outcome in apps/<slug>/state.json and push it.
#
#   record-stage.sh <slug> <stage> ok|fail
#
# Concurrent writers are the normal case, not the exception: app-verify and app-compliance
# both fire on the same push and both write the same app's state.json. Rebasing our commit
# onto theirs conflicts every time, because both edited the same object.
#
# So this does not rebase. It re-derives: take the remote's state.json, apply this one
# stage to it, commit that. The write is a single-field set, so applying it to whatever
# landed in the meantime is not a merge heuristic — it is the same answer.
#
# The sha is captured once, before any of that. It has to be the commit the stage actually
# judged; recording whatever HEAD happens to be after a fetch would record a lie, and the
# lie the gate exists to catch is exactly this one.
#
# A failure to push is a warning, not an error: losing the note costs a re-run, failing the
# job would throw away work that succeeded.
set -euo pipefail

slug=${1:?usage: record-stage.sh <slug> <stage> ok|fail}
stage=${2:?}
status=${3:?}

case "$status" in ok|fail) ;; *) echo "record-stage.sh: status must be ok or fail" >&2; exit 1 ;; esac

judged=$(git rev-parse HEAD)
file="apps/$slug/state.json"
# FACTORY_BRANCH is set by workflows started from a trigger branch (build/<slug> etc.), whose
# GITHUB_REF_NAME is the trigger, not the branch the work belongs on.
branch="${FACTORY_BRANCH:-${GITHUB_REF_NAME:-$(git rev-parse --abbrev-ref HEAD)}}"

git config user.name "factory"
git config user.email "factory@users.noreply.github.com"

for attempt in 1 2 3 4 5; do
  if [ "$attempt" -gt 1 ]; then
    git fetch -q origin "$branch" || { echo "::warning::fetch failed; $slug's $stage was not recorded"; exit 0; }
    # --mixed, not --hard: the working tree still holds this job's build output and
    # artifacts, and nothing below stages anything but state.json.
    git reset -q --mixed "origin/$branch"
    git checkout -q "origin/$branch" -- "$file" 2>/dev/null || rm -f "$file"
  fi

  .github/scripts/state.sh "$slug" stage "$stage" "$status" "$judged"
  git add "$file"
  if git diff --cached --quiet; then
    echo "state unchanged"
    exit 0
  fi
  git commit -q -m "$slug: $stage $status"

  if git push -q origin "HEAD:$branch" 2>/dev/null; then
    echo "recorded $stage=$status for $slug at ${judged:0:7}"
    exit 0
  fi
  echo "push rejected (attempt $attempt); someone else wrote first, re-deriving"
  sleep $(( RANDOM % 4 + attempt ))
done

echo "::warning::could not record $slug's $stage after 5 attempts"
