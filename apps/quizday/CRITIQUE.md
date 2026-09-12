# Quizday · critique

**Verdict: fail.** It is the best-looking app the factory has made — a morning newspaper you
would know from one crop of any screen, set in New York on grained newsprint under a lamp,
with a night editor talking over it who never once breaks character. And it is over on day 31:
`DailyPack.roundIndex` deals round 1's ten questions back in the same order forever
(`Pack.swift:80`), nothing in the app reads the `difficulty` it prints on every sheet, and
there is no `Ladder`, `Mastery`, `Run` or `Earned` anywhere in it — so the paper that promises
a fresh edition every morning is the same thirty papers on a loop.

| | Score | Evidence |
| --- | --- | --- |
| Idea | 5 | Masthead, dateline, ruled answer boxes, a pencilled correction, "the file", "the composing room" — `qa/01-today.png` and `qa/04-scorecard.png` are unmistakably one world, and it is a world no competitor in this category is in. |
| Look | 4 | Newsprint with grain, column rules and a lamp glow; six section inks on the section line; brass as a real second voice; dark designed as night press stock, not inverted (`dark-01-today.png`). Held at 4 because the paper stops at the kit's Settings and paywall — white/dark rounded cards and red `checkmark.circle.fill` bullets where every other screen is a 1.2 pt ruled box at radius 6 (`qa/05-paywall.png`, `qa/08-settings.png`). |
| Signature interaction | 3 | The code is exactly DESIGN.md's beat table — sweep on `.spring(response: 0.26)`, `Haptics.rigid()` at 200 ms, the stamp on `Motion.bouncy`, the pencil `.trim`, the tally with `Tones.step(runningCorrect)` (`QuestionSheet.swift:304-337`) — and the still is lovely. But `moment-answer.png` is **eighteen blank white frames**: the press has never once been filmed, across two polish passes. Nothing available shows it lands. |
| Reward | 4 | Not a sheet with a checkmark: the front page prints — 112 pt score, the tally, the tier stamped at −3°, shredded newsprint, a brass ribbon, five tiers with different bursts and tones and a second `PERSONAL BEST` stamp (`EditionView.swift:250-272`), and a real 1080×1350 front page to send (`qa/09-share.png`). Held at 4: `moment-win.png` is printed by frame 2 and then seventeen frames where only the clock changes, so the 1.5 s choreography is unfilmed too, and the ribbon is a 260 pt brass slab reading "1 DAY RUNNING" instead of the editor's "Day one on the desk." |
| Voice | 5 | "Filed." · "Half a lead, no story." · "The file is empty / Play an edition and it gets spiked here, dated." · "One knock at the door, at the hour you choose." · "Turn the page" where the kit says Continue. Pools of ten and eight drawn without replacement (`Voice.swift:50-63`); the promise appears on the paywall and nowhere else. |
| Craft | 3 | Hierarchy and rhythm hold and dark mode is designed, but four defects named in the last critique are all still here: the verdict stamp runs off the screen edge and covers the answer it lands on (`dark-02-question.png`, `ax-02-question.png`); at AX5 the section line is cut by the tab bar and the primary button is pushed off the first screen entirely (`ax-01-today.png`); the version footer sits behind the tab bar (`dark-08-settings.png`). |
| First minute | 4 | Onboarding is the drawn press on paper ending in "Turn the page"; Today opens on a turning flywheel, a dateline and one button; the first question teaches itself with a breathing ink box and a hovering stamp and no label anywhere (`QuestionSheet.swift:345-348`). The promise it makes is kept — for thirty days. |
| Escalation | 1 | `Pack.swift:80` is `((n % count) + count) % count` over 30 rounds, and inside those 30 there is no climb either: every single round is the same difficulty shape, `eeemmmmhhh`. No `Ladder` exists in the app. It flattens at session 1 and repeats verbatim at session 31. |
| Pull | 1 | The only thing that carries is a streak counter that counts. Nothing is earned by playing — the one unlock in the app is `store.isPro` (`PracticeView.swift:28`). The session ends on a number and a clock. |

## Slop tells present

- **Content chosen by `%` over a fixed array** — `Pack.swift:80`. `tells.mjs` FAIL `content-modulo`.
- **Nothing decides what comes next from what the player has done** — no `Ladder`, `Mastery`,
  `Run` or `Earned` in `apps/quizday/ios/App/`. `tells.mjs` FAIL `no-second-session`.
- **A `difficulty` stored and shown and never read** — printed on every sheet at
  `QuestionSheet.swift:137`, carried through `Pack.swift:12,27`, and compared by nothing.
  `tells.mjs` WARN `metadata-difficulty`.
- **A ladder whose last rung arrives in the first week** — there is no ladder; the curve is
  flat from rung 1.
- **Every unlock in the app is a purchase** — `PracticeView.swift:28`, the only gate.
- **Stats that accumulate where nothing consults them** — `CategoryStat` is written on every
  answer (`TodayView.swift:272-282`) and read in exactly one place, to draw the accuracy table
  (`PracticeView.swift:200-201`), which is itself behind the paywall. It chooses nothing.
- **The session cannot be lost, extended or done badly** — `answer()` appends to `flags` and
  that is all (`TodayView.swift:247-254`). There is no chain, no clean sheet named while you
  play, nothing that can break.
- **The reason to return is a streak counter, and the streak does nothing but count** —
  `Streaks.current` (`Data.swift:60`) feeds a ribbon and a ledger line and no decision.

Not present, and worth saying: no gray canvas, no SF Symbol heroes, no number-tile stats, no
win in a sheet, no frozen point sizes, no text-on-a-gradient icon, no praise that repeats, and
no business-model copy anywhere but the paywall.

## Missing captures

- **`qa/design/ladder.png` does not exist**, and `qa.json` declares no `ladder` — because
  there is nothing to film shallow-to-deep. That absence is the finding, not an excuse: the
  app has no depth axis to photograph.
- **`moment-answer.png` is eighteen identical blank frames.** The signature interaction has
  never been captured.
- **`moment-win.png` is one frame of question ten and seventeen frames of the finished page**
  where only the countdown ticks. The press rule, the count-up, the tally printing, the stamp
  landing, the confetti and the ribbon are all off camera.

Scored what is visible. I have not assumed the unfilmed motion is good.

## The second session

**Where the curve stops:** at session 1. `DailyPack.roundIndex` (`Pack.swift:80`) is
`((n % count) + count) % count` with `count == 30`, so day 31 deals day 1's ten questions in
the same order, forever — the exact failure TASTE.md names this app for. Worse than a ladder
that flattens late: the 300-question pack has an identical `eeemmmmhhh` difficulty shape in
29 of its 30 rounds (round 24 is `eeeemmmhhh`), so round 30 is no harder than round 1.
`Ladder.flattensAt` has nothing to compute.

**What chooses the next unit:** nothing. `items = DailyPack.items(for: today)`
(`TodayView.swift:238`) reads the day's round straight off the array in file order. There is no
`Mastery`. The one record of how the player is doing, `CategoryStat`, is written on every
answer (`TodayView.swift:272-282`) and read only to draw a table (`PracticeView.swift:200-201`).

**What is at risk, and what losing it costs:** nothing named. There is no `Run`, no chain, no
"still clean" state on the sheet. The thinnest version survives — a perfect spoils, because
`Tier.extra` needs all ten (`Voice.swift:82-90`) — but the app never says so while you play,
so nothing is felt to be at stake. When it goes it costs only the run, which is right; there
is just nothing there to go.

**What can be earned without paying:** nothing. Grep the gates and there is one:
`store.isPro` at `PracticeView.swift:28`. Practice, the accuracy table and the difficulty
picker are all behind it. No mode, no section, no title, no piece of the world arrives because
someone played well.

**Why someone opens this on Thursday:** because the paper comes every morning and this one is
handsome — which works until the morning they recognise the questions, and then there is no
answer at all. The ending names a clock ("Tomorrow's edition goes to press in 6:08:52") and
never what is waiting in it. Compare Thousand's standard: *"The bench is swept. Twenty-two
tiles are drying, eleven are ready tomorrow."*

## Keep

- **The whole look.** The newsprint canvas with its grain and column rules, New York
  throughout, the mono dateline as a third voice, the ruled box at radius 6 repeated at four
  sizes, the printer's ornament closing short pages, the six section inks, brass as the second
  voice. Dark mode as night press stock. Do not touch any of it.
- **The night editor.** Every string in `Voice.swift` and `AppInfo.swift`, the empty states,
  the button labels, the reminder copy. This is the best voice in the repo.
- **Red that judges nobody.** The stamp lands red on a hit and a miss alike; right takes proof
  green, wrong is pencilled out in graphite. That decision is why this screen does not look
  like every other quiz app, and it must survive.
- **The correction.** The hand-drawn two-arc ellipse and strike, reused to circle today on the
  calendar. One idea doing two jobs.
- **The front page share card** (`ShareEdition.swift`) and the printed month
  (`ScorecardView.swift:242-270`) — both genuinely worth screenshotting.
- **The reward's tier structure** in `Voice.swift:79-143`. Five tiers that differ in burst,
  tone, stamp angle and masthead rule is real choreography; it only needs filming.

## Fix, in this order

**1 · Stop dealing the same ten. Choose them.** `Pack.swift:80`, `TodayView.swift:238`.
Replace `roundIndex`/`items(for:)` with `Mastery<String>` over all 300 question ids, persisted
next to `CategoryStat`: `mastery.record(id, correct:)` on every answer (extend
`TodayView.answer`), and build the round with
`mastery.next(from: pool, count: 10, unseenShare: 0.5, avoiding: lastSeven)`. This keeps the
daily edition free and dated but makes day 31 ten questions pulled toward what you got wrong
and have not seen, in an order that is not day 1's. Two things to settle while doing it:
SPEC.md's "the same ten for everyone" can no longer be literally true for a personalised round
— either state the edition as *your* edition in the dateline, or keep a shared spine of six
date-seeded questions and let `Mastery` choose the other four; and 300 questions is not enough
pool for either, so `pack/build.py` has to run again to at least 1,000. SPEC.md:66 already
books this for v1.1; it is v1.0 work now. Next capture: `ladder.png` at sessions 5 / 50 / 500
shows three different sets of ten.

**2 · Give it a ladder, and make the printed `difficulty` mean something.** New
`Ladder([.init("hard", from: 1, every: 12, opensAt: 1, ceiling: 6), .init("medium", from: 3,
every: 20, opensAt: 8, ceiling: 8), .init("pool", from: 60, by: 40, every: 5, opensAt: 1)])`
keyed on editions filed, read where the round is assembled so the mix climbs from `eeeemmmmmh`
at session 1 to six hard at session ~150. The `difficulty` string on `QuizItem` becomes the
thing the selector filters on instead of a caption at `QuestionSheet.swift:137`. Say in
DESIGN.md what sessions 5, 50 and 500 are like and where it stops. Next capture: `tells.mjs`
loses `content-modulo`, `no-second-session` and `metadata-difficulty`.

**3 · Put something at stake on the sheet.** Adopt `Run` in `TodayView`: `run.hit()` /
`run.miss()` in `answer()`, and print the chain where the editor would — a mono line beside
the tally, `SET CLEAN · 6`, that pencils itself out on a miss with the same `PencilStrike`
already in `QuestionSheet.swift:201`. Feed `run.tier(beating: bestScore)` to `EditionView`
instead of raw score, so a clean sheet and a new best are different front pages. It costs the
run and nothing else — no life, no progress, never tomorrow. Next capture: `02-question.png`
carries a live chain; `moment-answer` shows it break.

**4 · Open one door with play instead of money.** `Earned([.init(id: "latenight", title: "The
late edition", blurb: "Ten more, set from what got past you.", at: 7), .init(id: "archive",
title: "The morgue", blurb: "Every edition you have filed, reopenable.", at: 21), .init(id:
"nightdesk", title: "Night desk", blurb: "The paper, set after dark.", at: 50)])` keyed on
editions filed. Make **the late edition** free and adaptive — a second round built from the
questions you missed, which is where the `CategoryStat` data finally chooses something. The
paywall stays a fine door for the composing room; it stops being the only one.

**5 · End the session on what is waiting.** `EditionView`, under the tier subline and above
the fold: `earned.next(after: editionsFiled)` in the editor's voice — *"Nineteen filed. The
morgue opens at twenty-one."* — replacing the countdown box as the last thing the page says.
Keep the clock; demote it. The ribbon at `EditionView.swift:72-81` prints
`Voice.streak(streak, todayPlayed: true)` ("Day one on the desk.") and sizes to its type
instead of a 260 pt brass slab.

**6 · Cap the stamp and hold the largest text.** `QuestionSheet.swift:181-189`: give `Stamp` a
`frame(maxWidth: 190)` with `minimumScaleFactor(0.8)` and anchor it `.bottomTrailing` on a miss
too, so "Close. The desk has it here." stops covering the answer and running off the screen
(`dark-02-question.png`). `TodayView.swift:67`: clamp `SectionLine` to `.accessibility2` and
let it wrap inside the column rules; pad the sheet's scroll content so answer D clears the
bottom strip (`ax-02-question.png`). `RootView` Settings: clear the version footer from behind
the tab bar.

**7 · Film the two moments.** `qa.json`'s `answer` moment produces eighteen white frames and
`win` produces seventeen identical ones. The demo presses at 1.8 / 3.4 / 4.2 s and the win at
2.0 / 3.6 s (`TodayView.swift:193-231`) are both outside the camera's window. Move them to
6 / 10 / 14 s and 8 / 12 s, raise `frames` to 24, and set `delay` to 4.0 so the first frame is
a live sheet, not a launch screen. Until this passes, no reviewer can see the one thing
DESIGN.md spends its longest table on.

## Against the mocks

- **`mock-1-play` → `02-question.png`:** matched, and in light mode improved on — the knocked-out
  type, the proof-green fill, the pencil ellipse and strike are all there. The build is flatter
  in one way the mock hides: the mock's stamp sits clear of the answer's words, and the build's
  sits on them whenever the pool line is long (`dark-02`, `ax-02`).
- **`mock-2-win` → `03-result.png`:** matched almost exactly — score, tally, stamp, ribbon,
  fold, countdown, share box, footer. The mock shows confetti mid-fall and a 12-day ribbon
  sized to its number; the build's ribbon is a slab that spans the column at one day. The
  deeper gap is not in the still: the mock is a photograph of a moment, and the filmstrip shows
  that moment has never been captured happening.
- **`mock-3-first` → `07-onboarding.png`:** matched; the press on paper, the masthead, "Turn
  the page".
- **DESIGN.md's Practice summary, reported column and the accuracy table** are built as drawn.
- **Nothing in DESIGN.md describes a second session**, which is why the build has none. The
  document specifies the win to the millisecond and says nothing about session 50. That is the
  direction's failure as much as the build's, and fix 2 is not done until DESIGN.md answers it.
