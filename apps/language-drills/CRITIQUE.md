# Thousand · critique

**Verdict: pass.** This is a Sevillian tile-setter's workshop and it commits — plaster with a
trowelled grain, twelve named glazes, a bevelled square that repeats from 318 pt down to 9 pt,
and a man who talks about mortar and kilns instead of streaks and levels; one crop of the win
or the Wall names the app. What most decides it is that the tile is a real object rather than a
flashcard — and the one thing standing between that and a clean pass is that in dark mode the
word painted on it sits at **1.92:1** against its own face.

| | Score | Evidence |
| --- | --- | --- |
| Idea | 5 | Every screen is the workshop: the course and the bench (`qa/02-bench.png`), the wall as twelve panels of azulejo (`qa/03-wall.png`), the kiln shelf and the mortar bars (`qa/04-progress.png`), the swept bench with the tools laid down (`qa/05-swept.png`). No flag, no mascot, no flame anywhere. |
| Look | 4 | Plaster mesh + `Canvas` grain under a bevelled tile language, and dark is designed rather than inverted — night indigo with the lamp warm behind the wall (`qa/design/dark-01-win.png`), the tile face dimmed to `#DCD2C0` so it does not glare (`qa/design/dark-02-bench.png`). Held back by the light-mode wall, where the unfired tiles vanish (`qa/01-win.png`, panels 5–12 read as coloured stripes in empty air). |
| Signature interaction | 4 | The mechanism is all there and correct — `TurningTile` is `Animatable` on the angle so the sheen tracks the rotation and the clay hairline fades in at edge-on (`ios/App/DrillTile.swift:56`, `:86`, `:239`), with `Haptics.soft` → `.rigid` + `Tones.pop` at the edge → flight to the course on `.step(n)` (`ios/App/BenchView.swift:318`, `:352`). But the filmstrip proves none of it: `qa/design/moment-turn.png` has one prompt-face frame out of eight, no mid-rotation frame at all, and frames 6 and 7 are identical. |
| Reward | 4 | Full screen on the plaster, never a sheet: a 100 pt count-up with a haptic per tick, the day's tiles pressing into the wall on a climbing scale, the wall line, and three real tiers — `.set` glows, `.clean` bursts at 1.1, a new hundred bursts at 1.5 and runs a lustre across the whole wall with the hero held in amber (`ios/App/WinView.swift:205`–`:268`, shown in `qa/01-win.png`). Docked for the largest-text layout (below) and the wall behind it losing its bare clay. |
| Voice | 5 | The setter is a character: ten praise lines and eight near-miss, never the same twice running (`ios/App/Voice.swift:19`, `:59`); counts spelled out — "Fifty-four tiles are drying. Six are ready tomorrow." (`qa/05-swept.png`); every button is his — *Set the first tile*, *See the wall*, *Back to the wall*, *Take the wall down*. The pitch appears only on onboarding 3 and the paywall, exactly as TASTE.md allows. |
| Craft | 3 | Dynamic Type is handled with real thought — the tile clamps at `accessibility1` so the word, example and chime stay on the object, and it holds beautifully (`qa/design/ax-02-bench.png`). Against that: the answer face's headword fails contrast in dark, the win's two buttons are off the bottom at AX5 (`qa/design/ax-01-win.png`), the kiln stacks misreport 48 vs 13, and the moment filmstrip opens on a white frame. |
| First minute | 4 | The first frame is already plaster and cobalt with drawn art and no symbols (`qa/07-first.png`), and the Bench then explains nothing — the tile peeks at 14° twice and stops forever once touched (`ios/App/BenchView.swift:437`). The dark onboarding art is the light art on indigo, so the unfired tiles glare (`qa/design/dark-07-first.png`). |

`node tools/design/tells.mjs language-drills` → **0 hard tells, 0 smells.**

**Captures missing.** No Settings screen, no onboarding pages 2 or 3 (so `finishTitle: "Set the
first tile"` is confirmed only in `ios/App/Thousand.swift:20`, not in a capture), no word sheet
opened from the Wall, no locked panel under its dust sheet, and no render of the share card.
`qa/design/ax-*` covers only the win and the bench — the Wall, Progress, the swept bench and
the paywall are unjudged at the largest text size. Scores above cover what is visible.

## Slop tells present

**None.** Three came close and are worth naming so polish does not drift into them:

- `ios/App/ProgressWallView.swift:161` — the kiln shelf ends in a big number over a tracked grey
  caption, twice, side by side. The drawn stacks are what keep it off the list; they have to
  stay, and start telling the truth (fix 5).
- `ios/App/ProgressWallView.swift:104` — "THE TWELVE PANELS" is twelve identical name / count /
  bar rows. It survives because each bar is in its own glaze and they are ordered longest
  first, but it is the one screen region that could be any app's settings list.
- `qa/design/dark-06-paywall.png` — `hand.raised.fill` sits in front of the promise line as a
  bare monochrome glyph. Not a hero, so not a tell, but it is the only sticker on the wall.

## Keep

- **The tile as an object.** Two genuinely different painted faces — glaze ground with cream
  letters, then cream field inside a glaze band with four amber corner motifs — plus the bevel,
  the sheen and the 3 pt clay edge. `qa/02-bench.png` is not a flashcard app's screenshot.
- **The three grades.** *Got it* filled in cobalt and 30 % wider between two outlined chips; the
  only capsules on a screen of squares, so the eye lands on them without a label telling it to.
- **Dark mode.** The lamp glow behind the wall, the plaster gone blue, the face dimmed rather
  than inverted. `qa/design/dark-01-win.png` is the best frame the app has.
- **The voice, entire.** Do not touch the pools, the spelled-out counts, or the Settings footer
  "It never counts the days you were away."
- **The teaching.** Not one word of instruction anywhere; the peek does it and then leaves.
- **The icon.** A glazed azulejo with a hand-painted eight-point star, neighbours cropping at the
  edges, 3° off square. Reads at every size.

## Fix, in this order

**1 · The English on the tile is unreadable at night.**
`ios/App/DrillTile.swift:174` (`Text(word.translation).foregroundStyle(glaze)`) and `:164`
(the Spanish top-left) paint on `AppBrand.tileFace`, which is light in *both* modes — but
`glaze` resolves to the **dark** value there. `node tools/design/contrast.mjs 5C9BE8 DCD2C0`
→ **1.92:1 FAIL**; almagre 2.26, verdigris 2.09. DESIGN.md's own table specifies
`#1C5AA6 on #F4ECDD 5.84 AA`, i.e. the light glaze, whatever the mode. Add
`static func faceGlaze(_ theme: Int) -> Color` to `AppBrand` returning the *light* hex as a
plain `Color(hex:)`, and use it for both `Text`s and for the 1.5 pt fillet at `:149`. Next
capture: in `dark-02-bench.png`, "to help" is deep cobalt on cream and passes `contrast.mjs`
at 5.8 or better.

**2 · `-demo turn` films everything except the turn.**
`ios/App/BenchView.swift:461` holds the answer face for 3.6 s of a 4.2 s cycle, so at roughly
one frame every two seconds the camera lands on it almost every time —
`qa/design/moment-turn.png` has one prompt face, zero frames between 0° and 180°, and frames
6/7 identical. Replace the loop with explicit held beats on one card: 2.5 s at 0°, then step
the angle by hand — `withMotion(.linear(duration: 0.9)) { angle = 90 }`, hold 1.2 s at edge-on,
then to 180 on `Motion.bouncy`, hold 2.5 s, grade `.good`, hold 1.5 s while it flies — and run
it three times, not eight. Next capture: at least one frame edge-on showing the clay hairline
and the sheen crossing, and one frame with the tile shrunk in flight toward the course.

**3 · The thousand disappears in light mode.**
`ios/App/WallMosaic.swift:90` sets `bare = brand.palette.surface.opacity(0.5)`; over
`#EDE3D6` that is about a 3 % luminance step, so in `qa/01-win.png` eight of the twelve panels
read as a coloured stripe floating in nothing — the exact opposite of `design/mock-2-win.png`,
where the unfired grid is plainly there and the wall is a finite object you are filling. Fill
bare tiles with `brand.palette.surface.shaded(0.05)` at full opacity and give each a 0.5 pt
inset shadow line so it reads as a recessed grout gap. Same at `ios/App/Tiles.swift:165` for
the Wall screen's 44 pt tiles and, by inheritance, for the share card. Next capture: in
`01-win.png` and `03-wall.png` every one of the thousand slots is countable in light mode.

**4 · At the largest text the reward is off the screen.**
`qa/design/ax-01-win.png`: "Two hundred in the wall." takes three lines, the praise line is
clipped by the bottom edge and both *Back to the wall* and *Share the wall* are past it. It is
a `ScrollView` (`ios/App/WinView.swift:46`) so it is reachable, but the moment the app is
proudest of arrives with nothing to do. Clamp the hero and the copy block with
`.dynamicTypeSize(...DynamicTypeSize.accessibility2)`, drop `wall`'s fixed `.frame(height: 300)`
to `min(300, …)` under accessibility sizes, and pin `actions` in a `.safeAreaInset(edge: .bottom)`
so the primary button is always on screen. Next capture: `ax-01-win.png` shows the hero, the
headline and *Back to the wall* in one frame.

**5 · The kiln stacks lie about the numbers.**
`ios/App/ProgressWallView.swift:138` caps the stack at 22 tiles, so 48 due today and 13 due
tomorrow draw at 1.6:1 instead of 3.7:1 — in `qa/04-progress.png` the two piles look almost
the same height and the tracked number underneath has to do all the work, which is the row of
number tiles the design set out to avoid. Keep the cap for the frame but make it honest: below
the cap draw one tile per word at true scale; above it, compress the *overlap* rather than
dropping tiles, so the pile keeps growing. The 74 × 11 rods also read as coloured sticks —
narrow to about 52 pt and lift `overlap` to 6 so more of each face shows and it reads as
stacked squares. Next capture: the *due today* pile is visibly about three and a half times
the *tomorrow* pile.

**6 · The Bench is bottom-heavy.**
In `qa/02-bench.png` there is roughly 330 pt of empty plaster between the course and the tile
and about 400 pt between the chips and the tab bar, so the block DESIGN.md says is centred as
one thing floats in a large blank room — `design/mock-1-play.png` reads tighter and more
deliberate. Centre the tile-plus-chips group in the space below the course with a single
`Spacer()` above and below, and bring the course's tracked marks closer to their slots. While
there: `qa/02-bench.png` was shot with the course entirely empty; capture the store shot
mid-session so the filled glazes appear, as the mock does. Next capture: the tile sits on the
optical centre and the course carries colour.

**7 · The workshop turns the lights on but the art does not.**
`WallAtNoon` and `KeptWall` are the light SVGs shown unchanged on the night canvas, so their
unfired tiles come through as bright cream rectangles on indigo (`qa/design/dark-07-first.png`,
and the bottom-right of `qa/design/dark-06-paywall.png`). Render a second pair with the plaster
and bisque values from the dark column (`#131826`, `#1F2536`, `#3A3730` for the clay edge) and
swap on `colorScheme`. In the same pass: `qa/design/moment-win.png` frame 1 is a plain white
screen, so give the target a launch screen on `canvas`; and replace the `hand.raised.fill` in
front of the paywall promise with the drawn `CornerMotif` or nothing at all.

## Against the mocks

- **Bench — `design/mock-1-play.png` → `qa/02-bench.png`.** The closest of the three. The face,
  the glaze band, the four amber motifs, the rank mark, the hairline and the three chips with
  *Got it* filled and widest all arrived. Two things are flatter: the mock's course carries nine
  glazed tiles and the build's capture is an empty row, and the mock's tile sits in a tighter
  column where the build leaves a third of the screen bare under the chips (fix 6). The mock's
  chime is a solid glyph in a well; the built `SoundArcs` is thin enough at 44 pt to read as a
  signal-strength mark rather than sound.
- **Win — `design/mock-2-win.png` → `qa/01-win.png`.** The choreography, the tiers and the amber
  hero all landed, and the built wall is arguably better composed. The gap is the unfired tiles:
  the mock's wall is a solid grid of a thousand slots so the coloured ones are visibly *inside*
  something, and the build's dissolve into the plaster so the lower panels look like stray bars
  (fix 3). The build also runs three stacked sentences where the mock ran two, and two of them
  can land close together — "Every one of them held." over "Every panel standing, none left
  bare." Let `Voice.standing` return nil when the praise line already says it.
- **Onboarding — `design/mock-3-first.png` → `qa/07-first.png`.** Effectively identical in light:
  same art, same wide display face, same plaster. The build sets the art a little smaller and
  leaves a longer gap between the subtitle and the page dots. Dark is where it falls behind the
  promise, since the mock only ever described the lit workshop (fix 7).
- **Not mocked, and it shows.** Progress is the weakest screen in the build and had no mock to
  aim at: the kiln shelf reads as two piles of coloured sticks and the twelve panels as a list.
  An App Store editor would lead with `01-win.png` — the amber `213`, the twelve-panel wall and
  "Two hundred in the wall." is a screenshot a stranger would want, and it is the one that gets
  sent to a group chat. A stranger's one sentence: *"It's a Spanish app that looks like a
  Seville tile shop, and the thing you build actually stays built."*
