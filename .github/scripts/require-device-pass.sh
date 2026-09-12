#!/usr/bin/env bash
# Refuse to submit an app the owner has never held in their hand.
#
#   require-device-pass.sh <slug>
#
# Four things in a shipped app cannot be proven by any runner, and three of them are the
# ones a first review rejects over: the daily reminder actually firing, haptics, the share
# sheet, and a real sandbox purchase — a scheme's StoreKit configuration is never honoured
# by `simctl launch`, so no simulator has ever bought anything.
#
# The ship skill has always told the agent to set these flags "only once the owner confirms.
# The gate refuses to pass on your word." This is that gate; until now nothing read them.
#
# storekit_verified is required only of an app that sells something. An app with no products
# has no purchase to verify, and demanding one would leave it unshippable.
set -euo pipefail

slug=${1:?usage: require-device-pass.sh <slug>}
file="apps/$slug/state.json"

[ -f "$file" ] || {
  echo "::error::apps/$slug/state.json does not exist, so no device pass was ever recorded."
  exit 1
}

flag() {
  node -e '
    const fs = require("fs");
    const s = JSON.parse(fs.readFileSync(process.argv[1], "utf8"));
    console.log(s[process.argv[2]] === true ? "true" : "false");
  ' "$file" "$1"
}

sells=$(node -e '
  import("./tools/asc/products.mjs").then((m) => {
    const p = m.loadProducts(process.argv[1]);
    const n = (p.subscriptions ?? []).length + (p.oneTime ?? []).length;
    console.log(n > 0 ? "true" : "false");
  }).catch(() => console.log("false"));
' "$slug")

fail=0

if [ "$(flag device_tested)" != "true" ]; then
  echo "::error::$slug: device_tested is not set. The owner has to run the TestFlight build on a phone — the reminder firing, haptics, the share sheet — before this version goes to App Review."
  fail=1
else
  echo "ok: device_tested"
fi

if [ "$sells" = "true" ]; then
  if [ "$(flag storekit_verified)" != "true" ]; then
    echo "::error::$slug: storekit_verified is not set, and this app sells something. A sandbox purchase has to complete on a real device: no simulator can make one, so a paywall that cannot sell is the kind of thing App Review finds first."
    fail=1
  else
    echo "ok: storekit_verified"
  fi
else
  echo "ok: $slug sells nothing, so storekit_verified is not required"
fi

exit "$fail"
