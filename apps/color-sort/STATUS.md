stage: built
date: 2026-09-11
spec: SPEC.md · qa: qa.json · privacy source: privacy.json
next: app-verify, then aso → shots → compliance → pages

## Where it stands

Scaffolded, implemented and verified on a `macos-26` runner with no human in the loop.

- **Builds against the iOS 26 SDK**, deployment target iOS 17, on an iPhone 17 Pro Max
  simulator running iOS 26.5. `xcodegen generate` runs before every build; no `.xcodeproj`
  is committed.
- **`.github/scripts/verify-app.sh color-sort` passes.** All five screens in `qa.json`
  build, launch and render, the bundle check is clean, and no crash report belongs to
  `com.starhiveconcept.colorsort`.
- **Every screen was looked at, not just compiled.** Each capture below was read back as a
  PNG before the commit that introduced it, in light, in dark, and at the largest
  accessibility text size.
- **Listing written**, inside every limit: name 27/30, subtitle 29/30, keywords 99/100,
  promo 162/170, description 3280/4000. No word is repeated between the name, the subtitle
  and the keyword field, because App Store search indexes all three together.
- **Privacy generated, not hand-written.** `privacy.json` is the source; the manifest and
  the App Store privacy answers come from `tools/privacy/sync.mjs`.

## What works

- **The solvability guarantee, which is the whole wedge.** `LevelGenerator` deals a random
  board, `Solver` searches it, and a board it cannot finish is discarded and re-dealt. The
  search is breadth-first over tube states — positions are keyed by their tubes packed four
  bits per unit and sorted, so boards differing only in tube order collapse to one — which
  makes the move count it returns the shortest there is, and that number is par. A
  depth-first pass with the same visited set is the fallback for a board whose breadth-first
  frontier does not fit the budget; if neither finishes, the board is thrown away rather
  than served. Nothing a player is handed is unverified.
- **Hint replays the verified line.** While the player is still on it, the hint is free: the
  stored solution advances a cursor. The moment they take their own route it re-solves from
  the board actually in front of them, so the hint is right even off the original line. It
  marks the source tube ↑ and the destination ↓ and says the move in words.
- **Play.** Tap a tube, tap where it should go; it pours when the top colors match and there
  is room. Undo, restart, move counter against par. Every pour is written to disk
  immediately, so a kill or a crash never costs a level.
- **Progress.** Today's puzzle, seeded from the date so it is the same board for everyone;
  current streak, longest run, days played; a month calendar shaded on the days played;
  levels and dailies cleared; a plain-text share line.
- **Packs.** The level ladder with cleared levels marked, and the three things the unlock
  buys — calm mode, the Okabe–Ito color-blind palette, and a shape marker on every unit.
  Locked toggles open the paywall rather than doing nothing.
- **Settings and paywall** from FactoryKit, plus rows for what is on the device and an
  erase-everything control. `factoryReviewPrompt(afterSessions: 3)` is wired in
  `Tidepour.swift`.
- **The paywall shows the product** with `-fakeProducts`: one non-consumable, $4.99, "one
  time", with Restore, Terms and Privacy. There is no auto-renewal disclosure and there must
  not be — nothing here renews.
- **Free tier is real.** The daily puzzle and the first 60 levels, with undo, restart, hints,
  streak and calendar, are free forever. `AppInfo.freeLevelCount` is the one place that says
  60.

## Accessibility

- No frozen font sizes anywhere; the two display numbers use FactoryKit's `scaledFont`.
- Checked at `accessibility-extra-extra-extra-large` in light and in dark. The first pass
  was broken — the header truncated to "4 m… par… So-luti…" and the hint banner pushed the
  board off screen — and is fixed: the header stacks when it no longer fits across, the
  banner is line-limited, the three controls drop to symbols with VoiceOver labels, and the
  board holds a floor of 240pt.
- Every tube is one VoiceOver element that reads its contents bottom-up ("from the bottom,
  2 blue, then red"), with the shape markers as a second, non-color channel.

## Changed outside this app

`FactoryKit/Sources/FactoryKit/SettingsView.swift` takes an optional `upgradeTitle` and
`activeTitle`. Both default to the old strings, so no other app changes; Tidepour passes
"Unlock Tidepour", because a row offering to "Upgrade to Pro" would name a product this app
does not sell. Quizday was rebuilt to confirm the kit change is source-compatible.

## What is stubbed or deliberately absent

- **No timer, no lives, no coins, no consumables, no ad SDK, no analytics SDK, no network
  code.** All four of those are absences by design, and the compliance gate checks the "no
  ads" claim in the description against the binary.
- **No notifications**, so there is no streak reminder. A streak you are nagged about is a
  job.
- **Level ladder is drawn to 240 squares** when unlocked, or `currentLevel + 60` if that is
  further. That is how many squares are shown, not how many boards exist — boards are
  generated on the way in and there is no end to them.
- **The eighth palette color is unused.** The ladder tops out at seven colors, because
  seven plus two spares is the widest board the breadth-first pass finishes on
  comfortably and an eighth would start handing out upper-bound pars instead of true ones.

## What could not be checked here

- **A real purchase.** No runner can complete one. The paywall was exercised with
  `-fakeProducts`; StoreKit's own sandbox path is untested until TestFlight on a phone.
- **Haptics.** `Haptics.tap()` and `Haptics.success()` are wired to pours and to clearing a
  level; a simulator cannot feel them.
- **The share sheet.** `ShareLink` renders; presenting it needs hardware.
- **Generation time on a real device.** Dealing and solving runs off the main actor with a
  still "Dealing a board" state rather than a spinner, and every generated board is cached,
  so a level is solved once per install. On the runner no level in `qa.json` was ever caught
  mid-deal by the capture tooling. An A-series phone is faster than this runner, but that is
  an inference, not a measurement.

## One judgement call worth flagging

SPEC.md's risk section says the answer to guideline 4.3 "must be visible in the first
screenshot: the daily puzzle and streak, not a generic tube board", while its Store section
lists "Every level has a solution. We check before you see it." as caption one. Screenshot
one is the board — but it is not a generic tube board: it carries the "Solution verified"
badge and the hint arrows, which is the 4.3 answer stated more directly than a calendar
states it. The daily puzzle and streak are screenshot two. If the reviewer disagrees,
swapping the first two entries in `store/screenshots.json` and `qa.json` is the whole fix.

## Blocked on the owner

1. **Search the App Store for `Tidepour`.** Never checked against Apple — the planning
   sandbox had no route to it and neither does this runner. Alternates held in reserve:
   `Hueflask`, `Pourline`.
2. **Create the App Store Connect record** (Apple's API refuses `CREATE` on `apps`) and the
   one non-consumable IAP, `com.starhiveconcept.colorsort.unlock` at $4.99.
3. **TestFlight pass on a phone** — haptics, the share sheet, a real sandbox purchase — then
   the submit approval.
