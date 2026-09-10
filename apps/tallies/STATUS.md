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

## Not done yet

- Dark mode and large-text passes have not been run. Everything on screen is a standard
  SwiftUI component with system colours and no frozen font sizes — the one display-size
  number uses `scaledFont`, which scales with Dynamic Type — so both are expected to hold,
  but expected is not checked.
- `/ship tallies` is the next stage: screenshots, then compliance, then the page.
