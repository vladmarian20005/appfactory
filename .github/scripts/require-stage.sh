#!/usr/bin/env bash
# Refuse to run a stage whose predecessor did not pass on this code.
#
#   require-stage.sh <slug> <previous-stage> [<previous-stage> ...]
#
# Two conditions, and the second is the one that matters. "The previous stage passed" is
# easy and nearly useless on its own: an agent can fix a build, get a green verify, then
# rewrite three screens, and the green is still sitting in state.json. So the stage also
# has to have judged a commit that is an ancestor of HEAD. If it is not, the result belongs
# to code that no longer exists and this stage must not consume it.
set -euo pipefail

slug=${1:?usage: require-stage.sh <slug> <previous-stage> [...]}
shift
file="apps/$slug/state.json"

[ -f "$file" ] || {
  echo "::error::apps/$slug/state.json does not exist, so no stage has ever passed for $slug."
  exit 1
}

fail=0
for stage in "$@"; do
  read -r status sha < <(node -e '
    const fs=require("fs");
    const s=JSON.parse(fs.readFileSync(process.argv[1],"utf8"));
    const st=(s.stages||{})[process.argv[2]]||{};
    console.log(`${st.status||"missing"} ${st.sha||"-"}`);
  ' "$file" "$stage")

  if [ "$status" != "ok" ]; then
    echo "::error::$slug: stage '$stage' is '$status'. Run it and let it pass before this one."
    fail=1
    continue
  fi

  if [ "$sha" = "-" ]; then
    echo "::error::$slug: stage '$stage' passed but recorded no commit, so it cannot be trusted."
    fail=1
    continue
  fi

  # A shallow clone has no history to reason about; say so rather than passing by accident.
  if ! git cat-file -e "$sha^{commit}" 2>/dev/null; then
    echo "::error::$slug: commit $sha from stage '$stage' is not in this checkout. Use fetch-depth: 0."
    fail=1
    continue
  fi

  if ! git merge-base --is-ancestor "$sha" HEAD; then
    echo "::error::$slug: stage '$stage' passed on $(git rev-parse --short "$sha"), which is not an ancestor of HEAD ($(git rev-parse --short HEAD)). That result belongs to code that has since been rewritten. Re-run '$stage'."
    fail=1
    continue
  fi

  echo "ok: $stage passed on $(git rev-parse --short "$sha"), an ancestor of HEAD"
done

exit "$fail"
