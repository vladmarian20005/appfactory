# Tallies · critique

**Verdict: fail.** This is the pipeline smoke test with a beautiful design document sitting
next to it, unread by the compiler: `Color(.systemGroupedBackground)` with white cards, an SF
Symbol `+`, a Swift Charts bar chart and the kit's orange, on all five screens. The one thing
that decides it: **none of DESIGN.md was built** — no `AppBrand.swift`, no stave, no notch, no
`Ladder`, no `Mastery`, no `Run`, no `Earned`, no `Tones`, no `confetti`, no `ShareImage`, no
art, and not one of the twelve readings — so this is not a build that fell short of its
direction, it is the pre-direction app with the direction still in a file beside it.

| | Score | Evidence |
| --- | --- | --- |
| Idea | 1 | Nothing of "a tally-stick carver's bench" reaches the screen: `qa/01-counters.png` is three white rounded rows with a coloured capsule and a `+`, which is the generic counter app DESIGN.md §2 says it must not be. |
| Look | 1 | `tells.mjs` reports `kit-default-brand` and four `gray-canvas` FAILs — `CountersView.swift:47`, `:50`, `:144`, `CounterDetailView.swift:30` — and the app wears the kit's default orange; a grep of all 999 lines of `ios/App` for `AppBrand`, `brandBackground`, `brandDisplay` or `brandFont` returns nothing. |
| Signature interaction | 1 | `increment()` at `CounterDetailView.swift:171` is `Haptics.tap()` plus an inserted row; the only motion is `.contentTransition(.numericText())` at `:39`. No blade, no notch, no overshoot, no spring, no tone — `Motion.`, `pressable`, `popIn` and `Tones` appear nowhere in the app. |
| Reward | 1 | `tells.mjs` FAIL `no-reward`: there is no win in the app at all. Nothing happens at the fiftieth tap, or the hundredth; `confetti`, `CountUp` and `Haptics.celebrate` are absent from every file. |
| Voice | 1 | Labels only — "Nothing counted yet" (`CountersView.swift:20`), "Tallies Pro" / "Unlock everything in Tallies" (`qa/05-paywall.png`) — and the store pitch recited inside the product at `RootView.swift:84`, which is a hard FAIL. The carver does not speak once. |
| Craft | 2 | Tidy and well-commented, but large text breaks the hierarchy: in `qa/design/ax-01-counters.png` the hero total `98` renders *smaller* than the counter's name, because `CounterRow.total` is `lineLimit(1).minimumScaleFactor(0.5)` (`CountersView.swift:215–216`) while the name grows; in `ax-02-detail.png` the goal ring's own `6` stays tiny while its caption becomes huge. Dark mode is the system's inversion to pure black (`dark-01-counters.png`), not a designed appearance. |
| First minute | 1 | Onboarding is three SF Symbols — `plus.circle.fill`, `chart.bar.fill`, `lock.shield.fill` (`AppInfo.swift:17`, `:20`, `:23`) — ending on the kit's "Continue" (`Tallies.swift:38` passes no `nextTitle:`/`finishTitle:`), and page 1's subtitle explains the controls: "Tap to add, tap to take away." |
| Escalation | 1 | No `Ladder` exists. The only thing that differs between session 5 and session 500 is `chartDays` at `CounterDetailView.swift:17–19`, which takes exactly two values, 7 and 14, and switches on a *purchase*. The screen at 5 entries and at 500 is the same screen with taller bars. |
| Pull | 1 | Nothing waits. A session has no boundary in the code and ends on `summaryLine` — "48 in 7 days, 6.9 a day on average." (`CounterDetailView.swift:137`, visible in `qa/02-detail.png`) — a number under a bar chart. |

**Missing captures.** There are no `qa/design/moment-*.png` filmstrips and no `qa/design/ladder.png`;
`qa.json` has no `moments` block and `LaunchOptions.swift:10–22` has no `-demo` flag, so
DESIGN.md's `-demo cut` and `-demo score` cannot be filmed — the app has nothing to film. There
are also no `ax-03/04/05`. I scored Signature interaction, Reward, Escalation and Pull from the
code, which is unambiguous: the mechanisms are absent, not merely unphotographed.

## Slop tells present

- **Gray canvas with white cards.** `CountersView.swift:47`, `:50`, `:144`; `CounterDetailView.swift:30`. `qa/01-counters.png`, `qa/02-detail.png`.
- **One accent colour on gray.** The kit's system orange is the only voice on every screen; the six counter colours are `CounterPalette` defaults (`Model.swift:84–91`), not DESIGN.md's pigments.
- **An SF Symbol as the hero of onboarding.** `AppInfo.swift:17`, `:20`, `:23`.
- **A screen that is a `List` of `Label`s.** `HistoryView.swift:41–70`; `qa/03-history.png` is 40 identical rows of circle-plus-name-plus-time.
- **A result that is a number.** "48 in 7 days, 6.9 a day on average." — `CounterDetailView.swift:133–138`.
- **Copy that explains the business model in the product.** "Tallies has no ads and no account. Everything you count stays on this phone." — `RootView.swift:84`.
- **Copy that explains the controls.** "Tap to add, tap to take away." — `AppInfo.swift:18`.
- **The icon is a glyph on a gradient.** `ios/App/Assets.xcassets/AppIcon.appiconset/icon-1024.png` is three white bars on an orange gradient. The drawn icon DESIGN.md specifies exists and is good — `design/icon-1024.png`, a notched ash board with the fifth stroke struck through — and was never copied into the asset catalog.
- **The kit's own words on the first and last screens.** Onboarding "Continue" (`Tallies.swift:38`); the paywall passes no `cta:` (`RootView.swift:33–38`) and has no `hero:`.
- **Praise that never changes.** There is no praise pool because there is no praise.
- **Every unlock is a purchase.** `Model.swift:103`, consumed at `CountersView.swift:37`, `:90`, `HistoryView.swift:16`, `CounterDetailView.swift:18`.
- **Stats that accumulate where nothing consults them.** "Taps recorded 469" (`RootView.swift:71`) and History's week/month totals (`HistoryView.swift:80–92`) are computed, displayed, and read by no decision in the app.

## The second session

- **Where the curve stops.** It never starts: `Ladder` appears nowhere in `ios/App`. The single
  cross-session variable is `chartDays` — `CounterDetailView.swift:17–19` — with two values, 7
  and 14, and the dial is money, not days kept. Effective `flattensAt` is **1**.
- **What chooses the next unit.** Nothing chooses anything. `Model.swift:38–49`
  (`dailyTotals(days:)`) is a fixed trailing window, and there is no "next unit" in the app to
  choose — no reading, no rota, no `Mastery`. This is not `%` over an array; it is one screen
  redrawn with a larger number.
- **What is at risk.** Nothing, and there is no sitting: `increment()`
  (`CounterDetailView.swift:171`) and `decrement()` (`:177`) each insert one `Tap` and save. No
  `Run`, no chain, no clean, no session boundary anywhere in 999 lines. DESIGN.md's wax — the
  one idea that would make `−` mean something — is unbuilt; `−` silently subtracts.
- **What can be earned without paying.** Nothing. Every door in the app is `store.isProUnlocked`
  (`Model.swift:103`). The rack, the chalk, the gauge, the oil, the mark and the wall — all six
  of DESIGN.md's earned unlocks — do not exist.

**Why someone opens this on Thursday:** there is no answer in the app's own terms. It is a
number they typed, a bar chart of the number, and a list of the times they typed it.

## Keep

- **The data model.** `Tap(delta:at:counter:)` at `Model.swift:57–69` stores every tap with its
  timestamp, and the comment at `:52` gives the right reason. All twelve of DESIGN.md's readings
  and the hour-grain strip are computable from these rows with no schema change — the play can
  be built on top of what is already persisted.
- **The deterministic seed.** `Tallies.swift:66–95`, including the `window(for:today:)` reasoning
  at `:98`. Extend it to 61 days kept and 9 scored staves rather than replacing it.
- **Dynamic Type is honest.** Every size goes through `scaledFont(size:)` (`CountersView.swift:210`,
  `CounterDetailView.swift:38`); there is not one `.font(.system(size:))` in the app.
- **The accessibility-size row swap.** `CountersView.swift:132–146` and the comment at `:134`.
  The same instinct is needed on the stave.
- **The direction itself, and the mocks.** `design/mock-1-play.png`, `mock-2-win.png`,
  `mock-3-first.png` and `design/icon-1024.png` are the target and they are good. Nothing in
  DESIGN.md needs rethinking; it needs building.

## Fix, in this order

1. **Wear the brand.** Paste DESIGN.md §Tokens into `ios/App/AppBrand.swift`, apply
   `.brand(AppBrand.brand)` at the root in `Tallies.swift:35` and `.brandBackground()` on each
   screen, and delete all four `Color(.systemGroupedBackground)` / `secondarySystemGroupedBackground`
   at `CountersView.swift:47`, `:50`, `:144` and `CounterDetailView.swift:30`. Add the limewash
   `Canvas` (900 seeded strokes at `ink.opacity(0.028)`) and the bench-edge rule. Copy
   `design/icon-1024.png` over the asset catalog's icon and run `node tools/design/art.mjs` so
   `bench`, `stave`, `rack` and `gate` exist as `Image("…")`. Next capture: `01-counters.png` is
   limewash and ash at corner radius 5, `tells.mjs` loses `kit-default-brand` and all four
   `gray-canvas` FAILs, and the home screen icon is the notched board.
2. **Build the cut.** Replace `stepButton` (`CounterDetailView.swift:83`) and `plusButton`
   (`CountersView.swift:219`) with the stave and the chisel from DESIGN.md §The signature
   interaction: the V notch opening on `.spring(response: 0.16, dampingFraction: 0.74)` with its
   1 pt overshoot, `.buttonStyle(.pressable(scale: 0.98))`, `.confetti(trigger: cuts, count: 7, power: 0.22)`
   for the swarf, `Tones.shared.play(.step(run.chain % 5))`, `Haptics.rigid()` down and
   `Haptics.tap()` on the blade's lift, and the gate's diagonal every fifth cut on `Motion.gentle`.
   Add `-demo cut` to `LaunchOptions.swift` and a `moments` block to `qa.json`. Next capture:
   `moment-cut.png` shows five frames in which the notch grows and the blade walks.
3. **Build the score at fifty.** The reward from DESIGN.md, in place, not in a sheet: gates
   lighting 26 ms apart, the scoring stroke as `.trim(to:)` over 0.34 s, `CountUp(to:onTick:)`
   behind the stave at `brandDisplay(size: 132)`, the stave rising into the rack on one
   `matchedGeometryEffect`, `.confetti(power: 0.9, count: 64)`, `Haptics.celebrate()`,
   `Tones.shared.play(.fanfare)`, and the three tiers off `run.tier(score:beating:)` with their
   headlines. Next capture: `moment-score.png` ends on `FIFTY, AND NOT A WAXED ONE` and
   `tells.mjs` loses `no-reward`.
4. **Put the ladder and the readings in.** `Ladder([...])` exactly as DESIGN.md §The ladder
   writes it (`flattensAt` 217, `climbs(through: 150)` true), keyed on distinct days kept, and
   `ios/App/Readings.swift` implementing `Readings.next(...)` over a `Mastery<String>` of the
   twelve ids — precondition filter, `avoiding: recent`, then "moved most since last shown",
   with `mastery.record(id, correct: moved > 0.15)`. Render it on the face as the `READING`
   panel. Next capture: `ladder.png` shows day 5, day 50 and day 500 as three different screens
   — one reading and a fortnight of strip, five readings and a gauge, twelve readings and an
   hour-grain half-year.
5. **Make a sitting mean something.** A `Run` scoped to a sitting: `run.hit()` on every cut,
   `run.miss()` on the wax stick, which fills the last notch with a paler scar that stays on the
   stave. End a sitting on the sitting card in place of the reading, with DESIGN.md's exact
   shape — "Seven cut, none waxed. Forty-three notches into this stave. Nine in the rack — the
   gauge goes on the bench at eight." Delete `summaryLine` (`CounterDetailView.swift:133`). Next
   capture: `02-detail.png` ends on the carver's sentence, not "6.9 a day on average."
6. **Give the player a door that money cannot open.** `Earned` on staves scored, with the six
   rungs from DESIGN.md §Earned — `rack` at 1, `chalk` at 3, `gauge` at 8, `oil` at 20, `mark` at
   50, `wall` at 120 — and `earned.next(after:)` as the sitting card's tail. Next run:
   `tells.mjs` loses `paid-unlocks-only`, and `02-detail.png` shows the rack rail under the strip.
7. **Let the carver talk, and stop reciting the pitch.** Delete the store pitch at
   `RootView.swift:84`. Replace `AppInfo.onboarding` (`:16–25`) with DESIGN.md's three
   `OnboardingPage(title:subtitle:art:)` pages on `bench`, `gate` and `rack`, and pass
   `nextTitle: "Go on", finishTitle: "Take the blade"` at `Tallies.swift:38`. Pass the paywall
   its headline "The rack and the ledger", its three bullets, `cta: "Start the 3-day trial"` and
   `hero: { Image("Rack") }` at `RootView.swift:33`. Wire the praise, near-miss and goal pools.
   Add `SoundsToggle()` to `TalliesSettings` and a `ShareLink` over `ShareImage.render` to the
   face's toolbar. Next capture: `05-paywall.png` has the rack drawn on it, and the first and
   last screens are in the app's voice.

## Against the mocks

- **The face vs `mock-1-play.png`.** The mock is a 116 pt compressed-heavy `247` burned into the
  bench, an ash stave at 2.5° with its gates cut and the chisel resting at the next position, a
  brass-ruled strip of fourteen days as cut gates, a `READING` panel saying "Thursdays run a
  third above the rest.", `KEPT 61 DAYS · LONGEST RUN 19`, and nine dated staves standing in the
  rack. The build (`qa/02-detail.png`) is a white card with a blue `98` in SF Rounded, a system
  `accessoryCircularCapacity` gauge, two bordered circles, a second white card with a Swift
  Charts bar chart, and a third white card of two destructive `Label`s that the tab bar clips.
  Nine elements in the mock; three of them exist in any form.
- **The win vs `mock-2-win.png`.** The mock is `FIFTY, AND NOT A WAXED ONE` in keel red over a
  ghost `300`, the scored stave lifting with its dated end-grain, swarf in the air, and a sitting
  card reading "Twelve cut, none waxed. Fifty into this stave, and it is scored. Ten in the rack
  — the bench takes its colour at twenty." The build has no win state of any kind and no capture
  to compare against.
- **The bench vs `mock-3-first.png`.** The mock's empty state is the drawn bench — chisel, rack
  rail, a curl of shavings, cut ash — under **A bare bench** and "Lay a stave on the bench". The
  build's is `ContentUnavailableView` with `systemImage: "list.bullet"` and "Create the first
  one" (`CountersView.swift:19–26`). The populated bench in `qa/01-counters.png` is three white
  rows where the mock promised overlapping tilted staves with painted end-grain and live gates.
- **Dark.** The mock's dark is a blue-black wall with the wood still warm under a tungsten lamp.
  `dark-01-counters.png` is pure black with `secondarySystemGroupedBackground` rows — the
  system's inversion, which DESIGN.md explicitly rejected.
- **The ledger vs §Screens 3.** Promised: small staves with pigment bands and a 34 pt week
  figure, then each day a gate cut into a rule with its notches placed by the time they happened.
  Built: an inset-grouped `List` whose day sections are `+1` rows (`qa/03-history.png`) — the
  "row of identical tiles" shape §Slop we are avoiding named as the thing to beat.