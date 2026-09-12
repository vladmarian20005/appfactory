# Quizday · critique

**Verdict: fail.** This is the best-looking thing the factory has made — grained newsprint under
a lamp, New York throughout, an answer that takes ink under a red stamp that judges nobody, a
front page that prints itself at 112 pt, and a night editor who never once breaks character or
mentions the business model. It fails on the one question a still cannot ask: every one of the
thirty rounds has the identical 3-easy / 4-medium / 3-hard shape, nothing in the app reads the
difficulty it prints on every sheet, and on day 31 `Pack.swift:80` deals round 1's ten questions
back in the same order, forever — so session 5, session 50 and session 500 are the same session.

| | Score | Evidence |
| --- | --- | --- |
| Idea | 5 | The edition is not a skin, it is the mechanic: masthead, dateline and section line on `qa/01-today.png`, the correction column on `02-question.png`, the month as back issues on `04-scorecard.png`. One crop of any of them says *newspaper*. |
| Look | 5 | Paper grain, a lamp glow and two column rules on every screen; brass, graphite, proof green and stamp red doing separate jobs; dark is night press stock with warm type, not an inversion (`qa/design/dark-03-result.png`). Nothing is a white card with a shadow. |
| Signature interaction | 4 | The press is all there in `QuestionSheet.swift:304-337`: the sweep on a 0.26/0.85 spring with the type knocking out through `InkSweep`, `Haptics.rigid` at 200 ms, the stamp on `Motion.bouncy` at 230, `thud` at 380, the pencil trim at 300, the tally square and `Tones.step(runningCorrect)` at 520. Held off 5 because the stamp lands across the answer she pressed (`02-question.png`, the box reading "Deezer") instead of past it. |
| Reward | 4 | `EditionView.swift:250-272` prints the page over ~1.5 s and `moment-win.png` frames 5–6 catch the score mid-count-up and then landed; five tiers, a second `Personal best` stamp in brass, newsprint-coloured confetti in `03-result.png`, and a real 1080×1350 front page in `09-share.png`. Held off 5 because the page ends on a clock, not on what is waiting. |
| Voice | 5 | Ten praise lines and eight near-miss lines drawn without replacement (`Voice.swift:7-31`), tier sublines that differ at 9 and 8, "Turn the page" instead of Continue, "¶ something wrong here?" instead of Report. The promise sentence appears on the paywall and nowhere else. |
| Craft | 3 | Dark is designed and AX5 holds and scrolls (`ax-02-question.png`). Against it: the verdict stamp runs to the screen edge and covers the answer she picked in dark and at AX5; the version footer sits half-legible under the tab bar (`dark-08-settings.png`); the hand press dissolves into the canvas in dark (`dark-01-today.png`, `dark-07-onboarding.png`); and Today, Practice and the result all end in a dead lower third. |
| First minute | 4 | Onboarding is drawn art on paper under the masthead and the first question teaches itself with an ink breath on box A and a hovering stamp, with no label anywhere (`QuestionSheet.swift:210-223, 345-348`). Held off 5 because both filmstrips open on six and two frames of flat white before the paper arrives. |
| Escalation | 1 | All thirty rounds are `easy,easy,easy,medium,medium,medium,medium,hard,hard,hard` in that order, and `Pack.swift:76-81` cycles them modulo 30. There is no `Ladder`, no curve, and the app stops changing at session 1 — then repeats verbatim at session 31. |
| Pull | 1 | Nothing is at risk during a round, nothing is chosen from what she got wrong, nothing is earned by playing, and the page ends on `Text(timerInterval:)` counting down to midnight (`EditionView.swift:180-193`). The only thing that waits is a streak that counts. |

## Slop tells present

None of the visual tells. The canvas is paper, not `systemGroupedBackground`; every hero is a
drawn SVG; the result is a printed page, not "8 out of 10" in a card; the Scorecard's stats are
one 96 pt number over a single mono ledger line, not three tiles; the icon is a stamp on
newsprint; the motion is springs. That whole list is genuinely clear.

Every tell of an app nobody opens twice, however:

- **Content chosen by `%` over a fixed array.** `ios/App/Pack.swift:80` —
  `((n % count) + count) % count` over 30 rounds. Day 31 is round 1 again, questions in the same
  order, and the sheet even says `ROUND 1` in its dateline.
- **A `difficulty` stored and shown and never read.** Written on all 300 questions, printed on
  every sheet at `ios/App/QuestionSheet.swift:137` (`Q4 OF 10 · MEDIUM`), and compared by nothing.
  `tells.mjs` reports it as a smell; the pack data makes it worse — the mix is identical in
  rounds 1, 15 and 30, so there is nothing for it to describe.
- **A ladder whose last rung arrives before the first week.** There is no `Ladder` in the app at
  all (`tells.mjs`: `no-second-session`). `flattensAt` would be session 1.
- **Every unlock is a purchase.** The only gate in the app is `store.isPro` at
  `ios/App/PracticeView.swift:28` and `:38`. Nothing arrives because someone played well.
- **Stats that accumulate where nothing consults them.** `CategoryStat` is written on every
  answer (`ios/App/TodayView.swift:273-279`, `PracticeView.swift:358-363`) and read in exactly
  one place, to draw the table at `PracticeView.swift:200-201` — behind the paywall, for a
  player who by then has no way to act on it.
- **The session cannot be lost, extended, or done badly.** No `Run`. Ten questions arrive, ten
  get answered, the tier is computed afterwards; nothing can break mid-round.
- **The end of a session is a number and "come back tomorrow."** `EditionView.swift:180-193` is a
  ruled box reading `TOMORROW'S EDITION GOES TO PRESS IN` over a live countdown. It is the
  best-set version of that tell anyone has shipped, and it is still that tell.
- **The reason to return is a streak that only counts.** `Data.swift:60-76` derives it from the
  saved days and `StreakRibbon` draws it. It changes no question, opens no door, risks nothing.

## The second session

- **Where the curve stops:** at session 1. `ios/App/Pack.swift:76-81` picks the round by
  `dayNumber % 30`, and the pack's thirty rounds all carry the same difficulty shape — round 1,
  round 15 and round 30 are each `easy ×3, medium ×4, hard ×3` in that order. Nothing anywhere
  climbs; at session 31 the content repeats word for word.
- **What chooses the next unit:** the calendar, and only the calendar
  (`ios/App/Pack.swift:80`, `:89-91`). Not what she got wrong, not what she has not seen, not
  what she just scraped. `Mastery` appears nowhere in the app.
- **What is at risk:** nothing. `Run` appears nowhere; there is no chain to break and no perfect
  to spoil during the ten. The clean-sweep bonus at `EditionView.swift:155-161` is scored after
  the fact, so it is a reward for a round already over rather than something she can feel
  slipping at question seven.
- **What can be earned without paying:** nothing. `PracticeView.swift:28` (`store.isPro ||
  LaunchOptions.forcePro`) is the only door in the app, and money is the only key. `Earned`
  appears nowhere.

**Why someone opens this on Thursday:** because it is pretty and it is a habit — which is to say,
the app has no answer of its own. It cannot tell her that Geography keeps catching her, cannot
put a hard sheet in front of her because she has earned one, cannot hold anything back for her to
reach. It offers a countdown and a number that got one bigger. Pull is 1.

## Missing captures

`qa/design/ladder.png` was not produced, and `qa.json` defines no ladder capture — there are only
the two `moments`. That absence is itself the finding: there is no depth dial to film. Escalation
and Pull are scored from `Pack.swift`, the pack data and the absence of `Ladder`/`Mastery`/`Run`/
`Earned`, which are unambiguous without the strip. Everything else was judged from all nine light
screens, all nine dark, both AX screens, both filmstrips, the icon and the three mocks.

## Keep

Nearly all of it. This is a look worth protecting, and the next pass must not flatten it to make
room for mechanics.

- The paper canvas: grain, lamp glow, column rules, `corner: 6`, the ruled box at four sizes, the
  printer's ornament closing a short column.
- New York everywhere with SF Mono uppercase tracked as the third voice, and the 112 / 96 / 88 pt
  hero numbers.
- The ink press, beat for beat — the knock-out sweep, the off-axis stamp, the pencil correction in
  graphite, the footnote rule drawing itself, the tally square with `Tones.step(runningCorrect)`
  so a good round climbs the scale audibly.
- The decision that **red never means wrong**: proof green for right, graphite and a pencil for
  wrong, red reserved for the stamp that lands either way.
- The night editor: both pools, without replacement, and every button label he wrote.
- The Scorecard's month printed at three ink densities with today circled in pencil, and the
  single mono ledger line in place of stat tiles.
- The share front page and the drawn icon.

## Fix, in this order

1. **Make day 31 ten questions she has not owned, not round 1 again.**
   `ios/App/Pack.swift:76-91`. Delete `roundIndex`'s modulo and serve the day from
   `Mastery.next(from:count:avoiding:)` over all 300 question ids, seeded by the day key so the
   edition is still the same ten for everyone on the same date, weighting what she got wrong,
   what she has never seen, and what she got right slowly. Record every answer with
   `mastery.record(_:correct:)` where `CategoryStat` is written today
   (`TodayView.swift:273-279`). Grow the pack past 300 in the same pass. *Next capture:* a
   `ladder.png` in which the day-31 sheet is not the day-1 sheet.
2. **Give the difficulty something to do.** Add `Ladder([.init("hard", from: 3, every: 12)])`
   keyed on editions filed, and let it choose the easy/medium/hard mix the selector filters
   `QuizItem.difficulty` on, so the shape moves from 4/4/2 at edition 1 toward 1/3/6 past
   edition 150 and `ladder.flattensAt` clears the gate. The word printed at
   `QuestionSheet.swift:137` then describes a real decision. *Next capture:* `ladder.png` shallow
   to deep shows the section line and the `Q4 OF 10 · HARD` mark changing across panels.
3. **Put the round at risk, and only the round.** Adopt `Run` in `TodayView`: `hit()` / `miss()`
   per answer, `chain` and `isClean` printed as a short mono chain beside the tally at the head
   of the sheet, drawn in ink and pencilled out with the same `PencilStrike` the wrong answer
   gets. A broken chain costs this edition's tier and nothing else — no life, no streak, no
   tomorrow. `Tier` then reads `run.tier(beating:)`. *Next capture:* `02-question.png` shows the
   chain beside the tally; `moment-answer.png` shows it struck on the miss.
4. **Open one door with play instead of money.** `Earned` at, say, seven editions filed: a free
   **late edition** — five questions built from what got past her, available the evening of any
   day she has filed — which is finally something `CategoryStat` chooses. Keep Practice behind
   the paywall; a paywall is a fine door, it just cannot be the only one. *Next capture:* a new
   screen in `qa.json` showing the late edition unlocked with no purchase.
5. **End the edition on what is waiting, not on a clock.** Above the countdown at
   `EditionView.swift:180-193`, one line from `earned.next(after:)` in the editor's voice —
   *"Nineteen filed. The late edition opens at twenty-one."* / *"Geography has caught you four
   times. It leads tomorrow."* — specific, earned, true, no guilt. Keep the countdown below it,
   smaller. *Next capture:* `03-result.png` names something that is not a time.
6. **Three craft blemishes, one commit.** (a) Clamp the verdict stamp at
   `QuestionSheet.swift:181-189` to `frame(maxWidth: 190)` anchored bottom-trailing with
   `.offset(x: 10)`, so "Half a lead, no story." stops covering the answer she pressed and stops
   reaching the screen edge in dark and at AX5. (b) Clear the version footer from behind the tab
   bar in Settings (`dark-08-settings.png`) with a bottom `safeAreaInset` spacer. (c) Give
   `press-body.svg` its own outline stroke in `ink` for dark, or draw its frame in `surface` —
   in `dark-01-today.png` and `dark-07-onboarding.png` the press is navy on navy and the hero of
   the first screen disappears. *Next capture:* the stamp clears the answer; no type under the
   tab bar; the press reads as a silhouette in both modes.
7. **Fix what the strips can see.** Add a `ladder` capture to `qa.json` (the question sheet at
   editions 1, 10, 60 and 200) — there is currently none, which is why Escalation had to be read
   entirely from code. Move the `-demo answer` presses to 6/10/14 s with `delay: 4.0` so the
   0–220 ms ink sweep lands mid-frame instead of between frames, and move `-demo win` to 8/12 s
   so the confetti burst at ~1.24 s is on camera. Both strips currently open on flat white — hold
   the paper canvas from the launch screen so the app never shows white. *Next capture:*
   `moment-answer.png` shows a box half-inked; `moment-win.png` shows the paper flying; neither
   opens white.

## Against the mocks

- **Question sheet (`mock-1-play.png` → `02-question.png`)** — very close, and the build adds
  grain the mock only suggests. One regression: in the mock the stamp hangs off the right margin
  beside "The Thar" and leaves the answer legible; in the build it lies across the box, and in
  dark and at AX5 it runs into the screen edge. The mock's ruled tally squares are also a touch
  larger and read better at a glance.
- **The edition (`mock-2-win.png` → `03-result.png`)** — the build has everything the mock
  promised and the confetti is better than drawn. Flatter in two places: the tier stamp is about
  half the page width against the mock's three-quarters, so `STOP THE PRESS` reads as a caption
  rather than as a headline slammed onto the page; and the streak ribbon is drawn at a fixed
  width, so at `1 DAY RUNNING` it is a wide brass slab around a small number — the mock's ribbon
  fits its "12". The dateline also comes out as `SATURDAY, SEPTEMBER 12` where the mock set
  `THURSDAY 11 SEPTEMBER`; the comma-and-month-first form is a system date, not a masthead.
- **Onboarding (`mock-3-first.png` → `07-onboarding.png`)** — the build beats the mock: the
  button says "Turn the page" where the mock still said "Continue". Flatter in composition: the
  press is drawn smaller than the mock's, leaving a band of empty paper above the masthead rule
  and a second one under the subtitle, where the mock fills the sheet.
- **Not mocked, and the weakest screen: the paywall.** `05-paywall.png` is the kit's layout in
  the brand's colours — a rounded surface panel with `checkmark.circle.fill` bullets, where the
  Practice screen next door sets the same three lines as ruled rows led by a printer's fist. The
  desk art and the headline carry it; the bullets are the one place in the app where the
  newspaper stops.
</content>
