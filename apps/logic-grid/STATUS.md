stage: built
date: 2026-09-15
next: app-verify

Crosshatch is built: seven screens in the brand, `verify-app.sh` green, `tells.mjs` reporting
no hard tell and no smell, the listing written and inside every en-US limit.

## What works

**The engine.** `Solver` closes a plate by pure deduction — clue propagators for all seven
kinds, row and column uniqueness, and transitivity through a third category. `Generator` seeds
an answer, emits candidate clues, adds until the plate proves out, then prunes while the answer
stays the only one it can be, dropping direct clues and the kinds the player is already good at
first. Among the minimal sets it keeps the one that leans hardest on what `Mastery` asked for,
with its measured depth as close under the rung's target as it can get. A plate it cannot prove
is discarded; the fallback serves the whole truth rather than an unproved plate. The spec's
"generate at build time into a bundled pack" escape hatch was not needed: a 5×6 plate rules in
well under a second on the simulator.

**The bed.** The staircase matrix drawn on copper in `Canvas`, with a real `Button` per cell
over it — a press state, a VoiceOver label and a hint on every one. Cast marks cut into the
heads instead of rotated eight-point text, registration bands in each category's ink on the
paper outside the bevel, the legend above, the clue list below with spent clues struck through
and sealed ones crosshatched over, and the margin with its plate caps, point count, stamped
figures, scars, loupe and burnisher.

**The cut, judged.** A mark is forced or it is not, and the solver decides at the moment it is
made. Forced: it takes, the line grows, the tone climbs. True but not yet proved: the burin
skids and leaves a hairline that prints. Contradicting the clues: it does not take at all.
Judgement waits 260 ms so the two strokes on the way to a point are not called a guess. The
assist is only what DESIGN.md says — a fixed pairing ruling out its row and its column.

**The pull.** Stills, inks, wipes, the paper comes down, the press turns, the print peels off
with the answer engraved in its solved rows, filings fall, and the margin card names what is
waiting. Four tiers, a twelve-line praise pool, `CountUp` behind the plate, `Earned`, and a
share card that spoils nothing.

**The play.** `Ladder` with five dials, `flattensAt` 270 and `climbs(through: 150)` true.
`Mastery<String>` over the seven clue-kind ids, written on every cut, every slip and every
loupe, and read to build the next plate; a second `Mastery` over the thirty-two subjects.
`Run` for what is at risk on one plate and nothing beyond it. Six `Earned` milestones on plates
pulled, the first at one and the last at a hundred and fifty. Today's plate is seeded from the
date alone — subject, clue kinds and all — so it is the same plate for everybody.

**The rest.** The line with the day-book page and the drying line, the run with the plate shelf
and what playing has opened, the kit's settings with the bench's rows, onboarding and the
paywall in the engraver's voice with the lozenge for a bullet.

## What is stubbed or unproved

- **A real purchase.** No runner can complete one. The paywall is exercised with
  `-fakeProducts`; `store.isPro` drives the run past the fortieth plate and the two toggles.
- **Haptics and sound.** Wired exactly as DESIGN.md sets out — `Haptics.rigid` on the bite,
  `thud` on a point, `impact(0.18)` through the cascade, `celebrate` on the pull; `Tones` on
  `.step(chain % 5)`, `.pop`, `.miss`, `.success`, `.fanfare`. Neither can be felt or heard on a
  simulator. The owner's TestFlight pass on a phone is where they are judged.
- **The share sheet.** `ShareLink` over `ShareImage.render` is wired on the win and on the line;
  the sheet itself needs hardware.
- **Persistence is `UserDefaults` JSON, not SwiftData.** The spec named SwiftData for solved
  results. One `Record` — the run, the prints, both masteries, the plate on the bed and the
  settings — encodes to JSON and is written after every mark, which is what the spec actually
  asks for ("state saved on every mark, so a crash never costs a puzzle") with one file and one
  failure mode instead of a schema and a container.
- **Nine localizations.** Only `en-US` is written, as the build stage's step 10 asks; `app-aso`
  writes the other nine that `listing-check.sh` wants.
- **Screenshots.** `store/screenshots.json` is written and the raw captures are in `qa/`;
  composing them is `app-shots`.

## Two changes in FactoryKit

Both are the "capability goes into the kit" pattern rather than app-local hacks, both are
additive, and every app that does not ask for them is unchanged.

- `PaywallView` put a `checkmark.circle.fill` back on the selected offer row. Where an app has
  set its bullets with `.ruled(mark:)` — a printed mark, because it has banished the tick on
  purpose — the offer row now uses that mark.
- `OnboardingView(indexMark:)` draws the page indicator with the app's own mark: the current
  page as that character, every other page as an empty ruled cell. Without it the indicator is
  the system's dots, as before.

## Checked on the simulator

`verify-app.sh logic-grid` builds, launches and renders all seven screens with no crash report.
Every screen was read next to its mock and fixed against it — the plate's margin, the win's
composition, the print on the line, the run's shelf. `node tools/design/tells.mjs logic-grid`
reports 0 hard tells and 0 smells.
