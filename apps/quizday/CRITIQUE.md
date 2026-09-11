# Quizday · critique

**Verdict: pass.** The newspaper arrived: newsprint with grain and column rules under a lamp,
New York everywhere, a drawn hand press turning on the step, answers as ruled boxes that take
ink, a red stamp that lands off-axis on every answer either way, and a front page that prints
itself at 112 pt with a brass ribbon and shredded newsprint in the air. The one thing that
decides it: the ink press and the edition are now *built* — `QuestionSheet.press(correct:)` and
`EditionView.printEdition()` hold the exact beats, springs, haptics and tones DESIGN.md wrote —
where the last build had a 0.18 s ease and "8 out of 10 / Come back tomorrow".

| | Score | Evidence |
| --- | --- | --- |
| Idea | 5 | Cover the word "Quizday" on any capture and it is still a paper: `01-today` is a masthead, strapline, dateline and an iron hand-press over grain; `02-question` heads with a section tick in ink blue and `Q4 OF 10 · MEDIUM`; `04-scorecard` is `THE FILE` with a ledger line and a month printed in ink density; `06-practice` is a type case with printers' fists. No competitor screenshot looks remotely like this. |
| Look | 4 | Paper canvas at `#F5EFE2` with 1,400-stroke grain, two column rules and a lamp glow, one radius (6), one shape (the ruled box) at four sizes, nine named colours plus six section inks, and dark genuinely designed — `dark-01-today` is blue-black press stock with warm ivory type and brighter brass, not an inversion. Held off 5 because the paper stops at the kit's two screens: `05-paywall` puts red `checkmark.circle.fill` bullets in a filled card with a `hand.raised.fill` glyph, and `08-settings` is white rows (near-black in `dark-08`) rather than `surface`. |
| Signature interaction | 4 | `QuestionSheet.swift:304–337` is the four beats as written: `InkSweep` masked 0→1 on `.spring(response: 0.26, dampingFraction: 0.85)`, `Haptics.rigid()` at 200 ms, `.pop`/`.miss` at 210 ms, the stamp on `Motion.bouncy` at 230, the pencil ellipse and strike trimming over 0.34 s, the footnote rule drawing itself, and the tally square at 520 ms with `Tones.play(.step(runningCorrect))`. `02-question` shows the result — knocked-out type in proof green, the answered line struck in graphite, a red stamp hanging past the right margin. Not 5: `moment-answer.png` is 18 identical frames, so nothing is proven on camera, and a long stamp line (`dark-02-question`, "CLOSE. THE DESK HAS IT HERE.") covers the answer it lands on. |
| Reward | 4 | `EditionView.printEdition()` prints the page in order — press rule sweeping, masthead `.popIn(0.18)`, `CountUp(to:duration: 0.7)` at `.brandDisplay(size: 112)` firing `Haptics.impact(0.4 + 0.05n)` and a climbing `.step(n)` per tick, the tally 34 ms apart, the tier stamp with `Haptics.celebrate()` and `.fanfare`, newsprint confetti in the paper palette, then the brass ribbon unrolling — five tiers with their own bursts, plus the `PERSONAL BEST` stamp. `03-result` is a front page worth screenshotting, and `09-share` is the 1080 × 1350 version of it. Not 5: `moment-win.png` shows only the settled page for sixteen frames, the result's tally prints silently (`EditionView.swift:56` — no per-square `Haptics.selection()` or `.tap` tone), and the ribbon is an over-wide brass slab with "1 DAY RUNNING" crammed into its left third. |
| Voice | 5 | Ten praise lines and eight near-miss lines drawn without replacement (`Voice.swift`, `VoicePool`), five tier headlines with their own sublines ("One got past you. One."), `Today is still blank.`, `¶ something wrong here?`, `One knock at the door, at the hour you choose.`, and buttons that say what happens — `Open today's edition`, `Print the edition`, `See the composing room`. The pitch appears once, on the paywall (`AppInfo.swift:56`), and nowhere else: the reminder is now "Today's edition is on the step." |
| Craft | 4 | Hierarchy is unambiguous — one thing over 44 pt per screen (112 on the result, 96 on the file), rhythm on a 10/16/18 pt grid, and the captures are reproducible now (`03-result` and `dark-03-result` show the same eight). Against it: at AX5 `ax-01-today` overflows `GENERAL KNOWLEDGE` past the right column rule to the screen edge and runs the rest of the section line under the tab bar, and `ax-02-question` hides answer D behind the bottom strip while the stamp, still at its fixed size, buries "Superman". Today, Practice and the result all end a third of a page above the fold with only the ornament in the gap. |
| First minute | 4 | `07-onboarding` opens on the masthead, the strapline and the drawn press over paper with a red `Continue` — the promise "this is a newspaper" is made in the first second and the app keeps it. Nothing explains the controls: the first box breathes ink 12 % and the stamp ghosts above it (`QuestionSheet.swift:211–222, 345–347`), and only the VoiceOver hint says "Tap to stamp this answer". Not 5 because the page is empty from the subtitle to the dots, and the onboarding masthead's rules run full-bleed against an inset glow, leaving a visible seam across `dark-07-onboarding` at the top rule. |

`node tools/design/tells.mjs quizday` → **0 hard tells, 0 smells** (was 17 FAILs).

All captures listed in the skill are present and were read: nine light screens, nine dark, two
AX, two filmstrips, the icon. The icon is now the drawn one — cream newsprint, an ink masthead
bar, a brass hairline and a broken red stamp rim with a hand-weighted tick; at 60 pt it will be
the only warm, light, non-gradient square in a row of blue question marks.

## Slop tells present

**None.** Specifically checked and clear: no `systemGroupedBackground` anywhere; no green/red
pair (a miss is graphite and a pencil, and the stamp is red on right answers too); no SF Symbol
hero — six drawn SVGs carry Today, onboarding, the paywall, Practice and the empty file; no
"out of ten" sentence and no "come back tomorrow"; no stat tiles (one 96 pt run over a mono
ledger line); no `.sheet` win; no pitch outside the paywall; no `.easeOut`-only motion; the
icon is a drawing; praise comes from pools.

Two things sit close to the line without crossing it, and both are in the *Fix* list: the
kit's paywall card and the kit's Settings rows are the only white-card surfaces in the app.

## Keep

- **The ink press, exactly as built.** The sweep with the knocked-out second copy of the type,
  the off-axis stamp, and the hand-drawn correction. Do not tidy the ellipse — the overshoot
  past the box edge is why it reads as a pencil.
- **Red carries no judgement.** The stamp is red on a right answer too; a miss is graphite.
  That single decision is what keeps this out of the genre.
- **The tally as three legible states** — solid, struck, ruled — used identically in the sheet,
  the result and the share card.
- **The printed month.** `04-scorecard`'s ink-density calendar with the score knocked out at 8+
  and today circled in pencil is real information design, and the mono legend beats chips.
- **The ledger line** `BEST 13 · 19 EDITIONS FILED · 148 OF 190 ANSWERED`.
- **The share image.** `09-share` is a front page, not a screenshot of a score.
- **The voice pools and the tier sublines**, and the reveal's content — explanation, mono
  source dateline, `¶ something wrong here?`.

## Fix, in this order

1. **Film the two moments — they still show nothing.** `moment-answer.png` is 18 identical
   frames of an already-revealed question and `moment-win.png` is two blank frames then sixteen
   of a settled page with only the countdown ticking. The demo fires too early for the camera:
   `TodayView.swift:202–208` presses at 1.8 / 3.4 / 4.2 s and `:226–230` at 2.0 / 3.6 s, while
   the filmstrip's first usable frame lands several seconds after launch. Push the first press
   to ~6 s and space the rest ~4 s apart (`at(6.0)`, `at(10.0)`, `at(14.0)`; the win's tenth
   answer at `at(8.0)` and `next()` at `at(11.0)`), and raise `frames` in `qa.json`'s moments
   to 24. *Next capture:* consecutive frames of `moment-answer` differ — one shows the box part
   inked, one the stamp mid-drop, one the tally square arriving — and `moment-win` catches the
   count-up between 0 and the score with confetti in the air.

2. **Stop the stamp swallowing the line it lands on.** `dark-02-question` and `ax-02-question`
   show "CLOSE. THE DESK HAS IT HERE." and "HALF A LEAD, NO STORY." lying across the whole
   answered box, so the answer she pressed is unreadable — the short lines ("Pencil it out.")
   look right, the long ones do not. In `QuestionSheet.swift:180–190`, cap the stamp:
   `.fixedSize()` → a `.frame(maxWidth: 190, alignment: .trailing)` with `.lineLimit(1)` and
   `.minimumScaleFactor(0.7)`, and on a miss anchor it `.bottomTrailing` with `offset(x: 16,
   y: 14)` the way the correct case already does, so it straddles the bottom rule instead of
   the type. *Next capture:* in `dark-02-question` the word "Superman" is legible with the
   stamp clear of it.

3. **Make the largest text hold.** `ax-01-today`: `SectionLine` (`Paper.swift:416`) lays
   `GENERAL KNOWLEDGE` past the right column rule to the screen edge and the rest of the line
   disappears under the tab bar — give each name `.lineLimit(1).minimumScaleFactor(0.6)` and
   clamp the line to `...DynamicTypeSize.accessibility3`, as the question headline already is.
   `ax-02-question`: answer D sits behind the bottom strip; add `.padding(.bottom, 24)` inside
   the sheet's scroll content so the last box clears the inset. *Next capture:* both AX shots
   show every answer and every section name inside the column rules.

4. **Give the paywall the paper.** `05-paywall` is the one screen a stranger meets that is not
   this app: the kit's "Unlock everything in Quizday." subtitle
   (`FactoryKit/Sources/FactoryKit/PaywallView.swift:61`), red `checkmark.circle.fill` bullets
   in a filled card (`:72`) and a `hand.raised.fill` glyph on the promise (`:82`). Add
   `subtitle:` and a bullet-mark option to `PaywallView` (it belongs in the kit, not copied
   into the app), pass the editor's line — *Where the paper is set before it goes to press.* —
   and the printers' fist on ruled lines that `PracticeView` already draws, and drop the
   raised hand entirely. *Next capture:* `05-paywall` and `06-practice` read as the same room.

5. **Take the white cards out of Settings.** `08-settings` is white system rows on newsprint and
   `dark-08-settings` is near-black ones; the canvas is right and the cells are not. Apply the
   brand's `surface` and a 1.2 pt ink rule at radius 6 to the kit's `SettingsView` rows the way
   `.ruledBox()` does elsewhere, and pad the bottom so the version footer stops sitting behind
   the tab bar (visible ghosted in `dark-08-settings`). *Next capture:* the rows are `#FBF7EC`
   in light and `#1E2230` in dark, with the footer clear of the bar.

6. **Fix the ribbon on the result.** `03-result` stretches the brass to 260 pt
   (`EditionView.swift:75–76`) with `1` and `DAY RUNNING` crowded into its left third and a
   third of the slab empty — the mock's ribbon is snug to its type. Size it to its content
   (`.fixedSize()` with 20 pt of internal padding), and on day one print the editor's own line,
   `Day one on the desk.` (`Voice.streak`), rather than a pluralised `1 DAY RUNNING`.
   *Next capture:* the ribbon ends just past the caption, and day one reads like the editor.

7. **Let the result's tally be heard.** DESIGN.md's 1040–1400 ms beat is one square at a time
   with `Haptics.selection()` per square and `Tones.play(.tap)` on every third; the squares
   stagger correctly (`EditionView.swift:56`, `Tally(stagger: 0)`) but land in silence, so the
   page's middle beat is the only one the hand and ear miss. Fire them from `Tally`'s per-index
   `popIn` delay when a `stagger` is set. *Next capture:* not visible — verify in the code and
   on the Thursday phone pass.

## Against the mocks

- **Question sheet — `mock-1-play.png` vs `02-question.png`.** Built, essentially line for
  line: the section tick in ink blue, `Q4 OF 10 · MEDIUM`, the tally in three states, the
  headline over its 2.5 pt rule, four ruled boxes with mono `A B C D` gutters, proof green with
  knocked-out type, the graphite strike, the hand-drawn ellipse, the stamp past the right
  margin, the mono source, `¶ something wrong here?` and the ornament. Flatter in one place:
  the mock leaves the unpressed answers in soft grey so the pressed pair carries all the
  contrast; the build inks C and D at full strength, which makes the sheet noisier than drawn.
- **Result — `mock-2-win.png` vs `03-result.png`.** The masthead, dateline, `8` at 112 pt with
  `/10`, the ten squares, `STOP THE PRESS` in its double-ruled stamp at −3°, the subline, the
  ribbon, the fold, the two ruled boxes and the mono footer are all there, with the confetti
  frozen mid-air exactly as `-stillFrames` should show it. Flatter: the mock's ribbon is sized
  to its type where the build's is a wide brass slab, and the mock keeps scraps falling through
  the lower third that the build leaves empty between the boxes and the footer.
- **First run — `mock-3-first.png` vs `07-onboarding.png`.** The promise is made: masthead,
  strapline, the drawn press, *One edition a day*, a red `Continue`. Flatter: the mock's page
  is composed to its foot; the build leaves a third of it blank under the subtitle, and the
  masthead's full-bleed rules cut a visible seam across the glow in `dark-07-onboarding`.
- **Today, unplayed — DESIGN.md §Screens 1 vs `01-today.png`.** Masthead, strapline, dateline,
  the press with its flywheel, the italic line, the section line with coloured ticks and the
  prominent button: all present and in order. The page then stops a third of the way up the
  screen with only the ornament below it — on a phone this tall, either the press wants to be
  larger or the column wants the countdown or the run in that gap.
- **Paywall — DESIGN.md §Screens 9 vs `05-paywall.png`.** `desk.svg` at 280 pt on paper and the
  promise in the one place it belongs. Everything between them is still the kit's: see fix 4.
