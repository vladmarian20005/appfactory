stage: built
date: 2026-09-10
spec: SPEC.md · qa: qa.json · privacy source: privacy.json

## Where it stands

Scaffolded, implemented and verified on `macos-26` with no human in the loop. This app is the
pipeline smoke test the spec asked for, and the pipeline ran.

- **Builds against the iOS 26 SDK**, deployment target iOS 17, iPhone 17 Pro Max simulator on
  iOS 26.5. `xcodegen generate` runs before every build; no `.xcodeproj` is committed.
- **`verify-app.sh tallies` passes.** All five screens in `qa.json` build, launch and render,
  and no crash report belongs to `com.starhiveconcept.tallies`.
- **Every screen in the MVP exists and was looked at**, not just compiled. Each capture in
  this list was read back as a PNG before the commit that introduced it.
- **Listing written**, inside every limit: name 23/30, subtitle 27/30, keywords 93/100,
  promo 137/170, description 2386/4000. No word is repeated between the name, the subtitle
  and the keywords, because App Store search indexes all three together.
- **Privacy generated, not hand-written.** `privacy.json` is the source; the manifest and the
  App Store privacy answers come from `tools/privacy/sync.mjs`.

## What works

- **Counters.** Several counters as cards, each with its name, its running total and a large
  `+` that adds one without leaving the screen. Swipe to delete. The toolbar `+` opens the
  new-counter sheet (name, a colour from a fixed palette of six, an optional daily goal).
  Empty state has one line of copy and a button that creates the first counter.
- **Counter detail.** The total large, `+` and `−`, the goal ring as a `Gauge` when a goal is
  set, and the daily totals as a Swift Charts bar chart. Reset today and reset everything are
  both behind a confirmation, and both are disabled when there is nothing to reset.
- **History (Pro).** Every tap across every counter, newest first, grouped by day, over a
  per-counter total for the week and the month. Free users get the locked state with the
  reason and a way through to the paywall.
- **Settings and paywall** from FactoryKit, plus rows for what is on the device and an
  erase-everything control. `factoryReviewPrompt(afterSessions: 3)` is wired in `Tallies.swift`.
- **The free tier is real, not decorative.** Three counters and seven days of chart free;
  unlimited counters, the History screen and the fourteen-day chart on Pro.
- **The paywall shows both products** with `-fakeProducts` — $2.99 weekly and $19.99 yearly,
  each with the 3-day trial, and the guideline 3.1.2 renewal disclosure under the button.

## What is stubbed or deliberately absent

- **No network, by design.** The spec asked for none. The only URLs in the app are the
  support, privacy and terms links, which hand off to Safari; nothing here opens a socket.
- **No notifications, no permissions prompts, no date seeding.** Also by design: it is what
  makes every screen deterministic to screenshot.
- **`appStoreID` is nil**, so the kit hides the Share row in Settings. It fills in once the
  app record exists in App Store Connect.

## What could not be checked without hardware

- **A real purchase.** No runner can complete one. The paywall was verified with
  `-fakeProducts`, which injects display-only offers; the StoreKit purchase path itself is
  unexercised. `Products.storekit` carries the right ids and prices, but the App Store
  Connect subscriptions still have to be created and priced to match.
- **Haptics.** `Haptics.tap()` fires on every increment and on the paywall rows. A simulator
  reports nothing, so that it *feels* right is unverified.
- **The share sheet**, which needs `appStoreID` and a device.
- **Tap routing on the counter row.** The row keeps its navigation link and its `+` as
  siblings rather than nesting the button inside the link, precisely so a tap cannot be
  ambiguous — but there is no tap driver on the runner, so this was reasoned about and
  checked visually (the system draws its own disclosure chevron for the link), not tapped.

## Dark mode and large text

Both passes were run on the simulator and the captures read back.

- **Dark mode holds** on the counters list and the detail screen. Everything is a system
  colour or a palette colour over `secondarySystemGroupedBackground`, so there was nothing
  to fix.
- **Large text needed a fix, and got one.** At
  `accessibility-extra-extra-extra-large` the counter row broke: the total wrapped
  mid-number, so 334 rendered as "33" over "4" — a wrapped number is a different number.
  The row now lays out vertically at accessibility sizes, with the name over the total over a
  full-width `+`, and the total carries `lineLimit(1)` and `minimumScaleFactor` so it shrinks
  instead of breaking. The name needed `fixedSize(horizontal: false, vertical: true)` as
  well, or the enclosing `HStack` truncated it to one line instead of the three it was
  allowed. The default-size layout is unchanged, and `verify-app.sh` passes after the change.
- The detail screen already held at that size: the number, the ring and the buttons all
  scale, and the card scrolls rather than clipping.

## Where the compliance gate stands

`.github/scripts/compliance.sh tallies` was run at this commit. It reports 3 failures, and
all three are artifacts a later stage produces — none is a defect in the app:

1. `privacy_url returned 404` and 2. `support_url returned 404` for
   https://starhiveconcept.com/tallies-privacy-policy-terms/ — the policy page has not been
   published yet. It generates from `privacy.json` in `app-pages`.
3. `no apps/tallies/store/screenshots/en-US` — the composed App Store screenshots come from
   `app-shots`, out of the raw captures and `store/screenshots.json`, which is written.

Everything the gate can check at this stage passes: the privacy manifest is present, valid
and in sync with `privacy.json`; the paywall carries the renewal terms, restore and both
legal links; every metadata file is inside its limit; there is no placeholder text and no
frozen font size; and the "no ads" and "no analytics" claims were checked against the binary.

## Not done yet

- `/ship tallies` is the next stage: screenshots, then compliance, then the page. Those three
  failures above are exactly what it clears.
