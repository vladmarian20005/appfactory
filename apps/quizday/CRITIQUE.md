# Quizday · critique

**Verdict: fail.** This is the template with a trivia schema poured into it: system gray canvas,
white rounded cards, one purple accent, green-and-red answers, an SF Symbol wherever art should
be, and a win that is the sentence "8 out of 10" followed by "Come back tomorrow for ten more."
The one thing that decides it: **DESIGN.md's newspaper — the paper canvas, the ink press, the
stamp, New York throughout — is not in the build at all**; `tells.mjs` reports 17 hard FAILs
including `kit-default-brand`, and none of `AppBrand`, `.brand(…)`, `brandDisplay`, `confetti`,
`CountUp`, `Tones`, `Motion.*`, `popIn` or `ShareImage` appears anywhere in `ios/App/`.

| | Score | Evidence |
| --- | --- | --- |
| Idea | 1 | `qa/01-today.png` is "Today / Friday, September 11 / Round 14" over gray with purple chips — no masthead, no dateline, no press, nothing that says newspaper. Cover the word "Round" and it is any daily quiz on the store. |
| Look | 2 | `Color(.systemGroupedBackground)` on eleven lines across four files (`TodayView.swift:84,164`, `QuestionCard.swift:44`, `ScorecardView.swift:63`, `PracticeView.swift:94,151,222`); white cards; the palette is one purple plus system green/red/orange. `qa/design/dark-01-today.png` is the same screen on pure black — inverted, not designed. |
| Signature interaction | 2 | The answer tap is a color swap under `.animation(.easeOut(duration: 0.18), value: selected)` (`QuestionCard.swift:58`) with `Haptics.tap` then `.success`/`.warning` (`TodayView.swift:231`). No ink sweep, no stamp, no spring, no tone, no tally inking in — the four beats DESIGN.md specifies are absent. `qa/02-question.png` shows the result: a green bordered pill and a red one. |
| Reward | 1 | `TodayView.swift:120–124` prints `Text("\(score) out of \(shownFlags.count)")` at 44 pt above "A solid round. Come back tomorrow for ten more." — TASTE.md's slop tell quoted line for line. `qa/03-result.png` confirms: ten flat purple squares, a "Streak started" card, a countdown card, a gray share card. `tells.mjs` → `no-reward`. |
| Voice | 2 | Four fixed verdict strings in a `switch` (`TodayView.swift:176–183`), so the tenth win reads exactly like the first, and the product recites its own pitch in four places: `TodayView.swift:49`, `:144`, `RootView.swift:93`, `Reminders.swift:27`. No night editor, no newsroom vocabulary, no pools. |
| Craft | 3 | Tidy and aligned at default size in light mode — consistent 16 pt gutters, the calendar's three-step density ramp in `qa/04-scorecard.png` is genuine information design. But `qa/design/ax-02-question.png` hyphenates the difficulty pill to "Medi-/um" and the bottom button covers two of the four answers, and `ax-01-today.png` pushes the categories card entirely under the tab bar. (Also: `qa/03-result.png` and `dark-03-result.png` show different squares for the same `-answered 8` — `Quizday.swift`'s sample `flags.shuffle()` is unseeded, so the captures are not reproducible.) |
| First minute | 2 | Onboarding is three SF Symbols at hero size — `10.circle.fill`, `hand.raised.fill`, `text.book.closed.fill` (`AppInfo.swift:17,22,27`) — and page two *is* the pitch ("No ads. Nothing runs out." / "That is the whole point."). It lands on a gray screen with a purple button. Nothing in the first ten seconds makes a promise about a world. |

Missing captures, scored as unseen rather than assumed good:

- **No `qa/design/moment-*.png` at all.** `qa.json` has no `moments` key and `LaunchOptions.swift`
  has no `-demo` flag, so neither the signature interaction nor the win was filmed. The motion
  scores above come from reading `QuestionCard.swift` and `TodayView.swift`, which contain a
  single 0.18 s ease and no choreography — but a filmstrip would have been the evidence.
- No `ax-*` capture of the result, the scorecard or the paywall; no capture of onboarding, of
  Practice (locked or setup), or of Settings.
- The app icon in the build (`ios/App/Assets.xcassets/AppIcon.appiconset/icon-1024.png`) is
  **"10" in white on a purple gradient** — TASTE.md's "the icon is text on a gradient", verbatim.
  The drawn stamp-on-newsprint icon exists at `design/icon-1024.png` and has never been rendered
  into the asset catalog.

## Slop tells present

- **Gray canvas with white cards** — `qa/01-today.png`, `qa/02-question.png`, `qa/03-result.png`,
  `qa/04-scorecard.png`, `qa/05-paywall.png`; `TodayView.swift:84`, `TodayView.swift:164`,
  `QuestionCard.swift:44`, `ScorecardView.swift:63`, `PracticeView.swift:94`.
- **One accent on gray, green and red the only other color** — `QuestionCard.swift:129,135`
  (`Color.green.opacity(0.16)` / `Color.red.opacity(0.14)`), visible in `qa/02-question.png`.
- **An SF Symbol as a hero** — onboarding `AppInfo.swift:17,22,27`; Practice locked
  `PracticeView.swift:62` (`Image(systemName: "infinity")`).
- **"8 out of 10" in a card followed by "Come back tomorrow"** — `TodayView.swift:120–124,181`,
  `qa/03-result.png`.
- **Stats as a row of identical number tiles with gray captions** — `ScorecardView.swift:97–99`
  ("13 day streak", "13 best streak", "19 days played"), `qa/04-scorecard.png`.
- **Copy that explains the business model inside the product** — `TodayView.swift:49`,
  `TodayView.swift:144`, `RootView.swift:93`, `Reminders.swift:27`, `AppInfo.swift:23–24`.
- **`.easeOut` the only motion there is** — `QuestionCard.swift:58`; no `Motion.*` anywhere.
- **Nothing bigger than `.largeTitle`** — the biggest type in the app is `scaledFont(size: 44)`
  on the result; `tells.mjs` → `no-display-type`.
- **Praise that never changes** — `TodayView.swift:176–183`.
- **The icon is text on a gradient** — `ios/App/Assets.xcassets/AppIcon.appiconset/icon-1024.png`.

## Keep

- **The mechanic and the pack.** One shared round a day, every answer carrying an explanation,
  a source and a report affordance (`qa/02-question.png`) is the wedge and it works. The reveal
  content — explanation, `Source: Britannica`, report — is the right *information*; only its
  dress is wrong.
- **The calendar's density ramp.** `ScorecardView` shades a played day by score in three steps
  with a legend (`qa/04-scorecard.png`). Recolour it ink instead of purple and it is DESIGN.md's
  printed month almost as-is.
- **The restraint.** No HUD, no coins, no interstitials, the rating prompt deliberately on the
  result and never mid-question (`TodayView.swift:165–167`). That judgement is right; keep it.
- **The compliance and accessibility scaffolding** — combined accessibility elements on the
  header and the square row, `accessibilityHint` on every answer, the auto-renew disclosure on
  the paywall.

## Fix, in this order

1. **Put the brand in the app.** `ios/App/` has no `AppBrand.swift`. Paste DESIGN.md §Tokens
   verbatim into one, and apply `.brand(AppBrand.brand)` to `RootView` *and* to `OnboardingView`
   in `Quizday.swift:36–41`. Then delete every `Color(.systemGroupedBackground)` and
   `Color(.secondarySystemGroupedBackground)` (eleven sites, listed above) and replace the screen
   backgrounds with `.brandBackground()` and the card surfaces with `.brandSurface()`. Add the
   paper grain and the two 0.5 pt column rules as DESIGN.md §Canvas describes. *Next capture:*
   `01-today` is ivory `#F5EFE2` with visible column rules, not `#F2F2F7`; `dark-01-today` is
   `#151821` with warm type, not black; `tells.mjs` loses `kit-default-brand` and all eleven
   `gray-canvas` FAILs.

2. **Build the ink press on the answer.** Rewrite `QuestionCard.answerButton` as DESIGN.md's
   ruled box — 1.2 pt ink rule at radius 6 on `surface`, a 26 pt mono gutter with `A B C D` at
   11 pt tracking 1.6, New York 19 pt — and replace `.animation(.easeOut(duration: 0.18))`
   (`QuestionCard.swift:58`) with the four beats: a gradient-mask ink sweep 0→1 on
   `.spring(response: 0.26, dampingFraction: 0.85)` in `success` green or `miss` graphite,
   `Haptics.rigid()` at 200 ms, `Tones.shared.play(.pop)` / `.miss` at 210 ms, then the stamp
   dropping from scale 1.6/−14° to 1.0/−6° on `Motion.bouncy` with `Haptics.thud()`. Delete
   `Color.green.opacity(0.16)` and `Color.red.opacity(0.14)` and both `checkmark.circle.fill` /
   `xmark.circle.fill` — a miss is the pencil ellipse and strike, never a red border.
   Use `.buttonStyle(.pressable)`. *Next capture:* `02-question` shows four ruled boxes with
   letter gutters and a red stamp hanging past the right margin; the `moment-answer` filmstrip
   shows the sweep crossing the box frame to frame.

3. **Make finishing print an edition.** Replace `TodayView.done` (`:110–168`) with DESIGN.md's
   choreography: masthead `QUIZDAY` `.popIn(delay: 0.18)`, the mono dateline at 0.26,
   `CountUp(to: score, duration: 0.7, onTick:)` at `.brandDisplay(size: 112)` with
   `Tones.shared.play(.step(n))` and `Haptics.impact(0.4 + 0.05 * n)` per tick, the ten squares
   printing 34 ms apart, the tier headline stamping at −3° with `Haptics.celebrate()` and
   `.fanfare`, then `.confetti(trigger:power:count:colors:)` in `#F5EFE2 #FBF7EC #1B2027 #C1362C`.
   Four tiers with DESIGN.md's headlines and sublines — `EXTRA! EXTRA!`, `STOP THE PRESS`,
   `THE EDITION IS FILED`, `TOMORROW'S IS ALREADY SET`, `A BLANK SHEET` — plus the brass
   `PERSONAL BEST` stamp on a new best. Delete the `verdict(score:total:)` switch entirely.
   *Next capture:* `03-result` has a number at 112 pt and no sentence containing "out of";
   `tells.mjs` loses `no-reward` and `no-display-type`.

4. **Take the pitch out of the product.** Four lines to change. `TodayView.swift:49` →
   the italic *"Ten questions, set this morning."* over the printers' section line.
   `TodayView.swift:144` → drop it; the countdown box carries only
   `TOMORROW'S EDITION GOES TO PRESS IN`. `RootView.swift:93` → the Settings footer becomes
   OpenTDB attribution only. `Reminders.swift:27` → `Ten questions, two minutes. Round {n}.`
   under the title `Today's edition is on the step.` And rewrite onboarding page 2
   (`AppInfo.swift:21–25`) to DESIGN.md's *Stamp your answer / Press one and the ink lands —
   with the reason it's right underneath.* The paywall keeps the single promise sentence and it
   is the only place it appears. *Next capture:* `tells.mjs` reports zero `pitch-in-product`.

5. **Render the art and the real icon.** Six SVGs sit unused in `design/art/`. Run
   `node tools/design/art.mjs` and use them: `press-body` + `press-wheel` as Today's hero,
   `stamp` and `desk` on onboarding 2 and 3, `desk` as the paywall hero via `PaywallView(…,
   hero:)`, `case` for Practice locked (replacing `Image(systemName: "infinity")`,
   `PracticeView.swift:62`), `spike` for the empty Scorecard. Then render `design/icon.svg` over
   `Assets.xcassets/AppIcon.appiconset/icon-1024.png` — the shipped file is still "10" on purple.
   *Next capture:* `05-paywall` has the drawn desk above the headline; the icon is cream with a
   red stamp; `tells.mjs` loses `paywall-no-hero`.

6. **Rebuild the Scorecard around one number.** Delete the three tiles at
   `ScorecardView.swift:97–99` and put the streak at `.brandDisplay(size: 96)` with a brass
   ribbon behind the mono label `DAYS RUNNING`, and one ledger line under it:
   `BEST 13 · 19 EDITIONS FILED · 147 OF 190 ANSWERED`. Recolour the calendar to `ink` at
   0.92 / 0.62 / 0.34 with the score knocked out in paper at 8+, an empty ruled square for
   unplayed, and today circled in the hand-drawn accent ellipse. *Next capture:* `04-scorecard`
   has exactly one thing over 44 pt and no purple squares; `tells.mjs` loses `stats-tiles`.

7. **Give it sound, a share image, and film the moments.** Wire `Tones` per DESIGN.md §Sound and
   add `SoundsToggle()` to `QuizdaySettings`. Replace `ShareCard.text` at `TodayView.swift:151`
   and `ScorecardView.swift:77` with `ShareImage.render` at 1080 × 1350 — masthead, dateline,
   the score at 320 pt, the ten squares, the tier stamp, the brass ribbon — keeping the text line
   as the fallback with `🟥`/`⬜`. Then add a `-demo <name>` flag to `LaunchOptions` and
   `moments: ["answer", "win"]` to `qa.json` so `design-captures.sh` films them. *Next capture:*
   `qa/design/moment-answer-*.png` and `moment-win-*.png` exist and consecutive frames differ;
   `tells.mjs` loses `silent-game`, `text-share` and `ease-only`.

## Against the mocks

- **Question sheet — `mock-1-play.png` vs `qa/02-question.png`.** The mock is a sheet: grain,
  column rules, a mono section mark with a blue tick, `Q4 OF 10 · EASY`, the tally as solid ink
  blocks, the question in New York bold over a 2.5 pt rule, four ruled boxes with `A B C D`
  gutters, the correct answer in proof green circled by hand, the wrong one struck through in
  graphite, a red `CORRECTION ON PAGE TWO` stamp hanging past the margin, the source as a mono
  dateline, `¶ SOMETHING WRONG HERE?`, and a printer's ornament closing the column. The build is
  gray, has no tally at all, no section colour, no letters, a green-bordered pill and a
  red-bordered pill, `Not this time` in system orange next to `info.circle.fill`, "Report a
  problem" as a purple SF Symbol link, and a purple pill button on a `.bar` strip. Every element
  of the mock is missing.
- **Result — `mock-2-win.png` vs `qa/03-result.png`.** The mock has the masthead, the dateline,
  `9` at 112 pt with `/10` beside it, ten ink blocks, `STOP THE PRESS` in a double-ruled red
  stamp at −3°, the subline *"One got past you. One."*, a brass ribbon reading `12 DAYS RUNNING`,
  shredded newsprint mid-air, the countdown and share as two ruled boxes below a fold, and a mono
  footer. The build has "8 out of 10" at 44 pt, "A solid round. Come back tomorrow for ten more.",
  purple squares, an orange flame that says "Streak started", and two white cards. Flatter on
  every axis — no tier, no stamp, no ribbon, no burst, no masthead, no fold, no footer.
- **First run — `mock-3-first.png` vs the build's onboarding.** The mock opens on the masthead
  and strapline over a drawn iron hand-press with a brass lever and a red flywheel hub, New York
  bold *"One edition a day"*, and a red `Continue`. The build opens on `10.circle.fill` and a
  purple `Continue`, and its second page announces the business model. The promise the mock makes
  in its first second — *this is a newspaper* — the build never makes.
- **Today, unplayed — described in DESIGN.md §Screens 1 vs `qa/01-today.png`.** No masthead, no
  strapline, no dateline, no press, no section line with coloured ticks, no ribbon. What shipped
  is a system large title, a purple date, a `largeTitle` round number, the pitch paragraph, and
  category names as gray capsule chips inside a white card — the "chips in a card" DESIGN.md
  explicitly rules out.
- **Paywall — DESIGN.md §Screens 9 vs `qa/05-paywall.png`.** No `desk.svg` hero, no ruled boxes,
  no New York; three purple `checkmark.circle.fill` bullets in a white card, a `hand.raised`
  glyph beside the promise, and two rounded offer rows. The kit's default paywall with a purple
  tint. Only the auto-renew disclosure is where it should be.
