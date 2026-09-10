#!/usr/bin/env bash
# Facts about a built .app that App Store Connect checks at upload time, checked here
# instead, where a failure costs seconds rather than an archive.
#
#   .github/scripts/bundle-check.sh <path/to/Some.app>
#
# macOS only (plutil). verify-app.sh runs it on the simulator build, so a bad bundle fails
# verify on every push; the beta lane runs it again on the archive it is about to upload,
# so the rules that judged the build are the rules that judge the upload.
#
# Every check here cost a real upload once. The first: a project.yml with
# TARGETED_DEVICE_FAMILY "1" at project level shipped a bundle claiming iPad, because
# XcodeGen's target preset says "1,2" and a target setting beats a project one. Apple
# answered ITMS-90474 after a five-minute archive.
set -euo pipefail

app=${1:?usage: bundle-check.sh <Some.app>}
plist="$app/Info.plist"
[ -f "$plist" ] || { echo "::error::$plist does not exist"; exit 1; }

fails=0
fail() { echo "::error::$*"; fails=$((fails + 1)); }
pass() { echo "  ok   $*"; }
# json for arrays, raw for scalars: plutil refuses to print a bare string as JSON, and it
# writes its complaint to stdout, so the value has to be trusted only on a zero exit.
get()  { local v; v=$(plutil -extract "$1" "${2:-raw}" -o - "$plist" 2>/dev/null) && printf '%s' "$v" || echo "null"; }

echo "Bundle check for $(basename "$app")"

# ── Device family ─────────────────────────────────────────────────────────────
# The factory ships iPhone apps: its screenshots are 6.7" only. A bundle that claims iPad
# needs iPad screenshots in App Store Connect and, unless it opts out of multitasking,
# all four orientations — ITMS-90474 rejects the upload otherwise.
families=$(get UIDeviceFamily json | tr -d ' \n')
case "$families" in
  "[1]") pass "UIDeviceFamily is iPhone only" ;;
  *2*)   fail "UIDeviceFamily is $families: the bundle claims iPad. Put TARGETED_DEVICE_FAMILY: \"1\" under the target's settings in project.yml (at project level XcodeGen's own preset, 1,2, overrides it). If iPad is intended, add the ~ipad orientations and iPad screenshots, then relax this check." ;;
  *)     fail "UIDeviceFamily is $families; expected [1]" ;;
esac

# ── Orientations ──────────────────────────────────────────────────────────────
orient=$(get UISupportedInterfaceOrientations json | tr -d ' \n')
case "$orient" in
  *UIInterfaceOrientationPortrait*) pass "portrait is supported" ;;
  *) fail "UISupportedInterfaceOrientations is $orient; the app must at least support portrait" ;;
esac

# ── Export compliance ─────────────────────────────────────────────────────────
# Without this answer in the bundle, every TestFlight build shows "Missing Compliance"
# and cannot be installed until a human answers the encryption question in a browser.
case "$(get ITSAppUsesNonExemptEncryption)" in
  false) pass "ITSAppUsesNonExemptEncryption is false" ;;
  true)  fail "ITSAppUsesNonExemptEncryption is true; the factory's apps use no non-exempt encryption. Set INFOPLIST_KEY_ITSAppUsesNonExemptEncryption: NO in project.yml" ;;
  *)     fail "ITSAppUsesNonExemptEncryption is missing. Set INFOPLIST_KEY_ITSAppUsesNonExemptEncryption: NO in project.yml, or every TestFlight build waits for a click" ;;
esac

# ── Identity ──────────────────────────────────────────────────────────────────
for key in CFBundleIdentifier CFBundleShortVersionString CFBundleVersion CFBundleDisplayName MinimumOSVersion; do
  v=$(get "$key")
  if [ "$v" = "null" ] || [ "$v" = '""' ]; then fail "$key is missing"; else pass "$key = $v"; fi
done

if [ "$fails" -gt 0 ]; then
  echo "::error::bundle check failed with $fails problem(s)"
  exit 1
fi
echo "bundle check: ok"
