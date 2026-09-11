# Tidepour · critique

**Verdict: pass.** This is a tide pool at dusk that happens to contain a sorting puzzle: ink-blue
water in both appearances, light standing inside hand-blown glass, kelp fronds growing under a
vial that came good, and a win that is a sun coming up over a lit rack with the number of pours
set 96 points high in New York. The one thing that decides it is `qa/01-win.png` — the app the
last critique reviewed ended in a half-height sheet with `checkmark.seal.fill` on it, and this one
ends in a picture someone would actually send to a friend.

| | Score | Evidence |
| --- | --- | --- |
| Idea | 5 | Every screen is the world, not the category: `qa/02-play.png` is glass on deep water with a lantern tick at par, `qa/03-chart.png` counts "9 EVENINGS IN A ROW", `qa/04-shore.png` heads "THE SHELF · 27 LIT", and the tabs read Pour / Chart / Shore — there is no "Play / Progress / Packs" left anywhere. |
| Look | 4 | Eight liquids as top-lit gradients with a specular stripe and a meniscus, on a drifting nine-point mesh (`AppBrand.swift:36`), with the vial silhouette repeating from the board to the shelf chips (`PacksView.swift:144`) to the share card; dark is designed, not inverted — the canvas measures `#14394A` light against `#0A2732` dark and the accent lifts `#35CEBC` → `#5EEBDA`. Held off 5 by three screens where the canvas does all the work: the paywall's ticked bullet card (`qa/06-paywall.png`), the Shore's undifferentiated 5-wide grid, and the Chart's dot calendar. |
| Signature interaction | 4 | `moment-pour.png` has ten frames and no two alike: the vial leaves the rack, tips 42° toward its target, the receiving level rises, and a completed vial throws particles and grows a frond (frames 6–7). The arc itself — glow at 14 pt under a 6 pt core, plus a splash bloom (`BoardView.swift:219–237`) — is real in code and visible in `moment-win.png` frame 2, but appears in *none* of the ten pour frames, which is the one thing that would make it a 5. |
| Reward | 5 | Full screen on the canvas (`PlayView.swift:58`, a `fullScreenCover`, no seal anywhere): sun over a horizon, `CountUp(to:duration: 0.7)` at `brandDisplay(size: 96)` inside a lantern ring ticking `Haptics.impact(0.3)` and a climbing `.step(n)`, a pooled praise line, the start-to-the-line rail, the rack rising one vial at a time on `.popIn(delay: 0.4 + i*0.06)`, and three tiers that actually differ — 1.4 / 1.0 / no confetti at all but a breathing lantern swell (`WinView.swift:34–43`, `Voice.swift:94`). It shares as a rendered `RackCard`, not a line of text. |
| Voice | 4 | Four pools of six (`Voice.swift`) with a no-repeat guard, and the keeper is consistent: "Clean as the flat at low tide.", "The tide goes further out", "See what opens", "Back to the shore", "Low tide. The glass is waiting." Docked a point because the two screens that ask for something say nothing in that voice: `qa/06-paywall.png` and `qa/07-first.png` both end in **Continue**, which DESIGN.md line 157 forbids by name. |
| Craft | 4 | One unmistakable hero per screen (110 pt streak, 96 pt pours, 64 pt counter), a single 18 pt radius, rhythm that holds, and the accessibility work survived the rebuild — at AX5 `ax-02-play.png` drops the controls to symbols, keeps the board and reads a vial bottom-up. Two flaws: on `ax-01-win.png` the "POURS" mark overflows the fixed 210 pt ring and sits across its stroke (`WinView.swift:105–115`), and the rack and all three buttons fall below the fold, so the first thing a win looks like at that size is a screen with no action on it. |
| First minute | 4 | `qa/07-first.png` is a drawn rack decanting at the shoreline under "Every light wants its own glass." in the display serif, on the brand canvas — two pages, no third page of pricing, no symbols. The board then teaches without a sentence: the vial the verified solution wants first breathes and stops for good after the first pour (`TubeView.swift:183`, `GameModel.swift:70`). The shipped icon is the drawn one. |

An App Store editor's answers: the screenshot I would lead with is `qa/01-win.png`, and yes, I would
put it in a puzzle story — a lit rack under a rising sun with a serif "12" is not a thing any of the
49 competitors has. The weakest screen is `qa/04-shore.png`: a screen named Shore with no shore in
it, forty-odd vials five across and nothing else above the fold. A stranger shown a crop would say:
"a water-sort game that someone actually designed."

## Captures missing

- **No Settings capture.** `qa.json` has no settings screen, and DESIGN.md lists it as one of the
  four. `SoundsToggle()`, the erase and the restore are unjudged.
- **AX only covers the win and the board** (`ax-01-win`, `ax-02-play`). The calendar grid, the
  shelf and the paywall bullets at AX5 are unverified.
- **No dark AX captures**, and **no capture of the rendered share card** — `RackCard`
  (`WinView.swift:221`) is confirmed in code only, never as an image.
- **No calm-mode capture**, so the muted palette and the 0.45 s pour are unseen.

## Slop tells present

None. `node tools/design/tells.mjs color-sort --strict` reports 0 hard tells and 0 smells, and none
of TASTE.md's screenshot tells survive: no gray canvas or white cards, no accent-on-gray, no symbol
as a hero, no `.medium` sheet, no stat tiles (`StreakView.swift:46` is one hero and two lines of
prose), no fixed praise, no icon-on-a-gradient, and nothing in the product states the deal outside
the paywall.

One thing sits just inside the line and should be watched: `StreakView.swift:87`, "The same rack
fills for everyone who walks down today — seeded from the date, walked before it is served," is the
store's first screenshot caption in the keeper's accent. It is flavour, not a footer, so it passes —
but it is the product explaining its wedge to someone already inside it.

## Keep

- **The win, whole.** The tier logic, the no-confetti-over-par rule, the count-up ticks, the rack
  lighting one at a time, the `ShareImage` card. Nothing here gets touched.
- **The glass.** The top-lit gradient, specular stripe and meniscus, the ring on the flat and the
  kelp frond under a completed vial. It is what makes the crop recognisable.
- **The accessibility work, again.** `ViewThatFits` header, symbol-only controls past AX1, the
  240 pt board floor, the Okabe–Ito palette with a shape stamped on every unit
  (`qa/05-accessible.png`), and the VoiceOver labels on everything drawn.
- **The voice pools and the no-repeat guard** (`Voice.swift:61`).
- **The teaching breath.** A vial that pulses and then stops forever, instead of a sentence.

## Fix, in this order

1. **Make the arc visible — it is the pour, and the film does not have it.** Ten frames at 0.1 s
   in `qa/design/moment-pour.png` and not one shows a stream between two mouths; the tipped vial
   hovers in the gap between rows with nothing leaving it. `lift(for:)` (`BoardView.swift:193`)
   carries the source only 34 % of the way and up `unit * 0.62`, so the mouth never arrives over
   the receiving rim and the whole span has to be crossed in `pourDuration` = 0.24 s
   (`Palette.swift:124`). Take the travel to 0.62, the rise to `unit * 1.1`, and the arc to 0.34 s
   (0.5 s in calm mode). *Next capture:* at least three of the ten `moment-pour` frames carry the
   quadratic with its glow, and the tipped mouth is above the destination, not between the rows.

2. **Give the paywall and onboarding the keeper's mouth — the strings are the kit's, so fix them
   in the kit.** `FactoryKit/Sources/FactoryKit/PaywallView.swift:61` hardcodes "Unlock everything
   in \(config.name)." and `:161` returns "Continue"; `OnboardingView.swift:61` is "Continue" /
   "Get started". Add `subhead: String? = nil` and `cta: String? = nil` to both `PaywallView`
   inits and `nextTitle:` / `finishTitle:` to `OnboardingView`, defaulting to today's strings so
   Quizday is untouched, then pass Tidepour's: subhead "The shelf runs further out than you can
   see.", CTA **Open the shore**, onboarding **Keep going** / **Walk down**. *Next capture:* the
   word "Continue" appears in neither `06-paywall.png` nor `07-first.png`.

3. **Put a shore on the Shore.** `qa/04-shore.png` is forty vials five across under one chart mark,
   with the unlock card and the three gated toggles far below the fold (`PacksView.swift:29–42`);
   it reads as a swatch wall, and it is the one screen with no hierarchy in it. Head it with
   `Image("OpenWater")` on a waterline, then band the shelf in tens with a chart mark per band —
   `RACKS 1–10 · ALL LIT`, `RACKS 11–20 · 7 LIT` — so the eye reads progress the way the fronds
   read it on the board. *Next capture:* `04-shore.png` has a horizon and at least two band marks
   above the fold, and no run of more than ten vials unbroken.

4. **Fix the win at accessibility sizes.** On `ax-01-win.png` "POURS" sits across the ring's stroke
   because the `VStack` of mark plus 96 pt number outgrows the fixed `frame(height: 210)`
   (`WinView.swift:105–115`), and the rack and all three buttons are below the fold. Let the ring
   size from the content (`overlay` a `Circle().strokeBorder` on the `VStack` with padding instead
   of a fixed frame), and past AX2 drop the ring and the rail entirely so the praise line, the rack
   and **Take the next one** are on screen. *Next capture:* a new `ax-01-win.png` where no type
   touches the ring and the primary button is visible without scrolling.

5. **Answer the finger, not just the tap.** Vials are tapped through `.onTapGesture`
   (`BoardView.swift:160`), so there is no press state under the thumb — DESIGN.md line 114 asks
   for `.buttonStyle(.pressable)` and `Haptics.soft()` on finger-down, and the shelf chips already
   have it (`PacksView.swift:85`). Wrap the vial in a `Button` with `.buttonStyle(.pressable)`.
   *Next capture:* not visible in a still — verify on the simulator that a held vial dips and
   answers before it is selected.

6. **Retire the seal glyph.** `checkmark.seal.fill` is still the "Charted" badge
   (`PlayView.swift:129`) and still marks the day's result (`StreakView.swift:93`). It is a system
   verification mark in a world of glass and water, and it is the last thing on screen that could
   belong to any app. Draw the mark instead: a small charted-line glyph — the hairline arc from
   `design/art/charted-line.svg` at 14 pt — in mint. *Next capture:* no `seal` symbol in
   `02-play.png` or `03-chart.png`.

7. **Let light mode be lighter.** Measured across all seven screens the two appearances differ by
   about one step of depth (`#14394A` against `#0A2732`), so the app effectively has one look and
   a user who chose Light gets a slightly shallower dark. DESIGN.md promised "two different
   underwater blues"; deliver that by taking the light canvas up toward dusk-in-the-shallows
   (`#1B4A5C` → `#22596B` at the top of the mesh) and warming the light lantern, keeping dark
   exactly as it is. *Next capture:* `01-win.png` and `dark-01-win.png` are two visibly different
   times of day rather than two exposures of one.

## Against the mocks

- **`design/mock-1-play.png` → `qa/02-play.png`.** Close. The canvas, the glass, the serif count,
  the `POURED / THE LINE · 12` rail with a lantern tick, the ring on the flat, the fronds and the
  Back / Show me / Refill buttons all arrived. Two things did not: the mock's hand-lettered
  "the charted line" arcs *over the board* from the source vial to the destination, where the build
  demotes it to a small italic label under the left end of the rail — the hint's actual arrows are
  good, but the drawn line is the more charming of the two; and the mock's vial in flight is
  tipped over the receiving mouth with a visible stream, which is fix 1.
- **`design/mock-2-win.png` → `qa/01-win.png`.** The build is at least as good as the mock. The sun,
  the ring, the 96 pt serif, the praise, the START / THE LINE rail, the lit rack with fronds and
  the three buttons are all there, and the build adds tiered confetti the mock did not draw. The
  only loss is the mock's water line across the screen separating the score from the rack — the
  build has no horizon between them, so the rack floats a little.
- **`design/mock-3-first.png` → `qa/07-first.png`.** The art, the serif headline and the subtitle
  landed, and the build is better for dropping the mock's warm sand wash in favour of the pool. The
  gap is the button: the mock's "Continue" was copied straight through when it should have been the
  first thing rewritten (fix 2).
- **`design/icon.svg` → the shipped icon.** Shipped, and it is the drawing: a lit vial standing in
  a ringed pool. One note for the next pass — the incoming pour is a detached orange ribbon in the
  top corner that never reaches the glass, so at 60 pt it reads as a swoosh rather than as
  something being poured. Extend the stream to the rim.
