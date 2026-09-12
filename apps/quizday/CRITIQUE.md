# Quizday · critique

**Verdict: pass.** It is a morning newspaper — newsprint with grain and column rules, New York
throughout, a stamp that lands off-axis on the box you pressed, a pencil that circles the line
you missed — and you would know it from one crop of any screen. What most decides it is that
the desk behind the paper is real: `Desk.swift` reads a ladder that climbs to edition 153 and a
`Mastery` that picks tomorrow's ten from what has been catching you, so the front page's closing
line — "Geography has caught you nine times. It leads tomorrow." — is a true sentence rather
than a flourish.

| | Score | Evidence |
| --- | --- | --- |
| Idea | 5 | Every screen is the paper: masthead and dateline on Today, the section line of inks, `THE FILE` with a month printed in ink density, `LATE EDITION · SET FROM YOUR OWN CORRECTIONS` (`qa/01-today.png`, `qa/04-scorecard.png`, `qa/10-late-edition.png`). |
| Look | 5 | Newsprint ivory with paper grain, a lamp glow and two hairline column rules; one ruled-box shape at radius 6 at four sizes; brass as a real second voice; dark is night press stock with warm type, not an inversion (`qa/design/dark-03-result.png`). |
| Signature interaction | 5 | The ink press is built beat for beat — a gradient-masked sweep with the type knocking out to paper, `Haptics.rigid()` at 200 ms, `.pop`/`.miss` at 210 ms, the stamp on `Motion.bouncy` with a `thud`, the pencil ellipse trimmed 0→1, the tally's tone climbing with the running count (`QuestionSheet.swift:323-356`, caught in `moment-answer.png` frames 13–18). |
| Reward | 4 | The edition prints over ~1.5 s — press rule, masthead, `CountUp` to 112 pt with a climbing scale, the tally square by square, the tier stamp at −3°, shredded newsprint, the brass ribbon (`EditionView.swift:327-349`; the still is `qa/03-result.png`). Held at 4 because the win filmstrip never reaches it — see below. |
| Voice | 5 | The night editor, ten praise lines and eight near-miss drawn without replacement (`Voice.swift:9-32`), five tier headlines with their own sublines, and buttons that say what happens: "Open today's edition", "Print the edition", "Pull the corrections", "Turn the page". The promise appears once, on the paywall. |
| Craft | 4 | Hierarchy, rhythm and rules are excellent and every pair is contrast-checked, but the largest text size breaks the head of the most-visited screen: `GENERAL KNOWLE / DGE` splits mid-word and `Q4 OF 10 · E…` truncates (`qa/design/ax-02-question.png`). |
| First minute | 4 | Three drawn pages in the brand, no promise recited, then box A breathes ink with no label anywhere telling you to tap (`QuestionSheet.swift:364-367`). Onboarding page one carries a dead band above the masthead (`qa/07-onboarding.png`). |
| Escalation | 4 | `flattensAt` is 153 and the mix demonstrably moves across `ladder.png`: 4·4·2 → 4·4·2 → 3·4·3 → 1·3·6, with the section line reordering to her weakest sections. Held at 4 because the first rung is at edition 39, so panels 1 and 2 are interchangeable. |
| Pull | 4 | A chain that costs only this edition's headline (`Tier.forEdition`, `Voice.swift:118-123`), three doors opened by playing and none by paying (`Desk.swift:34-47`), and a page that ends on what is waiting with the clock demoted below the fold (`EditionView.swift:203-224`). |

## Slop tells present

None.

`node tools/design/tells.mjs quizday` → 0 hard tells, 0 smells. Checked by eye as well: the canvas
is paper with grain and column rules, never `systemGroupedBackground`; no SF Symbol is the hero
of onboarding, an empty state, the result or the paywall (six drawn SVGs do that work); the
result is a front page, not "8 out of 10" over "come back tomorrow"; the Scorecard replaces three
number tiles with one 96 pt streak and a mono ledger line; praise comes from pools; the icon is a
drawing of the idea; and there is not one frozen point size in the app — every size goes through
`scaledFont` or `brandDisplay`.

## The second session

- **Where the curve stops.** Edition 153, honestly and by construction: `settled` last moves at
  rung 151 and `hard` at rung 153 (`Desk.swift:27-30`, `Ladder.lastChange`). Edition 1 is
  4 easy · 4 medium · 2 hard, edition 60 is 3 · 4 · 3, edition 200 is 1 · 3 · 6 — all three
  visible in `qa/design/ladder.png`, all three produced by `Desk.difficulties(at:)`
  (`Desk.swift:240-245`), and the pack carries the content to pay for it (165 hard of 450).
  Past 153 the shape is fixed and the *choice* carries it.
- **What chooses the next unit.** `DailyPack.slate(for:)` seeds the whole pack into a per-date
  order (`Pack.swift:87`), then `byWeakSection` pulls her weakest sections to the front and
  `Mastery.next(from:count:unseenShare:0.7,avoiding:)` picks from it (`Desk.swift:197-213`,
  `Mastery.swift:75`). No `%` over a count, no uniform random, and the last 140 ids are excluded
  so nothing returns inside a fortnight (`Desk.swift:65`). `difficulty` is read, not decorated.
- **What is at risk.** `Run` — the chain and the clean sheet, for the length of one edition
  (`TodayView.swift:21,289-290`). Losing it costs this edition's headline and nothing else: a
  nine that sets her longest chain prints `EXTRA! EXTRA!` where a nine without one prints
  `STOP THE PRESS` (`Voice.swift:118-123`). No life, no streak, no tomorrow, nothing to buy back.
- **What is earned without paying.** The late edition at seven editions filed, eight questions at
  twenty-five, and her own choice of section at sixty — gated on `Desk.earned`, never on the
  store (`Desk.swift:34-47`, `EditionView.swift:227`, `LateEditionView.swift:34`). The only
  `store.isPro` gate in the app is Practice (`PracticeView.swift:28`), which is a fine door but
  no longer the only one.

Why someone opens this on Thursday: because the paper leads with the section that keeps catching
her, it says so on the way out — "Geography has caught you nine times. It leads tomorrow." — and
five of her own misses are sitting on the spike for the evening.

## Keep

- The ink press, exactly as it is: the knockout type under the sweep, the stamp landing on the
  rule of the box she pressed and never over the correct line, the pencil circle and strike, and
  the tally tone climbing with the running count. Do not touch the timings.
- Red as the stamp on both a right and a wrong answer, with proof green for the printed line and
  graphite for the pencilled-out one. The colour that dominates the screen carries no judgement,
  and it is the single best decision in the app.
- The front page as the result screen, and the fold: the horizon line above, the countdown small
  and quiet below it.
- The dark palette. It is designed, not inverted, and the share card correctly stays on paper.
- The ledger line on the Scorecard and the month as ink density rather than a tint of the accent.
- "Turn the page" and "Start 3-day free trial" — the kit's words never reach the first or last
  screen.

## Fix, in this order

1. **The win is never on camera.** `qa/design/moment-win.png`: frames 1–4 catch the tenth answer
   landing, then frames 5–20 are pixel-identical on the answered question sheet with "Print the
   edition" still showing. The page goes to press at `at(12.0)` (`TodayView.swift:261`) against
   `delay: 9.0, frames: 20, interval: 0` (`qa.json:66-72`), and twenty fast screenshots of a
   static sheet run out before 12 s. Move the print to `at(9.5)` and drop the moment's `delay`
   to `7.5`. Fixed when `moment-win.png` shows the masthead setting, the score part-way through
   its count-up, and the burst in three different frames.
2. **Largest text breaks the head of the question sheet.** `qa/design/ax-02-question.png`:
   `GENERAL KNOWLE / DGE` breaks mid-word across three lines and pushes everything down, while
   `Q4 OF 10 · E…` truncates beside it and the section's 3 pt ink tick clips to a sliver. In
   `QuestionSheet.swift:135-155` the section mark has no Dynamic Type ceiling. Give the whole
   `sectionMark` row `.dynamicTypeSize(...DynamicTypeSize.accessibility1)`, add
   `.minimumScaleFactor(0.8)` and `.lineLimit(2)` to the category, and raise the `Q4 of 10`
   label's `minimumScaleFactor` to `0.6` so `EASY` survives. Fixed when `ax-02` reads
   `GENERAL KNOWLEDGE` on one or two whole-word lines with `Q4 OF 10 · EASY` complete.
3. **The printer's fist is an emoji.** `RootView.swift:30` passes `"\u{261E}"` to
   `PaywallBullets.ruled`, and `Text(mark)` (`FactoryKit/…/PaywallView.swift:96`) renders it in
   emoji presentation — three cartoon hands in blue, pink and teal on the paywall and the
   composing room (`qa/05-paywall.png`, `qa/06-practice.png`, worst in
   `qa/design/dark-05-paywall.png`). It is the one piece of clipart in an app of drawn art, and
   it is on the buying screen. Draw the fist as a small SwiftUI `Shape` in `Paper.swift` and pass
   it through, or force text presentation (`"\u{261E}\u{FE0E}"`) so it takes the section ink.
   Fixed when all three marks are the same drawn form in three of the brand's extras.
4. **The ladder's first rung is five weeks out.** `hard` steps `every: 38` and `settled` every
   50 (`Desk.swift:28-29`), so editions 1 through 38 are all 4 · 4 · 2 — which is why panels one
   and two of `ladder.png` (0 filed and 9 filed) are interchangeable. Bring the first step in:
   `.init("hard", from: 2, by: 1, every: 26, opensAt: 1, ceiling: 6)` puts the paper's first
   visible hardening at edition 27 and still leaves `flattensAt` at 131 — over the gate and five
   months out. Fixed when `ladder.png`'s second panel reads a different mix from its first.
5. **Settings is the one screen where the newspaper stops.** `qa/08-settings.png`: white capsule
   cards floating on newsprint under a sans-serif "Settings" large title, while every other
   screen is ruled boxes and New York. Give the kit's `SettingsView` the ruled-box treatment the
   paywall bullets got — `.brandSurface()` rows at corner 6 with hairline separators — or at
   minimum set the navigation title in the paper's own words ("The desk") so the seam is smaller.
   Fixed when `08-settings.png` has no white rounded card on it.
6. **Onboarding page one opens on a dead band.** `qa/07-onboarding.png`: roughly 380 px of empty
   paper sits above the masthead before anything is said, and the press is drawn smaller than
   `mock-3-first.png` promised. `AppInfo.swift:22` reserves `artHeight: 400` for a stack that
   measures about 340. Set `artHeight: 340` and `HandPress(width: 330)` so the press fills its
   slot the way the mock does. Fixed when the masthead sits within ~120 px of the safe area top.
7. **The paywall says the same thing twice, under an SF Symbol.** The subhead
   "Set your own rounds, any night of the week." (`RootView.swift:32`) is bullet one
   (`AppInfo.swift:55`) reworded, so the first two lines of the buying screen are a duplicate;
   and the promise is led by `hand.raised.fill` (`FactoryKit/…/PaywallView.swift:144`), the only
   SF Symbol on a page of drawn art. Give the subhead the editor's own line — *"The paper is set
   here, the night before."* — and lead the promise with a hairline rule instead of the symbol.
   Fixed when `05-paywall.png` has no repeated phrase and no raised hand.

Smaller, below the line: in dark mode the pencilled-out answer (`miss` at `#9C968A`) is the
brightest block on the sheet, so the error reads louder than the correction
(`qa/design/dark-02-question.png`) — drop it toward `#6A655C` in dark. And `-sampleData` seeds
`CategoryStat` and `DayResult` but not the `Desk`, which is why Settings reports
"Editions filed 19 / Questions you have seen 0" — a capture artefact, but it makes a shipped-
looking screen read as broken. There is no capture of Practice unlocked, so the accuracy table —
the one place a per-section number is *shown* rather than acted on — went unjudged.

## Against the mocks

- **mock-1-play → 02-question.** The build meets it and beats it. The stamp is clamped to 190 pt
  and dropped onto the box's bottom rule, so a long near-miss line no longer lies across the
  answer and runs off the page the way it does in the mock; the answer type is full ink rather
  than the mock's grey; and the run line (`RUN BROKEN` with its lozenges struck in the same
  pencil) is in the build and not in the mock at all.
- **mock-2-win → 03-result.** Matched, then extended: the build adds the fold, the horizon line
  and the late-edition box that the mock does not have, and deliberately shrinks the countdown.
  One thing is flatter — the mock's burst is larger and more varied (squares, triangles,
  ellipses, a brass scrap), where the build's reads as fine specks around the masthead. Raise
  the scrap size rather than the count.
- **mock-3-first → 07-onboarding.** The only screen flatter than its mock. The press is smaller
  and the page opens on empty paper (fix 6). The copy is better than the mock's: "Continue"
  became "Turn the page", and "the same ten for everyone" became "dated and set fresh each
  morning", which is now the true sentence — the desk personalises the sheet.
- **Screens with no mock** — the Scorecard, the late edition and the composing room — hold the
  same standard as the three that had one.

*Which screenshot goes first: `03-result.png`. A serif 8 at 112 pt, ten ink squares, `STOP THE
PRESS` stamped crooked in red and a brass ribbon, on paper. Nothing else in Trivia looks like it,
and it is the one a stranger would ask about.*
