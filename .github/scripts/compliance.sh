#!/usr/bin/env bash
# Apple compliance gate. Every check here is something App Review or App Store Connect
# rejects, turned into a build failure that costs a minute instead of a week.
#
#   .github/scripts/compliance.sh <slug>
#
# Runs anywhere: no Xcode, no simulator, no credentials. Fix the app, not the gate.
set -uo pipefail

slug=${1:?usage: compliance.sh <slug>}
app="apps/$slug"
ios="$app/ios/App"
meta="$app/store/metadata/en-US"
shots="$app/store/screenshots/en-US"

fails=0
warns=0
fail() { echo "::error::$*"; fails=$((fails + 1)); }
warn() { echo "::warning::$*"; warns=$((warns + 1)); }
pass() { echo "  ok   $*"; }

[ -d "$app" ] || { echo "::error::no such app: $app"; exit 1; }
echo "Compliance gate for $slug"

# ── 1. Privacy manifest ───────────────────────────────────────────────────────
# Required since 1 May 2024. App Store Connect rejects the upload itself, not the review.
echo "::group::Privacy manifest"
manifest="$ios/PrivacyInfo.xcprivacy"
if [ ! -f "$manifest" ]; then
  fail "no $manifest. Every app must declare its required-reason API use."
elif ! plutil -lint "$manifest" >/dev/null 2>&1; then
  fail "$manifest is not a valid plist"
else
  pass "$manifest is present and valid"
  # @AppStorage is UserDefaults, a required-reason API. If the app uses one and the manifest
  # does not say so, the upload is rejected.
  if grep -rq "@AppStorage\|UserDefaults" "$ios" 2>/dev/null; then
    if grep -q "NSPrivacyAccessedAPICategoryUserDefaults" "$manifest"; then
      pass "UserDefaults is declared"
    else
      fail "the app uses @AppStorage/UserDefaults but the manifest does not declare NSPrivacyAccessedAPICategoryUserDefaults"
    fi
  fi
  # The reverse: declaring an API you do not use is also wrong.
  if grep -q "NSPrivacyAccessedAPICategoryDiskSpace" "$manifest" && ! grep -rq "volumeAvailableCapacity\|systemFreeSize" "$ios" 2>/dev/null; then
    warn "the manifest declares DiskSpace but nothing in the app appears to read it"
  fi
fi

# The manifest, the App Store answers and the published policy all generate from
# privacy.json. If any has drifted, the app is telling Apple three different stories.
if [ -f "$app/privacy.json" ]; then
  if node tools/privacy/sync.mjs "$slug" --check >/dev/null 2>&1; then
    pass "privacy artifacts match privacy.json"
  else
    fail "the privacy artifacts are out of date with $app/privacy.json. Run: node tools/privacy/sync.mjs $slug"
  fi
else
  warn "no $app/privacy.json; the manifest and the App Store answers are hand-maintained and will drift"
fi
echo "::endgroup::"

# ── 2. Subscription paywall, guideline 3.1.2 ──────────────────────────────────
echo "::group::Paywall disclosures"
paywall="FactoryKit/Sources/FactoryKit/PaywallView.swift"
if [ ! -f "$paywall" ]; then
  warn "no $paywall to check"
else
  for needle in "renews automatically" "Restore" "termsURL" "privacyURL" "Manage subscription"; do
    if grep -q "$needle" "$paywall"; then pass "paywall mentions \"$needle\""
    else fail "the paywall has no \"$needle\". Guideline 3.1.2 wants the renewal terms, Restore, Terms and Privacy on the paywall itself."; fi
  done
fi
echo "::endgroup::"

# ── 3. Reachable legal pages ──────────────────────────────────────────────────
# `precheck` fails a submission on a privacy URL that 404s, after the upload has happened.
echo "::group::Privacy and support URLs"
for u in privacy_url support_url; do
  f="$meta/$u.txt"
  if [ ! -f "$f" ]; then fail "missing $f"; continue; fi
  url=$(cat "$f")
  code=$(curl -s -o /dev/null -w '%{http_code}' -L --max-time 25 "$url" || echo 000)
  if [ "$code" = "200" ]; then pass "$u -> 200  $url"
  else fail "$u returned $code: $url"; fi
done
echo "::endgroup::"

# ── 4. The listing, in every localization Apple indexes on the US storefront ──
# Limits, hygiene and the nine extra localizations live in one script, shared with app-aso
# (which writes them) and app-release (which uploads them).
echo "::group::Store metadata"
if .github/scripts/listing-check.sh "$slug"; then
  pass "listing is complete and inside every limit"
else
  fail "the listing failed listing-check.sh; see the errors above"
fi
echo "::endgroup::"

# ── 5. Screenshots ────────────────────────────────────────────────────────────
echo "::group::Screenshots"
if [ ! -d "$shots" ]; then
  fail "no $shots. deliver reads <screenshots>/<locale>/*.png and uploads nothing from a bare directory."
else
  n=$(find "$shots" -name "*.png" | wc -l | tr -d ' ')
  if [ "$n" -lt 1 ]; then fail "no screenshots in $shots"
  elif [ "$n" -gt 10 ]; then fail "$n screenshots; App Store Connect accepts at most 10"
  else pass "$n screenshot(s)"; fi
  # Apple rejects an image carrying an alpha channel even when it is fully opaque.
  for f in "$shots"/*.png; do
    [ -e "$f" ] || continue
    read -r w h a < <(node -e '
      const {PNG}=require("pngjs");const fs=require("fs");
      const p=PNG.sync.read(fs.readFileSync(process.argv[1]));
      console.log(p.width, p.height, p.alpha ? "alpha" : "noalpha");' "$f")
    if [ "$a" = "alpha" ]; then fail "$(basename "$f") has an alpha channel"; fi
    if [ "$w" != "1320" ] || [ "$h" != "2868" ]; then
      fail "$(basename "$f") is ${w}x${h}; Apple wants 1320x2868 (6.9\") as the primary iPhone size"
    fi
  done
  [ "$fails" -eq 0 ] && pass "all screenshots 1320x2868, no alpha"
fi
echo "::endgroup::"

# ── 6. Nothing unfinished ─────────────────────────────────────────────────────
echo "::group::Placeholders"
found=$(grep -rniE "\bTBD\b|lorem ipsum|example\.com|TemplateApp|PLACEHOLDER|FIXME|XXXX" "$ios" "$app/store" 2>/dev/null | grep -v "Binary file" | head -10)
if [ -n "$found" ]; then
  fail "placeholder text is still in the app or the listing:"
  echo "$found" | sed 's/^/    /'
else
  pass "no placeholder text"
fi
echo "::endgroup::"

# ── 7. Accessibility ──────────────────────────────────────────────────────────
# A frozen point size ignores Dynamic Type. FactoryKit's scaledFont keeps the design and
# still scales; Theme.swift is where the primitive itself lives. A share card is not an
# exception: ShareImage.render pins Dynamic Type for the render, so scaledFont on a fixed
# canvas draws at the size it asks for.
#
# Matching `.system(size:` rather than `.font(.system(size:` is deliberate. The narrower
# pattern only saw the call written inline, so an app that wrapped the same thing in a
# `-> Font` helper passed a gate that failed the app which did not — the two spellings are
# the same defect, and tools/design/tells.mjs greps for this one.
echo "::group::Accessibility"
frozen=$(grep -rn "\.system(size:" "$ios" 2>/dev/null | head -10)
if [ -n "$frozen" ]; then
  fail "text with a frozen point size ignores Dynamic Type; use .scaledFont(size:) from FactoryKit:"
  echo "$frozen" | sed 's/^/    /'
else
  pass "no frozen font sizes"
fi
echo "::endgroup::"

# ── 8. The listing must not lie ───────────────────────────────────────────────
echo "::group::Claims match the binary"
if [ -f "$meta/description.txt" ] && grep -qiE "no ads|ad free|without ads" "$meta/description.txt"; then
  if grep -rqiE "admob|googlemobileads|applovin|ironsource|unityads|vungle|chartboost" "$ios" FactoryKit/Sources 2>/dev/null; then
    fail "the listing says the app has no ads, but an advertising SDK is linked"
  else
    pass "\"no ads\" claim holds: no advertising SDK"
  fi
fi
if [ -f "$meta/description.txt" ] && grep -qiE "no analytics|no trackers|no tracking" "$meta/description.txt"; then
  if grep -rqiE "firebase|amplitude|mixpanel|segment\.com|appsflyer|adjust\.com" "$ios" FactoryKit/Sources 2>/dev/null; then
    fail "the listing says there is no analytics, but an analytics SDK is linked"
  else
    pass "\"no analytics\" claim holds"
  fi
fi
# NSPrivacyTracking must agree with the App Privacy answers.
if [ -f "$manifest" ] && [ -f "$app/store/app_privacy_details.json" ]; then
  if grep -q "DATA_NOT_COLLECTED" "$app/store/app_privacy_details.json"; then
    if grep -A1 "NSPrivacyTracking" "$manifest" | grep -q "<true/>"; then
      fail "app_privacy_details says DATA_NOT_COLLECTED but the manifest sets NSPrivacyTracking true"
    else
      pass "privacy manifest and App Privacy answers agree"
    fi
  fi
fi
echo "::endgroup::"

# ── 9. What App Store Connect will be sent ────────────────────────────────────
# app-submit creates the in-app purchases from Products.storekit, and app-release sets the
# categories and content rights from store/release.json. A value Apple rejects fails there,
# after the owner has already been told the app is ready; here it costs a fix instead.
echo "::group::In-app purchases and release settings"
if out=$(node tools/asc/products.mjs "$slug" 2>&1); then
  pass "in-app purchases: $(echo "$out" | head -1 | sed "s/^$slug: //")"
else
  echo "$out" | grep '·' | sed 's/^ *· //' | while IFS= read -r l; do echo "::error::in-app purchase: $l"; done
  fail "in-app purchases would be rejected by App Store Connect (above)"
fi
rel="$app/store/release.json"
if [ ! -f "$rel" ]; then
  fail "no store/release.json: app-release takes the categories and content rights from it"
elif msg=$(node -e '
  const r = JSON.parse(require("fs").readFileSync(process.argv[1], "utf8"));
  const bad = [];
  if (!/^[A-Z_]+$/.test(r.primaryCategory ?? "")) bad.push("primaryCategory is missing");
  if (r.primaryCategory === "GAMES" && !/^GAMES_[A-Z_]+$/.test(r.primarySubcategoryOne ?? "")) bad.push("a game needs primarySubcategoryOne, e.g. GAMES_PUZZLE");
  if (r.contentRights && !["DOES_NOT_USE_THIRD_PARTY_CONTENT", "USES_THIRD_PARTY_CONTENT"].includes(r.contentRights)) bad.push(`contentRights "${r.contentRights}"`);
  if (bad.length) { console.log(bad.join("; ")); process.exit(1); }
  console.log(`${r.primaryCategory}${r.primarySubcategoryOne ? ` / ${r.primarySubcategoryOne}` : ""}`);
' "$rel" 2>&1); then
  pass "release settings: $msg"
else
  fail "store/release.json: $msg"
fi
echo "::endgroup::"

echo
if [ "$fails" -gt 0 ]; then
  echo "::error::compliance: $fails failure(s), $warns warning(s) — this app is not ready for App Review"
  exit 1
fi
echo "compliance: clean ($warns warning(s))"
