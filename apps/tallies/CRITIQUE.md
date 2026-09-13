# Tallies · critique

**Verdict: pass.** It is a tally-stick carver's bench — limewashed wall, ash boards at radius 5,
a V cut under your thumb, five to a gate, fifty to a stave, and the finished ones standing dated
in a rack — and it is unmistakable from one crop in a way no counter app on the store is. What
decides it is that the depth is real and not decoration: the ladder is keyed on days kept and
`flattensAt` 217, the sentence under the stave is chosen by a rule that reads what it already
said, three doors open by counting rather than paying, and `ladder.png`'s three panels are three
different screens.

| | Score | Evidence |
| --- | --- | --- | 
| Idea | 5 | `qa/01-face.png` — notches, a closed gate, wax, a chisel resting at the next position, a rack of dated end-grain. Nobody would mistake it for a counter app, or for any other app in this repo. |
| Look | 4 | Limewash canvas with 900 drawn strokes (`Bench.swift:9`), corner-5 ash with a lit top edge and a dark bottom, 116 pt compressed heavy, keel red as a real second voice, and a dark bench that is warm wood on blue-black rather than an inversion (`dark-01-face.png`). Held back by ~40 % dead canvas on `03-bench.png` and `07-lay.png`, and by the chisel glyph. |
| Signature interaction | 4 | `moment-cut.png` frames 1–3: the notch opens, swarf flies, the blade walks to the next position, the gate's diagonal lands, the total ticks 534 → 537 → 538. The two springs, `Haptics.rigid` then `tap` 130 ms later, and `.step(chain % 5)` are all in `CounterFaceView.swift:469–515`. The swarf is seven tiny squares where mock 1 has shavings, and frames 4–10 are identical. |
| Reward | 4 | `02-win.png` is not a sheet: the tier headline in keel red, a 132 pt ghost numeral counting up behind, the scoring stroke drawn corner to corner, the dated end-grain, swarf, and a sitting card that names what is waiting. Three tiers with different burst counts and a second `Haptics.celebrate` on a best (`CounterFaceView.swift:532–599`). Costs a point: the rack the stave flies into is behind the tab bar, and the praise line renders as a caption on the wax stick. |
| Voice | 4 | The carver is consistent and specific — "Stood up in the rack. It will be there in a year." (`02-win.png`), ten praise lines, eight near-miss, five goal (`AppInfo.swift:60–91`), buttons that say "Lay it on the bench" / "Plane today off" / "Take the blade". Two places he says something untrue: the `.best` headline (see Fix 3) and "the chalk comes out at three" for a chalk that does not exist (Fix 4). |
| Craft | 3 | Hierarchy on the face is exact and dark mode is designed, not inverted. Against it: three system disclosure chevrons on a screen whose whole claim is "not a list of cards" (`03-bench.png`), the dead half of the bench and the lay sheet, the rack under the tab bar on the win, and the date stamp covering the stave at the largest text size (`ax-02-win.png`). |
| First minute | 3 | **No capture of onboarding or the empty bench exists** — scored from the code, the art and mock 3. Three pages with drawn art ending in "Take the blade" (`AppInfo.swift:20–39`), a bare bench with `bench.svg` and "Lay a stave on the bench" (`BenchView.swift:50`), and the first cut taught with no text at all — a breathing blade and a pulsing ghost notch that stop for good at the first cut (`CounterFaceView.swift:318–338`). But the second screen a new person meets is the lay sheet, and it is half empty. |
| Escalation | 4 | `ladder.png`'s panels are not interchangeable: 14 → 49 → 182 days of strip, an hour band that only exists at 500, one stave in the rack → eight → a full rail, the bench oiled dark, and a different reading under each. `Ladder.flattensAt` is 217 and `climbs(through: 150)` is true (`Record.swift:319–323`). Two deductions in "The second session". |
| Pull | 4 | The reason to open it on Thursday is in the app's own terms and is not a streak: a sentence about your own record you have not heard yet, chosen by `Readings.next` (`Readings.swift:184–218`), a stave 43 into 50, and a rack one short of the gauge. |

## Slop tells present

None.

Two near-misses worth naming so the polish does not drift into them:

- `04-ledger.png` is eight ash cards of the same frame, radius and trailing number in a scroll.
  It stays the right side of "a `ScrollView` of identical cards" only because each day's notch
  run is a different shape, which is the screen's actual idea. Do not let the shapes get quieter.
- `04-ledger.png`'s header row — `PULL-UPS / 10 120` — is one step from stat tiles. It is
  rescued by the pigment band and the stave shape, but the two numbers carry no label at all and
  a stranger cannot tell which is the week.

## The second session

- **Where the curve stops.** `Record.swift:319–323`. Three dials — `readings` (last change rung
  133), `grain` (opens at 64, last change 178), `span` (last change 217). `flattensAt` is **217
  days kept**, which is at least seven months of counting, not 217 sessions. Past it the
  instrument is finished and the record is the thing that keeps changing. It does not flatten
  inside the first week and it does not lie about being infinite. One honest weakness: from rung
  133 to 217 the only thing that moves is seven more days of strip every nine days.
- **What chooses the next unit.** `Readings.swift:184–218`. Readings the ladder has not opened
  are dropped, then any whose precondition the record cannot meet, then the last three shown,
  then what is left is ordered by how far its number has moved since it was last said
  (`movement`, :192) and handed to `Mastery`. `next.mastery.record(chosen, correct: movement >
  0.15)` at :214 means a reading that keeps coming up unchanged loses strength and falls out of
  the rota — the strength is read to decide, not written and displayed. No `%`, no uniform
  random, no field that nothing consults.
- **What is at risk, and what it costs.** `Record.swift:265–277` replays the open sitting as a
  `Run`; every cut is `hit()`, every press of the wax stick is `miss()`
  (`CounterFaceView.swift:477, 521`). A wax breaks the chain, spoils `isClean`, and leaves a
  paler fill on the stave for good (`Bench.swift:137–140`) — which is the honest thing a real
  tally stick does. It costs this sitting's cleanliness and one visible mark. It does not cost a
  count, a day, a stave already scored, or money.
- **What is earned without paying.** `Record.swift:326–339` — six milestones on staves scored.
  Three are built and visible: the rack at 1 (`CounterFaceView.swift:62`), the brass gauge at 8
  (:63), the bench oiling at 20 (:64, `BenchView.swift:123`). **Three are not**: `chalk` (3),
  `mark` (50) and `wall` (120) appear in no `isUnlocked` call anywhere in the app, and the
  sitting card promises all three by name (`Record.swift:349–357`).

Why someone opens this on Thursday: because the bench is as they left it — forty-three into a
stave, a rack one short of the gauge — and because the carver has a sentence about their own
Tuesdays that they have not heard yet and that could not have been said in week one.

## Keep

- The idea and its whole vocabulary — stave, gate, notch, wax, plane, rack, sitting, reading.
  Every word in the app is in it and none of it is theme paint.
- The win's second and a half: the gates lighting left to right, the scoring stroke trimmed over
  0.34 s, the ghost `CountUp` with a haptic and a tone per tick, the stave carried into the rack
  on one `matchedGeometryEffect`, the three tiers. `CounterFaceView.swift:532–599`.
- The carver. The pools, the spelled numbers ("Forty-three into this stave"), the spoken dates,
  the sitting card, and the fact that "come back tomorrow" is nowhere in the app.
- The readings rota and the twelve preconditions. A reading that would have to invent something
  is never shown, and that is the app being honest rather than being clever.
- The ladder as stated: bounded at 217, keyed on days kept, said out loud in DESIGN.md.
- The dark bench — the wall goes cold and the wood stays warm because the lamp is tungsten.
- `KEPT 59 DAYS · LONGEST RUN 44` instead of a streak. It never resets and it never accuses.
- The icon, the rack of dated staves, the share card, and `Run`'s wax as the model for undo.

## Fix, in this order

1. **The win arrives somewhere you cannot see, and its best line is a caption on the undo
   button.** `02-win.png` and `dark-02-win.png`: the rack rail — the destination of the whole
   1.5 s — is cut in half by the tab bar, and in `moment-score.png` frames 3–8 the praise line
   "Done and dated. Nothing on it to explain." renders to the right of the wax stick and the word
   `WAX`, because `note` sits inside that `HStack` (`CounterFaceView.swift:198–227`). Lift `note`
   out into its own row directly under the stave, at `.callout` in `brandInk`, full width; and
   give the face `.padding(.bottom, 96)` under the rack (`CounterFaceView.swift:90`) so the rail
   clears the tab bar. The next `02-win.png` shows the praise on its own line and every stave in
   the rack, including the one that just landed.

2. **The chisel is the app's tool and it reads as a lipstick.** `Bench.swift:349–384` builds it
   from three rounded rectangles; at 46 pt it appears four times on `03-bench.png` and once on
   every face. Mock 1 has a tapered ash handle, a brass ferrule with two highlights, and a steel
   blade with a visible bevel and a lit cutting edge. Draw it: `design/art/chisel.svg` through
   `node tools/design/art.mjs`, used as `Image("Chisel")` at the stave's end and in the blade
   overlay. The next `03-bench.png` has a recognisable chisel on each board.

3. **"NOT ONE WAX, AND YOUR BEST" can print over a stave with wax in it.**
   `CounterFaceView.swift:534` calls `run.tier(score: run.longestChain, beating: bestCleanRun)`,
   and `Run.tier` returns `.best` on score alone (`Run.swift:55–60`) — so a sitting that waxed
   once and then beat the longest clean run gets the clean headline while the paler fill is on
   screen. Gate it: `let tier = run.isClean ? run.tier(score:beating:) : .good`, so a waxed
   sitting falls to "SCORED. THE WAX SHOWS, AND THAT IS FINE". While there, `bestCleanRun`
   (:601) is one `@AppStorage` key shared by every counter, so a new stave inherits another
   stave's record — key it on the counter. Capture a `-demo score-waxed` moment to show it.

4. **The carver promises three things the app does not have.** `Record.swift:326–339` declares
   `chalk` at 3 staves, `mark` at 50 and `wall` at 120; `grep isUnlocked` finds only `rack`,
   `gauge` and `oil`. At three staves the sitting card says "There is chalk on the bench if you
   want to name them" and there is no chalk. Build `chalk` — it is the nearest rung and the
   cheapest: a stave in the rack can be tapped and given a name, written on its end-grain in the
   stencil caps, so the rack becomes readable. Then either build `mark` and `wall` or delete them
   from `Bench.earned`, because a horizon that never arrives is worse than a shorter one.

5. **The bench is 40 % empty and wears three list chevrons.** `03-bench.png`: three staves and a
   dashed blank, then nothing at all until the rack rail at the foot, because `BenchView.swift:79–104`
   pins the rack under a `List` in a `VStack`. And `NavigationLink(value: counter)` inside that
   `List` (:252) draws a system disclosure chevron on every board — the one thing on the screen
   that says "row". Put the rack inside the scroll under the last stave, and replace the
   `NavigationLink` with a `Button` that appends to `path` so the chevron goes. The next
   `03-bench.png` has no chevrons and no gap between the staves and the rack.

6. **The strip lost the mock's brass rule and came back a bar chart.** `01-face.png` against
   `design/mock-1-play.png`: the mock cuts tapered notches down from a brass scale, two facets,
   the near one in shadow — the same shape as the stave's cuts at a different size. The build
   draws plain rectangles. Reuse `NotchShape(near:)` for each day's mark in `StripView` at the
   strip's pitch, keep the brass ticks `ruled:` already draws, and keep today in chalk blue. The
   test: crop the strip alone out of the next `01-face.png` and it is still obviously this app.

7. **The largest text size breaks the win, and the ledger's two numbers carry no label.**
   `ax-02-win.png`: the end-grain stamp grows past the stave and covers `PULL-UPS` and half the
   notches, because it is a fixed `.offset(x: 10)` overlay on a fixed-height board
   (`CounterFaceView.swift:352–366`). At `typeSize.isAccessibilitySize` put the stamp under the
   stave rather than over its end — `hero` (:127–142) already does exactly this swap. And on
   `04-ledger.png`, `PULL-UPS / 10 120` needs `WEEK` and `MONTH` in the stencil caps under the
   two figures, or the header row is a pair of orphan numbers.

## Against the mocks

- **The face (mock 1 → `01-face.png`).** The composition survives: hero, gauge, stave, strip,
  reading, kept-days, rack. What thinned out is the material. The mock's board has real grain,
  thickness and a cast shadow on the bench; the build's is a pale rounded rectangle with seven
  hairlines, and its lower two-thirds is blank ash with the name floating in it. The mock's
  notches are deep brown wedges you could put a thumb in; the build's are thin grey ticks
  crowded into the top 15 pt. The mock's strip is the best drawn thing in the direction and the
  build's is a bar chart (Fix 6). The wax stick, which the mock does not show, arrived as a small
  grey lozenge with the word `WAX` beside it — a text label doing an affordance's job.
- **The win (mock 2 → `02-win.png`).** Closest of the three. Everything the mock promises is
  present — headline, ghost numeral, scoring stroke, dated end-grain, swarf, sitting card — and
  the light version reads well. Two losses: the mock throws about eighteen shavings of varied
  size and rotation across the whole frame, the build throws a dozen small squares; and the
  mock's rack rail sits clear below the card with the newest stave glowing, where the build's is
  under the tab bar (Fix 1). The mock also tints "none waxed" verdigris inside the sitting card,
  which is a free piece of hierarchy the build did not take.
- **The bare bench (mock 3).** Cannot be compared — there is no capture of the empty bench or of
  onboarding in this run. From the code the art, the headline and the button are all as drawn.
  The next run should capture the first launch: it is the screen the store's third screenshot
  will come from, and it is the only part of "First minute" nobody has looked at.
