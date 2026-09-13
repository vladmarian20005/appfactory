stage: polished
date: 2026-09-13
spec: SPEC.md · direction: DESIGN.md · qa: qa.json · privacy source: privacy.json

## Where it stands

The critic failed this app on 13 Sep with a one-line verdict: **none of DESIGN.md had been
built**. There was no `AppBrand`, no stave, no notch, no `Ladder`, no `Mastery`, no `Run`, no
`Earned`, no `Tones`, no `confetti`, no `ShareImage`, no art and not one of the twelve
readings — the pre-direction app with its direction sitting in a file beside it. This pass
built the direction. Every fix in `CRITIQUE.md` is addressed.

- **Builds against the iOS 26 SDK**, deployment target iOS 17, on the iPhone 17 Pro Max
  simulator at iOS 26.5. `xcodegen generate` runs before every build; no `.xcodeproj` is
  committed.
- **`verify-app.sh tallies` passes** — seven screens build, launch and render, and no crash
  report belongs to `com.starhiveconcept.tallies`.
- **`tells.mjs tallies` reports no FAIL and no smell.**
- **Every capture in this list was read back as a PNG** next to the mock it implements,
  before the commit that introduced it — light, dark, and at the largest accessibility text
  size, plus both moments as filmstrips and the ladder as a three-rung strip.

## What works

- **The bench** (tab 1). One stave per counter, laid across the screen at a tilt seeded from
  its own name so the pile never jitters, each with its painted pigment band, its name burned
  into the wood, its running total at 44 pt and its last two gates cut live along the
  shoulder. The chisel at the right end cuts without leaving the screen. Swipe to delete. The
  free tier's fourth position is an uncut blank, not a lock row. Below it the rack: every
  stave anybody has scored, in the pigment of the counter it was cut for.
- **The face** (counter detail). The running total at 116 pt in compressed heavy; the brass
  gauge with its chalk line when a goal is set; the stave at 2.5° with the chisel resting at
  the next notch; the wax stick; the strip; the reading; `KEPT n DAYS · LONGEST RUN m`; and
  the rack rail once a stave has been scored.
- **The cut.** The V opens on `.spring(response: 0.16, dampingFraction: 0.74)` and carries a
  point past its width before it settles; seven pale slivers of swarf fly from the edge;
  `Tones.step` climbs through the gate and resets on the fifth; `Haptics.rigid()` on the bite
  and `Haptics.tap()` 130 ms later on the lift; the blade walks 1/50th of the stave to the
  next position; and every fifth cut strikes the gate's diagonal closed over 0.18 s.
- **The score at fifty.** The ten gates light 26 ms apart, the scoring stroke is drawn corner
  to corner, the total counts up behind the stave as a ghost numeral at 132 pt with a haptic
  and a tone on every tick, the stave rises and turns with its end-grain dated, the chips fly,
  and one `matchedGeometryEffect` carries it into the rack while a bare stave slides onto the
  bench. Three tiers off `run.tier(score:beating:)`, each with its own headline and burst.
- **The ledger** (tab 2, Pro). The week and the month per stave as small staves with the week
  figure at 34 pt, then each day as a rule with that day's cuts notched into it where in the
  day they landed — so a day is legible as a shape. Tapping a day opens the times.
- **Laying a stave.** A bare board across the top of the sheet takes the name as it is typed
  and the pigment band as it is picked; the chosen pot is marked with a cut, not a checkmark.
- **Settings and the paywall** from FactoryKit in the carver's voice: "On this bench" with
  staves, notches cut and days kept, `SoundsToggle()`, and "Clear the bench" behind its
  confirmation. The paywall has the rack as its hero, its own headline, subhead, bullets and
  promise. `factoryReviewPrompt(afterSessions: 3)` is still wired.
- **The share card** renders through `ShareImage.render` — the limewash ground, the stave, the
  total, a fortnight of strip and the app's own mark — behind a `ShareLink` in the toolbar.

## The second session

- **The ladder** is `Bench.ladder`, keyed on distinct days kept: `readings` opens one of the
  twelve every twelve days, `span` grows the strip from a fortnight to half a year, and
  `grain` opens at day 64 and cuts a day down to the hour. `flattensAt` is **217** and
  `climbs(through: 150)` is true. `qa/design/ladder.png` shows day 5, day 50 and day 500 as
  three different screens.
- **What comes next is chosen.** `Readings.next` drops any reading the record cannot support
  yet, drops the last three shown, orders what is left by how much it has *moved* since it was
  last said, and hands that order to `Mastery<String>` — whose strength is read back, so a
  reading that keeps coming up unchanged falls out of the rota. No modulo over a list, no
  uniform random, and nothing shown before it is true.
- **Something is at risk.** A sitting runs from the first cut to two minutes after the last,
  replayed from the tap rows so a relaunch and a capture see the same one. Every cut is
  `run.hit()`; the wax stick is `run.miss()` and fills the last notch with a paler scar that
  stays on the stave. It costs this sitting's cleanliness and one visible mark, and nothing
  else — not a life, not a count, not a day, and nothing you can buy back.
- **Something is earned.** `Bench.earned` on staves scored: the rack at 1, the chalk at 3, the
  gauge at 8, the oil at 20, the mark at 50, the wall at 120. None of them is for sale, and
  `earned.next(after:)` is what a sitting card ends on.
- **The ending opens.** "Ten cut, none waxed. Fifty into this stave, and it is scored. Eleven
  in the rack — the bench takes its colour at twenty." The words "come back tomorrow" are
  nowhere in the app.

## What is stubbed or deliberately absent

- **No network, by design.** The only URLs are the support, privacy and terms links, which
  hand off to Safari.
- **No notifications and no permission prompts.** DESIGN.md says why: a notification that
  guilts someone about a counter is the thing the taste bar refuses.
- **`appStoreID` is nil**, so the kit hides the Share row in Settings until the App Store
  Connect record exists.

## What could not be checked without hardware

- **A real purchase.** No runner can complete one. The paywall was verified with
  `-fakeProducts`, which injects display-only offers; the StoreKit path itself is unexercised.
- **Haptics and tones.** Both are wired exactly as DESIGN.md's beat tables say —
  `Haptics.rigid()` on the bite, `Haptics.tap()` on the lift, `.soft()` on a gate,
  `.celebrate()` on a scored stave, and `Tones.step(run.chain % 5)` climbing through the gate
  — but a simulator neither buzzes nor plays, so that it *feels* and *sounds* right is the
  owner's TestFlight pass to confirm.
- **The share sheet**, which needs a device.
- **Touch routing.** The stave's cut, its navigation link and the chisel are siblings rather
  than nested, so a tap cannot be ambiguous, but there is no tap driver here: the `-demo cut`
  and `-demo score` flags drive the interaction from inside the app instead.

## Dark mode and large text

- **Dark is designed, not inverted.** The wall goes blue-black and cold and the wood stays
  warm, because the lamp is tungsten and it is the only light in the room. One real bug came
  out of the dark captures: mixing a colour toward `ink` *lightens* it after dark — `ink` by
  night is the lamplight — so every cut on the night bench was paler than the wood it was cut
  into and the strip came out salmon. There is a `cutShadow` now, dark in both appearances.
- **Large text holds.** At `accessibility-extra-extra-extra-large` the hero total is still
  unmistakably the most important thing on the face — the critic's Craft finding was that it
  rendered *smaller* than the counter's name. The face stacks the total over the gauge rather
  than shrinking either, the stave gets more air above it so the chisel clears the caps, and
  a bench stave swaps to the stacked layout. Every size in the app goes through
  `scaledFont(size:)` or `brandDisplay(size:)`; there is not one `.font(.system(size:))`.

## One change in FactoryKit

`SettingsView` left its rows the system's white on whatever canvas an app had spent its
direction on — TASTE.md's first slop tell, shipped by the kit itself. Its sections now take
`brand.palette.surface`. An app that has not set a brand is unchanged, because
`factoryDefault`'s surface *is* that system colour.

## Not done yet

The next critic scores what this pass built. After that, `/ship tallies`: the screenshots
recompose from the seven new raw captures and `store/screenshots.json`, which is rewritten and
ordered with the scored stave first.
