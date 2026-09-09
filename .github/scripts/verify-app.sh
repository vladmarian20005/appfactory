#!/usr/bin/env bash
# Deterministic verification of one app. No agent, no judgement: it either builds, launches,
# renders every screen in qa.json and leaves no crash report, or it fails and says which.
#
#   .github/scripts/verify-app.sh <slug> [outdir]
#
# Expects a booted simulator in SIM_UDID (mac-setup exports it) and to be run from the repo
# root. Writes captures to <outdir>, default apps/<slug>/qa/.
set -euo pipefail

slug=${1:?usage: verify-app.sh <slug> [outdir]}
app_dir="apps/$slug/ios"
qa_json="apps/$slug/qa.json"
out=${2:-"apps/$slug/qa"}

[ -d "$app_dir" ] || { echo "::error::no such app: $app_dir"; exit 1; }
[ -f "$qa_json" ] || { echo "::error::$qa_json is missing; it lists the screens to verify"; exit 1; }
[ -n "${SIM_UDID:-}" ] || { echo "::error::SIM_UDID is not set; run tools/sim.sh boot first"; exit 1; }

scheme=$(node -p "require('./$qa_json').scheme")
mkdir -p "$out"

echo "::group::Generate the Xcode project"
# .xcodeproj is a build product; it is never committed.
(cd "$app_dir" && xcodegen generate)
echo "::endgroup::"

echo "::group::Build $scheme"
tools/sim.sh build "$app_dir" "$scheme"
echo "::endgroup::"

# Crash reports written before this run must not be blamed on it. A marker file rather than
# `find -newermt`, which is GNU-only and silently matches nothing on macOS's BSD find.
crash_dir="$HOME/Library/Logs/DiagnosticReports"
mkdir -p "$crash_dir"
marker=$(mktemp -t verify-start)

count=$(node -p "require('./$qa_json').screens.length")
echo "Verifying $count screen(s)"

failures=0
for i in $(seq 0 $((count - 1))); do
  name=$(node -p "require('./$qa_json').screens[$i].name")
  # Not `mapfile`: macOS ships bash 3.2, where it does not exist.
  args=()
  while IFS= read -r line; do [ -n "$line" ] && args+=("$line"); done < <(node -p "require('./$qa_json').screens[$i].args.join('\n')")

  echo "::group::$name  ${args[*]}"
  # Reinstall between screens so launch arguments that seed state start from a clean slate.
  tools/sim.sh reset "$app_dir" "$scheme" >/dev/null 2>&1 || true
  if ! tools/sim.sh run "$app_dir" "$scheme" "${args[@]}"; then
    echo "::error::$name failed to launch"
    failures=$((failures + 1))
    echo "::endgroup::"
    continue
  fi
  tools/sim.sh shot "$app_dir" "$scheme" "$out/$name.png"
  echo "::endgroup::"
done

echo "::group::Check the captures render"
shots=("$out"/*.png)
if [ ${#shots[@]} -eq 0 ] || [ ! -e "${shots[0]}" ]; then
  echo "::error::no captures were produced"
  exit 1
fi
node tools/qa/check-shot.mjs "${shots[@]}" || failures=$((failures + 1))
echo "::endgroup::"

echo "::group::Crash reports"
new_crashes=$(find "$crash_dir" -name "*.ips" -newer "$marker" 2>/dev/null | head -20)
if [ -n "$new_crashes" ]; then
  echo "::error::the app left crash reports:"
  while IFS= read -r c; do
    echo "--- $c"
    head -40 "$c"
  done <<< "$new_crashes"
  failures=$((failures + 1))
else
  echo "none"
fi
echo "::endgroup::"

if [ "$failures" -gt 0 ]; then
  echo "::error::verify failed with $failures problem(s)"
  exit 1
fi
echo "verify: $count screen(s) built, launched and rendered cleanly"
