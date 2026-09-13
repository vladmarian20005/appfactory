# Tallies · design

## The idea

**A tally-stick carver's bench: everything you count is a stave of pale ash, notched once
under your thumb, five to a gate, and when a stave is full it is scored across, dated on the
end and stood in the rack behind you.**

Three words: **cut, warm, unhurried.**

What it is NOT: the photorealistic chrome hand-clicker with a rolling odometer drum on a black
screen. Three of the five leading counter apps literally are that — see §2 — and it is the
first thing anyone reaches for when they design a counter. It is also not the wall of
saturated colour rows with a giant white number, and not the pink analytics dashboard of stat
tiles. Tallies draws **the mark**, not the machine that makes it.

Why the tally stick, and not a skin over one: the app is called Tallies, and a tally is a
notch. The whole category draws an instrument that *hides* the count inside a mechanism and
shows you a numeral; a tally stick *is* the count, in the open, cut into something. That
choice earns the app the one thing a counter usually cannot have — a picture of your record
that gets better the longer you keep it. A stave with five notches and a rack of forty scored
staves are not the same screenshot, and nothing about that had to be invented: it is what the
object does.

**And the bench has to still be interesting in March.** What Tallies ships today has no
ladder, no selection rule, nothing at risk in a sitting, one door in the whole app with money
as the only key, and an ending that is a bar chart. `tells.mjs` finds nine hard FAILs on it.
§"The play" is where that is fixed, and none of it is decoration: it is what makes the
fortieth sitting different from the first.

## Who and when

He is 34 and counts something most days — sets at the gym on Monday, stitches on the sofa on
Wednesday, cars past the window while his daughter naps on Saturday. He reaches for the phone
mid-thing, one-handed, often without looking down at it, so what he needs back is not a
dashboard but the certainty that the number is right. The feeling he comes for is **not losing
count**: an accurate record kept with no effort, still there and still legible a year later.

That sets the whole direction. Calm, tactile and unhurried is the job; the thumb has to be
able to find the target without the eyes; and the record has to look like something worth
having kept, because the only reason to open a counter app on a Thursday is to see what you
have got.

## 2. The category, looked at

`node tools/design/leaders.mjs "$RUNNER_TEMP/leaders" "Tally Counter" "Counter+" "Click
Counter" "Tally Counter - Simple Count" "Streaks"` — 22 screenshots, read outside the repo.
Three clichés, and all three are load-bearing for what follows.

1. **The chrome clicker.** Tally Counter, Counter+ and Click Counter are each a photoreal
   brushed-chrome hand tally counter with a four-digit odometer drum, on a black screen, with
   two glossy round buttons under it. Counter+ shoots it in a hand in front of a queue of
   people. This is the category's whole visual identity, it is shared by three of its five
   leaders, and **it is why Tallies is not an instrument.** The first idea for this app was a
   machined brass clicker; step 2 killed it.
2. **Saturated rows with a giant white number.** Counter (Tally Count) is a stack of
   full-bleed teal / yellow / blue / grey rows, each with a huge white right-aligned numeral
   and a `(+3)` in small type — and a "Remove Ads" row in Settings, which is the app the
   spec's wedge is written against.
3. **The habit-tracker dashboard.** Streaks is the polish bar: pink on white, consistent,
   genuinely good information design — and its stats screen is `21 BEST STREAK · 80.1% ALL
   TIME · 297 COMPLETIONS`, a row of identical number tiles with grey captions, which is a
   TASTE.md slop tell shipped by a category leader. Tallies has to be at least as finished as
   Streaks and must not reach for its stats screen.

## The play

The loop: **press to cut a notch into the stave, five to a gate, fifty to a stave.** What he
is chasing is a full stave — scored across, dated, and stood in the rack.

- **The session.** A **sitting**: from the first cut to two minutes after the last. Typically
  6–40 cuts, twenty seconds to ten minutes. It paces itself in fives — a gate closes every
  fifth cut, with its own small reward — and a stave is ten gates, fifty notches. A sitting
  ends on the **sitting card**, which slides up in place of the reading (see "The ending").
  The stave is a unit of magnitude, not of time: for reps it is one session, for glasses of
  water it is a week. Both are right.

- **At risk.** `Run`, for the length of one sitting and nothing beyond it. Every cut is
  `run.hit()`. Every press of the wax stick — the spec's `−` — is `run.miss()`: the last notch
  is **filled with wax**, a paler scar that stays visible on the stave forever. A sitting with
  no wax in it is **clean** (`run.isClean`); `run.chain` is the cuts since the last wax and
  `run.longestChain` is the longest clean stretch on this stave, which is what sets the win's
  tier through `run.tier(score:beating:)`.

  It costs **this sitting's cleanliness and one visible mark on the wood**, and nothing else.
  Not a life, not a count, not a day, not progress already earned, and nothing you can buy
  back. The number is never wrong — the wax is *how a correction is recorded honestly*, which
  is what a real tally stick does and what a counter app owes the person relying on it.

### The ladder

`Ladder`, keyed on **days kept** — distinct days with at least one cut on any stave. It
governs what the carver can *read back* to you, which is the only thing about a counter that
can honestly get deeper, because on day one there is nothing to read.

| Dial | From | By | Every | Opens at | Ceiling | What it is |
| --- | --- | --- | --- | --- | --- | --- |
| `readings` | 1 | 1 | 12 rungs | 1 | 12 | How many of the twelve readings the rota may draw from |
| `span` | 14 | 7 | 9 rungs | 1 | 182 | Days the strip and every reading look back over |
| `grain` | 1 | 1 | 38 rungs | 64 | 4 | How finely a day is cut on the strip: day → half-day → six hours → the hour |

```swift
let ladder = Ladder([
    .init("readings", from: 1, by: 1, every: 12, opensAt: 1,  ceiling: 12),
    .init("span",     from: 14, by: 7, every: 9,  opensAt: 1,  ceiling: 182),
    .init("grain",    from: 1, by: 1, every: 38, opensAt: 64, ceiling: 4),
])
```

**Where it stops, and what happens past it: `flattensAt` is 217** — about seven months of
counting — and `ladder.climbs(through: 150)` is true. That is the honest end and it is not a
dodge: a strip has to fit a phone's width, so a span that reaches back half a year is the
widest the bench holds, and an hour is as fine as a day usefully cuts. Past rung 217 the
*instrument* is complete and the **record** takes over entirely: every reading is drawn from
half a year of your own counting, the rota has twelve to choose between, and the strip is an
hour-by-hour portrait of how you actually spend a Tuesday. Session 500 is not a bigger version
of session 5; it is a thing session 5 could not have contained.

`grain` opens at 64 on purpose. It is the dial that takes over when the other two are half
spent, and it is the one that cannot be faked early: an hourly histogram of one week is noise,
and of six months is a portrait.

### What comes next

Under the stave the bench shows **one reading** — a sentence the carver draws from your record
— chosen fresh at the start of each sitting and held for it. `Readings.next(...)` in
`ios/App/Readings.swift`, over a `Mastery<String>` of the twelve reading ids:

1. **Drop anything that is not true yet.** Every reading declares a precondition over the
   record (`daysKept >= n`, `weekdaySamples >= 4`, `slips > 0`, `grain >= 3`) and is skipped if
   it cannot be computed. This is what "content that knows what it has already served" means
   for a counter: a reading that would have to make something up is never shown.
2. **Drop the last three shown** — `avoiding: recent`.
3. **Of what is left, take the one that has moved most** since it was last shown:
   `|value now − value then| ÷ its own spread over span`. After each showing,
   `mastery.record(id, correct: moved > 0.15)`, so `strength` falls for a reading that keeps
   coming up unchanged and `Mastery.next(from:count:unseenShare:avoiding:)` stops serving it.
   The strength is **read** to decide what comes next, which is the whole point.
4. **Ties break toward the reading the ladder opened most recently**, so a new arrival gets its
   moment.

No `%` over a fixed array, no uniform random, and no `difficulty` field that nothing compares.

**The twelve readings**, in the order `readings` opens them — one every twelve days kept:

| # | id | Opens | Needs | The line |
| --- | --- | --- | --- | --- |
| 1 | `today` | 1 | a cut today | "Nine today. Eleven yesterday." |
| 2 | `gate` | 13 | a gate closed | "Four gates and one. Six short of a stave." |
| 3 | `best` | 25 | 7 days kept | "Your deepest day was the 4th of March — forty-one." |
| 4 | `clean` | 37 | a wax on record | "Eleven sittings since the last wax." |
| 5 | `weekday` | 49 | 4 of that weekday | "Thursdays run a third above the rest." |
| 6 | `kept` | 61 | 3 days kept | "Sixty-one days kept. The longest you have gone is nineteen." |
| 7 | `pace` | 73 | 3 cuts today | "Three an hour since the first cut at 8:12." |
| 8 | `stave` | 85 | 2 staves scored | "Nine in the rack. This one is your fastest by two days." |
| 9 | `hour` | 97 | `grain` ≥ 3 | "You cut most between six and seven in the evening." |
| 10 | `month` | 109 | 2 months of record | "March is nineteen ahead of February." |
| 11 | `quiet` | 121 | a gap of 3 days | "Your longest quiet stretch was six days, in August." |
| 12 | `first` | 133 | — | "Two hundred days since the first cut, on the 3rd of January." |

Every one is computable from the `Tap(delta:at:)` rows the app already stores. No network, no
content pack, no seeding — the spec's determinism survives intact.

### Earned

`Earned`, on **staves scored** — earned by counting, never by paying. A stave is fifty notches,
so someone cutting ten a day scores one every five days. The paywall is a fine door and the
ledger stays behind it; these are the doors it cannot open.

| At | id | What opens | The line |
| --- | --- | --- | --- |
| 1 | `rack` | **The rack.** Scored staves stand behind the bench, oldest at the back; one can be pulled out to read the dates it covers. | "Your first stave is scored. It stands in the rack behind you now." |
| 3 | `chalk` | **The chalk.** A scored stave's end-grain can be written on — what that one was for. | "Three in the rack. There is chalk on the bench if you want to name them." |
| 8 | `gauge` | **The brass gauge.** The strip gains a ruled brass scale, so a day's depth is read off rather than compared. | "Eight staves. The gauge is worth fitting now — you have enough to measure against." |
| 20 | `oil` | **The oil.** The bench darkens with use: the ash goes honey, the grain deepens, the rack rail takes a shine. | "Twenty staves. The bench has taken on a colour. That was you." |
| 50 | `mark` | **The carver's mark.** Your own mark is struck into the end of every stave, dated from your first cut. | "Fifty. Your mark goes on the end of every stave from here, dated the 3rd of January." |
| 120 | `wall` | **The long wall.** The rack becomes a wall: every stave ever scored in one run, at about a year to a screen. | "A hundred and twenty. They do not fit the rack any more — there is a wall for them." |

`earned.next(after: stavesScored)` is what a sitting ends on.

### The ending

The exact words, on the sitting card:

> **"Seven cut, none waxed. Forty-three notches into this stave. Nine in the rack — the gauge
> goes on the bench at eight."**

The shape: `"{n} cut, {none waxed | m waxed}. {notches} notches into this stave. {staves} in
the rack — {earned.next shortened}."` Past the last mark it names the record instead:
`"{n} cut, none waxed. {notches} notches into this stave. {staves} in the rack, and {days} days
kept."` On a first-ever sitting: **"Three cut. Forty-seven to go on this stave, and then it is
scored and stood up."**

Specific, earned, true, and no guilt in it. The words "come back tomorrow" appear nowhere in
the app.

### Sessions 5, 50 and 500

- **5.** One reading — "Nine today. Eleven yesterday." — a fortnight of strip, a stave eleven
  notches in, and an empty rack with the first stave four gates away.
- **50.** Five readings in the rota, seven weeks of strip, the brass gauge on it, nine staves
  standing in the rack with their dates, and a longest clean run worth protecting.
- **500.** Twelve readings, half a year of strip cut to the hour, the bench oiled dark, the
  carver's mark on every stave end, and a wall of them instead of a rack. The reading under
  the stave is drawn from six months of his own counting and says something he did not know
  about his own Tuesdays.

## The signature interaction

**The cut.** The stave lies across the bench at 2.5°, working shoulder towards you, and the
chisel — a broad blade with a brass ferrule and an ash handle — rests on the shoulder at the
next notch position. It is the verb he performs a hundred times a week.

| ms | what happens |
| --- | --- |
| finger down | The blade sinks 5 pt into the shoulder and its handle tips 1.5°: `.buttonStyle(.pressable(scale: 0.98))` plus `.spring(response: 0.11, dampingFraction: 0.92)` on the blade's offset. The wood under the edge darkens to `ink.opacity(0.18)` in a 3 pt band. `Haptics.rigid()` comes from the style — the edge meeting the grain. |
| 0 | The cut is taken. A second press is ignored until 90 ms. |
| 0–130 | **The notch opens.** A V — two facets, the near one at `ink.opacity(0.55)`, the far one at `0.22`, so it reads as depth — scales from nothing to full on its own baseline with `.spring(response: 0.16, dampingFraction: 0.74)`, widening 1 pt past its final width and settling back. That overshoot is the whole pleasure: the wood gives, then holds. |
| 40 | **The chip flies.** `.confetti(trigger: cuts, colors: [ash, palest ash, walnut], from: the notch, count: 7, power: 0.22)` — seven pale slivers thrown up and to the right, gone in half a second. Not confetti: swarf. |
| 55 | `Tones.shared.play(.step(run.chain % 5))` — the tone climbs through the gate and resets on the fifth, so the five-bar gate is audible before it is visible. |
| 90–170 | **The blade lifts** on `Motion.pop` and comes to rest over the *next* position, 9 pt further along the shoulder. The stave never moves; the blade walks. That travel is the anticipation for the next cut, and it is why the thumb can find the target without looking. |
| 130 | `Haptics.tap()` on the lift — the second tick. A real cut is bite then release, and two taps 130 ms apart is what makes the thumb believe it. |
| every 5th | **The gate closes.** The four uprights just cut are struck through by a diagonal at 62°, a `Path` `.trim(to:)` 0→1 over 0.18 s on `Motion.gentle`, cut deeper at `ink.opacity(0.62)`. `Haptics.soft()`, `Tones.shared.play(.pop)`. The closed gate then slides 4 pt left into the row with `matchedGeometryEffect`, making room for the next. |
| every 50th | **The stave is scored** — see "The reward". |

**Why it holds up the thousandth time:** the notch overshoot is a physical answer rather than a
state change; the blade's walk means the finger always knows where the next one lands; the tone
resets every five, so the ninety-ninth cut sounds different from the hundredth; and the stave
is never the same picture twice, because it is filling.

**Teaching the first one with no text.** On a bare stave the blade **breathes** — lifting 3 pt
and settling over 2.6 s, `.ambientFloat(distance: 3, period: 2.6)` — and a single ghost notch
is drawn on the shoulder where the first cut will land, at `ink.opacity(0.10)`, pulsing with
`.breathing(amount: 0.05, period: 2.6)`. Both stop at the first cut and never come back. There
is no "tap to add" anywhere in the app. The VoiceOver hint is the exception and does explain:
`"Cuts a notch into \(counter.name)"`.

## The reward

**The stave is scored.** The fiftieth notch fills the shoulder, and the screen does not open a
sheet with a checkmark — the stave is finished, dated and stood up in front of you.

| ms | what happens |
| --- | --- |
| 0 | The fiftieth cut lands as normal: blade down, notch opens, `Haptics.rigid()`. |
| 90 | **Everything holds.** The bench dims 10 %, the blade stops mid-lift, and the stave's ten gates light one after another, left to right, 26 ms apart, in `highlight`. |
| 320–660 | **The score.** One long stroke is drawn corner to corner across the whole stave, `.trim(to:)` 0→1 over 0.34 s on `Motion.gentle`, cut deep and dark. This is the scoring cut that closes a tally stick. `Haptics.thud()` when it lands at 660. |
| 420–1120 | **The count.** Behind the stave the counter's running total rises as a ghost numeral at `.brandDisplay(size: 132)` in `highlight.opacity(0.16)`: `CountUp(to: total, duration: 0.7, onTick:)`, each tick firing `Haptics.impact(0.3 + 0.05 × n)` and `Tones.shared.play(.step(n))`. |
| 700–1120 | **The stave lifts** off the bench, rotates upright over 0.42 s on `Motion.bouncy` and travels back into the rack, shrinking to rack scale. One `matchedGeometryEffect` the whole way, so it is the same object arriving somewhere, not a card dismissing. |
| 860 | **The chips fly.** `.confetti(trigger:power: 0.9, count: 64, colors: [#EDE1C6, #F6EFDC, #6A4A2A, #A2361B], from: UnitPoint(x: 0.5, y: 0.46))` — heavy shavings falling fast, never party confetti. |
| 960 | **The end-grain is dated.** The date stamps into the stave's end in the stencil caps, scale 1.4 / −8° → 1.0 / −2° on `Motion.bouncy`, with `Haptics.celebrate()` and `Tones.shared.play(.fanfare)`. |
| 1120 | **A fresh stave slides onto the bench** from the left, +80 pt on `Motion.gentle`, shoulder bare, blade resting at the first position. |
| 1240 | **The line sets**: the tier headline, then the sitting card under it. |
| 1500 | Everything stops. Only the lamp keeps breathing; the rack is still. |

**Tiers**, from `run.tier(score: notchesThisStave, beating: bestCleanRun)`:

| Tier | When | Headline | The difference |
| --- | --- | --- | --- |
| Best | A clean stave that beats your longest clean run | `NOT ONE WAX, AND YOUR BEST` | Chips `power: 1.4, count: 110`; the date stamps **twice** — a fainter impression at −9°, 70 ms early, behind the final one; the whole rack rail turns `highlight` for 0.6 s; `Haptics.celebrate()` twice, 200 ms apart; `.fanfare` then `.step(7)`. |
| Great | A clean stave | `FIFTY, AND NOT A WAXED ONE` | Chips `power: 1.0, count: 72`, `.fanfare`. The scoring stroke is cut in one pass. |
| Good | A stave with wax on it | `SCORED. THE WAX SHOWS, AND THAT IS FINE` | Chips `power: 0.6, count: 40`, `.success` rather than `.fanfare`. The scoring stroke is cut in two passes, 90 ms apart. |

**The day's goal** — the spec's feature — is the other, smaller win. Crossing it fills the
brass gauge to the chalk line, the line flashes once, `Haptics.success()`,
`Tones.shared.play(.success)`, eighteen chips at `power: 0.4`, and one line from the goal pool.
It is deliberately not the stave's ceremony: a goal is a day, a stave is a record.

**Inside the loop**, the small reward is the gate closing every fifth cut — the diagonal
drawing itself, `Haptics.soft()`, `.pop`. A sitting has a shape you can hear before you see it.

## Look

### Palette

Light is the bench under a north window at eleven in the morning: limewashed wall, pale ash,
walnut cuts. Dark is not that inverted — it is the same bench at night with one clipped lamp:
the wall goes blue-black and cold, and the wood stays warm, because the lamp is tungsten and
it is the only light in the room.

| Role | Light | Dark | Job |
| --- | --- | --- | --- |
| `canvas` | `#C3B9A3` | `#13161A` | **Limewash.** The workshop wall behind the bench, warm-grey by day and blue-black at night. |
| `surface` | `#F0E5CC` | `#262117` | **Ash.** The stave, the sitting card, the reading panel, the ledger's day strips. |
| `ink` | `#221A0F` | `#F1E7D3` | **Walnut / lamplight.** Notches, headings, the hero numbers. |
| `inkSoft` | `#4C4334` | `#A79C87` | Dates, the stencil caps, the strip's scale. |
| `accent` | `#17506A` | `#6FBADD` | **Chalk-line blue.** The primary action, today's mark, selection, the goal line. |
| `onAccent` | `#FFF3E8` | `#1E0B05` | Type on the chalk blue. |
| `highlight` | `#A2361B` | `#F0885F` | **Keel red** — the marking raddle a finished stave is scored with. The second voice: the win headline, a scored stave's date, a best, the rack rail. |
| `success` | `#2C6650` | `#6FC0A0` | **Verdigris.** A clean sitting, a goal met. Never system green. |
| `miss` | `#6B5C43` | `#9B8E76` | **Wax.** A cut taken back is filled, not alarmed. Never red. |

`extras` — the six pigments on the bench, which are the spec's "fixed palette of six" for a
new counter. Used as the painted band on a stave's end, that counter's bars on the strip, and
its mark in the ledger. Pigment 0 is the same keel red as `highlight`, which is correct: it is
the same pot.

| # | Name | Light | Dark |
| --- | --- | --- | --- |
| 0 | Keel red | `#A2361B` | `#F0885F` |
| 1 | Chalk blue | `#17506A` | `#6FBADD` |
| 2 | Verdigris | `#2C6650` | `#6FC0A0` |
| 3 | Ochre | `#7E5C12` | `#E0B455` |
| 4 | Logwood | `#5C3A6B` | `#B491C6` |
| 5 | Graphite | `#3E4247` | `#A8AEB5` |

Checked with `node tools/design/contrast.mjs`:

```
ink      #221A0F on #C3B9A3   8.82 AAA    #F1E7D3 on #13161A  14.78 AAA
ink      #221A0F on #F0E5CC  13.73 AAA    #F1E7D3 on #262117  13.04 AAA
inkSoft  #4C4334 on #C3B9A3   5.00 AA     #A79C87 on #13161A   6.69 AA
inkSoft  #4C4334 on #F0E5CC   7.77 AAA    #A79C87 on #262117   5.90 AA
onAccent #FFF3E8 on #17506A   8.04 AAA    #1E0B05 on #6FBADD   8.82 AAA
accent   #17506A on #C3B9A3   4.51 AA     #6FBADD on #13161A   8.42 AAA
accent   #17506A on #F0E5CC   7.02 AAA    #6FBADD on #262117   7.42 AAA
highlight#A2361B on #F0E5CC   5.45 AA     #F0885F on #262117   6.39 AA
success  #2C6650 on #F0E5CC   5.37 AA     #6FC0A0 on #262117   7.41 AAA
miss     #6B5C43 on #F0E5CC   5.19 AA     #9B8E76 on #262117   4.97 AA
```

The pigments run 3.15–5.20 on canvas and 4.90–8.09 on surface in light, and 5.95–9.36 in dark.
On canvas they are only ever painted bands and bars, never type, so 3:1 is their bar and the
weakest — ochre at 3.15 — clears it; every pigment is AA or better on `surface`, which is where
any text in a pigment sits. `highlight` at 3.50 on canvas is likewise only the win headline at
30 pt and the rack rail, both well past the large-text threshold.

Three roles moved after the mocks were rendered and read. `inkSoft` was `#5F5544`, which came
back at 4.36 on the canvas — under AA for a 10.5 pt stencil cap — and `accent` was `#1D5C78` at
4.38; both were darkened. `miss` was `#8A7B63` at 3.18 and went to `#6B5C43`. Then the first
render of mock 3 showed the real problem: at `#CFC7B8` the wall and the ash were too close in
value, and the screen read as exactly the beige the spec complains about. The wall went down to
`#C3B9A3` and the ash up to `#F0E5CC` — 8.82 against 13.73 for `ink`, a step you can see — and
`inkSoft` came down again to `#4C4334` to hold AA on the darker wall.

### Canvas

`BrandCanvas.glow(Color(light: 0xD8CFBC, dark: 0x232A30), at: UnitPoint(x: 0.24, y: 0.02))` —
the north window over the left shoulder by day, the clipped lamp by night. Off-centre on
purpose: a centred glow reads as a vignette, an off-centre one reads as a light source in a
room. The lift is deliberately small. The first mocks used `0xE6DFD2` and it washed the wall
out to beige across the top two-thirds, which cost exactly the value step the darker canvas
had just bought; a window you can find is better than one that floods the room.

Over it the app draws **the limewash** in a single `Canvas`: 900 short horizontal brush
strokes, 8–22 pt long, 1 pt wide, angled ±3°, seeded from a fixed constant so every launch and
every screenshot is identical, at `ink.opacity(0.028)` in light and `.white.opacity(0.030)` in
dark. It never animates — a moving texture is noise.

And **the bench edge**: a 3 pt horizontal band at `ink.opacity(0.10)` with a 1 pt
`highlight.opacity(0.25)` line along its top, running the full width 26 pt below the safe area
on the bench and the face. It is the app's horizon, it says which surface the work is lying
on, and it is in every screenshot.

### Type

`BrandType(display: .default, displayWidth: .compressed, displayWeight: .heavy, body: .default)`
— **SF Pro Compressed Heavy** for every display element. Compressed heavy is the lettering
stencilled on crates, tool chests and timber ends; it is free, it is nobody else's in this
category, and at 116 pt a compressed numeral is unmistakable from one crop. Body copy stays SF
Pro text, because the carver's sentences are speech and have to read easily.

The third voice is **the stencil caps**: `.system(.caption2, design: .monospaced)` with
`.textCase(.uppercase)` and `.tracking(2.6)`. It is the marking on the wood — `STAVE 9`,
`KEPT 61 DAYS`, `THIS SITTING`, `READING`, a date on an end-grain — and never a sentence.

Hero numbers, always compressed heavy through `.brandDisplay(size:)`, which scales with
Dynamic Type:

- the counter's running total on the face — **116 pt**, the largest thing in the app
- the win's ghost numeral — 132 pt at `highlight.opacity(0.16)`, behind the stave
- a stave's total on the bench — **44 pt**
- the ledger's day total — **34 pt**
- the share card's total — **300 pt** on the 1080 × 1350 canvas

Every screen has exactly one thing at 44 pt or over, and nothing else competes with it. No
`.font(.system(size:))` anywhere, on any screen, including the share card: `scaledFont(size:)`
and `brandDisplay(size:)` say the same point size and still scale.

### Shape

**The notch** is the one distinctive shape: a V cut 9 pt wide and 14 pt deep, two facets at
different depths. It repeats at every scale — the cuts on a stave, the day marks on the strip,
the bullet before a paywall line, the selection mark in the pigment picker (a cut, never a
checkmark), and a rule of three notches as a section divider.

**The stave** is the surface: a long rounded rectangle at corner radius **5**, with a 1.5 pt
darker edge along the bottom and a 0.5 pt highlight along the top, so it reads as a piece of
wood with thickness rather than a card with a shadow. `corner: 5` for the whole brand — against
the kit's 22, that alone changes the app's feel.

**The gate** — four uprights and a diagonal — is the progress glyph everywhere: a day cell on
the strip, the goal gauge's ticks, a day header in the ledger.

Nothing in this app is a 22 pt white card with a shadow.

### Art

Drawn as SVG in `design/art/`, rendered by `node tools/design/art.mjs` into the asset catalog
and used as `Image("…")`. No SF Symbol is ever the hero of a screen.

| File | Depicts | Where |
| --- | --- | --- |
| `bench.svg` | The bench in three-quarter: a part-notched stave, the chisel resting on its shoulder, a curl of shavings, the rack rail behind, light from the left. | The empty bench, onboarding 1 |
| `stave.svg` | One stave seen along its length, four gates cut and the fifth open, the painted end-grain band. | Onboarding 2, the add sheet's header |
| `rack.svg` | Six scored staves standing in a rack, each with a different pigment band and a dated end. | The paywall hero, the ledger's locked state |
| `gate.svg` | A single five-bar gate cut deep into ash, the diagonal half-struck, a shaving curling off it. | Onboarding 3, the ledger's empty state |

### Motion

| Spring | For |
| --- | --- |
| `.spring(response: 0.11, dampingFraction: 0.92)` | The blade biting. `Cut.bite`. |
| `.spring(response: 0.16, dampingFraction: 0.74)` | The notch opening, with its 1 pt overshoot. `Cut.open`. |
| `Motion.pop` | The blade lifting and walking to the next position. |
| `Motion.bouncy` | The stave rising into the rack; the date stamping. |
| `Motion.gentle` | The scoring stroke, the gate's diagonal, the reading swapping, the sitting card rising. |
| `Motion.snappy` | Navigation, the add sheet, the pigment picker. |

Ambient: the lamp breathes behind the bench, `.breathing(amount: 0.03, period: 4.4)`; on a bare
stave only, the blade floats, `.ambientFloat(distance: 3, period: 2.6)`, until the first cut.
Both go through FactoryKit, so both stand still under `-stillFrames`.

Never moves: the limewash, the bench edge, the rack, the strip, the stencil caps. Cut notches
never move again once cut — that is the point of them.

### Sound

`Tones` throughout, on the ambient session, with `SoundsToggle()` in Settings.

| Tone | When |
| --- | --- |
| `.step(run.chain % 5)` | Every cut — climbing through the gate, resetting on the fifth |
| `.pop` | A gate closing |
| `.miss` | A cut waxed over |
| `.step(n)` | Each tick of the win's count-up |
| `.fanfare` | A stave scored |
| `.success` | The day's goal reached |
| `.tap` | Selection: a pigment, a stave pulled from the rack |

## Voice

**The carver** — the person who made the staves and keeps the bench. Quietly interested in what
you are counting and completely uninterested in whether you did enough of it.

Three rules:

1. **A number, never an adjective.** "Forty-three into this stave." Never "Great work!"
2. **It reports; it never instructs.** Nothing the app says is a request, a suggestion or an
   imperative about counting.
3. **One sentence, two at most, and it fits on the sitting card.**

### Onboarding

`OnboardingView(pages:nextTitle: "Go on", finishTitle: "Take the blade")`, each page
`OnboardingPage(title:subtitle:art:)`.

| # | Title | Subtitle | Art |
| --- | --- | --- | --- |
| 1 | **A stave for each thing** | "Ash, fifty notches long. One for whatever you are keeping a number on — reps, birds, glasses, cars past the window." | `bench.svg` |
| 2 | **Five to a gate** | "Four uprights and a stroke across them, the way people have counted since before there were numbers to count in." | `gate.svg` |
| 3 | **Full staves go in the rack** | "Scored, dated and stood up behind the bench. Nothing you have cut is ever taken back down." | `rack.svg` |

Page 3 is the one onboarding page allowed to carry the promise, and it carries it as a fact
about the world rather than as a pitch.

### Praise pool — a stave scored

1. "Scored. Fifty notches, and the date on the end."
2. "That is a stave. It goes in the rack the way it is."
3. "Full. The next one is already on the bench."
4. "Fifty. The rack takes it without comment."
5. "Cut through. Good grain on that one."
6. "Done and dated. Nothing on it to explain."
7. "A stave closed. The bench is clear again."
8. "Fifty notches, all of them yours."
9. "Scored across. That is the whole length of it."
10. "Stood up in the rack. It will be there in a year."

### Near-miss pool — a cut waxed

1. "Waxed. The record would rather be right than tidy."
2. "Filled. It still shows, and it should."
3. "Taken back. The wax is paler; you will always know."
4. "One out, one filled. The count is right again."
5. "Waxed over. Nobody minds a wax."
6. "Back to where it was. The mark stays, the number does not."
7. "Filled with wax. An honest stave has a few."
8. "Corrected. The stave keeps the story."

### The day's goal reached

1. "The gauge is at the line."
2. "Eight, and the line is reached."
3. "That is the day's mark, at 6:41."
4. "Level with the line. The rest is extra."
5. "The chalk line is behind you."

### The win's headline, per tier

| Tier | Headline |
| --- | --- |
| Best | `NOT ONE WAX, AND YOUR BEST` |
| Great | `FIFTY, AND NOT A WAXED ONE` |
| Good | `SCORED. THE WAX SHOWS, AND THAT IS FINE` |

### Empty states

| Where | Art | Headline | Line | Button |
| --- | --- | --- | --- | --- |
| No counters | `bench.svg` | **A bare bench** | "There is ash cut to length and a chisel on the rail. Say what the first stave is for." | "Lay a stave on the bench" |
| Ledger, Pro, no cuts | `gate.svg` | **No cuts yet** | "The ledger fills itself the moment a blade goes into anything." | — |
| Ledger, free | `rack.svg` | **The rack is behind the bench** | "Every cut you have made, by the day you made it, with the week and the month beside it." | "See what Pro opens" |
| A stave with no cuts | — | — | Nothing at all: the bare stave, the ghost notch and the breathing blade do the teaching. | — |

### Days kept, and what replaces a streak

The app remembers you and shows it unasked, in the stencil caps at the foot of the face:
`KEPT 61 DAYS · LONGEST RUN 19`. That is all. There is no streak counter, no flame, no number
that goes back to zero, and nothing anywhere that mentions a day you did not count. A gap is
simply a gap in the strip, which is the truth and is not an accusation.

### The reminder notification

**None is sent.** The spec asks for no permissions and no notifications, and a notification
that guilts someone about a counter is the exact thing the taste bar refuses. If one is ever
added it carries this line and only this line:

> "The bench is as you left it — forty-three into the stave."

No count of days missed, no question, no request.

### Paywall

`PaywallView(headline:bullets:promise:cta:hero:)`.

- Headline: **"The rack and the ledger"**
- Bullets:
  - "As many staves on the bench as you want, not three."
  - "The ledger: every cut you have made, by the day, with the week and the month beside it."
  - "The strip on each stave reaches back as far as your record goes, not seven days."
- Promise: **"Three staves and a week of strip stay free, and nothing already cut is ever taken back down."**
- `cta:` **"Start the 3-day trial"** — the trial wins the button, because App Review wants it named there.
- Dismiss: **"Not now"**
- `hero:` `rack.svg`

### Button labels

| Action | Label |
| --- | --- |
| Create the first counter | "Lay a stave on the bench" |
| Toolbar add | the bare-stave glyph, `accessibilityLabel: "Lay a new stave"` |
| Add sheet, confirm | "Lay it on the bench" |
| Add sheet, cancel | "Leave it" |
| Onboarding next / finish | "Go on" / "Take the blade" |
| Paywall | "Start the 3-day trial" |
| Ledger, locked | "See what Pro opens" |
| Free footer on the bench | "Three staves on the bench — the rack holds more" |
| Reset today | "Plane today off" |
| Reset everything | "Plane the stave back" |
| Confirm reset today | "Plane it off" |
| Confirm reset all | "Take it all off" |
| Erase everything | "Clear the bench" |
| Share | "Send the stave" |

## Screens

Every MVP screen the spec names, with every feature it names, in the bench's language.

### 1. The bench — Counters (tab 1) · mock 3 shows it empty

**Its one job:** every stave you keep, and a cut without leaving the screen.

**Hero:** the staves themselves, laid across the screen like work on a bench. Not a list of
cards.

Top to bottom: the bench edge rule under the navigation bar; then one **stave per counter**,
full width less 20 pt, 92 pt tall, each tilted by a seeded angle between −1.4° and +1.6°
(hashed from the counter's id, never random per frame, or it will jitter every redraw) and
overlapping the one above by 6 pt, so they read as a pile of work rather than as rows. Each
stave carries its painted pigment band at the left end, its name burned into the wood in
compressed heavy 22 pt, its running total right-aligned at 44 pt, and along its shoulder **the
last two gates cut**, live. The chisel sits at the right end as the increment — a 44 pt target
drawn as the blade, never an SF Symbol plus.

**What moves:** a cut plays its whole interaction in place on the stave — the notch opens, the
chip flies, the total ticks. Staves `.popIn(delay: index × 0.05)` on appear. Nothing else.

**The toolbar add** is a **bare stave with the first notch cut into it**, drawn as a `Shape` —
a rounded rectangle at radius 5 with a V taken out of its top edge. Not a chisel: a chisel was
tried at toolbar size in mock 3 and at 22 pt it reads as a blob. The stave glyph is the app's
own shape language and still resolves at that size.

**System controls:** `NavigationStack` and its toolbar; a `List` underneath with
`.listRowBackground(Color.clear)`, `.listRowSeparator(.hidden)` and `.brandBackground()`, kept
only because swipe-to-delete is the system's and should stay the system's. Nothing in it looks
like a list row.

**Free tier:** not a lock row. The fourth position on the bench is an **empty stave blank** —
unpainted, uncut — with "Three staves on the bench — the rack holds more" in the stencil caps
across it. Tapping it opens the paywall.

**Empty:** the bare bench, `bench.svg`, and "Lay a stave on the bench". Mock 3.

### 2. The face — Counter detail · mock 1 shows it mid-cut

**Its one job:** one stave, in your hand, and the cut.

**Hero:** the running total at 116 pt compressed heavy, sitting *behind* the stave as though
burned into the bench, with the stave overlapping its lower third.

Top to bottom:

- Inline navigation title: the counter's name. The toolbar carries a `ShareLink` ("Send the
  stave") over `ShareImage.render`, and a `Menu` with "Plane today off" and "Plane the stave
  back", each behind its confirmation and each disabled when there is nothing to take off —
  the spec's two resets, kept exactly.
- The bench edge rule.
- The total at 116 pt, with the day's figure under it in the stencil caps — `9 TODAY` — or,
  when a goal is set, **the brass gauge**: a ruled scale along the stave's top edge with a
  chalk-blue line at the goal, filling `success` as the day's cuts land. This is the spec's
  goal ring, rebuilt as the thing a bench would actually have.
- **The stave**, 300 pt long at 2.5°, its gates cut, its wax fills showing, the chisel resting
  at the next position.
- The two actions: **the chisel** is the cut, a 64 pt target at the blade; **the wax stick** is
  the take-back, a 52 pt target at the stave's left end, smaller and quieter because it is the
  rarer act. Both `.buttonStyle(.pressable)`.
- **The strip** — the spec's fourteen-day chart, in the app's own language. The last `span`
  days (7 free, 14 and growing on Pro), each day a gate cut into a brass-ruled scale, its depth
  the day's count, today's in chalk blue and a day with wax showing it. Drawn in one `Canvas`,
  with one `.accessibilityElement` per day carrying "Tuesday the 4th, nine" so VoiceOver reads
  the chart properly.
- **The reading**, on an ash panel with the brass lamp above it once `gauge` is earned: the
  carver's sentence at 17 pt, labelled `READING` in the stencil caps. One reading, chosen by
  the rota, held for the sitting.
- **The sitting card** rises in place of the reading when a sitting ends.
- `KEPT 61 DAYS · LONGEST RUN 19` in the stencil caps at the foot.
- **The rack rail** across the bottom once `rack` is earned: each scored stave 10 pt wide with
  its date, oldest at the back.

### 3. The ledger — History, Pro (tab 2)

**Its one job:** every cut, by the day it was made.

**Hero:** the per-counter totals at the top as a row of **small staves**, each with its pigment
band, its week figure at 34 pt compressed and its month figure at 17 pt in `inkSoft` beside it
— the spec's "per-counter total for the week and the month", drawn rather than tabulated, and
explicitly *not* a row of identical number tiles with grey captions.

Under it, grouped by day, newest first: each day is a **gate cut into a rule** with the date in
the stencil caps, and beneath it that day's cuts as a run of notch glyphs on an ash strip,
positioned by the time they happened, so a day is legible as a shape. A cut taken back shows as
a wax notch. Tapping a day's strip expands it to the individual times.

**System:** `NavigationStack`, `List` for scrolling and sections, `.brandBackground()`, clear
rows, no separators.

**Locked (free):** `rack.svg`, "The rack is behind the bench", and "See what Pro opens".

### 4. Laying a stave — the add sheet

**Its one job:** name it, pick its pigment, set a goal or do not.

**Hero:** a **bare stave** across the top of the sheet that takes the name as it is typed,
burned in, and takes the pigment band as it is picked.

Below it the system's `Form` on `.brandBackground()`: the name `TextField` ("What is this stave
for?"); the six pigments as a row of painted end-grain swatches with the chosen one marked by a
cut notch rather than a checkmark; and the goal `Toggle` with its `Stepper`, footer "A goal
puts a chalk line on the gauge. Leave it off and the stave just fills."

Buttons: "Leave it" and "Lay it on the bench".

### 5. Settings (tab 3)

The kit's `SettingsView` under `.brand(AppBrand.brand)` and `.brandBackground()`, with the
Tallies rows: an **On this bench** section — `Staves`, `Notches cut`, `Days kept` — then
`SoundsToggle()`, then "Clear the bench" behind its confirmation ("Clear the bench — every
stave and every notch on this phone?"). Footers: free — "Three staves and a week of strip.
Nothing already cut is ever taken back down."; Pro — "Everything you have cut is on this phone
and nowhere else."

The kit's restore, rate, share, support and privacy rows are unchanged.

### 6. The paywall · and 7. Onboarding

Both the kit's, named in the carver's voice as §Voice sets out, each with its art.

### Captures

The critic sees motion through `qa.json`'s `moments`, so the app plays its own signature
interaction and its win on a launch flag: `-demo cut` runs five cuts and closes a gate on the
face; `-demo score` runs the forty-eighth to the fiftieth and scores the stave. Both seed a
fixed record — 61 days kept, 9 staves, a fortnight of strip — so the bench, the rack, the
gauge and a real reading are on screen in every capture rather than a first-launch blank. The
seed is deterministic, which keeps the spec's promise that every screen is reproducible.

## Icon

**The concept:** one five-bar gate, cut into a stave, seen close up. Not the machine — the mark.

**The composition:** the stave lies across the square at −3°, full bleed left and right, with
limewash above and below so it reads as a board on a bench rather than as a page. Its shoulder
is at the top of the board and **four uprights are cut down from it**, each 124 units wide and
412 deep, so every cut breaks the shoulder's lip. The stroke is struck across them at +7.6°,
cut the same way the uprights are — a lit upper lip over a dark trough — so the gate is closed
and this is the fifth. The painted keel-red band caps the near end. The board's lower edge
shows its thickness.

**The colours:** ash `#FCF7EA` → `#DFC99B` down the face, the cut running `#D8BC8A` on the near
facet to `#1A1207` at depth, keel red `#C4462A` → `#8A2A11`, limewash `#DBD2BD` → `#A99E86` with
the window at the upper left.

Read at 120 px next to the leaders' icons: a pale board with four deep marks and a stroke
through them — a tally, and nothing like the chrome drums it sits beside. Three earlier
versions failed that test and were redrawn: a thin stave at −28° whose marks vanished; a
close crop that read as a lined notepad with a red margin; and a version whose shoulder lip was
drawn *over* the cuts instead of under them, so each notch appeared to be crossed out. No
letter, no numeral, no glyph on a gradient. Rendered to `design/icon-1024.png`.

## Share card

1080 × 1350, through `ShareImage.render`. The limewash ground with its brush texture; the stave
laid across at 2.5° with every gate on it; the counter's name burned in at the upper left in
compressed heavy; the running total at 300 pt in walnut; the pigment band at the end. Under it
the strip of the last fourteen days as gates on the brass scale, and
`KEPT 61 DAYS · NOT ONE WAX ON THIS STAVE` in the stencil caps. At the foot, the app's mark —
three notches and `TALLIES`.

Every size on it is asked for through `brandDisplay(size:)` or `scaledFont(size:)`;
`ShareImage.render` pins Dynamic Type to `.large` for the render, so the card lays out
identically for everybody.

## Tokens

The complete `AppBrand.swift` to paste:

```swift
import FactoryKit
import SwiftUI

enum AppBrand {
    static let brand = Brand(
        palette: BrandPalette(
            canvas: Color(light: 0xC3B9A3, dark: 0x13161A),
            surface: Color(light: 0xF0E5CC, dark: 0x262117),
            ink: Color(light: 0x221A0F, dark: 0xF1E7D3),
            inkSoft: Color(light: 0x4C4334, dark: 0xA79C87),
            accent: Color(light: 0x17506A, dark: 0x6FBADD),
            onAccent: Color(light: 0xFFF3E8, dark: 0x1E0B05),
            highlight: Color(light: 0xA2361B, dark: 0xF0885F),
            success: Color(light: 0x2C6650, dark: 0x6FC0A0),
            miss: Color(light: 0x6B5C43, dark: 0x9B8E76),
            extras: [
                Color(light: 0xA2361B, dark: 0xF0885F),   // keel red
                Color(light: 0x17506A, dark: 0x6FBADD),   // chalk blue
                Color(light: 0x2C6650, dark: 0x6FC0A0),   // verdigris
                Color(light: 0x7E5C12, dark: 0xE0B455),   // ochre
                Color(light: 0x5C3A6B, dark: 0xB491C6),   // logwood
                Color(light: 0x3E4247, dark: 0xA8AEB5),   // graphite
            ]
        ),
        type: BrandType(display: .default,
                        displayWidth: .compressed,
                        displayWeight: .heavy,
                        body: .default),
        corner: 5,
        canvas: .glow(Color(light: 0xD8CFBC, dark: 0x232A30),
                      at: UnitPoint(x: 0.24, y: 0.02))
    )
}
```

The six pigments replace `CounterPalette`'s tangerine / ocean / forest / grape / rose / slate.
The spec's "a colour from a fixed palette" is unchanged as a feature; what the six colours are,
and what they are called, is not.

## Slop we are avoiding

1. **Stats as a row of identical number tiles with grey captions.** It is what a counter app
   reaches for the moment it has data, and Streaks — the best-finished app in the category —
   ships exactly it. Tallies has no stat tiles anywhere. Its numbers are one hero total, one
   strip, and one sentence in the carver's voice chosen by the rota from twelve, none of which
   can be shown before it is true.

2. **A result that is a number in a card over "Come back tomorrow."** Every counter app's
   session simply stops; Tallies ships this today, with a Swift Charts bar chart as its ending.
   Instead a sitting ends on the sitting card, which names what is waiting in the carver's
   voice — "Nine in the rack — the gauge goes on the bench at eight." The phrase "come back
   tomorrow" is in none of the app's copy.

3. **The system-grey canvas with white rounded cards** — which is what Tallies ships today, on
   all three screens, plus its category cousin, the photoreal chrome odometer three of the five
   leaders are. Instead: limewash with a drawn brush texture, ash staves at corner radius 5, a
   drawn bench edge as the horizon, and a hero at 116 pt in compressed heavy. Every screen is
   recognisable from one crop and none of them is an instrument.

## Roads not taken

- **The brass hand tally counter** — a machined body, an enamel name plate, number wheels
  rolling over under the thumb, a shelf of them in a fitted case. Killed at §2: three of the
  five leading counter apps already are a photorealistic chrome clicker with an odometer drum,
  so the most obvious world for this app is the one the category owns outright.
- **The core sample** — each counter a glass tube filling with a band of colour for every day,
  read as a geological column, so a year of counting is a stratum. It deepens by construction
  and would make a beautiful share image, but the moment-to-moment verb — a grain falling — has
  none of the cut's weight, and you cannot read your total off a stratum.
