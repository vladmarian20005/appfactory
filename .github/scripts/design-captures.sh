#!/usr/bin/env bash
# What the critic looks at, beyond verify's light-mode captures: every screen in dark mode,
# the first two at the largest accessibility text size, and each of qa.json's `moments` as a
# filmstrip of the app actually moving.
#
#   .github/scripts/design-captures.sh <slug> [outdir]
#
# Run verify-app.sh first: this reuses its build. Expects a booted simulator in SIM_UDID and
# the repo root as the working directory. Writes to apps/<slug>/qa/design/ by default.
#
# A moment is launched WITHOUT -stillFrames — the point is to see it move — with the app's own
# `-demo <name>` flag playing the interaction by itself, since nothing here can touch a screen:
#
#   "moments": [
#     { "name": "pour", "args": ["-onboarded", "-level", "3", "-demo", "pour"],
#       "delay": 0.5, "frames": 8, "interval": 0.15,
#       "note": "the signature pour, played by the app" }
#   ]
set -euo pipefail

slug=${1:?usage: design-captures.sh <slug> [outdir]}
app_dir="apps/$slug/ios"
qa_json="apps/$slug/qa.json"
out=${2:-"apps/$slug/qa/design"}

[ -f "$qa_json" ] || { echo "::error::$qa_json is missing"; exit 1; }
[ -n "${SIM_UDID:-}" ] || { echo "::error::SIM_UDID is not set; run tools/sim.sh boot first"; exit 1; }

scheme=$(node -p "require('./$qa_json').scheme")
rm -rf "$out"
mkdir -p "$out"
tmp=$(mktemp -d -t design)

restore() {
  tools/sim.sh ui light >/dev/null 2>&1 || true
  xcrun simctl ui "$SIM_UDID" content_size large >/dev/null 2>&1 || true
}
trap restore EXIT

# 0..n-1, and nothing when n is 0. Not `seq 0 $((n - 1))`: BSD seq counts down, so for n=0 it
# yields 0 and -1, and the script dies reading moments[0] of an app that has none.
upto() { [ "$1" -gt 0 ] && seq 0 $(( $1 - 1 )) || true; }

# args_of <jsonpath-expression> → one argument per line
args_of() { node -p "(require('./$qa_json').$1 || []).join('\n')"; }

launch() {
  tools/sim.sh reset "$app_dir" "$scheme" >/dev/null 2>&1 || true
  tools/sim.sh run "$app_dir" "$scheme" "$@" >/dev/null
}

count=$(node -p "require('./$qa_json').screens.length")

echo "::group::Dark mode"
tools/sim.sh ui dark >/dev/null
for i in $(upto "$count"); do
  name=$(node -p "require('./$qa_json').screens[$i].name")
  args=()
  while IFS= read -r line; do [ -n "$line" ] && args+=("$line"); done < <(args_of "screens[$i].args")
  launch ${args[@]+"${args[@]}"} -stillFrames
  tools/sim.sh shot "$app_dir" "$scheme" "$out/dark-$name.png"
done
echo "::endgroup::"

echo "::group::Largest accessibility text"
tools/sim.sh ui light accessibility-extra-extra-extra-large >/dev/null
for i in $(upto $(( count < 2 ? count : 2 ))); do
  name=$(node -p "require('./$qa_json').screens[$i].name")
  args=()
  while IFS= read -r line; do [ -n "$line" ] && args+=("$line"); done < <(args_of "screens[$i].args")
  launch ${args[@]+"${args[@]}"} -stillFrames
  tools/sim.sh shot "$app_dir" "$scheme" "$out/ax-$name.png"
done
xcrun simctl ui "$SIM_UDID" content_size large >/dev/null
echo "::endgroup::"

echo "::group::Moments"
moments=$(node -p "(require('./$qa_json').moments || []).length")
if [ "$moments" -eq 0 ]; then
  echo "::warning::$qa_json has no moments, so nobody can see the signature interaction or the win move"
fi
for i in $(upto "$moments"); do
  name=$(node -p "require('./$qa_json').moments[$i].name")
  delay=$(node -p "require('./$qa_json').moments[$i].delay ?? 0.5")
  frames=$(node -p "require('./$qa_json').moments[$i].frames ?? 8")
  interval=$(node -p "require('./$qa_json').moments[$i].interval ?? 0.15")
  args=()
  while IFS= read -r line; do [ -n "$line" ] && args+=("$line"); done < <(args_of "moments[$i].args")
  launch ${args[@]+"${args[@]}"}
  sleep "$delay"
  tools/sim.sh frames "$tmp/$name" "$frames" "$interval" >/dev/null
  node tools/qa/filmstrip.mjs "$out/moment-$name.png" "$tmp/$name"/frame-*.png
done
echo "::endgroup::"

# The ladder: the same screen deep into the app, so a flat curve is visible to someone who
# only ever sees stills. A screenshot of session 5 and a screenshot of session 500 being the
# same screenshot is the whole finding — the factory shipped a game whose difficulty stopped
# at level 36 and every gate passed it. `ladder` entries are ordered shallow to deep and are
# composed into one strip, left to right, for the critic's Escalation score (TASTE.md, "The
# second session"). Added 12 Sep 2026.
#
#   "ladder": [
#     { "name": "level-1", "args": ["-onboarded", "-reset", "-level", "1", "-moves", "3"] },
#     { "name": "level-40", "args": ["-onboarded", "-reset", "-level", "40", "-moves", "3"] },
#     { "name": "level-400", "args": ["-onboarded", "-reset", "-level", "400", "-moves", "3"] }
#   ]
echo "::group::Ladder"
rungs=$(node -p "(require('./$qa_json').ladder || []).length")
if [ "$rungs" -lt 2 ]; then
  echo "::warning::$qa_json has fewer than two ladder rungs, so nobody can see whether the app changes as it is played"
else
  mkdir -p "$tmp/ladder"
  for i in $(upto "$rungs"); do
    name=$(node -p "require('./$qa_json').ladder[$i].name")
    args=()
    while IFS= read -r line; do [ -n "$line" ] && args+=("$line"); done < <(args_of "ladder[$i].args")
    launch ${args[@]+"${args[@]}"} -stillFrames
    tools/sim.sh shot "$app_dir" "$scheme" "$(printf '%s/ladder/%02d-%s.png' "$tmp" "$i" "$name")"
  done
  node tools/qa/filmstrip.mjs "$out/ladder.png" "$tmp"/ladder/*.png
fi
echo "::endgroup::"

rm -rf "$tmp"
echo "design captures for $slug in $out:"
ls -1 "$out"
