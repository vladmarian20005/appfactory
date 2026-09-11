# Quizday · design

## The idea

**A one-sheet morning newspaper that prints itself fresh every day — ten questions set in
ink on warm newsprint, answered by stamping them, with the reason printed underneath like a
correction column.**

Three words: **printed, quiet, certain.**

What it is NOT: the category cliché of a purple-neon game show — saturated blue and violet
gradients, glossy candy pills, a coin-and-hearts HUD along the top, a cartoon mascot, a stock
photograph above every question. All five leaders are that app. Quizday is paper and ink, and
it is recognisable from one crop of any screen.

Why print, and not a skin over print: the spec's mechanic *is* an edition. The same ten
questions for everybody today, dated, never repeated, filed when you finish, a new one
tomorrow morning — that is what a newspaper is, and no trivia app on the store is one. The
idea chooses the serif, the hairline rules, the stamp, the calendar of back issues, and the
voice of the night editor who set the thing.

## Who and when

She is 41, reads on her phone before anyone else in the house is up, and keeps three or four
small daily rituals — the crossword, the word game, the news. She comes for two minutes of
ordinary curiosity with coffee, not a match against a stranger; the reviewers who love this
category say so plainly ("great diversity of questions", "I like the explanations to each
answer at the end"), and the ones who leave say why ("every time I get a question wrong… I
have to sit through a long ad"). The feeling she comes for is **composure**: something that
starts the day well, tells her something she did not know, costs her nothing and interrupts
her never.

## The signature interaction

**The ink press.** Answering a question is pressing ink into paper, and it is the verb she
performs a hundred times a week.

The answers are not buttons on a card. Each is a **printed line inside a ruled box**: a 1.2 pt
ink rule at 6 pt radius over the paper surface, the answer set in New York at 19 pt, with a
mono letter marker — `A B C D` at 11 pt, tracking 1.6 — in a 26 pt gutter divided off by a
hairline.

Beat by beat:

| ms | what happens |
| --- | --- |
| finger down | The box depresses: `.buttonStyle(.pressable(scale: 0.985))`, and its gutter darkens to ink at 0.10. `Haptics.soft()` comes from the style. |
| 0 | The tap locks; no second answer is taken. |
| 0–220 | **The ink sweep.** The chosen box fills left to right from the gutter — `success` green if right, `miss` graphite if wrong — driven by a linear-gradient mask on `inkProgress` 0→1 with a 14 pt soft leading edge. The answer's type knocks out to paper colour as the ink passes under it (a second copy of the text in `canvas`, masked by the same sweep). Spring: `.spring(response: 0.26, dampingFraction: 0.85)` through `Motion.resolved`. |
| 200 | `Haptics.rigid()` — the impression lands. |
| 210 | `Tones.shared.play(.pop)` when right, `.miss` when wrong. |
| 230–420 | **The stamp.** The verdict stamp — a **double-ruled box**: a 2 pt accent rule at 3 pt radius with a 0.8 pt inner rule inset 3 pt, the line inside it in New York bold italic 13 pt, tracking 1.6, uppercase, on `canvas.opacity(0.86)` so the paper shows through — drops from scale 1.6 / −14° / opacity 0 to scale 1.0 / −6° / opacity 1 on `Motion.bouncy`. It lands at ~380 ms with `Haptics.thud()` and settles on the spring's own overshoot. It sits over **the box she answered**, hanging 16 pt past the right margin, and never over the correct one — that is the line she came to read. The text is from the praise pool when right, the near-miss pool when wrong: **the stamp is red either way**, so red never means "you are wrong". (Mock 1 shows it.) |
| 320–660 | On a miss only: **the pencil correction.** A hand-drawn ellipse — a `Path` of two offset arcs, `.trim(to:)` animated 0→1 over 0.34 s — circles the correct answer in `inkSoft` graphite, and a single struck line is drawn the same way through the one she picked. The sheet takes one `.shake(trigger:)`. No red border. No buzzer. |
| 420–620 | **The footnote sets.** A hairline rule draws itself across the sheet (trim 0→1, 0.2 s) and the explanation rises from +14 pt on `Motion.gentle`, New York 17 pt. The source follows as a mono dateline, `SOURCE · BRITANNICA`, 11 pt tracking 1.6. Reporting a problem is a small printer's mark (a ¶ and "something wrong here?") at the end of that rule — not a button in a card. |
| 520 | **The tally inks in.** The row of ten squares at the top of the sheet fills its next square, with `Haptics.selection()` and `Tones.shared.play(.step(runningCorrect))`, so a good round audibly climbs the scale by question six. Three states, and they are legible from across a room: a **hit** is a solid ink square; a **miss** is a 1.4 pt ruled square with a single graphite diagonal struck through it, the same pencil as the correction; a question **not yet reached** is a 1 pt square at `ink.opacity(0.20)`. |

**Between questions**, the sheet turns: the answered sheet lifts 8 pt, rotates 1.5° and slides
up out of frame over 0.28 s on `Motion.gentle` while the next rises from +60 pt with a 0.5°
counter-rotation. The next page off the pile.

**Why it holds up the thousandth time:** the sweep travels the same distance every time, so
the rhythm becomes learnable and then pleasurable; the stamp lands off-axis, so it never looks
mechanical; and because the tone tracks the running count, question six of a good round sounds
different from question six of a bad one.

**Teaching the first one, with no text:** on the very first question of a player's first
round, box A breathes once — the ink sweeps 12 % across and retreats over 0.9 s on
`Motion.gentle` — and the stamp art hovers above it at 40 % opacity with `.ambientFloat()`.
It stops the instant any box is touched and never comes back. There is no "tap an answer"
label anywhere in the app; the VoiceOver hint (`"Tap to stamp this answer"`) is the exception
and does explain.

## The reward

**The edition prints.** Finishing the tenth question does not open a sheet with a checkmark —
the screen becomes the day's front page coming off the press.

| ms | what happens |
| --- | --- |
| 0 | The last sheet slides away (0.28 s). The paper darkens 4 % and a 3 pt press rule sweeps left to right across the page over 0.30 s. |
| 180 | **The masthead sets**: `QUIZDAY` in New York bold, 34 pt, tracking 6, a hairline rule above and a 2.5 pt rule below. `.popIn(delay: 0.18)`. |
| 260 | **The dateline**: `ROUND 12 · THURSDAY 11 SEPTEMBER`, mono 11 pt, tracking 2. `.popIn(delay: 0.26)`. |
| 340–1040 | **The score prints.** `CountUp(to: score, duration: 0.7, onTick:)` at `.brandDisplay(size: 112)` in ink, with `/10` beside it at 34 pt in `inkSoft`. Each tick fires `Tones.shared.play(.step(n))` climbing and `Haptics.impact(0.4 + 0.05 × n)`. |
| 1040–1400 | **The tally prints**, one square at a time 34 ms apart, each `.popIn(delay:)`, `Haptics.selection()` per square and a `.tap` tone on every third. |
| 1180 | **The headline stamps.** The tier headline drops from scale 1.5 / −11° to −3° inside a 2 pt ruled stamp box in accent red, with `Haptics.celebrate()` and `Tones.shared.play(.fanfare)`. |
| 1240 | **The paper flies.** `.confetti(trigger:power:count:colors:)` with the paper palette — `#F5EFE2`, `#FBF7EC`, `#1B2027`, `#C1362C` — so it reads as shredded newsprint and ticker tape, never party confetti. |
| 1400 | **The streak ribbon unrolls** across the lower right: a printed banner in brass with two notched ends, drawn as a SwiftUI `Shape`, scaling in x from 0 on `Motion.bouncy`, the number at 44 pt. |
| after | Everything stops. The desk lamp keeps breathing behind the page; nothing else moves. |

**Tiers**

| Score | Headline | The difference |
| --- | --- | --- |
| 10 | `EXTRA! EXTRA!` | Confetti `power: 1.5, count: 130`; the headline stamps twice — a fainter second impression at −7°, 60 ms earlier, behind the first; the masthead rule doubles to two 2.5 pt rules. |
| 8–9 | `STOP THE PRESS` | Confetti `power: 0.9, count: 70`, `.fanfare`. |
| 5–7 | `THE EDITION IS FILED` | No burst. The stamp lands harder (`Haptics.thud`) and fourteen scraps fall from the top: `.confetti(rain: true, count: 14, power: 0.4)`. |
| 1–4 | `TOMORROW'S IS ALREADY SET` | No burst, no fanfare. One `.pop`. The headline *sets* rather than stamps — fades up at 0°, no rotation. |
| 0 | `A BLANK SHEET` | As above, and the stamp box is empty, ruled, unprinted. |

**New best streak**, at any tier: a second stamp, `PERSONAL BEST`, in brass at +5°, 220 ms
after the first, with its own `Haptics.thud()` and `Tones.shared.play(.step(7))`.

**Inside the loop**, the small reward is the tally square inking in after every answer, with
its climbing tone — the round has a shape you can hear before you see the score.

## Look

### Palette

Light is newsprint on a kitchen table in the morning. Dark is not that inverted — it is the
same paper under a press lamp at night: a deep blue-black stock with warm type on it.

| Role | Light | Dark | Job |
| --- | --- | --- | --- |
| `canvas` | `#F5EFE2` | `#151821` | Newsprint ivory / night press stock. Behind everything. |
| `surface` | `#FBF7EC` | `#1E2230` | A fresh sheet laid on the stock: answer boxes, the calendar block, ruled panels. |
| `ink` | `#1B2027` | `#F2EDE1` | Press black, faintly blue. Headlines, questions, the score. |
| `inkSoft` | `#5E6470` | `#9AA1B2` | Datelines, explanations' attribution, the pencil. |
| `accent` | `#C1362C` | `#E2695C` | **Stamp red.** The stamp, the press rules, the primary action, today's pencil circle. |
| `onAccent` | `#FFF8EC` | `#1A1210` | Type on the stamp and in the prominent button. |
| `highlight` | `#8E6214` | `#E3AE4E` | **Brass.** The streak ribbon, `PERSONAL BEST`, the run. The second voice. |
| `success` | `#2F6B4F` | `#6FBF95` | Printed proof green — the ink a right answer takes. Never system green. |
| `miss` | `#6F6A60` | `#9C968A` | **Graphite.** A wrong answer is pencilled out, not alarmed. |

`extras` — the thirteen sections of the paper get six inks, used as the 3 pt left rule on a
section line, the section mark on a question sheet, and the bar in the accuracy table:

| # | Light | Dark | Sections |
| --- | --- | --- | --- |
| 0 | `#2D4F7C` ink blue | `#8FB4E6` | Geography, Space |
| 1 | `#6B3A63` plum | `#C99BC0` | Art & Literature, Music |
| 2 | `#1F6B70` teal | `#6FC9CE` | Science, Technology |
| 3 | `#A8552A` rust | `#E39A6E` | History, Food & Drink |
| 4 | `#4A6327` olive | `#A8C877` | Nature, Sport |
| 5 | `#44505E` slate | `#A6B4C4` | General Knowledge, Film & TV, Language |

Checked — `node tools/design/contrast.mjs` — every pair at 3:1 or better, body pairs at AA:

```
#1B2027 on #F5EFE2  14.29 AAA   #F2EDE1 on #151821  15.18 AAA
#5E6470 on #F5EFE2   5.19 AA    #9AA1B2 on #151821   6.85 AA
#1B2027 on #FBF7EC  15.30 AAA   #F2EDE1 on #1E2230  13.55 AAA
#5E6470 on #FBF7EC   5.55 AA    #9AA1B2 on #1E2230   6.12 AA
#FFF8EC on #C1362C   5.19 AA    #1A1210 on #E2695C   5.63 AA
#C1362C on #F5EFE2   4.78 AA    #E2695C on #151821   5.41 AA
#2F6B4F on #F5EFE2   5.49 AA    #6FBF95 on #151821   8.07 AAA
#8E6214 on #F5EFE2   4.69 AA    #E3AE4E on #151821   8.81 AAA
#6F6A60 on #F5EFE2   4.69 AA    #9C968A on #151821   6.03 AA
```

Extras on canvas run 4.58–7.60 in light and 7.54–9.45 in dark. The original brass `#B07A1E`
came back at 3.24 — large text only — and was darkened to `#8E6214` so a ribbon caption holds.

### Canvas

`BrandCanvas.glow(Color(light: 0xFFFDF6, dark: 0x232838), at: UnitPoint(x: 0.5, y: 0.10))` —
paper lit from a lamp above the top edge, because a flat fill reads as a screen and a lit one
reads as a sheet on a table.

Over it, the app draws **paper grain** in a single `Canvas`: 1,400 one-point strokes, 2–6 pt
long, angled ±12°, seeded so it is identical on every launch, at `ink.opacity(0.030)` in light
and `ink.opacity(0.045)` in dark. It never animates — a moving texture would be noise.
Under the grain sit two hairline **column rules** at 0.5 pt, `ink.opacity(0.08)`, inset 20 pt
from each edge and running the full height. They are the page's structure and they are visible
in every screenshot.

### Type

`BrandType(display: .serif, displayWidth: .standard, displayWeight: .bold, body: .serif)` —
**New York** throughout. It is free, it is a text face designed to be read, and it is the one
thing no competitor in this category has. Body copy is serif too; this is a paper.

The third voice is **SF Mono, uppercase, tracked**: `.system(.caption, design: .monospaced)`
with `.textCase(.uppercase)` and `.tracking(2.0)`. It is the dateline, the section mark, the
answer letters, the legend, the ledger line, the source attribution — never a sentence.

Hero numbers, always New York bold through `.brandDisplay(size:)`:

- the result score — **112 pt**, the single largest thing in the app
- the Scorecard streak — **96 pt**
- the Practice summary score — **88 pt**
- the streak ribbon number — 44 pt
- the share card score — 320 pt at 1080 × 1350

Every screen has exactly one thing at 44 pt or over, and nothing else competes with it.

### Shape

**The ruled box**: a rectangle with a 1.2 pt ink rule, corner radius **6**, filled with
`surface`. Answer boxes, the calendar block, the stamp, the panels, the tally squares (at
4 pt radius, the same shape shrunk) — one shape, repeated at four sizes. `corner: 6` for the
whole brand. Nothing in this app is a 20 pt white card with a shadow.

The second shape is **the rule**: hairline at 0.5 pt for structure, 1.2 pt for a box, 2.5 pt
under a masthead, 3 pt for the press sweep. Rules do the work that borders and shadows do in
the template.

The third is **the printer's ornament** that closes a column: two 54 pt hairlines with a 5 pt
ink lozenge (a square at 45°) between them, centred, at `ink.opacity(0.28)`. It goes at the
foot of any screen whose content ends before the page does — the question sheet after the
footnote, the Practice setup under the attribution — so a short page reads as finished rather
than as a screen that ran out.

### Art

Drawn as SVG in `design/art/`, rendered by `node tools/design/art.mjs` into the asset catalog
and used as `Image("…")`. No SF Symbol is ever the hero of a screen.

| File | Depicts | Where |
| --- | --- | --- |
| `press-body.svg` | An iron platen hand-press in three-quarter view: the frame, the bed, the lever, a stack of sheets beside it. Ink line over three flat fills. | Today (unplayed) hero, onboarding 1 |
| `press-wheel.svg` | The press's spoked flywheel, alone, centred in its own square viewBox so it can rotate on its own axis. | Composited over `press-body` at its hub; turns 360° every 20 s, standing still when `Motion.isStill` or Reduce Motion |
| `stamp.svg` | The rubber stamp from the side, wooden handle, ink pad below, caught mid-press with a bloom of red under the rim. | Onboarding 2; the ghost that teaches the first answer |
| `desk.svg` | Top-down: a cup with a ring stain, a folded sheet, a pencil at an angle, a brass clip. | Onboarding 3, paywall hero |
| `spike.svg` | A spindle spike through a stack of filed back issues, the topmost dated. | Scorecard empty state |
| `case.svg` | A composing stick and a type case with loose sorts in it. | Practice locked hero |

Everything else is SwiftUI shapes: the stamp ring, the pencil circle and strike, the ribbon,
the tally, the calendar, the grain.

### Motion

| Spring | Used for |
| --- | --- |
| `Motion.snappy` | Selection, the tally square, pickers, month steps |
| `Motion.bouncy` | The stamp landing, the score arriving, the ribbon unrolling |
| `Motion.gentle` | The page turn, the footnote rising, the teaching breath |
| `Motion.pop` | Press states, via `.pressable` |

**Ambient:** the lamp glow behind the paper swells on `.breathing(amount: 0.02, period: 6.0)`
— slow enough to ignore — and the press flywheel turns on Today's unplayed screen. That is
all. **Never moves:** the paper grain, the column rules, the calendar, the type.

Entrances are staggered `.popIn(delay:)` at 0.05 s apart, top of the sheet down.

### Sound

`Tones`, on the ambient session, with `SoundsToggle()` in Settings.

| Tone | When |
| --- | --- |
| `.tap` | Picking a section or difficulty; every third tally square on the result |
| `.pop` | The ink landing on a right answer |
| `.miss` | The ink landing on a wrong one — two notes down, never a buzzer |
| `.step(n)` | The tally square, `n` = the running correct count; the score's count-up; `.step(7)` under `PERSONAL BEST` |
| `.success` | Finishing onboarding |
| `.fanfare` | The headline stamping, at 8 and over only |

## Voice

**The night editor who set tomorrow's paper**: dry, brisk, quietly proud of the edition,
never cute and never chatty.

Three rules:
1. He talks in the newsroom's terms — file, set, print, correction, the desk — and never once
   explains them.
2. He never mentions ads, money, lives or what the app does not have. The calm is felt, not
   announced. The single exception is the paywall.
3. Praise is eight words or fewer. He is not impressed easily and he does not gush.

### Onboarding — three pages

| Art | Title | Subtitle |
| --- | --- | --- |
| `press-body.svg` + `press-wheel.svg` | One edition a day | Ten questions, the same ten for everyone, set fresh each morning. |
| `stamp.svg` | Stamp your answer | Press one and the ink lands — with the reason it's right underneath. |
| `desk.svg` | Then the day is yours | Every edition you file is dated and kept. The run is the only score that carries. |

No onboarding page states the promise. The paywall is the only place in the product that does.

### Praise pool — right answer, on the stamp (ten)

`Filed.` · `Clean copy.` · `That one's yours.` · `Straight to the front page.` ·
`No correction needed.` · `Set and printed.` · `Good ear.` · `The desk agrees.` ·
`Ink dry already.` · `Bang on.`

### Near-miss pool — wrong answer, on the stamp (eight)

`Correction on page two.` · `Close. The desk has it here.` · `Not this edition.` ·
`Pencil it out.` · `We'll run the right one.` · `Half a lead, no story.` ·
`The subeditor caught it.` · `That one got away.`

Both pools draw without replacement inside a round, so no line repeats in the same ten.

### The win's headline and subline, by tier

| Score | Headline | Subline |
| --- | --- | --- |
| 10 | `EXTRA! EXTRA!` | Ten for ten. The desk is speechless. |
| 9 | `STOP THE PRESS` | One got past you. One. |
| 8 | `STOP THE PRESS` | Two slipped through. The rest are yours. |
| 5–7 | `THE EDITION IS FILED` | {score} of ten, and the other {n} are explained below. |
| 1–4 | `TOMORROW'S IS ALREADY SET` | A hard sheet. You still read ten reasons. |
| 0 | `A BLANK SHEET` | It happens on the night desk too. |

### Empty states

- **Scorecard, nothing filed** (art `spike.svg`): `The file is empty` / `Play an edition and it gets spiked here, dated.`
- **Accuracy table, nothing recorded**: `No copy on record` / `Answer a few and your sections show up here, worst first.`
- **Today, already played**: `Tomorrow's edition goes to press in` and the countdown, mono, 34 pt.
- **Practice, the wire is down** (network error): `The wire is down` / `Nothing came through. Try again in a moment.`

### Streak messages

| When | Line |
| --- | --- |
| day 1 | Day one on the desk. |
| days 2–6 | {n} days running. |
| day 7 | A full week in print. |
| days 8–29 | {n} days running. |
| day 30 | A month of editions. |
| a run just ended | The run ended at {n}. Start another. |
| unplayed, a run alive | {n} days running. Today keeps it. |

### Reminder notification

Title: `Today's edition is on the step.`
Body: `Ten questions, two minutes. Round {n}.`

### Paywall

Headline: **The composing room**

- Set your own rounds — any section, any night, as many as you like
- See which sections you own and which keep catching you
- Choose the difficulty: easy, medium or hard

Promise (the one sentence, and the only place in the app it appears): *The daily edition
stays free and always will — no ads, nothing to run out of. Pro buys you more type, not the
paper.*

### Button labels

| Where | Label |
| --- | --- |
| Today, unplayed | Open today's edition |
| Question 1–9, after the reveal | Next question |
| Question 10, after the reveal | Print the edition |
| Result, share | Share the edition |
| Practice, locked | See the composing room |
| Practice, setup | Set a round of ten |
| Practice, summary | Another round / Back to the case |
| Paywall | Start the free trial |
| Onboarding | Continue / Get started (the kit's) |
| Question sheet, reporting | something wrong here? |
| Settings, erase | Erase my history |

## Screens

Every MVP screen the spec names, kept. What changes is what they are like.

The `TabView` and its four tabs stay the system's, in the brand's tint — on the iOS 26 SDK
that bar is Liquid Glass and it should be. The symbols: `newspaper.fill` (Today),
`calendar` (Scorecard), `tray.full.fill` (Practice), `gearshape.fill` (Settings).

### 1 · Today, unplayed — *mock 1 shows the question; this one is described here*

One job: make her want to start, in three seconds. Hero: the press, turning.

Top to bottom: the **masthead** — `QUIZDAY` in New York bold 30 pt, tracking 6, a 0.5 pt rule
above and a 2.5 pt rule below, with the strapline `A NEW EDITION EVERY MORNING` in mono 10 pt
tracking 2.4 under it — then the **dateline** in mono, `THURSDAY 11 SEPTEMBER · ROUND 12`. Then `press-body.svg` at 200 pt tall with `press-wheel.svg` composited at its hub,
turning once every 20 s. Then a line of New York 19 pt italic: *"Ten questions, set this
morning."* Then **today's sections**, as a printers' section line — the category names in mono
uppercase separated by `·`, wrapped, with a hairline above and below and each name preceded by
a 3 pt tick in its section ink. Not chips in a card. Then the streak ribbon if a run is alive.
Then `Button("Open today's edition").brandProminent()`, full width.

System: `NavigationStack` with an inline empty title (the masthead is drawn), the `TabView`,
the button. Everything else is drawn on paper.

### 2 · Today, a question — **mock 1**

One job: one question, and the reason underneath. Hero: the question itself, New York bold
27 pt, up to three lines, with a 2.5 pt rule under it.

Top: the **tally** of ten squares, 4 pt radius, inked as far as she has got, with `Q4` and the
section mark in mono beside it. Then the question and its rule. Then four ruled answer boxes,
10 pt apart. After the reveal: the hairline, the explanation in New York 17 pt, the mono
source dateline, the ¶ report mark. The verdict stamp sits over the answered box.

`safeAreaInset(edge: .bottom)` holds the prominent button on a paper strip with a 1.2 pt rule
along its top — not `.bar`, which reads grey on newsprint.

Motion: the ink sweep, the stamp, the pencil, the footnote, the tally — all as §"The signature
interaction".

### 3 · Today, printed — **mock 2**

One job: be worth screenshotting. Hero: the score at 112 pt.

The front page, in the order it prints: masthead, dateline, score and `/10`, the tally, the
tier headline stamped in its ruled box, the streak ribbon in brass, then — below a hairline
fold, so they never compete — two ruled boxes side by side: the countdown
(`TOMORROW'S EDITION GOES TO PRESS IN` in mono over `6:12:44` at mono 28 pt, a
`Text(timerInterval:)`) and the `ShareLink` labelled **Share the edition**, a ruled box with
the share glyph in accent above it, not a filled tile. The page closes on a hairline and the
mono footer `QUIZDAY · A NEW EDITION EVERY MORNING`, pinned to the bottom of the column.

The rating prompt stays here, after the page has settled, never mid-question.

### 4 · Scorecard

One job: show the run and the back issues. Hero: the streak at 96 pt.

Masthead `THE FILE`. Then the **streak block**: the number at `.brandDisplay(size: 96)` in
ink with a brass ribbon behind the mono label `DAYS RUNNING`, and under it one **ledger line**
in mono — `BEST 12 · 19 EDITIONS FILED · 147 OF 190 ANSWERED` — which replaces the three
identical number tiles entirely.

Then **the month**, as a printed calendar block: a `surface` ruled box, weekday letters in
mono 10 pt tracking 2, hairline column rules between the seven columns. A played day is a
solid **ink** square — density by score, `ink` at 0.92 / 0.62 / 0.34 for 8+, 5–7, under 5, so
the month reads as a printed pattern rather than a tint of the accent — with the score
knocked out in paper colour when it is 8 or over. An unplayed day is an empty ruled square. A
future day is blank. **Today is circled in pencil**: the same hand-drawn two-arc ellipse as
the correction, in accent red. Month arrows are system `Button`s with chevrons; the legend is
a mono footer line, not a row of chips.

Then **today's edition**: if filed, the ten squares, the score and the `ShareLink`; if not,
`Today is still blank.` in New York italic. Then **the morning edition**: a system `Toggle`
and `DatePicker` on a ruled block, labelled *The morning edition* and *Ready by*, with the
editor's caption under it.

Empty, with nothing ever filed: `spike.svg`, `The file is empty`, and the line above.

### 5 · Practice, locked

Hero: `case.svg` at 180 pt. Headline **The composing room** in New York bold 28 pt, the
editor's line under it, then the three bullets as ruled lines each led by a printer's fist
(`☞`, drawn as a small shape) in its section ink — not `checkmark.circle.fill`. Then
`Button("See the composing room").brandProminent()`. The promise sentence does **not** appear
here; it is on the paywall.

### 6 · Practice, setup

A `surface` ruled block headed `SET A ROUND` in mono: a system menu `Picker` for the section,
a system segmented `Picker` for the difficulty, and `Button("Set a round of ten")`.

Under it **the accuracy table**, as a printed league table: one row per section, a 3 pt left
rule in that section's ink, the name in New York 17 pt, a ruled bar — a 1 pt ruled box with an
ink fill at 0.85, not a tinted `ProgressView` — and `35/42` in mono at the right edge. Sorted
worst first, because that is what she came to see. OpenTDB's attribution is the mono footer
line at the bottom of the page.

### 7 · Practice, a round

The same sheet as Today's question, without the tally; the header reads
`COMPOSING ROOM · GEOGRAPHY · MEDIUM` in mono. `Done` in the toolbar, system.

### 8 · Practice, summary

A smaller print of the result: masthead `PROOF`, the score at 88 pt, the tally, the section
and difficulty in mono, then `Another round` and `Back to the case`. No confetti — a proof is
not an edition.

### 9 · Paywall

The kit's `PaywallView(…, hero:)` with `desk.svg` at 200 pt on paper. Headline, the three
bullets, the offers as the kit draws them, the promise sentence, system buttons throughout.

### 10 · Settings

The kit's `SettingsView` with `.brandBackground()` so the `Form`'s grey is gone and the paper
shows through, plus `SoundsToggle()`, the play rows (days filed, questions in the pack,
reported), *Erase my history*, and OpenTDB's attribution as the section footer.

### 11 · Reported

The flagged questions as a **correction column**: each one a ruled block, the question in New
York, its code and date in mono beneath, swipe to delete, and a link to support at the foot.

## Icon

`design/icon.svg`, rendered to `design/icon-1024.png`.

**The concept:** the day's edition, stamped. Full-bleed newsprint ivory with a faint fibre
texture. Across the top third, an abstracted masthead — one 0.5 pt hairline, one heavy ink
bar, one hairline, and beneath them three short knocked-out blocks that read as a dateline at
any size (no letters, no words). Across the lower two thirds, seven body rules
suggesting columns, fading from 34 % to 8 % as they go down. Over all of it, off-centre and
rotated −13°, the **stamp**: a 36 pt rim in `#C1362C` broken by two gaps (a dashed circle, so
the rim reads as rubber lifting unevenly rather than as a printed ring), a lighter 11 pt ring
inside it, and a tick drawn as two strokes of different weight — 54 pt down, 66 pt up — as a
hand pressing harder on the upstroke. Two soft ellipses of red at 11 % and 7 % bloom past the
rim where the ink got out.

**The colors:** `#F5EFE2` ground, `#1B2027` masthead and rules, `#C1362C` stamp, `#8E6214` a
single brass hairline under the masthead bar. Nothing else.

At 60 pt it is a cream square with a red ring on it — the only warm, light, non-gradient icon
in a row of blue and violet question marks. Subject sits inside the middle 80 %; corners are
square and full bleed.

## Share card

`ShareImage.render` at **1080 × 1350**, and it is the front page:

- A 24 pt ivory margin, then a 3 pt ink rule.
- Masthead `QUIZDAY` in New York bold, 96 pt, tracking 22, centred, hairline above and 5 pt
  rule below.
- Dateline in mono, 30 pt, tracking 5: `ROUND 12 · THU 11 SEP`.
- The score at **320 pt** New York bold in ink, with `/10` at 96 pt in `inkSoft` beside it.
- The ten tally squares in a row, 72 pt each: solid ink for a hit, an empty 3 pt ruled square
  for a miss.
- The tier headline in a 4 pt ruled stamp box in accent red, rotated −3°, 54 pt.
- The brass streak ribbon at the lower right when the run is 2 or longer.
- A 0.5 pt rule and a mono footer, 24 pt: `QUIZDAY · A NEW EDITION EVERY MORNING`.
- Paper grain over the whole card at 3 %.

The text fallback keeps the existing shape but takes the brand's ink: `🟥` for a hit, `⬜`
for a miss — the stamp's red on paper — over `Quizday · Round 12`, then `Streak 12 days`.

## Tokens

```swift
import FactoryKit
import SwiftUI

enum AppBrand {
    static let brand = Brand(
        palette: BrandPalette(
            canvas:    Color(light: 0xF5EFE2, dark: 0x151821),
            surface:   Color(light: 0xFBF7EC, dark: 0x1E2230),
            ink:       Color(light: 0x1B2027, dark: 0xF2EDE1),
            inkSoft:   Color(light: 0x5E6470, dark: 0x9AA1B2),
            accent:    Color(light: 0xC1362C, dark: 0xE2695C),
            onAccent:  Color(light: 0xFFF8EC, dark: 0x1A1210),
            highlight: Color(light: 0x8E6214, dark: 0xE3AE4E),
            success:   Color(light: 0x2F6B4F, dark: 0x6FBF95),
            miss:      Color(light: 0x6F6A60, dark: 0x9C968A),
            extras: [
                Color(light: 0x2D4F7C, dark: 0x8FB4E6),   // ink blue
                Color(light: 0x6B3A63, dark: 0xC99BC0),   // plum
                Color(light: 0x1F6B70, dark: 0x6FC9CE),   // teal
                Color(light: 0xA8552A, dark: 0xE39A6E),   // rust
                Color(light: 0x4A6327, dark: 0xA8C877),   // olive
                Color(light: 0x44505E, dark: 0xA6B4C4),   // slate
            ]
        ),
        type: BrandType(display: .serif,
                        displayWidth: .standard,
                        displayWeight: .bold,
                        body: .serif),
        corner: 6,
        canvas: .glow(Color(light: 0xFFFDF6, dark: 0x232838),
                      at: UnitPoint(x: 0.5, y: 0.10))
    )

    /// The section inks, by the pack's category names. Six inks, thirteen sections.
    static func ink(for category: String) -> Color {
        let extras = brand.palette.extras
        switch category {
        case "Geography", "Space":                        return extras[0]
        case "Art & Literature", "Music":                 return extras[1]
        case "Science", "Technology":                     return extras[2]
        case "History", "Food & Drink":                   return extras[3]
        case "Nature", "Sport":                           return extras[4]
        default:                                          return extras[5]
        }
    }

    /// The dateline / section-mark / legend face: SF Mono, uppercase, tracked.
    static func dateline(_ size: CGFloat = 11) -> Font {
        .system(size: size, weight: .medium, design: .monospaced)
    }
}
```

Applied once at the root: `.brand(AppBrand.brand)` on `RootView` **and** on `OnboardingView`,
so the first screen is already the paper.

## Slop we are avoiding

This genre — and this app's own first build — falls into three of TASTE.md's tells.

1. **"One accent color on gray, with green and red for right and wrong the only other
   color."** Every leader does exactly this, and so does the current build:
   `Color.green.opacity(0.16)` with a green border, `Color.red.opacity(0.14)` with a red one,
   on `systemGroupedBackground`. Quizday has **no red for wrong at all**. A right answer takes
   printed proof green; a wrong one is pencilled out in graphite and the right one is circled
   by hand. Red is the stamp, and the stamp lands on every answer either way — so the colour
   that dominates the screen carries no judgement. The canvas is paper with grain, a lamp glow
   and column rules.

2. **"A result that is '8 out of 10' in a card followed by 'Come back tomorrow'."** The
   current build ships this line for line — `Text("\(score) out of \(shownFlags.count)")`
   above `"A solid round. Come back tomorrow for ten more."` Instead the edition prints itself
   over 1.5 seconds: the masthead sets, the score counts to 112 pt with a climbing scale, the
   ten squares print one by one, the tier headline stamps at −3°, shredded newsprint flies,
   and a brass ribbon unrolls. Four tiers, a fifth stamp for a personal best, and a front page
   at 1080 × 1350 to send to someone.

3. **"An SF Symbol scaled up as the hero of onboarding, an empty state, a result or the
   paywall."** The current build opens on `10.circle.fill`, `hand.raised.fill` and
   `text.book.closed.fill`, and locks Practice behind a 44 pt `infinity`. Six drawn SVGs
   replace them: the hand-press (with a flywheel that turns), the stamp, the desk, the spike of
   back issues, the type case — each one a piece of the same world.

And two more this app specifically had: **stats as a row of identical number tiles with gray
captions** — three of them on the Scorecard — replaced by one 96 pt streak and a single mono
ledger line; and **`.easeOut(duration: 0.16)` as the only motion there is**, replaced by the
springs in §Motion.

## Roads not taken

- **The pub quiz on a Tuesday night** — a slate chalkboard, brass, beer mats and a landlord
  with a microphone; funny, but the dark room fights the coffee-and-morning moment the
  reviewers describe, and convincing chalk is the one texture SwiftUI does badly.
- **The night observatory** — ten questions as ten stars, each right answer lighting one until
  the day's constellation is drawn; beautiful, but deep indigo with glowing points is the
  nearest neighbour of the very purple-blue gradient every competitor already owns.
</content>
</invoke>
