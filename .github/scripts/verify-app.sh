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
bundle_id=$(node -p "require('./$qa_json').bundleId || ''")
[ -n "$bundle_id" ] || { echo "::error::$qa_json has no bundleId; the crash check needs it to tell this app's crashes from the simulator's"; exit 1; }
mkdir -p "$out"

echo "::group::Generate the Xcode project"
# .xcodeproj is a build product; it is never committed.
(cd "$app_dir" && xcodegen generate)
echo "::endgroup::"

echo "::group::Build $scheme"
tools/sim.sh build "$app_dir" "$scheme"
echo "::endgroup::"

# What App Store Connect would reject at upload, caught on the simulator build instead.
echo "::group::Check the bundle"
built=$(find "$app_dir/.build/Build/Products/${SIM_CONFIG:-Release}-iphonesimulator" -maxdepth 1 -name "*.app" | head -1)
[ -n "$built" ] || { echo "::error::the build produced no .app"; exit 1; }
.github/scripts/bundle-check.sh "$built"
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
  # -stillFrames, always and last: FactoryKit pauses looping motion and freezes celebrations
  # at their peak under it, so an app that is alive still settles for the capture. Last, so
  # it can never be read as the value of the flag before it.
  if ! tools/sim.sh run "$app_dir" "$scheme" "${args[@]}" -stillFrames; then
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
  # Only crashes belonging to the app under test. A simulator writes reports for its own
  # system processes too — a MobileCal crash failed this step once, which is a red build
  # nobody can act on and trains everyone to ignore the check.
  mine=""
  others=0
  while IFS= read -r c; do
    [ -n "$c" ] || continue
    if grep -q "$bundle_id" "$c" 2>/dev/null; then
      mine="$mine$c"$'\n'
    else
      others=$((others + 1))
    fi
  done <<< "$new_crashes"

  if [ -n "$mine" ]; then
    echo "::error::$scheme left crash reports:"
    while IFS= read -r c; do
      [ -n "$c" ] || continue
      echo "--- $c"
      head -40 "$c"
    done <<< "$mine"
    failures=$((failures + 1))
  else
    echo "none for $bundle_id"
  fi
  [ "$others" -gt 0 ] && echo "  ($others unrelated simulator crash report(s) ignored)"
else
  echo "none"
fi
echo "::endgroup::"

if [ "$failures" -gt 0 ]; then
  echo "::error::verify failed with $failures problem(s)"
  exit 1
fi
echo "verify: $count screen(s) built, launched and rendered cleanly"
