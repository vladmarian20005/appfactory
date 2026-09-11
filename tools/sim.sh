#!/usr/bin/env bash
# Simulator driver. Works the same on a laptop and on a GitHub macOS runner.
#
#   tools/sim.sh boot                                  create + boot the factory device, print its UDID
#   tools/sim.sh build   <project-dir> <scheme>
#   tools/sim.sh run     <project-dir> <scheme> [args…]     e.g. -onboarded -sampleData -pro
#   tools/sim.sh shot    <project-dir> <scheme> <out.png>
#   tools/sim.sh reset   <project-dir> <scheme>
#   tools/sim.sh ui      <light|dark> [content-size]        appearance + Dynamic Type, for the design matrix
#   tools/sim.sh frames  <out-dir> [count] [interval]       screenshots in quick succession, to see motion
#
# Device selection, in order of precedence:
#   SIM_UDID      an exact device, used as-is. What CI passes.
#   SIM_DEVICE    a device name to look up (default: the factory device below).
#
# CI notes. `boot` creates the device rather than hoping the image ships one, because the
# runner's preinstalled set changes between image releases. Nothing here swallows a boot
# failure: a device stuck in Creating used to produce a green step and a black PNG.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

FACTORY_DEVICE="${SIM_DEVICE:-factory-69}"
# Preference list, first available wins. Every entry is a 6.9" device (1320x2868), the size
# App Store Connect wants as the primary iPhone screenshot. A list rather than one name
# because the runner image's newest device changes with each Xcode release.
DEVICE_TYPES="${SIM_DEVICE_TYPE:-iPhone 17 Pro Max:iPhone 16 Pro Max}"

die() { echo "sim.sh: $*" >&2; exit 1; }

# Resolve the device to work with, without creating anything.
resolve_udid() {
  if [ -n "${SIM_UDID:-}" ]; then echo "$SIM_UDID"; return; fi
  xcrun simctl list devices available -j | node -e '
    const d = JSON.parse(require("fs").readFileSync(0, "utf8"));
    const name = process.argv[1];
    let hit = "";
    for (const rt of Object.values(d.devices))
      for (const dev of rt) if (dev.name === name && dev.isAvailable) hit = dev.udid;
    console.log(hit);
  ' "$FACTORY_DEVICE"
}

# Newest available iOS runtime identifier.
newest_runtime() {
  xcrun simctl list runtimes -j | node -e '
    const rs = JSON.parse(require("fs").readFileSync(0, "utf8")).runtimes
      .filter(r => r.isAvailable && r.platform === "iOS")
      .sort((a, b) => a.version.localeCompare(b.version, undefined, { numeric: true }));
    if (!rs.length) { console.error("no available iOS runtime"); process.exit(1); }
    console.log(rs[rs.length - 1].identifier);
  '
}

# Deterministic capture settings: same clock, same battery, same appearance every run.
freeze_chrome() {
  local udid=$1
  xcrun simctl ui "$udid" appearance "${SIM_APPEARANCE:-light}" >/dev/null 2>&1 || true
  xcrun simctl status_bar "$udid" override \
    --time "9:41" --batteryState charged --batteryLevel 100 \
    --cellularMode active --cellularBars 4 --wifiMode active --wifiBars 3 >/dev/null 2>&1 || true
}

cmd_boot() {
  local rt udid type
  rt=$(newest_runtime)
  # Recreate so a device left dirty by a previous run cannot leak into this one.
  if [ -z "${SIM_UDID:-}" ]; then
    xcrun simctl delete "$FACTORY_DEVICE" >/dev/null 2>&1 || true
    udid=""
    while IFS= read -r type; do
      [ -n "$type" ] || continue
      if udid=$(xcrun simctl create "$FACTORY_DEVICE" "$type" "$rt" 2>/dev/null); then
        echo "sim.sh: using '$type' on $rt" >&2
        break
      fi
      udid=""
    done <<< "${DEVICE_TYPES//:/$'\n'}"
    [ -n "$udid" ] || die "none of these device types exist on $rt: $DEVICE_TYPES"
  else
    udid="$SIM_UDID"
  fi

  xcrun simctl boot "$udid" >/dev/null 2>&1 || true   # already-booted is fine; the wait below is the real check
  if ! xcrun simctl bootstatus "$udid" -b >/dev/null 2>&1; then
    echo "sim.sh: first boot failed, erasing and retrying once" >&2
    xcrun simctl shutdown "$udid" >/dev/null 2>&1 || true
    xcrun simctl erase "$udid" >/dev/null 2>&1 || true
    xcrun simctl boot "$udid" >/dev/null 2>&1 || true
    xcrun simctl bootstatus "$udid" -b >/dev/null 2>&1 \
      || die "device $udid ($DEVICE_TYPE) never finished booting"
  fi
  freeze_chrome "$udid"
  echo "$udid"
}

# Capture once the screen stops changing. `simctl launch` returns when the process spawns,
# not when it has drawn, so a fixed sleep captures the launch screen on a loaded runner.
capture_stable() {
  local udid=$1 out=$2 tmp_a tmp_b deadline
  tmp_a=$(mktemp -t simshot); tmp_b=$(mktemp -t simshot)
  # 60s, not 30: verify reinstalls the app before every screen, and a first launch onto a
  # cold runner occasionally takes longer than half a minute to put up its first frame. At
  # 30s that was photographed as a flat white launch screen and failed the blank check — a
  # different screen each run, three runs of Tidepour in a row. The wait only costs anything
  # on a screen that has not drawn; a screen that draws is captured as soon as it settles.
  deadline=$(( $(date +%s) + ${SHOT_TIMEOUT:-60} ))
  sleep "${SHOT_DELAY:-1}"

  # Phase 1: wait until the app has actually drawn something.
  #
  # Stability alone is not enough, and assuming otherwise is what produced three blank
  # screenshots on the first CI run: an app that has launched but not yet rendered shows a
  # flat white window, and two consecutive captures of flat white are identical, so the
  # stability test below declares victory on an empty screen. Wait for content first.
  while [ "$(date +%s)" -lt "$deadline" ]; do
    xcrun simctl io "$udid" screenshot --type=png "$tmp_a" >/dev/null 2>&1 || die "screenshot failed"
    if node "$SCRIPT_DIR/qa/check-shot.mjs" --quiet "$tmp_a"; then break; fi
    sleep 0.5
  done

  # Phase 2: now that there is content, wait for it to stop moving.
  while [ "$(date +%s)" -lt "$deadline" ]; do
    sleep 0.5
    xcrun simctl io "$udid" screenshot --type=png "$tmp_b" >/dev/null 2>&1 || die "screenshot failed"
    if cmp -s "$tmp_a" "$tmp_b"; then
      mv "$tmp_b" "$out"; rm -f "$tmp_a"
      return 0
    fi
    mv "$tmp_b" "$tmp_a"
  done

  # A screen with a live countdown never settles. Capturing the last frame is correct; the
  # blank check in verify-app.sh is what decides whether it is usable.
  echo "sim.sh: screen never settled in ${SHOT_TIMEOUT:-30}s; capturing the last frame" >&2
  mv "$tmp_a" "$out"; rm -f "$tmp_b"
}

# ── dispatch ──────────────────────────────────────────────────────────────────
cmd=${1:?usage: sim.sh <boot|build|run|shot|reset|ui> …}

if [ "$cmd" = "boot" ]; then cmd_boot; exit 0; fi

if [ "$cmd" = "ui" ]; then
  udid=$(resolve_udid); [ -n "$udid" ] || die "no device; run 'sim.sh boot' first"
  xcrun simctl ui "$udid" appearance "${2:?light|dark}"
  [ -n "${3:-}" ] && xcrun simctl ui "$udid" content_size "$3"
  echo "ui: appearance=$2 content_size=${3:-default}"
  exit 0
fi

# A screenshot can only prove a screen rendered; it cannot show that something moves. A few
# frames taken as fast as simctl allows (~0.3 s each on a runner, plus the interval) can:
# tools/qa/filmstrip.mjs lays them out as one image the critic reads. No settling here — the
# point is to catch the motion, not to wait it out.
if [ "$cmd" = "frames" ]; then
  udid=$(resolve_udid); [ -n "$udid" ] || die "no device; run 'sim.sh boot' first"
  out=${2:?out dir}; count=${3:-8}; interval=${4:-0.2}
  mkdir -p "$out"
  for i in $(seq 1 "$count"); do
    xcrun simctl io "$udid" screenshot --type=png "$(printf '%s/frame-%02d.png' "$out" "$i")" >/dev/null 2>&1 \
      || die "screenshot failed"
    sleep "$interval"
  done
  echo "frames: $count in $out"
  exit 0
fi

dir=${2:?project dir}; scheme=${3:?scheme}; arg4=${4:-}
udid=$(resolve_udid)
[ -n "$udid" ] || die "no available simulator (SIM_UDID unset, no device named '$FACTORY_DEVICE'). Run 'sim.sh boot'."
dir=$(cd "$dir" 2>/dev/null && pwd) || die "no such directory: $2"
derived="$dir/.build"
products="$derived/Build/Products/Debug-iphonesimulator"

find_app() {
  [ -d "$products" ] || die "no build products; run 'sim.sh build' first"
  local app; app=$(find "$products" -maxdepth 1 -name "*.app" | head -1)
  [ -n "$app" ] || die "no .app in $products; run 'sim.sh build' first"
  echo "$app"
}

case "$cmd" in
  build)
    # .xcodeproj is generated, never committed. Regenerate if a runner hasn't already.
    [ -d "$dir/$scheme.xcodeproj" ] || (cd "$dir" && xcodegen generate -q) \
      || die "no $scheme.xcodeproj and xcodegen failed"
    xcodebuild -project "$dir/$scheme.xcodeproj" -scheme "$scheme" -sdk iphonesimulator \
      -destination "id=$udid" -derivedDataPath "$derived" \
      COMPILER_INDEX_STORE_ENABLE=NO -quiet build
    echo "Built $scheme"
    ;;
  run)
    app=$(find_app)
    bundle=$(plutil -extract CFBundleIdentifier raw -o - "$app/Info.plist")
    xcrun simctl install "$udid" "$app"
    xcrun simctl terminate "$udid" "$bundle" >/dev/null 2>&1 || true
    xcrun simctl launch "$udid" "$bundle" "${@:4}" >/dev/null
    echo "Launched $bundle"
    ;;
  shot)
    capture_stable "$udid" "${arg4:?out.png}"
    echo "Saved $arg4"
    ;;
  reset)
    app=$(find_app)
    bundle=$(plutil -extract CFBundleIdentifier raw -o - "$app/Info.plist")
    xcrun simctl terminate "$udid" "$bundle" >/dev/null 2>&1 || true
    xcrun simctl uninstall "$udid" "$bundle" >/dev/null 2>&1 || true
    echo "Reset $bundle"
    ;;
  *) die "unknown command '$cmd'" ;;
esac
