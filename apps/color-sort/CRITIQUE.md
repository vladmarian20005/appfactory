# Tidepour · critique

**Verdict: pass.** A tide pool at dusk that happens to contain a sorting puzzle: light standing
inside hand-blown glass on deep water, a kelp frond growing under every vial that came good, and
a win that is a sun coming up over a lit rack with the count of pours set 96 points high in New
York. What decides it this round is not the look, which was already there — it is
`qa/design/ladder.png`: four racks from 3 to 210, and no two of them are the same game, which is
the first time anything in this factory has been able to prove that about itself.

| | Score | Evidence |
| --- | --- | --- |
| Idea | 5 | Every screen is the world rather than the category: `qa/02-play.png` is glass on deep water with a lantern tick at par, `qa/03-chart.png` counts "9 EVENINGS IN A ROW" over pools of light, `qa/04-shore.png` heads "THE SHELF · 27 LIT", and the tabs read Pour / Chart / Shore. Nothing anywhere says level, progress or pack. |
| Look | 4 | Eight liquids drawn as top-lit gradients with a specular stripe and a meniscus (`TubeView.swift:139`), on a nine-point drifting mesh (`AppBrand.swift:37`), with the vial silhouette repeating from the board to the shelf chips (`PacksView.swift:144`) to the share card; dark is designed, not inverted (`dark-02-play.png` is colder and deeper, not the same blue flipped). Held off 5 by the three screens the canvas carries alone: the Shore's forty identical chips five across, the paywall's ticked-bullet card (`qa/06-paywall.png`), and the Chart's dot calendar. |
| Signature interaction | 4 | `moment-pour.png` has ten frames and no two alike — the vial leaves the rack, tips 42° toward its target, the receiving level rises, a finished vial throws particles and grows a frond (frames 6–8) — and the code has a haptic and a climbing `Tones.step(n)` on every beat (`GameModel.swift:237–260`). Two things keep it off 5: the arc of light, the one thing that makes this a *pour* and not a swap, appears in none of the ten frames (`BoardView.swift:220–246` draws it over 0.24 s while the source only travels 34 % of the way, `Palette.swift:124`), and the vial is a bare `.onTapGesture` (`BoardView.swift:168`), so there is no press state under the thumb that DESIGN.md's own first row asks for. |
| Reward | 4 | Full screen on the canvas, no sheet and no seal: sun over a horizon, `CountUp` at `brandDisplay(size: 96)` in a lantern ring ticking `Haptics.impact(0.3)` and a climbing step tone, a pooled praise line, the start-to-the-line rail, the rack rising one vial at a time, three tiers that genuinely differ — 1.4 / 1.0 / no confetti at all but a breathing lantern swell (`WinView.swift:34–48`, `Voice.swift:94–102`) — and it ends on what opened or what is coming ("The ninth light at rack 31.", `qa/01-win.png`). Docked because the one film of it, `moment-win.png`, is ten identical frames: `qa.json`'s `delay: 2.2` opens the shutter after the 1.5 s choreography has finished, so nothing about the win can be *seen* to move. |
| Voice | 5 | Four pools of six with a no-repeat guard (`Voice.swift:11–56`), and the keeper holds: "Clean as the flat at low tide." in light, "Every light found its glass." in dark, "Low tide. The glass is waiting." while a board deals. The kit's words are gone from both ends — onboarding finishes on **Go on** (`qa/07-first.png`) and the paywall on **Take the whole shore** (`qa/06-paywall.png`) — and no screen inside the product recites the deal. |
| Craft | 4 | One unmistakable hero per screen (110 pt streak, 96 pt pours, 64 pt counter), a single 18 pt radius, every size through `scaledFont`/`brandDisplay`, and at AX5 the board holds while the controls drop to glyphs (`ax-02-play.png`). Three flaws: eleven vials lay out 5/5/1 so the last one floats alone in a void (`qa/05-accessible.png`, `BoardView.swift:96–119`); at AX5 "the charted line" and "THE LINE · 17" collide with no gap left between them; and the onboarding's lower third is empty (`qa/07-first.png`). |
| First minute | 4 | `qa/07-first.png` is a drawn rack decanting at the shoreline under "Every light wants its own glass." in the display serif, on the brand canvas — two pages, no symbols, no pricing page. The board then teaches with no sentence anywhere: the vial the verified solution wants first lights and its ring breathes until the first pour lands, for good (`TubeView.swift:186`, `GameModel.swift:71–76`). Not a 5 only because no capture shows the teaching ring, so its first ten seconds are confirmed in code alone. |
| Escalation | 4 | `ladder.png`'s four panels are four different games — 3 colours and a line of 8, then 9 colours and 28, then five measures deep and 39, then six and 47 — and `LevelGenerator.ladder` (`LevelGenerator.swift:88–92`) flattens at rung **200**, past the gate's 150, with DESIGN.md saying so out loud and saying why. Held at 4 by a real dead stretch inside that: `parBar` caps its within-band term at `units / 8` (`LevelGenerator.swift:126`), so every rack from **31 to 124** is nine colours, four deep, bar 28 — ninety-four racks of identical shape, which DESIGN.md's own table admits (rack 31 par 28, rack 80 par 28). |
| Pull | 4 | The charted line is a real thing to lose: go over it and the confetti does not fire, the verdict changes and the rack still counts (`Voice.swift:83–102`, `PlayView.swift:250–273`) — it costs the rack and nothing else. Three openings arrive for playing and none can be bought (`AppInfo.swift:56–66`), the win always names the next one, and the daily walks its own fortnight of rungs instead of dealing one board shape forever (`LevelGenerator.swift:149–162`). Docked because nothing the app records changes what it deals next: it stores your pours against par on every rack and never reads them. |

**As an editor.** The lead screenshot is `qa/01-win.png` — a lit rack under a rising sun with a
serif 17 in a lantern ring is not a thing any of the forty-nine competitors has — and I would put
it in a puzzle story. The weakest screen is `qa/04-shore.png`: a screen called Shore with no shore
in it, forty chips five across, and every door on it a purchase. A stranger shown one crop would
say: "a water-sort game somebody actually designed." On Thursday you open it because last night's
rack went three over the line and the app kept the number, because today's pool is the board
everyone else is walking too, and because the last win told you the ninth light is waiting at
rack 31.

## Captures missing

- **`ax-01-win.png` is not the win.** At the largest text size the capture caught the board still
  dealing — "Low tide. The glass is waiting.", hero 0, THE LINE · 0 — so the win at AX5 is
  unjudged, and the fix the last critique asked for there is unverified.
- **`moment-win.png` shows no motion.** Ten frames, all settled. The win's choreography is
  confirmed in code and at its peak in the still, never in the film.
- **No Settings capture**, though DESIGN.md lists it as one of four screens: `SoundsToggle`, the
  erase and restore are unseen.
- **No calm-mode capture** (muted palette, 0.45 s pour) and **no capture of the rendered share
  card** — `RackCard` (`WinView.swift:255`) exists in code only.
- **AX covers only the win and the board**, and there are no dark AX captures.

## Slop tells present

None. `node tools/design/tells.mjs color-sort` reports 0 hard tells and 0 smells, and none of
TASTE.md's screenshot tells survive: no grey canvas or white cards, no accent-on-grey (Ember is a
warm refusal, Kelp a vial come good — red and green never mean right and wrong), no SF Symbol as a
hero, no `.medium` sheet win, no row of identical number tiles (`StreakView.swift:46` is one hero
and two lines of prose), no frozen point sizes, and the icon is a drawn vial in a ringed pool.
Two soft watch items, neither a fail: `checkmark.seal.fill` is still the badge on the board and on
today's pool (`PlayView.swift:134`, `StreakView.swift:93`) — the last system verification mark in a
world of glass — and the Shore's unlock card restates the deal a second time outside the paywall
(`PacksView.swift:60`).

## The second session

- **Where the curve stops.** `LevelGenerator.swift:88–92`: colours stop climbing at rung 31, the
  par dial at 64, depth at 200 — `Ladder.flattensAt` is **200**, so the gate's 150 is cleared and
  past rung 200 every rack is nine colours six deep forever, stated in DESIGN.md:64–69 with the
  solver's provability as the reason. The honest caveat is inside the curve, not at its end:
  `parBar`'s `min(…, units / 8)` (`LevelGenerator.swift:126`) freezes racks 31–124 at one shape and
  one bar. Three comments still describe a ladder that no longer exists — depth "five at 50"
  (`LevelGenerator.swift:73`), "from level 50 on" (`TubeView.swift:15`), "from level 45 on"
  (`BoardView.swift:16`); the real steps are 125 and 200.
- **What chooses the next unit.** Nothing does. `advance(from:)` serves `n + 1`
  (`PlayView.swift:275–288`) and a board is a pure function of its number
  (`LevelGenerator.swift:242`), so it is never `%` over a fixed array and never repeats — but it is
  never *chosen* either. `LevelResult` stores moves against par for every rack
  (`Results.swift:7–25`) and no line of code reads that field to decide anything.
- **What is at risk.** The charted line. Going over it costs the clean sweep — `WinTier.overPar`
  fires no confetti and takes the warm swell instead (`Voice.swift:94–102`, `WinView.swift:39–48`)
  — and costs nothing else: the rack stays cleared, the best is kept (`PlayView.swift:255–257`), and
  a replay can still beat it. No life, no progress, no tomorrow. There is no thread across a
  session, though: `Run` is unused, so four racks in a row are four unrelated risks.
- **What is earned by playing.** `AppInfo.earned` (`AppInfo.swift:56–66`): the ninth light at 31,
  tall glass at 125, deep glass at 200 — the three rungs where the rack itself changes shape, named
  at the win the moment they are crossed and named as a horizon when they are not
  (`WinView.swift:147–169`). None is purchasable. But they appear only on the win screen: every
  door on the Shore is `store.isUnlocked` (`PacksView.swift:101–119`).

Why someone opens this on Thursday: an unbeaten line on a rack they went over, a shared board that
is different today, and a named thing waiting further up the shore.

## Keep

- The win, whole: sun, lantern ring, the count with its per-tick haptic and climbing tone, the
  start-to-the-line rail, the rack lighting one vial at a time, and the three tiers where over par
  gets no confetti at all. This is the picture the app is sold on.
- The liquid: top-lit gradient, specular stripe, meniscus, ring on the flat, frond under a vial
  that came good. Nothing else in the category looks like it.
- The voice, and the button words — Pour it again, Take the next one, Show me, Refill, Go on, Take
  the whole shore.
- The teaching ring: a breathing glow under the first move of the verified solution, no sentence
  anywhere, off for good after the first pour.
- The ladder as a type with a stated end, the three earned openings, and the daily that walks its
  own rungs.
- Okabe–Ito with a shape stamped on every unit (`qa/05-accessible.png`). Nobody else has it.

## Fix, in this order

1. **Make the pour look like a pour.** `moment-pour.png` has ten frames and not one shows a stream
   of light; the vial tips and the level changes, which is a swap with a rotation. In
   `BoardView.swift:201–210` take the source's travel from `0.34` to `0.62` and its rise from
   `unit * 0.62` to `unit * 1.15`, so the tipped mouth actually sits over the receiving rim; in
   `Palette.swift:124` stretch `pourDuration` from 0.24 s to 0.34 s (0.5 s calm); and in
   `GameModel.swift:253` stop fading `stream` to 0 at the landing — hold it through
   `landDuration` and drop it with the vial's return. Next capture: three or four of the ten frames
   carry a visible ribbon between two mouths.
2. **Retime the win so it can be seen to move.** `qa.json` `moments[1]`: `delay` 2.2 → 0.8,
   `interval` 0.16 → 0.12, `frames` 10 → 12. And stop the dealing screen reaching a capture at all
   — under `Motion.isStill`, generate on the calling actor in `GameModel.open`
   (`GameModel.swift:115–134`) instead of a detached task, so `ax-01-win.png` is the win rather than
   "Low tide. The glass is waiting." Next capture: `moment-win.png` frame 1 is a count mid-climb and
   an empty flat, frame 6 has confetti and half the rack lit; `ax-01-win.png` shows a win.
3. **Give the vial a press state.** `BoardView.swift:168` is a bare `.onTapGesture`, so nothing
   answers under the thumb until the finger lifts — DESIGN.md's pour table asks for
   `.buttonStyle(.pressable)` and `Haptics.soft()` on finger-down. Wrap the `TubeView` in a
   `Button` with `.buttonStyle(.pressable)` and move the soft tap to the press. Next capture: no
   still shows this, so say it in STATUS and confirm it on the device pass.
4. **Put what playing opens on the Shore.** `qa/04-shore.png` is a screen where every door is a
   purchase (`PacksView.swift:101–119`), which is the reading TASTE.md's `Earned` exists to defeat.
   Above the "How you pour" band add a "What the shore opens" band drawn from `AppInfo.earned`:
   three vials, lit when `highestCleared >= milestone.at`, each with its title and blurb, and the
   next one captioned "Rack 31 — the ninth light" in the keeper's voice. Next capture: the Shore
   shows three earned openings before it shows anything that costs money.
5. **Read what you already record.** Every rack stores its pours against par (`Results.swift:7–25`)
   and nothing consults it. Two cheap uses: on the shelf, draw a rack cleared over the line as
   half-lit glass with a lantern tick rather than full light (`PacksView.swift:128–188`), and on the
   win, when the player is inside the free ladder and has an over-par rack behind them, offer "Walk
   rack 23 again — you were four over" beside "Take the next one" (`WinView.swift:193`). Next
   capture: `qa/04-shore.png` has two kinds of lit vial, and the app is visibly paying attention.
6. **Break the ninety-four-rack plateau.** Racks 31–124 are one rack dealt ninety-four ways
   (`LevelGenerator.swift:88–92` with the `units / 8` cap at `:126`). Either bring the depth dial's
   first step inside the free ladder — `Ladder.Dial("depth", from: 4, every: 40, opensAt: 45,
   ceiling: 6)` puts five measures at rack 85 and six at 125 — or open a fourth dimension around
   rack 60 (a vial that starts capped, a narrow neck that takes one measure at a time) so the middle
   of the ladder changes shape at least once. While there, fix the three comments that still claim
   depth moves at 45 or 50 (`LevelGenerator.swift:73`, `TubeView.swift:15`, `BoardView.swift:16`).
   Next capture: add a `rack-90` panel to `qa.json`'s ladder and it is not interchangeable with
   `rack-40`.
7. **Stop orphaning the last vial.** Eleven vials lay out 5/5/1 and the odd one floats alone in a
   half-screen of empty water (`qa/05-accessible.png`, `ladder.png` racks 40/130/210). In
   `BoardView.swift:96–119` balance the rows — `ceil(count / rows)` per row, so eleven is 4/4/3 —
   and centre the block vertically. Next capture: `05-accessible` is a rack, not a rack and a
   straggler.

## Against the mocks

- **Play** (`design/mock-1-play.png` → `qa/02-play.png`). The mock draws the charted line *on the
  board*: a dashed mint arc labelled "the charted line" curving out of one mouth into an arrowhead
  over the target. The build reduces it to two small circular arrows on the vials and moves the
  words down into a chart mark under the rail — legible, much less magical. The mock's flat also has
  a horizon band and reflections under the glass; the build has ring glows only, so the middle of
  the screen is emptier than promised. The vials themselves are better than the mock.
- **Win** (`design/mock-2-win.png` → `qa/01-win.png`). The mock is "the tide goes out": a drawn
  waterline waves across the screen with the lit rack standing below it and a scatter of quiet
  coloured dots. The build has the sun, the ring, the rail and the fronds, but no waterline — and it
  fills the screen with ordinary paper confetti, so the tier reads as celebration rather than as the
  tide having gone out. Add the wave (a `Path` in `brand.palette.accent.opacity(0.35)` behind the
  rack) and tint the confetti further toward the rack's own liquids.
- **First** (`design/mock-3-first.png` → `qa/07-first.png`). The mock is a warm sand-and-dawn page;
  the build is deep water, and the build is right — it is the shore the rest of the app is in, and
  it replaces the mock's forbidden "Continue" with "Go on". Both share the flaw: a third of the
  screen below the subtitle is empty. Float the art with `ambientFloat` and pull the block down
  toward the optical centre.
