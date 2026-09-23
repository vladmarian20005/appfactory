# Crosshatch · critique

**Verdict: fail.** An engraver's bench, drawn through: copper ruled into a staircase matrix, cast marks
instead of rotated labels, a crosshatch that reads as tone, a pull that inks and wipes and prints, and a
generator that actually reads what the player is bad at — this is the first app through the factory
whose play is as designed as its look. It fails on one thing that decides it: the margin card ends every
session by naming what is waiting — "The pencil comes to the bench at four", "The aquatint box comes
down at thirty" — and three of the six things it names do not exist anywhere in the code, so the first
promise the second session makes is one the app does not keep.

| | Score | Evidence |
| --- | --- | --- |
| Idea | 5 | Every screen is the shop: the plate on paper on zinc (`qa/03-bed.png`), prints pegged on a cord over a day-book page (`qa/01-line.png`), plates standing in a rack (`qa/05-run.png`), a paywall whose hero is the drying line (`qa/06-paywall.png`). Even the icon is a plate with one point cut. |
| Look | 5 | A canvas with tooth and bed rails, New York Bold at 108 pt over the line, corner radius 3, six cast inks that never cross the bevel, copper that dims rather than inverts in `qa/design/dark-03-bed.png`. One crop of the plate is unmistakable. |
| Signature interaction | 4 | The code has it all — `Cut.bite` and `Cut.point` springs (`AppBrand.swift:49-50`), two-pass `CutShading` trimmed over 160 ms (`PlateView.swift:117-131`), swarf from the cell (`PlateView.swift:283-287`), a 22 ms cascade with a haptic every second cell (`Bench.swift:343-364`). But `moment-cut.png` shows two cuts and eight identical frames, and the slip has no shake and no skid: `bench.slips` is published (`Bench.swift:332`) and no view reads it; `.shake(trigger:)` appears nowhere. |
| Reward | 4 | `qa/02-win.png` is a print you would send: the answer engraved, filings frozen mid-fall, `PULLED CLEAN. NOTHING GUESSED ON IT` in copper, a margin card that names the record. Four tiers with their own filings, haptics and tones (`Bench.swift:575-610`, `PullView.swift:222-229`). Held at 4: the print does not go up on the line (`matchedGeometryEffect` is nowhere), the ghost numeral is hidden under the print, and the press "turns" by 0.6° (`PullView.swift:260`). |
| Voice | 4 | The engraver is real and varied: twelve praise lines, nine near-misses, five for a block closing (`AppInfo.swift:49-89`), "Read three again. It settles Dyer and the packet." (`Bench.swift:467`), every button in his words. Held at 4 because the Settings footer recites the free tier — "One plate a day and the first forty of the run" (`RootView.swift:116-118`) — and the daily's margin reads `PLATE 2719` (`qa/04-first.png`), which is a day number, not a plate. |
| Craft | 3 | Hierarchy and rhythm are right and dark mode is designed. Largest text is not: in `qa/design/ax-01-line.png` the today card's button is a column reading "Ba / ck / to / th" and the date breaks "SEPTE / MBER"; in `ax-02-win.png` the print sheet grows past the screen and the headline sets on top of it. At the default size "Rule the next plate" already wraps to two lines on the margin card (`qa/02-win.png`). |
| First minute | 3 | Onboarding is not captured — `qa/04-first.png` is the uncut daily, which is the first *plate*, not the first *minute*. On it the teaching is faint: the ghost crosshatch is there, the "copper thread" is a 2 pt bar beside clue one (`BedView.swift:232-239`), and the floating burin is the whole `burin.svg` — plate and all — pasted at 58 pt in the paper's corner (`BedView.swift:79-86`), which reads as a misplaced thumbnail rather than a tool on the bench. |
| Escalation | 4 | `ladder.png` is four different games: 3×4 with five direct clues → 4×4 with either/or at depth 6 → 5×6 with arithmetic at depth 9 → 5×6 with exclusive-or at depth 14. All five dials are read by `Play.shape(at:)` (`Record.swift:21-28`); `flattensAt` is 270 and stated. Not 5: the last two panels share a shape and the strip cannot show the sealed clues or the depth that separate them, and the free run stops at 40 with only the daily's week (14–205) climbing past it for a non-payer. |
| Pull | 3 | The next plate is genuinely chosen — `Mastery.next` over the seven kinds, avoiding last plate's (`Bench.swift:154-158`), the generator scoring sets by how hard they lean on `want` (`Generator.swift:79-85`). But the ending's promise is hollow three times out of six: `hasEarned` is consulted for `burnisher` and `chine` only (`Bench.swift:495`, `PullView.swift:292`, `LineView.swift:95`). Pencil, aquatint and edition are blurbs on a shelf (`RunView.swift:156-178`). |

## Slop tells present

- **The business model inside the product.** `RootView.swift:116-118`, visible in `qa/07-shop.png`'s footer
  position when free: "One plate a day and the first forty of the run. Every print you have pulled stays on
  the line." The paywall and onboarding page 3 carry the promise; a Settings footer may not.
- **An ending that names what never arrives.** `Record.swift:54-63` promises the pencil at 4, the aquatint at 30,
  the edition at 150; `Play.horizon` (`Record.swift:67-76`) puts them on every margin card; nothing in the
  app changes when they are reached. TASTE's fifth owed thing is "specific, earned, **true**".
- **Large text does not hold.** `qa/design/ax-01-line.png` and `ax-02-win.png` — a broken button and a headline
  set over the print. Not a frozen size (everything scales through `scaledFont` and `brandDisplay`), but a
  layout that was never looked at past `.xxxLarge`.

`tells.mjs`: 0 hard tells, 0 smells.

## The second session

- **Where the curve stops.** `Play.ladder` (`Record.swift:13-19`): members 4→6 by rung 111, categories 3→5 by 85,
  kinds 2→7 by 136, depth 2→14 by 228, sealed 1→4 from 150 to **270**. `flattensAt` is 270, past 150, and
  every dial is read in `Play.shape(at:)`. Past 270 the shape is fixed and what still changes is `want`
  (`Bench.swift:154`), which is honest and said so. A plate pulled clean advances the rung by 2
  (`Bench.swift:560`), so the ladder rewards deduction over trial. The free run stops at 40
  (`Record.swift:79`); the daily runs the published week 14/28/46/68/96/140/205 (`Record.swift:37-43`) free.
- **What chooses the next unit.** `Mastery<String>` over clue-kind ids, written on a forced cut
  (`Bench.swift:311`), a slip (`:316`) and a loupe (`:464`), read in `rule()` (`Bench.swift:154-156`) with
  `unseenShare: 0.34` and `avoiding: recentKinds`; a second `Mastery` over 32 themes avoiding the last
  three (`:157-158`). The generator deals the wanted kinds twice as often (`Generator.swift:217`), prunes them
  last (`:231-236`), and scores the surviving set on `leaning` and on measured depth against the rung's
  target (`:78-85`, `:282-284`). Nothing here is `%` over a fixed list; the only seeded uniform draw is the
  daily's theme (`Bench.swift:147`), which must be shared and is. The praise pools use `seed % count`
  (`AppInfo.swift:94`) — that is fine for lines, and the seed moves every plate.
- **What is at risk.** `Run` for one plate: a forced cut is `hit()`, an unforced or contradicting one is `miss()`
  (`Bench.swift:417-423`); a miss appends a scar that prints (`:314`, `PullView.swift:65-73`); the tier is
  `run.tier(score: longestChain, beating: bestLine)` and a scarred or burnished plate can never be a best
  (`Bench.swift:526-531`). Losing costs the clean sheet, the line, and one hairline on this print. The rung
  still advances, the plate still pulls, nothing earned is lost, and the burnisher at twelve is a mercy
  that takes the scratch off the print and not off the record (`:498-507`). Right.
- **What is earned without paying.** `Play.earned` names six (`Record.swift:51-64`). Two are real: the burnisher
  (`Bench.swift:493-507`) and chine-collé, which colours the stock of every print (`LineView.swift:94-98`,
  `PullView.swift:290-295`, visible in `qa/01-line.png`). The line at one is the line, which exists from the
  first pull regardless. The pencil, the aquatint box and the edition are consulted by nothing:
  `grep hasEarned` finds `burnisher` and `chine` and no other id. A player at four plates is told "There is
  a pencil on the bench if you want to name them" and there is no pencil.

Why open it on Thursday: because Thursday's plate is rung 68 and Wednesday's was 46, because the next plate in
the run was built against the three clue kinds you are worst at, because yesterday's print is on the line
in yesterday's colour and today's square in the day-book is still bare copper — and, until the fix above,
*not* because the aquatint box comes down at thirty.

## Keep

- The plate. Cast marks in the heads, the two-pass crosshatch at 40° and 72° that reads as tone, the lozenge
  point with its lip, registration bands outside the bevel and never inside, the margin with its plate
  caps and 34 pt count, figures stamped into the void as blocks close. This is the app.
- The pull's result screen: the tilted print with the answer in solved rows, copper headline, the quote, the
  margin card with its lozenge rule and proof caps, filings in copper and ink rather than party colours.
- The line: 108 pt New York, prints on a cord with lozenge pegs, chine-collé stock, the day-book with a
  filled lozenge per pulled day and the registration cross on today, `214 PULLED · 31 DAYS RUNNING ·
  LONGEST 58` unasked at the foot.
- Dark mode: the copper dims and the paper goes to night; nothing is inverted.
- The engine and its honesty: solver-judged cuts, scars that print, a clean pull climbing two rungs, the
  sealed clue that bites open when the plate runs dry of forced moves, `Mastery` read by the generator.
- The voice, all of it, and every button label.
- The icon.

## Fix, in this order

1. **Make the earned things real, or stop promising them.** `Record.swift:51-64`, `RunView.swift:143-187`,
   `PullView.swift:317-375`, `LineView.swift`. Build the three: *pencil* — a `TextField` on the print's margin
   on the line (`PrintSheet`, non-compact) that writes a `title` override on `Pull`, shown in the plate caps
   under the title; *aquatint* — once earned, the cast marks on every print and on the hanging prints get a
   `CutShading(tone: 0.25)` wash under them so the figures come out in tone; *edition* — `№ 151` in the
   print's margin from the 150th, and the drying line grouped into spreads of seven with a rule between.
   If that is too much for a polish pass, cut `Play.earned` to `line`, `burnisher`, `chine` and rewrite
   `Play.horizon` so no card names a thing that does not arrive. Next capture: `01-line.png` at 214 pulls
   shows numbered, toned, titled prints; a `-rung 5` capture's margin card names something that the
   `-rung 51` line visibly has.
2. **Largest text.** `LineView.swift:144-166`: read `dynamicTypeSize.isAccessibilitySize` as `Legend` already
   does (`BedView.swift:124-140`) and stack the today card vertically — portrait, caps, title, then the
   button at `maxWidth: .infinity`. `PullView.swift:233-288`: the fixed `.frame(height: 296)` is what puts the
   headline on the print; let the press size itself, and give `PrintSheet` the same
   `.dynamicTypeSize(...DynamicTypeSize.accessibility1)` cap the plate has (`PlateView.swift:280`) with the
   same one-line reason — a print is a fixed object too. Give the margin card's two buttons a `VStack` at
   accessibility sizes. Next capture: `ax-01-line.png` reads "Back to the bed" on one line; `ax-02-win.png`
   shows the print, then the headline under it, then the card.
3. **The Settings footer.** `RootView.swift:116-118`: both states read "Everything you have cut is on this phone
   and nowhere else." The free tier is stated on the paywall and nowhere else. Next capture: `07-shop.png`
   without `-pro` shows no mention of forty.
4. **The slip.** `PlateView.swift:444-460`: `.shake(trigger: bench.slips)` on the cell that skidded (keep the
   pairing of the last unforced action on `Bench`), `Haptics.soft()` is already there. Draw the skid: on a
   slip, a `Path` from the cell's centre 6 pt past its edge in `Plate.trough.opacity(0.45)`, trimmed
   0→1 on `Cut.bite`, kept for the plate's life alongside the margin scar. Next capture: a `-demo cut` with
   `slipAt` shows a hairline leaving a cell, not just one lying in the margin.
5. **The first minute.** `BedView.swift:79-86`: the burin is the whole `burin.svg` at 58 pt. Cut a second file,
   `design/art/burin-tool.svg`, the tool alone, and lay it 140 pt wide across the paper's lower edge at
   −4° with the same `ambientFloat`. `BedView.swift:232-239`: replace the 2 pt bar with a real thread — an
   anchor preference from the ghost cell and one from the clue's lozenge, and a `Path` between them in
   `highlight` at 1 pt, breathing. Add `08-onboarding` to `qa.json` with no `-onboarded` so the three pages
   and "Take the burin" are seen. Next capture: `04-first.png` shows a tool on a bench and a line from
   clue one to a cell; an onboarding capture exists.
6. **The pull's last 400 ms.** `PullView.swift:264-283`: a `@Namespace` on `RootView`, `matchedGeometryEffect(id:
   pull.number)` on the `PrintSheet` here and on the newest print in `LineView.dryingLine`, so at `.settled`
   the print travels; failing that, the print slides up and out and the line tab's newest peg pops in. Move
   the print down 30 pt so the 132 pt ghost numeral shows above it as `mock-2-win.png` has it; turn the
   press by travelling the plate 10 pt on `.press` rather than tilting it 0.6°. Next capture: `02-win.png`
   shows the numeral's top; `moment-pull.png` has more than three distinct states in twelve frames.
7. **Two words in the margin.** `Bench.swift:166`: the daily is numbered `day % 9000` and prints `PLATE 2719`.
   Number dailies by their week and day — `PLATE W38·3` — or drop the number and set `TODAY'S PLATE · 23
   SEPTEMBER · DEPTH 4`. `PullView.swift:377-382` and `PrintSheet`: "twelve points · line of twenty-six"
   reads as a contradiction because the line counts every cut and the points count only fixes. Either count
   the line in points only (`run.hit()` on `.point` cuts) or say "twenty-six cuts, twelve points, longest
   line twenty-six". Next capture: `04-first.png`'s margin has no four-digit plate; `02-win.png`'s print
   never shows a line longer than its points.

## Against the mocks

- **Mock 1, the bed.** Close. The build's plate, legend, bands, margin and clue list match the mock cell for
  cell. Flatter: the mock's `SETTLED` figures sit in the void at 22 pt with two rows; the build's are
  smaller and the void is empty in `03-bed.png` because no block has closed at that pose. The mock's margin
  shows the scar as a hairline running from the plate's edge out into the margin; the build's runs across
  "OF 12" in the caps. The three grey lozenges under the plate read as a page indicator, not a rule.
- **Mock 2, the win.** The build has the tilted print, the copper headline, the quote and the margin card.
  Flatter: the ghost numeral `24` that the mock shows rising behind the print is hidden under it; the
  mock's plate stands clear to the right showing its cuts and figures, the build's is mostly covered; the
  mock's proof strip is 24 lozenges in groups of six, the build's is 18 identical grey dots.
- **Mock 3, first.** Not captured. The mock's masthead — `CROSSHATCH` between two rules and a lozenge, the
  plate at 400 pt, "A plate a day" in New York at 42 pt, the page indicator as a cut lozenge and two ruled
  cells — is in `AppInfo.swift:100-130` and `Crosshatch.swift:17-22`, and the polish pass has to show it.
- **Mock 4, the line.** The mock's title is "The line" in New York Bold; the build's is the system large title in
  SF Pro — the first thing on the screen and the only thing on it not in the brand. TASTE keeps the
  navigation chrome standard, so this is a note, not a fix: if the polish pass wants the mock's title, set
  the nav title inline and draw the screen's own `brandFont(.largeTitle)` heading. The mock's today card
  fits on one line with a one-line button; the build's title and button both wrap at the default size.
  The mock's prints overlap the hero's lower third; the build's hang just under it, which is fine.
- **The tab bar.** The mock names the fourth tab "Shop" with a small sun; the build uses `lightbulb.max`,
  which says "ideas" and not "the shop". `wrench.and.screwdriver` or `lamp.desk` would be the engraver's.
