# Lacework · design

## The idea

**A lacemaker's pillow by a window: a pattern pricked into a card and pinned to the bolster,
one bobbin of indigo thread in your hand, and the thread wound from pin to pin until every
pin is taken — then the pins come out and the piece lifts off the pillow as lace.**

Three words: **wound, quiet, whole.**

What it is NOT: **neon on black.** Four of the five leaders are the same screenshot — Color
Maze Master, Color Maze and Maze Madness are glowing arrows on `#101018`, three red hearts at
the top, `Lv. 270` beside them, a lightbulb hint with a badge, and `RELAX YOUR BRAIN!` in a
sticker across the bottom; their icons are neon arrows on a navy gradient. Color Fill 3D is the
other cliché, isometric candy cubes with a purple progress bar and a gem count. Tomb of the
Mask is a pixel arcade in yellow on black. Lacework is **light**: linen, parchment, steel and
brass under window light, with one thread. It has no hearts, no level counter in the corner,
no lightbulb, no arrows anywhere. Its one screenshot is the one screenshot in this category
that is not dark.

The polish bar the best of them set is real and it is this: Color Maze and Maze Madness make a
**picture** out of the finished path — a chameleon, a wave, a crab — and that picture is what
people want. Lacework keeps that pull and earns it honestly: a finished board is a piece of
lace, drawn by the thread you wound, and it goes into a sampler you keep.

## Who and when

He is 38, plays one puzzle a night in bed with the phone on its lowest brightness, and has
deleted three maze apps this year — one because the ads started at level ten after the listing
promised none, one because it reset him to level one, and one because the "daily" stopped
working. He wants ten quiet minutes that are **genuinely hard and never unfair**: a board that
has exactly one answer, that he can reach by looking rather than by trying, and that nobody is
selling him a way out of. The feeling he comes for is the last pin going in — the thread coming
home with nothing left bare, and the piece being *his*.

So nothing on the pillow hurries him and nothing on it is for sale: no clock, no lives, no
hint to buy. The only thing at stake on any evening is whether tonight's piece was worked
**clean** — wound in one go, never picked out — and that costs tonight's board and nothing
else. Calm, and not weightless.

## The play

The loop: **wind one thread through every pin on the pattern, and lift the lace off.** What
he is chasing is a piece worked clean — one thread, never unwound — on a pattern harder than
last night's.

- **The session.** One pattern: four to fifteen minutes, ended by the last pin. A pattern has
  `pins` to take — 25 at rung 5, 81 at rung 50, about 180 at rung 150 — and it paces itself in
  **plaits**: every straight run of four or more pins, at the turn that ends it, tightens into a
  plaited bar (see the signature interaction), so the piece visibly firms up as the thread goes.
  A day offers two patterns: **today's pattern**, seeded from the date so it is the same for
  everyone, and **the next pattern in your own book** (the run). A session ends on the margin
  card (see "The ending"). Nothing counts down and nothing stops him working on.

- **At risk.** `Run`, for the length of one pattern and nothing beyond it. The only thing you
  can do wrong on a pillow is **pick the thread out** — unwind it because it went somewhere it
  should not have.

  - Each pin taken: `run.hit()`. The thread wraps it and the pin sinks.
  - Each **unpick** — one continuous backwards drag, however many pins it unwinds, or a touch
    on an earlier pin of the thread to cut back to it: `run.miss()`, once per gesture, not per
    pin. The thread comes off those pins and they spring back up.
  - A **dead end** — the thread reaches a pin with no bare neighbour while pins remain — is not
    a miss by itself; the thread tugs, the lacemaker says so, and the unpick that follows is the
    miss.

  `run.chain` is **the thread** — pins taken since the last unpick — and `run.longestChain` is
  the longest thread wound on this pattern, which is the score the win's tier is measured on.
  `run.isClean` is a piece worked with no unpick at all.

  What an unpick costs: **this pattern's clean sheet and this thread.** Nothing else. Not a
  life, not a hint, not the day, not a piece already in the sampler, not tomorrow, and nothing
  that can be bought back. You always finish the pattern. Unpicking is free and unlimited; it
  simply means this piece was not worked clean, which is the truth and is all the pillow says.

  This is what makes looking ahead worth doing in a genre where trial and error usually works
  as well — and it does it with no timer, no lives and no score.

### The ladder

`Ladder`, keyed on **rung** — your own position in the pattern book. A pattern worked advances
it by 1. It never goes down. Today's pattern does not move it (see "Today's pattern").

| Dial | From | By | Every | Opens at | Ceiling | What it is |
| --- | --- | --- | --- | --- | --- | --- |
| `side` | 5 | 1 | 12 | 1 | 14 | Pins to a side — 5×5 up to 14×14 |
| `open` | 40 | 5 | 7 | 1 | 100 | How much of the gimp the pattern leaves out, as a percentage of the walls the generator tries to remove |
| `shape` | 1 | 1 | 45 | 30 | 4 | The pricking's outline: 1 a square, 2 a medallion (corners clipped), 3 one window (a hole), 4 a ground of windows |
| `loose` | 0 | 1 | 90 | 41 | 2 | Ends left loose: 0 both start and finish pinned, 1 only the start pinned, 2 neither — the thread may begin anywhere |

```swift
let ladder = Ladder([
    .init("side",  from: 5,  by: 1, every: 12, opensAt: 1,  ceiling: 14),
    .init("open",  from: 40, by: 5, every: 7,  opensAt: 1,  ceiling: 100),
    .init("shape", from: 1,  by: 1, every: 45, opensAt: 30, ceiling: 4),
    .init("loose", from: 0,  by: 1, every: 90, opensAt: 41, ceiling: 2),
])
```

**What `open` means, exactly.** The generator lays a path through every pin first and derives
the gimp from it: every pair of neighbouring pins that are *not* consecutive on the path gets a
wall candidate. With every candidate laid the pattern is a corridor and the thread leads
itself. The generator then walks the candidates in the ground's order (see "What comes next")
and, for the first `open` % of them, removes each one whose removal the solver can still prove
leaves **exactly one** way through. At 40 the pattern is mostly gimp; at 100 it is as open as
can be proved. The proof runs under a fixed node budget, so it is deterministic under a seed
and the dial is honest: the ceiling is "as open as the solver can prove", never "harder than
any board of this shape can be".

**Where it stops, and what happens past it: `flattensAt` is 221** — `loose` reaches 2 at rung
221 — and `ladder.climbs(through: 150)` is true. That is an honest end, stated rather than
dodged with an open dial. Every pattern here is solver-proved, so there is a hardest pattern of
a given shape: fourteen a side, as open as can be proved, a ground of windows, and no end
pinned. Past rung 221 the **shape** is fixed and what still changes is the only thing left:
which **ground** the pattern is pricked in — taken from your own record (see "What comes
next") — and where its windows fall, which the ground's template and the seed decide. Rung 300
and rung 900 are the same shape of pattern built in different grounds against different
weaknesses, and that is said plainly here rather than hidden.

`loose` opens at 41 and moves slowly on purpose: it is the dial that changes the game
qualitatively when the others are nearly spent. With both ends pinned the thread has a known
beginning and a known destination and the whole puzzle is the middle. With the finish loose you
no longer know where you are going. With both loose — from rung 221 — you do not know where to
begin, and the first thing you do on every pattern is read it for the one pin that can only be
an end. The solver proves uniqueness *up to reversal* for a loose pattern (a thread wound
backwards is the same lace), so nothing is ever ambiguous.

### Today's pattern

Today's is **not** on your personal rung — someone joining on day 300 must not be handed a
rung-300 pattern, and someone at rung 300 must not be handed a rung-1 one. It runs a published
week, like a crossword week, the same for everybody:

| Mon | Tue | Wed | Thu | Fri | Sat | Sun |
| --- | --- | --- | --- | --- | --- | --- |
| 6 | 14 | 26 | 40 | 58 | 82 | 120 |

Which gives, through the dials above: Monday 5×5 and mostly gimp; Wednesday 7×7; Friday 9×9,
four fifths open; Saturday 11×11 as a medallion; Sunday 14×14, fully open, with a window in it,
only the start pinned. Seeded from the date, so it is the same pattern for everyone who opens
it, exactly as the spec asks, and its ground is chosen from the date too (a seeded draw over
the grounds open at that rung, never the same ground as the previous three days). Today's
pattern is free forever at every rung, and it counts as a **piece** — for the sampler, for
`Earned`, for the days running — without moving the book's rung.

### What comes next

Nothing here is `%` over a fixed list and nothing is drawn uniformly at random.

**The eight grounds.** A ground is the pricking's character: it decides where the generator
removes gimp first, and so what kind of thinking the pattern asks for. Real lace grounds, in the
order the book opens them:

| # | Ground | Opens | What the generator does | What it asks of you |
| --- | --- | --- | --- | --- |
| 1 | Tulle | 1 | Removes candidates in seeded random order | Even, everywhere |
| 2 | Bar | 1 | Removes walls that lie *across* long straight corridors last, so the pattern keeps long bars | Count the bars; the plaits come easy |
| 3 | Rose | 10 | Removes the four walls around 2×2 blocks first | Every little square is a choice of two |
| 4 | Torchon | 22 | Removes walls along the diagonals first, so the open space runs in staircases | Read diagonally |
| 5 | Spider | 36 | Removes walls nearest the centre first; the border stays corridored | Open middle, tight edges |
| 6 | Fan | 52 | Removes walls nearest one corner first, fading toward the opposite corner | Open at one end, closed at the other |
| 7 | Honeycomb | 70 | Removes alternate candidates in a checker so that no two open cells share both a row and a column gap | Everything is a zigzag |
| 8 | Valenciennes | 90 | Removes walls along the border first; the centre stays corridored | Open edges, tight middle |

When `shape` is 3 or 4, the ground's template also decides **where the windows fall**: Spider
cuts its window dead centre, Fan cuts it in the closed corner, Valenciennes cuts a ring of
small windows just inside the border, Honeycomb cuts a checker of single-pin windows, the rest
cut theirs from a seeded position.

`Mastery<Ground>` over the eight ground ids, **written on every finished piece and read to
choose the next pattern in the book**:

- a piece worked with at most one unpick → `mastery.record(ground, correct: true)`
- a piece worked with three or more unpicks, or a pattern wiped and restarted →
  `mastery.record(ground, correct: false)`
- two unpicks: nothing recorded — neither mastery nor a miss

Then, for the next pattern in the book:

1. `let ground = mastery.next(from: groundsOpen(at: rung), count: 1, unseenShare: 0.3, avoiding: lastThreeGrounds).first`
   — the ground he is weakest at, with a share of ones he has not met, and not one of the last
   three.
2. The generator builds the pattern for `ladder.dials(at: rung)` in that ground, from the seed
   `(rung, playerSalt)`. The seed makes the pattern reproducible — a screenshot of rung 5 and a
   screenshot of rung 500 are repeatable — and it never comes round again, because the rung
   never repeats.
3. **Loose work** (endless, Pro) is the same rule with the counter `loosePiecesWorked` in place
   of the rung for the seed, and the *current* rung's dials, so a loose pattern is as hard as
   the book is right now and never the same pattern twice.

`open`, `side`, `shape` and `loose` are read by the generator; `strength` is compared in
`Mastery.next`. Nothing here is a field that is written, displayed and never read. The per-size
and per-ground ledger on the Patterns screen (the spec's "per-size solve stats") is a *view* of
the same records the generator reads.

### Earned

`Earned`, on **pieces worked** — today's patterns and book patterns and loose work together.
These arrive for winding, never for paying; the book past sixty is behind the one-time unlock,
and that door cannot be the only one.

| At | id | What opens | The line |
| --- | --- | --- | --- |
| 1 | `sampler` | **The sampler.** Finished pieces are kept on a cloth, newest first, and any one can be taken down and looked at. | "Your first piece is in the sampler. It will keep." |
| 6 | `silk` | **Rose silk.** A second thread — pick it in the workbox or from the pillow's menu; the piece is worked and kept in that colour. | "Six pieces. There is rose silk in the workbox now — wind with whichever you like." |
| 15 | `pin` | **The marking pin.** Press and hold any bare pin to push a marking pin in beside it (up to three on a pattern): a note to yourself that the thread must get there. It knows nothing and solves nothing. | "Fifteen. Take a marking pin from the cushion — press one in beside any hole you mean to come back to." |
| 40 | `gold` | **Gold thread**, and a **picot edge**: every piece from here is kept in the sampler with a scalloped edge, and the swatch you send carries it too. | "Forty pieces. Gold thread, and picots on the edge of everything you work from here." |
| 100 | `ticking` | **Indigo ticking.** The pillow is re-covered in blue-striped ticking; the linen stays in the workbox if he prefers it. | "A hundred. The pillow gets a new cover — indigo ticking, if you want it." |
| 200 | `initials` | **Initials.** Two letters, worked in small cross-stitch into the corner of every swatch and every piece in the sampler from here. | "Two hundred pieces. A lacemaker signs her work. Two letters, in the workbox." |
| 365 | `year` | **The year cloth.** The sampler hangs a second cloth; the first, with a year of pieces on it, is hemmed and framed at the top of the screen. | "A year of pieces. That cloth is full — it gets hemmed and hung, and a fresh one goes up." |

`earned.next(after: piecesWorked)` is what a session ends on. The marking pin is the one tool
in the app, and it is earned, free, and unlimited once it arrives. There is no hint: the pillow
never tells you where the thread goes, which is the whole point of it.

### The ending

The exact words, on the margin card under the lifted lace:

> **"Off the pillow clean — eighty-one pins in one thread. Nineteen pieces in the sampler.
> Gold thread comes at forty."**
>
> **"Next in the book: nine by nine, the spider ground."**

The shape, two lines: `"{Off the pillow clean | Off the pillow, picked out {once | n times}} —
{pins} pins in one thread. {pieces} pieces in the sampler. {earned.next, shortened}."` then, for
a book or loose pattern, `"Next in the book: {side} by {side}, the {ground} ground."`, and for
today's pattern, `"Today's is in the sampler. Tomorrow's is pricked at midnight."` Past the last
milestone the first line names the record instead: `"… {pieces} pieces in the sampler, and
{days} days running since the third of September."` On a first-ever piece: **"Your first piece.
It goes in the sampler, and the pillow is cleared for the next one."**

Specific, earned, true, and with no guilt in it. The words "come back tomorrow" appear nowhere
in the app.

### Sessions 5, 50 and 500

- **5.** Five by five — twenty-five pins, both ends pinned: a brass-headed start and a ringed
  finish. Two fifths open, so the gimp does most of the leading; the puzzle is one fork. Tulle
  or bar ground. Two pieces in the sampler and the silk four pieces away. The thread to protect
  is twenty-five pins long, and a clean piece is very possible.
- **50.** Nine by nine — eighty-one pins, four fifths open, both ends still pinned, and the rose,
  torchon and spider grounds in play, the next one chosen against his own record. The marking
  pin is on the cushion, the silk is in hand, the sampler has forty-odd pieces on it, and a
  longest thread of sixty is genuinely worth not breaking.
- **150.** Fourteen by fourteen with **a window cut in it** — about a hundred and eighty pins,
  as open as can be proved, every ground through Valenciennes in the book, and **only the start
  is pinned**: he does not know where the thread ends, so the first minute is spent finding the
  one pin that can only be a finish. Gold thread, picot edges.
- **500.** Fourteen by fourteen in a **ground of windows** — a checker of holes in a
  honeycomb, a ring of them in a Valenciennes — and **neither end pinned**: the thread may begin
  anywhere, and the pattern was built in the ground his record says he is worst at. Signed with
  his initials, kept on the second cloth.

  Session 5 and session 500 are not the same game. At 5 he follows the gimp between two brass
  pins. At 500 he reads a hundred and eighty holes for the two that can only be ends before he
  touches the pillow.

## The signature interaction

**Winding the thread.** It is the verb he performs eighty times a pattern and a few hundred
times a week, and every pin has the same three beats: the thread reaches, it wraps, the pin
sinks.

### Taking a pin

| ms | what happens |
| --- | --- |
| finger down | On the brass start pin (or, when both ends are loose, any bare pin). Its head brightens 12 %, and **the bobbin** appears — a small walnut bobbin, 14 × 34 pt, hanging 22 pt below and to the right of the finger, following it with a 60 ms lag on `Motion.gentle` so it swings. `Haptics.soft()`. |
| 0–70 | **The reach.** As the finger crosses into the inner 64 % of a neighbouring bare pin's cell, the thread extends from the last pin to the new one: a `Path` from centre to centre, `.trim(to:)` 0 → 1 over 0.07 s on `.spring(response: 0.12, dampingFraction: 0.9)` — `Lace.wind`. 3.4 pt, round caps, in the thread colour. |
| 40 | **The wrap.** If the thread turns at this pin, the corner is drawn as a wrap: the path goes *round* the pin on an arc of radius 0.36 cell rather than through its centre, so the thread visibly hangs on the pin the way lace does. Straight runs pass the pin on its outer side. |
| 70 | **The pin sinks.** Its head scales 1 → 0.86 and its shadow goes; it has been pushed into the pillow under the thread. `Haptics.selection()` — a detent, one per pin. |
| 70 | `Tones.shared.play(.step(runLength % 5), volume: 0.35)` where `runLength` is the pins in the current straight run — so a long bar plays a rising phrase and a turn starts the phrase over. The shape of the thread is audible before it is legible. |
| 110 | Settled. Nothing about a taken pin moves again until the lift. |

### The plait

When a straight run reaches its fourth pin and then **turns**, that run tightens into a plait
over 0.2 s: its stroke goes 3.4 → 3.8 pt and back on `Motion.pop`, and the **twist** appears
along it — a 1 pt second strand in the thread colour lightened 35 %, dashed 3/3, laid over the
run. `Haptics.tap()`, `Tones.shared.play(.pop, volume: 0.5)`, and one line from the plait
pool in the margin for 1.5 s. A wobbly path comes out plain; a well-read one comes out plaited,
and the difference is on the swatch.

### Picking out

Dragging back onto the previous pin unwinds it: the thread's end retracts over 0.07 s (the same
`.trim`, reversed), the pin **springs up** — scale 0.86 → 1.04 → 1 on `Motion.pop` — and the
plait, if the run had one, comes undone. `Haptics.soft()`, `Tones.shared.play(.tap,
volume: 0.3)`. The first pin unwound in a gesture is the `run.miss()`; the rest of the same
backwards drag are free. Touching a pin already on the thread and dragging from it cuts the
thread back to that pin in one motion — also one miss. One line from the near-miss pool sets in
the margin for 2 s.

### The dead end

The thread reaches a pin with no bare neighbour while pins remain: the thread's end **tugs** —
two 2 pt pulls along its last direction, 90 ms apart, in a `keyframeAnimator` — and the pin
that stopped it takes a `miss`-coloured ring for 1 s. `Haptics.rigid()`, `Tones.shared.play(
.miss, volume: 0.4)`. Never `Haptics.error()`; a dead end is information, not an alarm. The
near-miss line names it: "Nowhere to go from there. Unwind a little."

### Lifting the finger

The thread stays exactly where it is. The bobbin drops beside the last pin — falls 6 pt and
settles at 20° on `Motion.bouncy` — and lies there. Touching the bobbin, or the last pin, picks
it up again. A pattern half wound is saved as it stands and is exactly as it was after a
relaunch. Nothing is lost by stopping.

**Why it holds up the thousandth time:** every pin is three beats — reach, wrap, sink — with a
detent under the finger for each, the phrase climbs while the thread runs straight and resets
when it turns, a good run tightens into a plait you can see and hear, and the pillow is never
the same picture twice because it is filling.

### Tapping instead of dragging

A tap on a bare pin next to the thread's end takes it, with all the same beats. This is what
VoiceOver and Switch Control use, and what someone with a tremor uses; it is never mentioned in
text. Every pin is an accessibility element — "Pin, row 3 column 7, bare" / "on the thread" /
"start" — and the thread's end carries the hint: "Drag or double tap a neighbouring pin to
wind the thread onto it. Every pin, once."

### Teaching the first one with no text

On a pattern with no thread on it, the brass start pin's head **breathes** —
`.breathing(amount: 0.08, period: 2.4)` — and a **ghost thread** runs from it into the first
forced pin at the thread colour's 22 % opacity, `.trim` 0 → 1 over 1.2 s then gone, looping
every 2 s through a `TimelineView` that checks `Motion.isStill`. Both stop at the first pin
taken and never come back. The words "drag", "swipe" and "tap" appear nowhere on the pillow.

## The reward

**The lift.** The last pin goes in and the pillow does not open a sheet with a checkmark on it
— the pins come out and the lace lifts off while he watches.

| ms | what happens |
| --- | --- |
| 0 | The last pin sinks as normal. `Haptics.thud()`. |
| 120–720 | **The thread tightens.** A wave runs from the start pin to the last: each segment's stroke goes 3.4 → 3.8 pt and its colour brightens 6 %, staggered so the whole wave takes 0.6 s however many pins there are (`stagger = 0.6 / pins`). Every run gets its twist, plaited or not: the whole piece is lace now. `Tones.shared.play(.success)` at 200. |
| 260–860 | **The pins come out.** In the same wave, each pin's head rises out of the pillow — scale 1 → 1.3 → 0, opacity → 0 — and leaves a **prick**, a 1.5 pt hole in the card where it stood. Four beats spaced evenly through the wave fire `Haptics.impact(0.25 + 0.15 × beat)` and `Tones.shared.play(.step(beat))`. |
| 720–1120 | **The lace lifts.** The thread — now the whole figure, free of its pins — scales 1 → 1.06 and rises 14 pt on `Motion.bouncy`, a soft shadow growing under it (radius 0 → 18, opacity 0 → 0.22); the pillow dims 8 % on `Motion.gentle`. `Haptics.celebrate()` and `Tones.shared.play(.fanfare)` at 760. |
| 900–1500 | **The count.** Behind the lifted lace, the pins taken rise as a ghost numeral at `.brandDisplay(size: 112)` in `accent.opacity(0.14)`: `CountUp(to: pins, duration: 0.6, onTick:)`, each tick `Haptics.impact(0.25 + 0.03 × n)`. |
| 1000 | **Snips and pin-heads.** `.confetti(trigger: lifts, colors: [steel, threadColour, brass], from: UnitPoint(x: 0.5, y: 0.45), count: 40, power: 0.6)` — a small, heavy fall of steel and thread-ends, gone fast. Never party confetti. |
| 1150 | The tier headline sets under the lace in New York at 30 pt, in `highlight`, then the lacemaker's line from the praise pool under it in `inkSoft`. |
| 1320 | **The margin card** rises on `Motion.gentle` with the ending's two lines and the buttons. |
| 1500 | Everything stops. The lace hangs 14 pt above the pillow with its shadow under it; only the window light keeps breathing. |

**Tiers**, from `run.tier(score: run.longestChain, beating: bestThread)`:

| Tier | When | Headline | The difference |
| --- | --- | --- | --- |
| `best` | Clean, and a longer thread than he has ever wound | "Clean, and the longest thread you have wound" | The lace lifts **28 pt** and takes a **gold picot edge** — a scalloped hairline drawn around its outline, 40 scallops, on `Motion.bouncy` 200 ms after the lift; snips at `power: 1.2, count: 70`; `Haptics.celebrate()` twice, 200 ms apart; `.fanfare` then `.step(7)`. |
| `clean` | No unpick | "Worked clean, in one thread" | `power: 0.8, count: 52`, `.fanfare`. The full lift. |
| `good` | Four pins in five taken without an unpick — `hits / attempts ≥ 0.8` | "Off the pillow. Picked out {once | n times}, and nobody will know" | `power: 0.5, count: 34`, `.success` in place of `.fanfare`; the lift is 10 pt. |
| `finished` | The rest | "Off the pillow. It fought you, and it is lace all the same" | `power: 0.4, count: 26`, `.success`; the lift is 10 pt; no snips at all if it was wiped and restarted. |

**Inside the loop**, the small reward is the plait: a run tightening, the twist appearing,
`Haptics.tap()`, `.pop`. A pattern has a shape you can hear before you can see it: a rising
phrase per bar, a pop per plait, one lift.

## Look

### Palette

Light is the pillow by a window at ten in the morning: unbleached linen, a parchment pricking
card, steel pins with brass heads, indigo thread, the bobbin's walnut. Dark is not that inverted:
it is the same pillow at night under one lamp — the linen goes to a deep blue-grey, the card
dims to slate, and **the thread, brass and walnut stay warm**, because thread under a lamp is
still thread.

| Role | Light | Dark | Job |
| --- | --- | --- | --- |
| `canvas` | `#E8E0CF` | `#1A1C24` | **The linen.** The cloth over the pillow and the room behind everything. |
| `surface` | `#F8F3E7` | `#2A2C35` | **The pricking card.** The pattern's parchment, the margin card, the sampler cloth, the pattern book's pages. |
| `ink` | `#2A2521` | `#F2ECDF` | **Walnut ink.** Type, and the gimp. |
| `inkSoft` | `#655B52` | `#B3AB9C` | The caps, dates, the lacemaker's asides. |
| `accent` | `#31497A` | `#91A9E3` | **Indigo thread** — the working colour. The thread, primary actions, selection, today's ring. |
| `onAccent` | `#F8F3E7` | `#0E1526` | Type on the indigo. |
| `highlight` | `#A8413A` | `#F0917F` | **Madder.** The second voice: the win's headline, the best, a plait's flash, the bobbin's painted band, the day's pin on the month card. |
| `success` | `#4A7457` | `#8EC59B` | **Sage.** A plait made, a piece worked clean, the reminder pinned. Never system green. |
| `miss` | `#7A6748` | `#BFAE8C` | **The crease.** The ring on a dead-end pin, the near-miss line. A picked-out thread's crease in the card, never red, never an alarm. |

**`extras` — the workbox**, in this order:

| # | Name | Light | Dark | What it is |
| --- | --- | --- | --- | --- |
| 0 | Steel | `#6F7B88` | `#A2ADBA` | Pin shafts and heads |
| 1 | Brass | `#9C7A2E` | `#E0BB62` | The start pin's head, the finish pin's ring, the corner pins that hold the card |
| 2 | Rose silk | `#C4586A` | `#EC93A6` | The second thread (earned at 6) |
| 3 | Gold thread | `#A8842E` | `#DCB85A` | The third thread and the picot edge (earned at 40) |
| 4 | Walnut | `#7A4E2E` | `#B07A52` | The bobbin |

**The rule that governs all of them: colour is thread, and thread goes on the card.** The
pillow and the linen carry no colour but their own; the card carries the gimp in ink and the
pins in steel; the only saturated thing on the screen is the thread being wound, in whichever
colour he chose, and the one brass pin it started from. The madder and sage appear as words
and small marks in the margin, never on the card. That rule is what keeps the pillow from
becoming the category's neon tangle, and it is checkable: any colour inside the card's edge
that is not thread, brass or steel is a bug.

Checked with `node tools/design/contrast.mjs`:

```
ink       #2A2521 on #E8E0CF  11.55 AAA    #F2ECDF on #1A1C24  14.44 AAA
ink       #2A2521 on #F8F3E7  13.69 AAA    #F2ECDF on #2A2C35  11.81 AAA
inkSoft   #655B52 on #E8E0CF   5.04 AA     #B3AB9C on #1A1C24   7.46 AAA
inkSoft   #655B52 on #F8F3E7   5.98 AA     #B3AB9C on #2A2C35   6.11 AA
onAccent  #F8F3E7 on #31497A   8.02 AAA    #0E1526 on #91A9E3   7.79 AAA
accent    #31497A on #F8F3E7   8.02 AAA    #91A9E3 on #2A2C35   5.95 AA
accent    #31497A on #E8E0CF   6.76 AA     #91A9E3 on #1A1C24   7.28 AAA
highlight #A8413A on #F8F3E7   5.45 AA     #F0917F on #2A2C35   6.00 AA
highlight #A8413A on #E8E0CF   4.59 AA     #F0917F on #1A1C24   7.33 AAA
success   #4A7457 on #F8F3E7   4.83 AA     #8EC59B on #2A2C35   7.03 AAA
miss      #7A6748 on #F8F3E7   4.91 AA     #BFAE8C on #2A2C35   6.39 AA
steel     #6F7B88 on #F8F3E7   3.90 large  #A2ADBA on #2A2C35   6.11 AA
brass     #9C7A2E on #F8F3E7   3.62 large  #E0BB62 on #2A2C35   7.58 AAA
rose      #C4586A on #F8F3E7   3.83 large  #EC93A6 on #2A2C35   6.15 AA
gold      #A8842E on #F8F3E7   3.16 large  #DCB85A on #2A2C35   7.32 AAA
walnut    #7A4E2E on #F8F3E7   6.41 AA     #B07A52 on #2A2C35   3.81 large
```

Every role that carries body text is AA or better on what it sits on, in both modes. Steel,
brass, the two extra threads and the walnut are marks, not text — a 3.4 pt thread, a 5 pt pin
head, a bobbin — and clear the 3:1 glyph bar; none of them ever sets a word. `success` on the
linen (4.07) is only ever a glyph there, which is a 3:1 bar; wherever it sets a word it sits on
the card.

### Canvas

`BrandCanvas.glow(Color(light: 0xF6F0E3, dark: 0x2C2A30), at: UnitPoint(x: 0.22, y: 0.06))` —
window light from the upper **left** by day; the lamp on the same side at night, warmer. Small
on purpose: a glow you can find reads as a window, one that floods reads as a vignette.

Over it, drawn once in a single `Canvas`: **the weave**. Two fields of 0.75 pt lines at 0° and
90° on a 2.6 pt pitch, at `ink.opacity(0.035)` in light and `.white.opacity(0.03)` in dark,
seeded from a fixed constant so every launch and every screenshot are identical; it never
animates. It is linen. (After `ticking` is earned and chosen, a third field is added: 9 pt bands
of `accent.opacity(0.10)` every 34 pt, vertical. That is the only difference between the two
covers.)

And **the pillow**: on the Pillow screen, a rounded bolster the width of the screen less 12 pt
on each side, corner radius 28, in the canvas colour darkened 5 % with a 1 pt inner highlight
along its top edge and a 24 pt soft shadow beneath — the thing the card is pinned to. The card
sits on it at a slight, fixed −1.2°, held by **four brass pins** at its corners, each with a
2 pt shadow. Those four pins are in every screenshot of this app.

### Type

`BrandType(display: .serif, displayWidth: .standard, displayWeight: .medium, body: .default)`
— **New York Medium** for every display element. A sampler is lettered in a serif; the category
is heavy rounded sans and pixel faces without exception; New York is free and nobody else's
here. *Medium*, not bold: at 112 pt a medium-weight serif numeral has hairlines in it, and
hairlines are what this app is made of. Body copy is SF Pro, because the lacemaker speaks in
sentences that have to read fast on a phone at its lowest brightness.

The third voice is **the caps**: `.caption2` with `.textCase(.uppercase)` and `.tracking(2)`
in `inkSoft` — the small letters cross-stitched along the hem of a sampler: `TODAY'S PATTERN ·
NINE BY NINE · ROSE GROUND`, `THREAD 31`, `PATTERN 51`, `19 PIECES · 12 DAYS RUNNING`. Never a
sentence.

Hero numbers, always through `.brandDisplay(size:)` so they scale with Dynamic Type:

- **pieces worked, on the sampler — 112 pt**, the largest thing in the app after the win
- the win's ghost numeral — 112 pt at `accent.opacity(0.14)`, behind the lifted lace
- the next pattern's number on the book's front card — 76 pt
- pins taken, above the pillow — 34 pt (`54` with `of 81 pins` in the caps beside it)
- the swatch's pin count — 240 pt on the 1080 × 1350 card

Every screen has exactly one thing at 34 pt or over and nothing else competing with it. No
`.font(.system(size:))` anywhere, on any screen, including the share card: `scaledFont(size:)`
and `brandDisplay(size:)` say the same point size and still scale.

### Shape

**The pin** is the one distinctive shape: a 1 pt steel shaft with a round head, 5 pt across on
the card, drawn with a 1.5 pt highlight dot at its upper left and a 1 pt shadow below and to
the right. It is every cell's marker, the page indicator in onboarding
(`OnboardingView(indexMark: "●")`, set in New York), the bullet before every paywall line
(`PaywallBullets.ruled(mark: "●")`), the selection mark in every picker — never a checkmark,
anywhere in the app — the dot on the month card for a day worked, and a rule of three pin-heads
as a section divider.

**Corner radius 10**, for the whole brand. A pricking card is stiff paper with its corners
snipped, not a rounded card; the pillow alone is softer (28) and is drawn, not a surface.
Against the kit's 22 that alone changes how the app feels before anything else is drawn.

**The thread** is drawn one way everywhere: 3.4 pt, round caps and joins, going *round* a pin
on an arc of 0.36 cell where it turns, along the pin's outer side where it runs straight, and
with a 1 pt lightened dashed strand along any run that is plaited. The same thread, at the same
proportions, is the piece in the sampler (at 56 pt per piece), the swatch on the share card, the
figure on the icon, and the illustration's subject. **The gimp** — the pattern's walls — is the
other line: 2.5 pt in `ink.opacity(0.7)`, round caps, matte, drawn on the card *between* cells,
never through a pin. Thread never crosses gimp and never crosses itself; the app has no
crossing anywhere in it.

**A cell** is a 5 pt pin on parchment with a 1 pt prick-shadow, nothing else. No cell borders,
no grid lines: the pins *are* the grid, at the cell pitch (about 34 pt at five a side down to
about 25 pt at fourteen). Windows — the holes a shaped pricking has — are simply areas of the
card with no pins and no card: the pillow shows through a snipped edge.

### Art

Drawn as SVG in `design/art/`, rendered by `node tools/design/art.mjs` into the asset catalog
and used as `Image("…")`. No SF Symbol is ever the hero of a screen.

| File | Depicts | Where |
| --- | --- | --- |
| `pillow.svg` | The lace pillow three-quarter on: the bolster in linen, a pricking card pinned at its corners with a pattern of pins, a thread wound part way through it, a walnut bobbin lying beside the thread's end, window light from the left. | Onboarding 1, the sampler's empty state |
| `bobbins.svg` | Two bobbins crossed, one wound with indigo and one with rose, their spangles (the ring of glass beads on the end) catching the light, on linen. | Onboarding 2, the pillow's "today's is in the sampler" state |
| `lace.svg` | A finished piece lifted off the pillow: a square of lace with a picot edge, curling slightly at one corner, its shadow on the card below and the pricks where its pins were. | Onboarding 3, the sampler's masthead when the year cloth is earned |
| `book.svg` | The pattern book open on the pillow: a stack of pricked cards, the top one a medallion, a ribbon marker, a pin cushion beside it. | The paywall hero, the book's locked state |

Every piece is thread, steel, brass, walnut and parchment on linen, in the palette above and
nothing outside it. Anything that moves part by part — the pins sinking, the thread — is drawn
in SwiftUI; these are whole pictures that float.

### Motion

| Spring | For |
| --- | --- |
| `.spring(response: 0.12, dampingFraction: 0.9)` | The thread reaching a pin, and retracting. `Lace.wind`. |
| `Motion.pop` | A pin springing up when picked out; a plait tightening; a marking pin going in. |
| `Motion.bouncy` | The lace lifting; the bobbin dropping; the picot edge arriving. |
| `Motion.gentle` | The bobbin following the finger; the pillow dimming; the margin card; the pattern book's pages. |
| `Motion.snappy` | Navigation, sheets, the month card, the ledger. |

Ambient: the window light **breathes**, `.breathing(amount: 0.03, period: 5)`; on a pattern
with no thread on it, the start pin's head breathes and the ghost thread loops, until the first
pin. The bobbin swings on the finger's lag while winding. All of it through FactoryKit or behind
`Motion.isStill`, so it stands still under `-stillFrames`.

Never moves: the weave, the card, the gimp, a taken pin, the pricks, the sampler, the month
card. The thread, once wound, is still. Motion belongs to the moment of winding and to the lift.

### Sound

`Tones` throughout, on the ambient session, with `SoundsToggle()` in the workbox. Everything is
quiet — this is played in bed.

| Tone | Volume | When |
| --- | --- | --- |
| `.step(runLength % 5)` | 0.35 | Every pin taken — the phrase climbing along a bar, starting over at a turn |
| `.pop` | 0.5 | A plait tightening; a marking pin going in |
| `.tap` | 0.3 | A pin picked out; selection |
| `.miss` | 0.4 | A dead end |
| `.success` | 0.8 | The thread tightening on the last pin; a `good` or `finished` lift |
| `.fanfare` | 0.8 | A clean lift |
| `.step(n)` | 0.6 | The four beats of the pins coming out; `.step(7)` after a `best` |

## Voice

**The lacemaker** — old, unhurried, dry, and better at this than you will ever be. She talks
about the thread, the pins and the pillow. She has never once said "great job".

Three rules:

1. **She talks about the piece, never about you.** "Not a pin bare." Never "You're amazing!"
   and never "You're on a roll!"
2. **She never counts what you missed.** A day not worked is a pattern still pinned; an unpick
   is a thread that came back, which every thread does. Nothing she says is a number that goes
   down.
3. **One sentence. It has to fit in the margin of the card.**

### Onboarding

`OnboardingView(pages:nextTitle: "Go on", finishTitle: "Pick up the bobbin", indexMark: "●")`,
each page `OnboardingPage(title:subtitle:art:)`.

| # | Title | Subtitle | Art |
| --- | --- | --- | --- |
| 1 | **A pattern a day** | "Pricked into a card and pinned to the pillow every morning — the same one for everyone who opens it." | `pillow.svg` |
| 2 | **One thread, every pin** | "Wind it from pin to pin until none is left bare. It never crosses itself, and it never has to." | `bobbins.svg` |
| 3 | **Then the lace comes off** | "Pull the pins and the piece lifts free, into your sampler. Every pattern here was proved to have exactly one way through before it was pricked." | `lace.svg` |

Page 3 is the one onboarding page allowed to carry the promise, and it carries it as a fact
about the world rather than as a pitch.

### Praise pool — a piece lifted

1. "Off the pillow, and not a pin bare."
2. "That is lace. Hold it to the window."
3. "Every pin, once, and the thread came home."
4. "The pins are out and it holds its shape."
5. "Wound like you had done it before."
6. "One thread all the way round, and it lifts clean."
7. "The pattern is used up. Good."
8. "Into the sampler with that one."
9. "Not a knot in it."
10. "The card is empty and the piece is whole."
11. "Neat work. The gimp hardly had to hold you."
12. "Lift it. It is yours now."

### Near-miss pool — an unpick or a dead end

1. "Picked out. The thread does not mind."
2. "That pin was a dead end. Back to the last fork."
3. "Nowhere to go from there. Unwind a little."
4. "The thread came back on itself. It happens on every pillow."
5. "Wound short. Count the bare pins on that side before you go on."
6. "A pin skipped now is a pin bare later. Back up."
7. "The gimp says no. The thread goes round it, not through."
8. "Picked out twice. Look at the corners first — they only have one way in."
9. "Back a few. The pattern has not changed; only the thread has."

### Plait pool — a run tightening

1. "A plait."
2. "Straight and tight."
3. "{n} pins in a bar."
4. "That run will hold."
5. "Good and even."
6. "Plaited. The piece is firming up."

### The win's headline, per tier

| Tier | Headline |
| --- | --- |
| `best` | "Clean, and the longest thread you have wound" |
| `clean` | "Worked clean, in one thread" |
| `good` | "Off the pillow. Picked out {once | n times}, and nobody will know" |
| `finished` | "Off the pillow. It fought you, and it is lace all the same" |

### Empty states

| Where | Art | Headline | Line | Button |
| --- | --- | --- | --- | --- |
| Sampler, nothing worked | `pillow.svg` | **The sampler is bare** | "Today's pattern is pricked and pinned on the pillow. The first piece goes here." | "To the pillow" |
| Pillow, today's already lifted | `bobbins.svg` | **Today's is in the sampler** | "The next pattern in the book is pinned and waiting." | "Pin the next pattern" |
| Book, free, past sixty | `book.svg` | **The book goes on** | "Past the sixtieth the patterns go to fourteen pins a side, medallions and windows, pricked and proved the same way." | "See the whole book" |
| Month card, no days | — | **Nothing pinned this month yet** | "A day you work a piece gets a pin here." | — |
| A pattern with no thread | — | — | Nothing at all: the breathing start pin and the ghost thread do the teaching. | — |

### What remembers you, instead of a streak

Along the hem of the sampler, in the caps, unasked:

`19 PIECES · 12 DAYS RUNNING · LARGEST 12 × 12`

That is all. No flame, no number that goes back to zero, no red, and nothing anywhere that
mentions a day he did not work. A day missed is simply a prick with no pin in it on the month
card, which is the truth and is not an accusation. "Days running" counts consecutive days with
today's pattern lifted; the day it stops, the number quietly starts again from one and nothing
is said.

### The reminder notification

Off unless he pins it. "Pin a reminder" is a system `Toggle` on the sampler and in the workbox;
turning it on asks for permission then and only then, and schedules one local notification a
day at eight in the evening (a `DatePicker` under it sets the hour). It carries this line and
only this line:

> "Today's pattern is pricked and pinned."

No count of days missed, no question, no request, no "don't lose your streak".

### Paywall

`PaywallView(headline:bullets:bulletStyle:promise:subhead:cta:hero:onDone:)`, with
`bulletStyle: .ruled(mark: "●")` — the pin-head, set in New York, because this app's content
is thread on parchment and a `checkmark.circle.fill` in a rounded panel would be the one place
the design stops.

- Headline: **"The whole pattern book"**
- Subhead: "One payment. It is yours, like the pillow."
- Bullets:
  - "Every pattern past the sixtieth — up to fourteen pins a side, medallions and windows, each proved to have one way through."
  - "Loose work: a fresh pattern whenever you want one, as hard as the book is now, and never the same one twice."
  - "The ledger: your pieces by size and by ground."
- Promise: **"Today's pattern stays free, every day, and every piece you have worked stays in the sampler."**
- `cta:` **"Open the pattern book"** — one payment, no subscription and no trial, so the button
  says what the purchase does rather than naming a trial that does not exist.
- Dismiss: **"Another day"**
- `hero:` `book.svg`

### Button labels for every primary action

| Action | Label |
| --- | --- |
| Today's pattern, not started | "Pick up the bobbin" |
| Today's pattern, part wound | "Back to the pillow" |
| The next pattern in the book | "Pin the next pattern" |
| Loose work (Pro) | "Work a loose pattern" |
| Restart | "Pull the pins" |
| Confirm restart | "Pull them" |
| Share | "Send a swatch" |
| Look at a piece in the sampler | (a tap on the piece; VoiceOver "Piece 19, nine by nine, the rose ground, worked clean") |
| Onboarding next / finish | "Go on" / "Pick up the bobbin" |
| Paywall | "Open the pattern book" |
| Paywall dismiss | "Another day" |
| The book, locked | "See the whole book" |
| Reminder toggle | "Pin a reminder" |
| Thread picker | "Thread" (Indigo · Rose silk · Gold) |
| Cover picker | "Cover" (Linen · Indigo ticking) |
| Initials field | "Initials" |
| Marking pin | (press and hold; VoiceOver action "Set a marking pin") |
| Erase everything | "Empty the workbox" |
| Confirm erase | "Empty it" |
| Settings upgrade row | "Open the pattern book" (`upgradeTitle`) / "The pattern book is open" (`activeTitle`) |

## Screens

### 1. The pillow — Today (tab 1) · mock 1 shows it mid-wind

**Its one job:** the pattern, the thread, and the winding.

**Hero:** the card on the pillow — parchment pinned at its corners with four brass pins to a
linen bolster, pricked with pins at the cell pitch, the gimp laid between them in walnut ink,
and the thread wound through it from a brass start pin.

Top to bottom:

- `NavigationStack`, inline title: the pattern's name — "The rose ground" — with the date as
  the subtitle where the toolbar allows it, else `TODAY'S PATTERN · 24 SEPTEMBER` in the caps
  under the title. The toolbar carries a `Menu` with "Pull the pins" (behind its confirmation),
  "Thread" (once silk is earned) and, once the piece is lifted, a `ShareLink`.
- The **caps line**: `TODAY'S PATTERN · NINE BY NINE · ROSE GROUND`, and the count beside it:
  **54** at 34 pt in New York with `of 81 pins` in the caps.
- **The pillow**, with **the card** on it at −1.2°, and on the card: the pins, the gimp, the
  windows (if the shape has them) as snipped holes showing the pillow through, the brass start
  pin (and the ringed finish pin when it is pinned), the thread, the plaits, and the bobbin
  lying where the finger left it. At fourteen a side on a 393 pt phone the pitch is about 25 pt;
  the card fills the width less 32 pt and is square.
- **The margin**, on the pillow under the card: `THREAD 31 · PICKED OUT ONCE` in the caps at the
  left, and the lacemaker's most recent line in `inkSoft` at 15 pt, which changes on a plait, an
  unpick or a dead end and otherwise sits empty. Marking pins (once earned) are set on the card
  itself; nothing about them appears here.
- Once the piece is lifted, the margin becomes the **margin card** (see The reward) with the
  ending's two lines, "Send a swatch" and "Pin the next pattern".

**What moves:** the thread reaching and wrapping, the pins sinking and springing, the plait
tightening, the bobbin following and dropping, the ghost thread on a fresh pattern, the lift.
Nothing else.

**System controls:** `NavigationStack` and its toolbar, `Menu`, `ShareLink`, the confirmation
`alert`. The card is drawn: one `Canvas` for parchment, pricks, pins, gimp and thread, with a
`DragGesture(minimumDistance: 0)` over it and a transparent accessibility grid so every pin is
an element with a label and the tap-to-take fallback.

**Empty (a pattern with no thread):** nothing is written. The start pin breathes and the ghost
thread runs into the first forced pin.

### 2. The sampler — Progress (tab 2) · mock 4

**Its one job:** the pieces, and the days. This is the screen the first App Store screenshot
shows, per the spec's 4.3 note — today's pattern and the days running, not a bare grid.

**Hero:** **pieces worked** at 112 pt in New York Medium, sitting behind the top row of the
sampler with the pieces overlapping its lower third.

Top to bottom:

- **Today**: if today's pattern is not lifted, the card at half scale on the pillow with "Pick
  up the bobbin" (or "Back to the pillow"); if it is, **today's piece** at full width — the
  thread figure on parchment with its plaits, its caps line under it (`TODAY · NINE BY NINE ·
  ROSE GROUND · WORKED CLEAN`) and its tier line.
- **The sampler cloth**: a sheet of `surface` with a hemmed edge (a 1 pt `ink.opacity(0.2)`
  rule 8 pt in from the edge, all round). On it, every piece he has worked as a **small lace** —
  its thread figure at 56 pt square, plaits and picots included, in the thread it was worked in
  — in rows of five, newest first, with its date in the caps under it. Tapping one opens it full
  size on parchment with its ending line. The cloth grows down the screen; at five hundred
  pieces it is a long scroll of small laces, which is the point.
- **The month card**: the month as a pricking card — parchment, a 7 × 5 grid of pricks at
  `ink.opacity(0.18)`. A day he worked carries a **pin** in that day's thread colour; today is
  ringed in `accent`; a day he did not work is a prick with no pin — no grey, no red, nothing.
  The header reads `September` in New York with `TWENTY-TWO PINNED` opposite it in the caps.
- `19 PIECES · 12 DAYS RUNNING · LARGEST 12 × 12` in the caps along the hem.
- "Pin a reminder" as a system `Toggle`, and `ShareLink` over `ShareImage.render` — "Send a
  swatch".

**System:** `NavigationStack`, `ScrollView`, `Toggle`, `DatePicker` (hour), `ShareLink`.

### 3. The book — Packs (tab 3)

**Its one job:** the ladder, pattern by pattern, and what is waiting.

**Hero:** **the pattern book** — a stack of pricked cards, the next one on top, its number at
76 pt in New York on the card and its shape in the caps under it: `PATTERN 51 · NINE BY NINE ·
THE SPIDER GROUND`. Not a `List` of `Label`s and not a grid of level buttons.

- Button under it: "Pin the next pattern". Beside it, once the book is open: "Work a loose
  pattern".
- **Chapters**, one per side, five through fourteen, as tabs of the book down the right edge:
  each with `worked / clean` in the caps and its small laces in a row. The chapter the rung is
  in is the one whose tab is out.
- **The cushion** — `Earned`, as a pin cushion along the bottom: the sampler, the silk, the
  marking pin, the gold, the ticking, the initials, the year cloth — each drawn as a small
  object, each greyed until it arrives, with `earned.next(after:)`'s count under the next one.
- **Free tier:** past pattern 60 the next card is a **blank pricking card** with `THE BOOK GOES
  ON` in the caps across it. Tapping it opens the paywall. Not a lock row and not a price.
- **The ledger** (Pro): a ruled table on parchment, by size and by ground — `worked · clean ·
  longest thread` — which is the spec's per-size stats and is the same record `Mastery` reads.

**System:** `NavigationStack`, `ScrollView`.

### 4. The workbox — Settings (tab 4)

The kit's `SettingsView` under `.brand(AppBrand.brand)` and `.brandBackground()`, with
`upgradeTitle: "Open the pattern book"` and `activeTitle: "The pattern book is open"`, and an
**On the pillow** section — `Pieces worked`, `Longest thread`, `Days running` — then
`SoundsToggle()`, "Pin a reminder" with its hour, "Thread" and "Cover" as `Picker`s (rows
appear as they are earned), "Initials" as a `TextField` (from 200), and "Empty the workbox"
behind its confirmation ("Empty the workbox — every piece and every pin on this phone?").
Footers: free — "Today's pattern and the first sixty in the book. Every piece you have worked
stays in the sampler."; unlocked — "Everything you have worked is on this phone and nowhere
else."

The kit's restore, rate, share, support and privacy rows are unchanged.

### 5. The paywall · and 6. Onboarding · mock 3 shows onboarding page 1

Both the kit's, named in the lacemaker's voice as §Voice sets out, each with its art, the
paywall with `bulletStyle: .ruled(mark: "●")` and `hero: Image("Book")`. Onboarding sets its
title in New York over the art, with `LACEWORK` in the caps at the head of the screen between
two hairlines and a pin-head, and the page indicator drawn as the app's own mark: a pin-head
for the page you are on, an empty prick for each one you are not.

### The mocks

| Mock | Shows |
| --- | --- |
| `design/mock-1-play.html` | The pillow mid-wind: a nine-by-nine rose ground at rung 51, fifty-four of eighty-one pins taken, two plaits, the bobbin under the finger, `THREAD 31 · PICKED OUT ONCE` and a plait line in the margin. |
| `design/mock-2-win.html` | The lift at its peak: the pins out and the pricks left, the lace risen with its shadow, the ghost numeral behind, the `best` headline in madder, and the margin card. |
| `design/mock-3-first.html` | Onboarding page 1, the first thing a new user sees. |
| `design/mock-4-sampler.html` | The sampler: the hero at 112 pt, today's piece, the cloth of small laces, the month card and the hem. This is the first App Store screenshot, per the spec's 4.3 note. |

### Captures

The critic sees motion through `qa.json`'s `moments`, so the app plays its own signature
interaction and its win on a launch flag. `-demo wind` takes fourteen pins including two turns,
one plait, one unpick and the re-wind. `-demo lift` takes the last three pins and plays the
lift. Both seed a fixed record — rung 51, nineteen pieces, twelve days running, the silk and the
marking pin earned, today's pattern half wound — so every capture has a lived-in pillow rather
than a first-launch blank. `-rung 5|51|150|500` seeds the book for the ladder strip. The seed is
deterministic, which keeps the spec's promise that every screen is reproducible.

## Icon

**The concept:** a pricking card on the pillow with one thread wound through every pin. The
piece, not the pillow, and not an arrow.

**The composition:** the parchment card fills the square at −3°, nearly full bleed, held by
four brass pins at its corners, with a sliver of linen showing at the edges and the card's
shadow along the bottom and right so it reads as paper lying on cloth. In the middle 70 %, a
**five-by-five field of pins** — steel shafts seen end-on, each a round head with a highlight —
and **one indigo thread** wound through all twenty-five in a single path that reads as a
serpentine with a twist in it, going round each pin on a wrap and passing straight pins on the
outside, two of its runs plaited with the lighter strand. It starts at a **brass** pin at the
lower left and the last pin it reaches, at the upper right, is ringed. A **walnut bobbin** lies
across the lower-left corner where the thread began, its band painted madder. Three short bars
of gimp lie between pins where the pattern would have them.

**The colours:** the linen `#E8E0CF` → `#D9CFB8` at the edges; the card `#FAF5EA` → `#EFE7D6`
toward the lower right; the thread `#31497A` with a `#8FA5D6` twist; the pins `#6F7B88` heads
with `#FFFFFF` highlights and `#3E4750` shadows; brass `#9C7A2E` with a `#E8CC7A` highlight; the
bobbin `#7A4E2E` with a `#A8413A` band.

Read at 120 px next to the leaders' icons: a cream square with a blue winding line and steel
dots, next to Color Maze Master's red arrows on navy, Maze Madness's neon arrows on black,
Color Fill 3D's pink cubes and Tomb of the Mask's yellow pixel face. The only light icon in the
row. No letter, no numeral, no glyph on a gradient. Rendered to `design/icon-1024.png`.

## Share card

1080 × 1350 through `ShareImage.render`, and it **spoils nothing**: the finished figure is
today's answer, so the card never shows the piece — it shows **a swatch**, a five-by-five
window cut from its centre, which looks like lace and gives nothing away.

The linen with its weave. On it, laid at 1.5°, **a square of parchment** with `LACEWORK` in the
caps across the top between two hairlines and a pin-head, then the date and the pattern —
`24 SEPTEMBER · NINE BY NINE · ROSE GROUND` — in the caps. Under that the **hero number** —
pins taken — at 240 pt in New York Medium in walnut ink, with `PINS` in the caps beside it. Then
**the swatch**: the central 5 × 5 of the piece, drawn as thread at 44 pt a pin in the colour
it was worked in, plaits shown, on parchment with a hairline frame, and once `gold` is earned
with its picot edge. Under it, `ONE THREAD · WORKED CLEAN` or `ONE THREAD · PICKED OUT TWICE`,
and `LONGEST THREAD 81`. At the foot, his initials in cross-stitch once earned, and the app's
own mark: a pin-head between two short lengths of thread.

Text fallback: `Lacework · 24 September · 81 pins in one thread, worked clean.`

Every size on the card is asked for through `brandDisplay(size:)` or `scaledFont(size:)`;
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
            canvas: Color(light: 0xE8E0CF, dark: 0x1A1C24),
            surface: Color(light: 0xF8F3E7, dark: 0x2A2C35),
            ink: Color(light: 0x2A2521, dark: 0xF2ECDF),
            inkSoft: Color(light: 0x655B52, dark: 0xB3AB9C),
            accent: Color(light: 0x31497A, dark: 0x91A9E3),
            onAccent: Color(light: 0xF8F3E7, dark: 0x0E1526),
            highlight: Color(light: 0xA8413A, dark: 0xF0917F),
            success: Color(light: 0x4A7457, dark: 0x8EC59B),
            miss: Color(light: 0x7A6748, dark: 0xBFAE8C),
            extras: [
                Color(light: 0x6F7B88, dark: 0xA2ADBA),   // steel — pins
                Color(light: 0x9C7A2E, dark: 0xE0BB62),   // brass — the start pin, the corner pins
                Color(light: 0xC4586A, dark: 0xEC93A6),   // rose silk — the second thread
                Color(light: 0xA8842E, dark: 0xDCB85A),   // gold thread — the third, and the picots
                Color(light: 0x7A4E2E, dark: 0xB07A52),   // walnut — the bobbin
            ]
        ),
        type: BrandType(display: .serif,
                        displayWidth: .standard,
                        displayWeight: .medium,
                        body: .default),
        corner: 10,
        canvas: .glow(Color(light: 0xF6F0E3, dark: 0x2C2A30),
                      at: UnitPoint(x: 0.22, y: 0.06))
    )

    /// The workbox by name, so no view indexes `extras` by number.
    enum Workbox {
        static let steel  = brand.palette.extras[0]
        static let brass  = brand.palette.extras[1]
        static let rose   = brand.palette.extras[2]
        static let gold   = brand.palette.extras[3]
        static let walnut = brand.palette.extras[4]
    }

    /// The pillow is drawn, not a surface: the linen darkened a shade, with a highlight
    /// along its top edge. Both values were checked against the thread in both modes.
    enum Pillow {
        static let cloth     = Color(light: 0xDDD4C0, dark: 0x22252F)
        static let highlight = Color(light: 0xF4EDDD, dark: 0x343846)
        static let gimp      = Color(light: 0x2A2521, dark: 0xF2ECDF)   // drawn at 0.7 opacity
    }
}
```

## Slop we are avoiding

1. **One accent on gray, with green and red for right and wrong the only other colour** — and
   this genre's own version of it, neon arrows on black with three red hearts. Lacework has no
   hearts, no arrows and no red anywhere on the card. Right and wrong do not exist on a pillow:
   there is thread, wound or picked out, and the only marks are steel, brass, walnut ink and
   the one thread he chose. Madder and sage live in the margin as words and small marks. Colour
   is thread, and thread goes on the card.

2. **A win shown as a `.sheet` at `.medium` with a checkmark seal, and "Level cleared".**
   Lacework's win is the pins coming out of the pillow in a wave and the lace lifting off with
   its shadow under it, over 1.3 seconds, ending with the margin card naming what is waiting —
   "Nineteen pieces in the sampler. Gold thread comes at forty. Next in the book: nine by nine,
   the spider ground." No sheet, no seal, and "come back tomorrow" is in none of the app's copy.

3. **Content chosen by `%` over a fixed array, and a ladder whose last rung arrives in the
   first week.** Every maze app in the evidence set is a fixed list of hand-made levels dealt in
   order, and the reviews say when they run out. Lacework's book is generated from a seed that
   never repeats, in a ground chosen by `Mastery` from what he has worked badly, at a rung
   whose `Ladder` is still opening new dials at 150 and stops, honestly and stated, at 221 — and
   what he is handed at 500 is a pattern with no end pinned in a ground of windows, which is
   not the game he was handed at 5.

Worth naming a fourth, because every leader ships it: **the lightbulb hint with a badge that
counts down.** Lacework's one tool is a marking pin that knows nothing, and it is earned at
fifteen pieces, free, and unlimited.

## Roads not taken

- **The lantern string** — a night market's courtyard: every post gets a paper lantern, one cord
  strung from post to post, and when the last one is hung the whole string lights. Warm and
  playful, and it would have shared well. Killed because a night courtyard on indigo is one
  dark-canvas screenshot in a category that is nothing but dark-canvas screenshots, and the
  lighting-up win is the neon the leaders already have.
- **The mown meadow** — a hay meadow at dusk seen from above: one tractor, one pass, every strip
  cut and never crossed, and the finished field is a pattern you can see from the hill. Strange
  and lovely. Killed because a vehicle implies speed and a route, which is the wrong pull for a
  puzzle about looking before you move, and an overhead field of blocks is Color Fill 3D's
  screenshot.
