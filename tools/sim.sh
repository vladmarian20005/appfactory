#!/usr/bin/env bash
# Simulator helper.
#   factory/tools/sim.sh build <project-dir> <scheme>
#   factory/tools/sim.sh run   <project-dir> <scheme> [launch args…]   e.g. -onboarded -sampleData -screen trends -pro
#   factory/tools/sim.sh shot  <project-dir> <scheme> <out.png>
#   factory/tools/sim.sh tap   <project-dir> <scheme> <x> <y>      (via xcrun simctl + AppleScript is unreliable; prefer UI tests)
# SIM_DEVICE overrides the device name (default: iPhone 15 Pro Max, 6.7", 1290x2796).
set -euo pipefail
cmd=${1:?cmd}; dir=${2:?project dir}; scheme=${3:?scheme}; arg4=${4:-}
DEVICE="${SIM_DEVICE:-iPhone 15 Pro Max}"
udid=$(xcrun simctl list devices available -j | node -e '
const d=JSON.parse(require("fs").readFileSync(0,"utf8")); const name=process.argv[1]; let hit="";
for (const rt of Object.values(d.devices)) for (const dev of rt) if (dev.name===name && dev.isAvailable) hit=dev.udid;
console.log(hit)' "$DEVICE")
[ -n "$udid" ] || { echo "No available simulator named '$DEVICE'"; exit 1; }
dir=$(cd "$dir" && pwd)
derived="$dir/.build"
case "$cmd" in
  build)
    xcodebuild -project "$dir/$scheme.xcodeproj" -scheme "$scheme" -sdk iphonesimulator \
      -destination "id=$udid" -derivedDataPath "$derived" -quiet build
    echo "Built $scheme for $DEVICE"
    ;;
  run)
    xcrun simctl boot "$udid" 2>/dev/null || true
    xcrun simctl bootstatus "$udid" -b >/dev/null 2>&1 || true
    app=$(find "$derived/Build/Products/Debug-iphonesimulator" -maxdepth 1 -name "*.app" | head -1)
    [ -n "$app" ] || { echo "No .app found; run build first"; exit 1; }
    bundle=$(plutil -extract CFBundleIdentifier raw -o - "$app/Info.plist")
    xcrun simctl install "$udid" "$app"
    xcrun simctl terminate "$udid" "$bundle" 2>/dev/null || true
    xcrun simctl launch "$udid" "$bundle" "${@:4}" >/dev/null
    echo "Launched $bundle on $DEVICE"
    ;;
  shot)
    sleep "${SHOT_DELAY:-2}"
    xcrun simctl io "$udid" screenshot "${arg4:?out.png}" >/dev/null
    echo "Saved ${arg4}"
    ;;
  reset)
    app=$(find "$derived/Build/Products/Debug-iphonesimulator" -maxdepth 1 -name "*.app" | head -1)
    bundle=$(plutil -extract CFBundleIdentifier raw -o - "$app/Info.plist")
    xcrun simctl terminate "$udid" "$bundle" 2>/dev/null || true
    xcrun simctl uninstall "$udid" "$bundle" 2>/dev/null || true
    echo "Reset $bundle"
    ;;
  *) echo "unknown command $cmd"; exit 1 ;;
esac
