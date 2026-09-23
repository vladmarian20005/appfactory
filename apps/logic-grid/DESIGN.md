# Crosshatch · design

## The idea

**An engraver's bench at a jobbing print shop: a copper plate ruled into a grid, a burin in
your hand, two strokes to cut a pairing out and one deep point to fix it — and when the last
point is cut the plate is inked, wiped and pulled through the press as a print.**

Three words: **cut, exact, unhurried.**

What it is NOT: **the spreadsheet.** Every logic-grid app in the store is a white table with
hairline rules, column headings turned on their side at 8 points, a green ✓ and a grey or red
✗ — Cross Logic's own App Store icon *is* that table with a green tick on it. Crosshatch has
no tick and no cross anywhere in it. A pairing ruled out is two cut strokes; a pairing fixed is
a lozenge cut deep enough to hold ink. The app is named after the mark the category draws as a
system glyph, so the mark is the app.

And it is not the other two things this genre is: not a cartoon detective in a fedora pasted
into the corner cell, and not neon arrows on navy with three red hearts and a hint you have run
out of.

The world earns the app the one thing a logic-grid game usually cannot have: **a picture of
your answer worth sending to somebody.** A press pulls a print. Nothing about that had to be
invented.

## Who and when

She is 41, does the cryptic on the train and has three deduction games installed that she has
stopped opening — one because an ad ran longer than the puzzle, one because it started dealing
her the same board, and one because it wanted her to watch a video for a hint. She plays in the
twenty minutes before the house wakes up, or on the sofa with the television on, one puzzle, no
hurry, and she stops when it is solved rather than when a meter empties. The feeling she comes
for is **being right on purpose** — the specific satisfaction of a mark she could give a reason
for, and the knowledge that the thing in front of her has exactly one answer and she can reach
it without a guess.

That sets the whole direction. Nothing may hurry her: no clock, no score, no counter running
down. Everything must be **provable**, and the app must be visibly on her side about it — which
is why the only thing at stake in a session is whether every mark she made was forced. Calm,
but not weightless.

## The category, looked at

`node tools/design/leaders.mjs /tmp/leaders "Cross Logic" "Logic Grid Puzzles" "That's My Seat"
"Redirect It!" "Nonogram.com"` — 25 images, read outside the repo. Three clichés, and all three
decide something below.

1. **The spreadsheet.** Cross Logic and Logic Grid Puzzles are both, literally, an Excel sheet:
   white cells, 0.5 pt grey rules, category names rotated 90° and set at about 8 points so they
   fit, a green ✓ and a grey or red ✗ as the only colour on screen. Cross Logic's icon is a
   crop of that table. This is the category's entire visual identity and it is shared by its two
   most on-genre leaders. **It is why Crosshatch has no table, no rotated labels and no
   checkmark** — see "Look" and "Screens".
2. **The casual-mobile cast.** Cross Logic pastes a 3D-rendered detective in a fedora into the
   grid's corner cell and wraps the whole thing in a green case-file board strung with red
   thread; That's My Seat is Memoji faces in toilet cubicles saying "I like corner seat" over a
   bright blue gradient, with `PLACE THEM TO WIN!` burned into the screenshot. Loud, rendered,
   and aimed at somebody who is not the person in §Who and when.
3. **The arcade meter.** Redirect It! is neon on `#1a1a2e` with `CHALLENGE AWAITS` in a jagged
   sticker — and it is the app the spec cites as selling itself "minimalistic and relaxing",
   which tells you how little the category's calm positioning shows up in its pixels.
   Nonogram.com is the polish bar here — navy on white, consistent, genuinely good information
   design — and it ships **three red hearts and a lightbulb with a blue badge counting your
   remaining hints.** Crosshatch has to be at least as finished as Nonogram.com and must reach
   for none of its meters.

What nobody in the category has: **a canvas.** Not one of the five has anything behind the
content but white, a flat gradient or a stock wood photo. There is a lot of room here.

## The play

The loop: **read the clues, cut what they force, and pull the print.** What she is chasing is a
plate pulled clean — every point on it forced, not one scratch in the margin.

- **The session.** One plate: three to twelve minutes, ended by the pull. A plate has
  `members × (categories − 1)` **points** to cut — 8 at rung 5, 12 at rung 50, 24 at rung 150 —
  and it paces itself by **category**: each time one whole sub-grid resolves, its border is
  bitten deeper and a small engraved figure of that pairing appears in the plate's margin, so
  the margin fills with the print as you go. A day offers two plates: **today's plate**, seeded
  from the date so it is the same for everyone, and **the next plate in your own run.** A
  session ends on the margin card (see "The ending"). Nothing counts down and nothing stops you
  playing on.

- **At risk.** `Run`, for the length of one plate and nothing beyond it. In a puzzle that is
  pure deduction the only thing you can get wrong is **marking something the clues do not force
  yet** — and the plate has the solver, so it knows.

  - A mark the clues force at the moment you make it: `run.hit()`. The cut takes cleanly.
  - A mark that is true but **not yet forced** — a guess that happens to be right: the burin
    **skids**. The stroke overshoots the cell by 6 pt and leaves a hairline **scar** running out
    into the plate's margin. `run.miss()`. The mark stands; you were right.
  - A mark that **contradicts** the clues: the burin skids the same way, the cell shakes, the
    cut does not take. `run.miss()`, and a scar.

  `run.chain` is the **line** — consecutive forced cuts — and `run.longestChain` is the longest
  line on this plate, which is the score the win's tier is measured on. `run.isClean` is a plate
  with no scars in its margin.

  What a scar costs: **this plate's clean sheet, this line, and one hairline that prints on this
  pull.** Nothing else. Not a life, not a hint, not the day, not a plate already pulled, not
  tomorrow, and nothing that can be bought back. You always finish the plate. The scars are how
  the plate records honestly what happened on it, which is the whole point of the app.

  This is the mechanism that makes deduction worth doing in a genre where trial and error
  usually works just as well, and it does it with no timer, no score and no lives.

### The ladder

`Ladder`, keyed on **rung** — your own position in the run. A plate pulled advances it by 1; a
plate **pulled clean** advances it by 2, so someone who deduces rather than guesses climbs twice
as fast. It never goes down.

| Dial | From | By | Every | Opens at | Ceiling | What it is |
| --- | --- | --- | --- | --- | --- | --- |
| `members` | 4 | 1 | 55 | 1 | 6 | How many to a side — the width of every sub-grid |
| `categories` | 3 | 1 | 42 | 1 | 5 | How many categories are cross-referenced |
| `kinds` | 2 | 1 | 27 | 1 | 7 | How much of the clue vocabulary is in play |
| `depth` | 2 | 1 | 18 | 12 | 14 | Chained inferences the hardest forced step needs |
| `sealed` | 1 | 1 | 40 | 150 | 4 | Clues that start scratched out and bite open as you cut |

```swift
let ladder = Ladder([
    .init("members",    from: 4, by: 1, every: 55, opensAt: 1,   ceiling: 6),
    .init("categories", from: 3, by: 1, every: 42, opensAt: 1,   ceiling: 5),
    .init("kinds",      from: 2, by: 1, every: 27, opensAt: 1,   ceiling: 7),
    .init("depth",      from: 2, by: 1, every: 18, opensAt: 12,  ceiling: 14),
    .init("sealed",     from: 1, by: 1, every: 40, opensAt: 150, ceiling: 4),
])
```

**The seven kinds**, in the order `kinds` opens them:

| # | Kind | Opens | Example |
| --- | --- | --- | --- |
| 1 | direct | 1 | "The bell-ringer is Amos." |
| 2 | negative | 1 | "Brice does not take the six o'clock." |
| 3 | either / or | 28 | "The lamp is either Dyer's or Field's." |
| 4 | relational | 55 | "The ferry sails before the packet." |
| 5 | arithmetic | 82 | "The cargo on Frost Lane weighs twelve more than Dyer's." |
| 6 | adjacency | 109 | "The chandler's is next door to the ropewalk." |
| 7 | exclusive-or | 136 | "Either the keeper took the lamp, or he took the six o'clock — not both." |

**Where it stops, and what happens past it: `flattensAt` is 270** — `sealed` reaches 4 at rung
270 — and `ladder.climbs(through: 150)` is true. That is an honest end and it is stated rather
than dodged with an open dial. Every plate here is solver-verified, so there is a hardest plate
of a given shape; `depth: 14` is the ceiling because past fourteen chained inferences the
generator's search for a plate that *needs* that chain costs more time than there is between a
tap and the next screen. Past rung 270 the **shape** is fixed — five categories, six a side,
the whole vocabulary, four clues sealed, a fourteen-deep chain — and what still changes is the
only thing left: which kinds the generator leans on, which it takes from your own record (see
"What comes next"). Rung 300 and rung 900 are the same shape of plate built against different
weaknesses, and that is said plainly here rather than hidden behind a dial with no ceiling.

`sealed` opens at 150 on purpose. It is the dial that takes over when the other four are nearly
spent, and it changes the game qualitatively rather than quantitatively: from rung 150 you can
no longer read the whole clue list before you start. A sealed clue is crosshatched over, and it
**bites open the moment the plate has no forced move without it** — which the solver knows
exactly, so it can never deadlock and every plate stays provably solvable from what is legible.
The generator verifies this the same way it verifies uniqueness, and a plate that fails is
discarded, never served.

### The daily plate

The daily is **not** on your personal rung — a newcomer joining on day 300 must not be handed a
rung-300 plate, and a veteran must not be handed a rung-1 one. It runs a published week, like a
crossword week, the same for everybody:

| Mon | Tue | Wed | Thu | Fri | Sat | Sun |
| --- | --- | --- | --- | --- | --- | --- |
| 14 | 28 | 46 | 68 | 96 | 140 | 205 |

Seeded from the date, so it is the same plate for everyone who opens it, exactly as the spec
asks. Monday is three categories, four a side, direct and negative clues, depth 2. Sunday is
five categories, six a side, the whole vocabulary, depth 12, two clues sealed. The daily is free
forever at every rung.

### What comes next

Nothing here is `%` over a fixed list and nothing is drawn uniformly at random.

`Mastery<String>` over the **seven clue-kind ids**, written on every cut and **read** to build
the next plate:

- a forced cut → `mastery.record(kindThatForcedIt, correct: true)`
- a slip → `mastery.record(kindOfTheMoveYouMissed, correct: false)`
- a loupe → `mastery.record(kindOfTheClueItNamed, correct: false)`

Then, for the next plate in the run:

1. `let want = mastery.next(from: kindsOpen(at: rung), count: 3, unseenShare: 0.34, avoiding: lastPlatesKinds)`
   — the three kinds she is weakest at, with a share of ones she has not met yet, and not the
   ones the last plate leaned on.
2. The generator runs the spec's pipeline — seeded assignment, emit candidates, solve, prune
   while unique — and among the minimal clue sets it keeps **the one whose forcing chain uses
   `want` most**, tie-broken toward the set whose measured depth is closest to `depth(at: rung)`
   without exceeding it.
3. The **cast** — the subject of the plate and the names in it — comes from a
   `Mastery<String>` over thirty-two themes with `avoiding:` the last three, so a theme never
   comes round twice in a week and new ones are mixed through.
4. Everything is seeded from `(rung, playerSalt)`, so a plate is reproducible and a screenshot
   of rung 5 and a screenshot of rung 500 are repeatable; the daily is seeded from the date
   alone, so it is shared.

`depth` is compared, not merely stored — it is how step 2 picks between candidate sets — and
`strength` is compared, in `Mastery.next`, to decide what the generator is asked for. Neither is
a field that is written, displayed and never read.

### Earned

`Earned`, on **plates pulled**. These arrive for cutting, never for paying; the run past forty
is behind the one-time unlock, and that door cannot be the only one.

| At | id | What opens | The line |
| --- | --- | --- | --- |
| 1 | `line` | **The drying line.** Pulled prints hang on a cord behind the press, newest at the left; any one can be taken down and read. | "Your first pull is on the line. It will be dry by morning." |
| 4 | `pencil` | **The pencil.** A print taken down off the line (or today's) takes a name in italic under the plate's title, and the name hangs on the line with it. | "Four on the line. There is a pencil on the bench — take one down and name it." |
| 12 | `burnisher` | **The burnisher.** One scar a plate can be polished out by hand, leaving a faint bloom where it was — so the print comes out unscratched even when the plate did not. | "Twelve. The burnisher is worth keeping by you now." |
| 30 | `aquatint` | **The aquatint box.** Prints come out in tone as well as line — every cast mark on every print, on the win and on the line, comes up out of a round of fine `CutShading(tone: 0.25)`. | "Thirty pulled. The aquatint box comes down off the shelf, and every figure prints in tone." |
| 75 | `chine` | **Chine-collé.** A leaf of coloured paper goes under each pull, so every print carries the colour of its day and a year on the line reads as a calendar. | "Seventy-five. There is coloured stock under the bench — every pull takes the colour of its day from here." |
| 150 | `edition` | **The edition.** From the 150th every print carries its `№` in copper, and the drying line hangs in spreads of seven, a week to a spread, with a ruled upright between them. | "A hundred and fifty. From here every print is numbered, and the line hangs in weeks." |

A print is numbered by its place in her book (`platesPulled + 1`), never by the plate it came
off: the daily is everybody's plate and carries no number of hers, only `TODAY'S PLATE` and
the date. The line counts **points**: a forced point on the key lengthens it, any other forced
cut keeps it standing, a guess breaks it — so no print shows a line longer than its points.

The burnisher is a mercy, not an eraser: it takes the scratch off the **print**, and it does not
restore the line or the clean sheet. A burnished plate can never be a `best`.

`earned.next(after: platesPulled)` is what a session ends on.

### The ending

The exact words, on the margin card:

> **"Pulled clean — twenty-two points, longest line fourteen. Nine on the line. The aquatint box
> comes down at thirty."**

The shape: `"{Pulled clean | Pulled, {n} scars in the margin} — {points} points, longest line
{k}. {n} on the line. {earned.next, shortened}."` Past the last milestone it names the record
instead: `"… {n} on the line, and {pulls} plates since the third of January."` On a first-ever
pull: **"Your first pull. It goes up to dry, and the plate is wiped for tomorrow."**

Specific, earned, true, and with no guilt in it. The words "come back tomorrow" appear nowhere
in the app.

### Sessions 5, 50 and 500

- **5.** Three categories, four a side — eight points, three sub-grids. Direct and negative
  clues only, four of them, and the first one is lit for you. Two prints on the line and the
  pencil three pulls away. The line to protect is five cuts long.
- **50.** Four categories, four a side — twelve points, six sub-grids, and *either/or* now in
  the vocabulary, which is the first clue kind that cannot be read off a single row. Depth 4.
  Sixteen prints on the line with your own titles pencilled in their margins, the burnisher on
  the bench, and a longest line of nineteen that is genuinely worth not breaking.
- **500.** Five categories, six a side — twenty-four points, ten sub-grids, all seven kinds,
  and a fourteen-step chain somewhere in it. **Four of the clues are scratched out when the
  plate comes up**, and bite open one at a time as the plate runs dry of forced moves, so the
  first third is played on partial information. Every pull comes out in aquatint on coloured
  stock, numbered in your own edition, into a bound book. And the plate itself was built against
  the three kinds her own record says she is worst at.

  Session 5 and session 500 are not the same game. At 5 she reads four clues and marks. At 500
  she starts with half the list illegible.

## The signature interaction

**The cut.** It is the verb she performs twenty-odd times a plate and several hundred times a
week, and it has two forms.

### Ruling a pairing out — the crosshatch

| ms | what happens |
| --- | --- |
| finger down | The cell sinks 1.5 pt into the copper and darkens 8 % under the burin's point. `.buttonStyle(.pressable(scale: 0.97))` with `.spring(response: 0.09, dampingFraction: 0.95)` on the offset — `Cut.bite`. `Haptics.rigid()` comes from the style: the tool meeting metal. |
| 0–90 | **The first stroke.** A diagonal at −38°, `Path` `.trim(to:)` 0→1 over 0.09 s, drawn as a 1 pt lit lip over a 2 pt dark trough so it reads as a cut and not a line. |
| 30 | **Swarf.** `.confetti(trigger: cuts, colors: [copperLit, copper, bevel], from: the cell, count: 5, power: 0.18)` — five copper slivers thrown up and right, gone in 0.4 s. Not confetti: filings. |
| 70–160 | **The second stroke** crosses it at +38°. `Haptics.tap()` as it lands. Two strokes 70 ms apart is what makes a finger believe it cut something rather than toggled something, and it is the app's name happening under her thumb. |
| 55 | `Tones.shared.play(.step(run.chain % 5))` — the burin's note climbs while the line holds and drops back to the root when it breaks, so a long run of forced cuts is audible before it is legible. |
| 160 | Settled. A cut mark never moves again. |

### Fixing a pairing — the point

| ms | what happens |
| --- | --- |
| finger down | As above, but held 40 ms longer: the burin is going in, not across. |
| 0–150 | **The point opens.** A lozenge — the almond a burin actually cuts — scales from nothing to full with `.spring(response: 0.15, dampingFraction: 0.72)` (`Cut.point`), overshooting its width by 1.5 pt and settling back. That overshoot is the whole pleasure: the metal gives, then holds. `Haptics.thud()`, `Tones.shared.play(.pop)`. |
| 120–560 | **The cascade.** A fixed pairing rules out every other cell in its row and its column of that sub-grid, and the plate cuts them **itself**: each crosshatch opens 22 ms after the last, radiating out along the row first and then the column, each with its own pair of strokes and its own sliver of swarf. Every second one fires `Haptics.impact(0.18)` and `Tones.shared.play(.step(n))`, so the cascade is a little run up the scale. |
| 580 | If that sub-grid is now fully determined: **the category closes** — its border is bitten to `ink.opacity(0.62)` over 0.18 s on `Motion.gentle`, `Haptics.soft()`, `Tones.shared.play(.pop)`, and **a small engraved figure of the pairing stamps into the plate's margin** at scale 1.25 → 1.0 on `Motion.bouncy`. |

**Why it holds up the thousandth time:** one stab and the plate cuts itself outward in a run of
double-strokes you can hear climbing; the lozenge overshoots like metal rather than snapping
like a state change; the tone resets every five so the ninth cut sounds different from the
tenth; and the plate is never the same picture twice, because it is filling.

### The slip

The burin **skids**: the stroke runs 6 pt past the cell's edge and leaves a hairline scratch
across the margin, the cell takes `.shake(trigger: slips)`, `Haptics.soft()` — never
`Haptics.error()`, this is not an alarm — and `Tones.shared.play(.miss)`. One line from the
near-miss pool sets in the margin for 2 s. The scratch stays for the life of the plate and
prints on the pull.

### Teaching the first one with no text

On a fresh plate the burin lies beside the bed and **floats** — `.ambientFloat(distance: 3,
period: 2.8)` — and the one cell the first clue forces carries a **ghost crosshatch** at
`ink.opacity(0.09)`, `.breathing(amount: 0.05, period: 2.6)`, with a fine copper thread drawn
from it to the clue that forces it. Both stop at the first cut and never come back. The words
"tap" and "cell" appear nowhere in the app. The VoiceOver hint is the exception and does
explain: `"Rules out Amos and the six o'clock. Double tap again to fix it instead."`

## The reward

**The pull.** The last point is cut and the plate does not open a sheet with a checkmark on it —
it is inked, wiped, and printed while she watches.

| ms | what happens |
| --- | --- |
| 0 | The last point lands as normal: lozenge, `Haptics.thud()`, and the final cascade runs. |
| 120 | **Everything stills.** The clue list slides down and off, `Motion.gentle`; the plate is alone on the bed; the shop dims 12 %. |
| 200–420 | **Inking.** A dark wash sweeps the plate left to right over 0.22 s, filling every cut. `Haptics.soft()` at 200. |
| 420–560 | **Wiping.** The wash pulls back off the surface in 0.14 s, leaving ink only in the lines — which is exactly what an intaglio plate does and is the most satisfying 340 ms in the app. `Haptics.tap()` at 560. |
| 440–1140 | **The count.** Behind the plate, the points cut rise as a ghost numeral at `.brandDisplay(size: 132)` in `highlight.opacity(0.16)`: `CountUp(to: points, duration: 0.7, onTick:)`, each tick firing `Haptics.impact(0.28 + 0.045 × n)` and `Tones.shared.play(.step(n))`. |
| 560–860 | **The paper comes down.** A sheet of damp laid paper descends onto the plate on `Motion.gentle`, its deckle edge catching the light. |
| 780–900 | **The press turns.** The star wheel rotates 48° and the bed travels 10 pt. One heavy turn, not a spin. `Haptics.thud()` at 900. |
| 900–1300 | **The pull.** The paper peels back from the left edge — a mask sweeping left to right over 0.4 s on `Motion.bouncy`, the sheet curling as it lifts — revealing **the print**: the answer, engraved, the cast marks ranged in their solved rows, with the margin under it carrying the date and the plate number. The plate stays on the bed, wiped and blank. |
| 1060 | **Filings and paper dust.** `.confetti(trigger: pulls, colors: [copperLit, copper, ink, paper], from: UnitPoint(x: 0.5, y: 0.42), count: 54, power: 0.9)` — heavy, falling fast. Never party confetti. |
| 1180 | **The print goes up on the line**, travelling into the rack under one `matchedGeometryEffect` so it is the same object arriving somewhere rather than a card dismissing. `Haptics.celebrate()`, `Tones.shared.play(.fanfare)`. |
| 1320 | The tier headline sets in the margin at 30 pt, then the margin card rises under it on `Motion.gentle`. |
| 1500 | Everything stops. Only the north light keeps breathing; the line is still. |

**Tiers**, from `run.tier(score: run.longestChain, beating: bestLine)`:

| Tier | When | Headline | The difference |
| --- | --- | --- | --- |
| `best` | Clean, and a longer line than you have ever cut | `NOT A SCAR, AND YOUR LONGEST LINE` | The plate is pulled **twice** — a fainter artist's proof 80 ms early and 3 pt off register behind the final print; the drying line's cord goes `highlight` for 0.6 s; filings at `power: 1.4, count: 96`; `Haptics.celebrate()` twice, 200 ms apart; `.fanfare` then `.step(7)`. |
| `clean` | No scars in the margin | `PULLED CLEAN. NOTHING GUESSED ON IT` | `power: 1.0, count: 60`, `.fanfare`. The press turns in one pass. |
| `good` | Four in five cuts forced | `PULLED. {n} SCARS, AND THEY PRINT` | `power: 0.6, count: 36`, `.success` rather than `.fanfare`. The press turns in two half-turns 90 ms apart. |
| `finished` | The rest | `PULLED. IT GAVE UP IN THE END` | `power: 0.45, count: 26`, `.success`. No proof, no second turn. |

**Inside the loop**, the small reward is the category closing — the border biting deeper, the
figure stamping into the margin, `Haptics.soft()`, `.pop`. A plate has a shape you can hear
before you can see it: five cascades, four figures, one pull.

## Look

### Palette

Light is the shop at eleven in the morning under a north light over the right shoulder — the
zinc inking slab, a sheet of cream laid paper, and the plate, which is the only warm thing in
the room. Dark is not that inverted: it is the same bench at night with one lamp over it. The
slab and the paper go cold and dim; **the copper does not invert, it dims**, because metal under
one lamp is still metal.

| Role | Light | Dark | Job |
| --- | --- | --- | --- |
| `canvas` | `#96A199` | `#0F1413` | **The zinc slab.** The bench top behind everything, cool grey-green by day, near-black at night. |
| `surface` | `#F3EDDC` | `#23231E` | **Laid paper.** The mount the plate lies on, the clue list, the margin card, the print, the day-book page. |
| `ink` | `#15191A` | `#EFE8D6` | **Intaglio black.** Type, cut troughs, the rules of the grid. |
| `inkSoft` | `#2F3634` | `#A29D8C` | The plate caps, dates, the legend's secondary type. |
| `accent` | `#10525C` | `#67CBD6` | **Ink teal** — the working colour. Primary actions, selection, the loupe's thread, today's registration cross. |
| `onAccent` | `#F3EDDC` | `#04191C` | Type on the teal. |
| `highlight` | `#9E4E17` | `#F0A257` | **Copper.** The second voice: the win headline, a fresh cut's lip, the best, the drying line's cord, the edition number. |
| `success` | `#286554` | `#6FC6A4` | **Verdigris.** A clue used up, a category closed, a clean pull. Never system green. |
| `miss` | `#6E6455` | `#9E9483` | **The scar.** A dull scratch in the copper, never red, never an alarm. |

**`extras` — the six cast inks**, one per category on a plate. They are the shop's ink slabs:

| # | Name | Light | Dark |
| --- | --- | --- | --- |
| 0 | Copper | `#9E4E17` | `#F0A257` |
| 1 | Prussian | `#1D4468` | `#89B4E0` |
| 2 | Verdigris | `#286554` | `#6FC6A4` |
| 3 | Sanguine | `#8E3A33` | `#DE8B80` |
| 4 | Bistre | `#6E5416` | `#D7B15C` |
| 5 | Payne's grey | `#3B454C` | `#A3AEB6` |

**The rule that governs all of them: colour is ink, and ink only goes on paper.** Nothing
coloured is ever drawn on the copper — you cannot print onto a plate, you engrave it. So inside
the plate there are exactly two things, copper and cut; the cast inks appear on the paper
*around* it, as the registration bands at the head of each category's columns and rows, in the
legend, on the clue numerals, on the day-book squares and in the print. That rule is what keeps
the grid from becoming the category's table, and it is checkable: any colour inside the plate's
bevel is a bug.

**The plate itself** is drawn from its own ramp rather than from a palette role, because copper
dims at night instead of inverting:

| | Light | Dark |
| --- | --- | --- |
| Face, upper left | `#E0A05E` | `#B4793E` |
| Face, lower right | `#BE7A36` | `#A87643` |
| Bevel | `#7A4415` | `#40240C` |
| Cut trough | `#15191A` | `#0B0705` |
| Cut lip | `#FBDCB0` | `#E3B87E` |

Checked with `node tools/design/contrast.mjs`:

```
ink       #15191A on #96A199   6.62 AA     #EFE8D6 on #0F1413  15.21 AAA
ink       #15191A on #F3EDDC  15.14 AAA    #EFE8D6 on #23231E  12.91 AAA
inkSoft   #2F3634 on #96A199   4.63 AA     #A29D8C on #0F1413   6.85 AA
inkSoft   #2F3634 on #F3EDDC  10.58 AAA    #A29D8C on #23231E   5.82 AA
onAccent  #F3EDDC on #10525C   7.53 AAA    #04191C on #67CBD6   9.55 AAA
accent    #10525C on #F3EDDC   7.53 AAA    #67CBD6 on #23231E   8.33 AAA
accent    #10525C on #96A199   3.30 large  #67CBD6 on #0F1413   9.82 AAA
highlight #9E4E17 on #F3EDDC   5.05 AA     #F0A257 on #23231E   7.52 AAA
success   #286554 on #F3EDDC   5.83 AA     #6FC6A4 on #23231E   7.73 AAA
miss      #6E6455 on #F3EDDC   4.96 AA     #9E9483 on #23231E   5.27 AA
cut       #15191A on #E0A05E   7.89 AAA    #0B0705 on #B4793E   5.49 AA
cut       #15191A on #BE7A36   5.08 AA     #0B0705 on #A87643   5.10 AA
```

The six cast inks run 4.70–8.64 on light paper and 6.10–7.77 on dark, so every one is AA or
better wherever it carries a name. `accent` at 3.30 on the canvas is only ever a filled control
or a glyph there, which is a 3:1 bar. The **cut lip** is the one value that does not clear AA
against the darker end of the copper (2.65) and it is deliberately not load-bearing: it is the
light catching the edge of a cut, and every cut is legible from its trough alone. The copper
ramp was narrowed from an earlier `#E8A768 → #A85F22` for exactly this reason — at the old dark
end the cut fell to 3.65 and the crosshatch went mushy in the bottom-right corner of a 6×6
plate, which is where the hardest deductions live.

### Canvas

`BrandCanvas.glow(Color(light: 0xB0BAB0, dark: 0x1C2422), at: UnitPoint(x: 0.78, y: 0.06))` —
the north light over the **right** shoulder, because that is where an engraver wants it. Small
on purpose: a glow you can find reads as a window, one that floods reads as a vignette.

Over it, drawn once in a single `Canvas`: **the ground tooth**, which is the app's own name in
its own background. A field of fine parallel strokes at +62°, 1 pt wide and 3.5 pt apart, at
`ink.opacity(0.034)` in light and `.white.opacity(0.036)` in dark — and in the lower-left
quadrant a second field at −62° over the first, so that corner is literally **crosshatched** and
sits a shade darker. Seeded from a fixed constant, so every launch and every screenshot are
identical, and it never animates: a moving texture is noise.

And **the bed rails**: two 2 pt horizontal bands at `ink.opacity(0.12)` running the full width,
one 22 pt below the safe area and one 22 pt above the tab bar, with a 1 pt
`highlight.opacity(0.22)` line along the inner edge of each. They are the press bed the plate
lies on, they are the app's horizon, and they are in every screenshot.

### Type

`BrandType(display: .serif, displayWidth: .standard, displayWeight: .bold, body: .default)` —
**New York Bold** for every display element. An engraved plate's lettering is a serif; the
category is SF Pro and rounded cartoon faces without exception; New York is free, it is nobody
else's here, and at 108 pt a serif numeral is unmistakable from one crop. Body copy stays SF Pro
text, because the clues are sentences and have to read fast.

The third voice is **the plate caps**: `.system(.caption2, design: .monospaced)` with
`.textCase(.uppercase)` and `.tracking(2.4)`. It is what is punched into the margin of a plate —
`PLATE 214`, `17 SEPTEMBER`, `FOUR CATEGORIES, FIVE TO A SIDE`, `DEPTH 5`, `LINE 14` — and never
a sentence.

Hero numbers, always through `.brandDisplay(size:)` so they scale with Dynamic Type:

- **the line, on Progress — 108 pt**, the largest thing in the app after the win
- the win's ghost numeral — 132 pt at `highlight.opacity(0.16)`, behind the plate
- the next plate's number, engraved on its bevel in the run — 76 pt
- the plate's point count in the margin on the bed — 34 pt
- the share card's point count — 260 pt on the 1080 × 1350 canvas

Every screen has exactly one thing at 34 pt or over and nothing else competing with it. No
`.font(.system(size:))` anywhere, on any screen, including the share card: `scaledFont(size:)`
and `brandDisplay(size:)` say the same point size and still scale.

### Shape

**The lozenge** is the one distinctive shape: the almond a burin actually cuts, 15 pt across and
9 pt high, with slightly convex sides and points at either end. It is the fixed-pairing mark on
the plate, the bullet before every paywall line (`PaywallBullets.ruled(mark: "◆")`), the
selection mark in every picker — never a checkmark, anywhere in the app — the peg on the drying
line, and a rule of three lozenges as a section divider.

**Corner radius 3**, for the whole brand. A copper plate has a bevel filed on it, not a rounded
corner, and paper has a cut edge. Against the kit's 22 that alone changes how the app feels
before anything else is drawn. Nothing in this app is a 22 pt white card with a shadow.

**The crosshatch** is the ruled-out mark, and it is the one thing on this list the build must
not get wrong, because the first draft of mock 1 got it wrong. A ruled-out pairing is **the
whole cell filled with cut shading** — the cell darkens under a field of fine troughs — not two
strokes forming an X in the middle of it. Two strokes at cell size *is* an ✗, which is the
glyph this app exists to refuse, and it looked exactly like Cross Logic's grid until it was
redrawn.

Two things make the fill read as engraving rather than as a mesh, and both were learned from a
render:

1. **The two passes cross at about 32°, never at a right angle.** Square crossing produces a
   window screen; a shallow crossing produces lozenge-shaped interstices, which is why the
   technique is called crosshatch and why it reads as tone. The app's two passes run at
   **+40° and +72°**.
2. **Fine and close, not thick and open.** In a 21 pt cell: troughs 1.25 pt at
   `ink.opacity(0.85)`, spaced 4.4 pt, over a flat `ink.opacity(0.10)` wash, each with a
   0.5 pt `lip` hairline offset 0.7 pt to its upper left. Cut lines heavier than that turn the
   cell into a grille.

The same field, at the same two angles, is the app's mark everywhere else: a sealed clue, the
locked plate on the run, the empty part of the paywall's plate, and — laid in from the lower
right and fading out — the icon.

### Art

Drawn as SVG in `design/art/`, rendered by `node tools/design/art.mjs` into the asset catalog
and used as `Image("…")`. No SF Symbol is ever the hero of a screen.

| File | Depicts | Where |
| --- | --- | --- |
| `press.svg` | The star-wheel press three-quarter on: a plate on the bed, a sheet half-pulled and curling off it, the drying line strung behind with three prints on it, light from the right. | Onboarding 3, the empty drying line, the win's backdrop |
| `burin.svg` | The burin lying across a part-cut plate — mushroom handle in dark wood, lozenge-section shaft, a curl of swarf at its point, a field of crosshatch already cut behind it. | Onboarding 2, the bed's empty state |
| `plate.svg` | One copper plate seen square on, bevel catching the light on two sides, ruled into a grid with three cells crosshatched and one lozenge cut deep. | Onboarding 1, the day-book's empty state, the locked plate on the run |
| `rack.svg` | Six prints pegged on a cord to dry, each on a different colour of stock, each with a dated margin, the nearest one legible. | The paywall hero, the run's locked state |

Plus **the cast marks**: thirty-two small engraved glyphs — a bell, a ferry, a lamp, a key, a
fish, a lock gate, a coat, a barrel, a moon, a rope, a spoon, a hand — at `viewBox="0 0 64 64"`,
one stroke weight, no colour, in `design/art/marks/`. They are how a member of a category is
labelled on the plate, which is what kills the rotated 8 pt column heading. They are reused
across every theme, so the cost is fixed and does not grow with the content.

### Motion

| Spring | For |
| --- | --- |
| `.spring(response: 0.09, dampingFraction: 0.95)` | The burin biting. `Cut.bite`. |
| `.spring(response: 0.15, dampingFraction: 0.72)` | The point opening, with its 1.5 pt overshoot. `Cut.point`. |
| `Motion.pop` | A figure stamping into the margin; the loupe's thread. |
| `Motion.bouncy` | The pull peeling back; the print flying to the line. |
| `Motion.gentle` | The ink wash, the paper coming down, the clue list sliding, a category's border biting, the margin card. |
| `Motion.snappy` | Navigation, sheets, the day-book, the run. |

Ambient: the north light **breathes**, `.breathing(amount: 0.025, period: 5.2)`; on a plate with
no cuts on it, the burin **floats**, `.ambientFloat(distance: 3, period: 2.8)`, until the first
cut. Both go through FactoryKit, so both stand still under `-stillFrames`.

Never moves: the ground tooth, the bed rails, cut marks, the clue list once settled, the plate
caps, the drying line, the day-book. A cut is permanent, which is the point of it.

### Sound

`Tones` throughout, on the ambient session, with `SoundsToggle()` in Settings.

| Tone | When |
| --- | --- |
| `.step(run.chain % 5)` | Every cut you make — the line climbing, resetting when it breaks |
| `.step(n)` | Every second cell of the cascade; every tick of the win's count-up |
| `.pop` | A point cut; a category closing |
| `.miss` | A slip — the burin skidding |
| `.success` | A sealed clue biting open; a `good`/`finished` pull |
| `.fanfare` | A clean pull |
| `.tap` | Selection; the loupe |

## Voice

**The master engraver** — old, dry, exact. Entirely uninterested in how fast you did it and
extremely interested in whether you could name a reason for every mark on the plate.

Three rules:

1. **He talks about the plate, never about you.** "Nothing on this one is a guess." Never
   "Great work!" and never "You're on fire!"
2. **He names the evidence.** A hint says which clue and what it forces. Nothing the app says is
   an instruction about the interface.
3. **One sentence. It has to fit in a margin.**

### Onboarding

`OnboardingView(pages:nextTitle: "Go on", finishTitle: "Take the burin")`, each page
`OnboardingPage(title:subtitle:art:)`.

| # | Title | Subtitle | Art |
| --- | --- | --- | --- |
| 1 | **A plate a day** | "Copper, ruled into a grid, with a handful of clues under it. One goes on the bed every morning and it is the same plate for everyone." | `plate.svg` |
| 2 | **Cut what the clues force** | "Two strokes across a pairing rules it out. One deep point fixes it — and the plate does the rest of the crossing out itself." | `burin.svg` |
| 3 | **A finished plate gets pulled** | "Inked, wiped and printed on damp paper, and it goes up on the line to dry. Every plate here was proved to have exactly one answer, reachable by reasoning alone, before it was ever ruled." | `press.svg` |

Page 3 is the one onboarding page allowed to carry the promise, and it carries it as a fact
about the world rather than as a pitch.

### Praise pool — a plate pulled

1. "Pulled. The line held the whole way through."
2. "Clean off the plate. Nothing on it you could not give a reason for."
3. "That is a print. The margin is honest."
4. "Inked, wiped, printed. Hang it up."
5. "Good bite on that one. It came off whole."
6. "Every point on it was forced, and the plate knows it."
7. "Off the bed and onto the line."
8. "That plate gave up everything it had."
9. "Nothing guessed, nothing smudged."
10. "The press hardly had to work for that."
11. "Cut, and cut properly. The book is a page longer."
12. "There it is, in one pull."

### Near-miss pool — a slip

1. "The burin skidded. The clues had not said that yet."
2. "That may well be true. It is not yet proved."
3. "A scratch in the margin. It will print, and that is all."
4. "Not forced — not by anything legible on this plate."
5. "You got there ahead of the evidence."
6. "Right, and early. Copper remembers early."
7. "A guess. A good one, and the plate still shows where."
8. "Off the line. Something on the list says so; it is not four."
9. "Ahead of yourself. Carry on — the plate still pulls."

### A category closing

1. "That one is settled."
2. "Four figures in the margin now."
3. "Whole. Nothing left in that block."
4. "Closed, and it closed itself."
5. "The block is finished. It bites deeper."

### A sealed clue biting open

1. "The acid is through. Six is legible."
2. "Seven has come up. You had run out of forced moves without it."
3. "That one has bitten open. Read it."

### The win's headline, per tier

| Tier | Headline |
| --- | --- |
| `best` | `NOT A SCAR, AND YOUR LONGEST LINE` |
| `clean` | `PULLED CLEAN. NOTHING GUESSED ON IT` |
| `good` | `PULLED. {n} SCARS, AND THEY PRINT` |
| `finished` | `PULLED. IT GAVE UP IN THE END` |

### Empty states

| Where | Art | Headline | Line | Button |
| --- | --- | --- | --- | --- |
| Drying line, nothing pulled | `press.svg` | **The line is empty** | "The press is wound back, there is damp paper under the board, and today's plate is already on the bed." | "Set it on the bed" |
| The run, free, past forty | `rack.svg` | **The run goes on** | "Past the fortieth the plates go to five categories and six a side, ruled and proved exactly the same way." | "See the whole run" |
| Day-book, no days | `plate.svg` | **Nothing inked yet** | "Every day you pull a plate its square is inked in. A month reads as a page." | — |
| Today already pulled | — | **Today's is on the line** | "The next plate in your own run is ruled and waiting on the bench." | "Rule the next plate" |
| A fresh plate, no cuts | — | — | Nothing at all: the floating burin, the ghost crosshatch and the copper thread to the first clue do the teaching. | — |

### What remembers you, instead of a streak

At the foot of the day-book page, in the plate caps, unasked:

`214 PULLED · 31 DAYS RUNNING · LONGEST 58`

That is all. No flame, no number that goes back to zero, no red, and nothing anywhere that
mentions a day you did not play. A day you missed is simply a square of bare copper on the page,
which is the truth and is not an accusation.

### The reminder notification

**None is sent.** The spec asks for no permissions and no notifications, and a notification that
guilts somebody about a puzzle is the exact thing the taste bar refuses. If one is ever added it
carries this line and only this line:

> "Today's plate is on the bed, ruled and ready."

No count of days missed, no question, no request.

### Paywall

`PaywallView(headline:bullets:bulletStyle:promise:cta:hero:onDone:)`, with
`bulletStyle: .ruled(mark: "◆")` — the lozenge, set in New York, because this app's content is
type on paper and a `checkmark.circle.fill` in a rounded panel would be the one place the design
stops.

- Headline: **"The whole run"**
- Bullets:
  - "Every plate the generator has proved, past the first forty — up to five categories and six to a side."
  - "Muted ink: the plate in proof grey, and nothing in the margin but the date."
  - "The crossing-out assist, on or off, plate by plate."
- Promise: **"One proved plate every day stays free, and every print you have pulled stays on the line."**
- `cta:` **"Unlock every plate"** — one payment, no subscription and no trial, so the button says
  what the purchase does rather than naming a trial that does not exist.
- Dismiss: **"Not today"**
- `hero:` `rack.svg`

### Button labels for every primary action

| Action | Label |
| --- | --- |
| Today's plate, not started | "Set today's plate on the bed" |
| Today's plate, part cut | "Back to the bed" |
| The next plate in the run | "Rule the next plate" |
| Hint | "Name the clue" |
| Undo | "Take it back" |
| Burnish a scar (earned at 12) | "Burnish it out" |
| Restart | "Wipe the plate" |
| Confirm restart | "Wipe it" |
| Share | "Send the margin" |
| Onboarding next / finish | "Go on" / "Take the burin" |
| Paywall | "Unlock every plate" |
| Paywall dismiss | "Not today" |
| The run, locked plate | "See the whole run" |
| Calm mode toggle | "Muted ink" |
| Assist toggle | "Let the plate cross out for you" |
| Erase everything | "Scrap the plates" |
| Confirm erase | "Scrap them" |

## Screens

### 1. The bed — Play (tab 1) · mock 1 shows it mid-cut

**Its one job:** the plate, the clues, and the cut.

**Hero:** the plate — a copper rectangle lying on a sheet of paper on the zinc slab, its bevel
catching the light on two sides, ruled into the cross-referenced matrix.

Top to bottom:

- `NavigationStack`, inline title: the plate's subject — "The Six O'Clock Ferry". The toolbar
  carries a `Menu` with "Wipe the plate" (behind its confirmation) and "Muted ink", and a
  `ShareLink` once the plate is pulled.
- The **upper bed rail**, and the plate's four **registration crosses** — fine corner crosses at
  the plate's corners, the printer's own marks. They are in every screenshot of this app.
- The **legend**, on the paper mount above the plate: one row per category, its name in the
  plate caps in its cast ink, then its members as `mark + name` at 13 pt. This is where the
  names live, so nothing inside the grid has to be set at 8 points on its side.
- **The plate.** The staircase matrix, cells 34 pt at four a side down to 26 pt at six. Column
  and row heads are **cast marks** — the engraved glyphs from `design/art/marks/`, 22 pt, cut
  into the copper — never rotated text. Rules between cells are 0.5 pt at `ink.opacity(0.22)`;
  between sub-grids 1.5 pt at `ink.opacity(0.4)`, biting to 0.62 when a category closes. On the
  paper just outside the plate's edge, a 3 pt **registration band** in each category's cast ink
  runs along its columns and its rows. Colour never crosses the bevel.
- **The margin**, on the plate's lower edge: `PLATE 214 · 17 SEPTEMBER · DEPTH 5` in the plate
  caps, the point count at 34 pt, the **figures** stamped so far, and every **scar** as a
  hairline scratch. The **loupe** sits at its right (the hint) and the **burnisher** at its left
  (undo, and from twelve plates, taking a scar out).
- **The clue list**, on paper below: each clue at 17 pt in New York, with a hanging numeral in a
  lozenge in its category's cast ink. A clue **used up** by what has been cut strikes itself
  through with one fine `success` rule. A **sealed** clue is crosshatched over and unreadable
  until it bites open.
- The **lower bed rail**.

**What moves:** the cut and its cascade; the clue strike-through; the loupe's copper thread from
a clue to a cell; the clue list `.popIn(delay: index × 0.04)` on load. Nothing else.

**System controls:** `NavigationStack` and its toolbar, `Menu`, `ShareLink`, the confirmation
`alert`, `ScrollView`. The plate is drawn: a `Canvas` for the copper, the rules and the cut
marks, with a transparent `Button` grid over it at `.buttonStyle(.pressable)` so every cell is a
real 34 pt target with a real press state and a VoiceOver label.

**Empty (a plate with no cuts):** nothing is written. The burin floats, the first forced cell
carries its ghost crosshatch, and a copper thread runs to the clue that forces it.

### 2. The line — Progress (tab 2) · mock 4

**Its one job:** today's plate, everything pulled, and the run of days. This is the screen the
first App Store screenshot shows, per the spec's 4.3 note — not a bare grid.

**Hero:** **the line** — plates pulled — at 108 pt in New York Bold, sitting behind the drying
line with the prints overlapping its lower third.

Top to bottom:

- **Today**: if today's plate is not pulled, the plate itself on the bed at half scale with
  "Set today's plate on the bed"; if it is, **today's print** hanging at the left of the line,
  full width, with its margin and its tier line.
- **The drying line** (from the first pull): prints pegged on a cord with lozenge pegs, newest
  at the left, scrolling horizontally, each 96 pt wide with its date pencilled in the margin.
  Once `chine` is earned each sits on its day's colour of stock, so a year of them is a calendar.
- **The day-book page**: the month as a page of the shop's day-book — paper, ruled into a 7×5
  grid of squares at `ink.opacity(0.15)`. A day you pulled carries a **filled lozenge in that
  plate's lead cast ink**; today is ringed in `accent` with the registration cross in it; a day
  you missed is simply an empty square — no grey, no red, no mark at all. (Paper, not copper:
  the rule is that colour is ink and ink only goes on paper, and a day-book is a book.) The
  header reads `September` with `TWENTY-TWO INKED` opposite it in the plate caps. A month reads
  as a page, and a year of them is a portrait of how you actually spend a Tuesday.
- `214 PULLED · 31 DAYS RUNNING · LONGEST 58` in the plate caps.
- `ShareLink` over `ShareImage.render` — "Send the margin".

**System:** `NavigationStack`, `ScrollView`, `ShareLink`.

### 3. The run — Packs (tab 3)

**Its one job:** the ladder, plate by plate, and what is waiting.

**Hero:** **the plate shelf** — copper plates standing on edge in a rack, each with its number
engraved on its bevel. A pulled plate has its print pegged behind it; a plate ruled and
unfinished has the burin lying across it; an untouched one is bare copper. Not a `List` of
`Label`s and not a grid of level buttons.

- The **next plate** stands at the front, larger, its number engraved at 76 pt on the bevel, with
  its shape in the plate caps under it: `PLATE 51 · FOUR CATEGORIES, FIVE TO A SIDE · DEPTH 4`.
  Button: "Rule the next plate".
- **Earned**, as a shelf along the bottom: the line, the pencil, the burnisher, the aquatint box,
  the coloured stock, the book — each drawn, each greyed until it arrives, each with
  `earned.next(after:)`'s count under the next one.
- **Free tier:** plate 41 is a **blank, unruled plate** with `THE RUN GOES ON` in the plate caps
  crosshatched across it. Tapping it opens the paywall. Not a lock row and not a price.
- **Pro:** "Muted ink" and "Let the plate cross out for you" as system `Toggle`s on
  `.brandBackground()`.

**System:** `NavigationStack`, `ScrollView`, `Toggle`.

### 4. Settings (tab 4)

The kit's `SettingsView` under `.brand(AppBrand.brand)` and `.brandBackground()`, with an
**In the shop** section — `Plates pulled`, `Points cut`, `Longest line`, `Days running` — then
`SoundsToggle()`, "Muted ink", "Let the plate cross out for you", and "Scrap the plates" behind
its confirmation ("Scrap the plates — every print and every mark on this phone?"). Footers: free
— "One plate a day and the first forty of the run. Every print you have pulled stays on the
line."; unlocked — "Everything you have cut is on this phone and nowhere else."

The kit's restore, rate, share, support and privacy rows are unchanged.

### 5. The paywall · and 6. Onboarding · mock 3 shows onboarding page 1

Both the kit's, named in the engraver's voice as §Voice sets out, each with its art, the paywall
with `bulletStyle: .ruled(mark: "◆")`. Onboarding sets its title at 42 pt New York Bold over the
art, with `CROSSHATCH` in the plate caps at the head of the screen between two rules and a
lozenge, and the page indicator drawn as the app's own marks: a cut lozenge for the page you are
on, an empty ruled cell for each one you are not.

### The mocks

| Mock | Shows |
| --- | --- |
| `design/mock-1-play.html` | The bed mid-cut: a four-category, four-a-side plate at rung 51, nine of twelve points cut, one category closed, the cascade mid-run in one block, a scar in the margin, and the clue list with two clues struck through. |
| `design/mock-2-win.html` | The pull at its peak: the plate inked and wiped, the print peeling off it, the ghost numeral behind, the `best` headline, and the margin card. |
| `design/mock-3-first.html` | Onboarding page 1, the first thing a new user sees. |
| `design/mock-4-line.html` | The line: the hero at 108 pt, the drying line, today's plate on the bed, the day-book page and the plate caps at the foot. This is the first App Store screenshot, per the spec's 4.3 note. |

### Captures

The critic sees motion through `qa.json`'s `moments`, so the app plays its own signature
interaction and its win on a launch flag. `-demo cut` runs three crosshatches and one point with
its full cascade, closing a category. `-demo pull` runs the last two points and the pull. Both
seed a fixed record — plate 214, rung 51, 31 days running, nine prints on the line, four
categories and five a side — so every capture has a full bench in it rather than a first-launch
blank. The seed is deterministic, which keeps the spec's promise that every screen is
reproducible.

## Icon

**The concept:** one copper plate, crosshatched, with a single point cut clean in the middle of
it. The mark, not the machine, and not the table.

**The composition:** the plate fills the square at −4°, full bleed, with its **bevel showing
along the bottom and right** so it reads as a thick piece of metal rather than a page; the
corners show a sliver of the zinc slab behind. From the lower right, **a field of cut shading**
is laid in and fades out along a clean diagonal edge about a third of the way up — two passes of
parallel troughs, the first at **+40°** on a 30-unit pitch and the second at **+72°** on a
38-unit pitch, each a `#160B02` trough with a `#FFE7BE` hairline on its upper lip. The first
pass runs further up the plate than the second, so the tone has two steps: hatched at the edge,
crosshatched and darker in the corner. In the clear copper at the middle left sits **one deep
lozenge point**, about 410 units across, tilted −7°, with a `#FFF5E2` lip offset up and to the
left — the darkest and most deliberate thing on the icon — and a curl of swarf above it. A
registration mark is punched in the empty corner.

**The colours:** the face `#F4B87E` at the upper left → `#8E4E18` at the lower right; troughs
`#160B02` with `#FFE7BE` lips; the bevel `#4A2308`–`#A45E22`; the lozenge `#40250A` → `#0F0702`;
the zinc corners `#9AA49B` → `#5D6A63`.

**Four drafts, and what each one got wrong**, because the mistake is easy to repeat: the first
drew the hatching as six heavy strokes each way and came out a **garden trellis**; the second
halved the weight and came out a **window screen**; the third halved it again and was *still* a
screen, which is when the actual rule surfaced — **crossing at a right angle can only ever make
a mesh.** The fourth crosses the two passes at 32°, and the interstices become lozenges, and it
reads as engraved tone. The same finding governs the plate on every screen (see "Shape").

Read at 120 px next to the leaders' icons: copper, a dark textured wedge and one dark almond,
next to Cross Logic's white spreadsheet with a green tick, Nonogram.com's navy blocks and
Redirect It!'s neon arrows. No letter, no numeral, no glyph on a gradient. Rendered to
`design/icon-1024.png`.

## Share card

1080 × 1350 through `ShareImage.render`, and it **spoils nothing** — no cast, no marks, no
answer, which is the spec's requirement upgraded from a line of text to a picture.

The zinc ground with its crosshatch tooth. On it, laid at 1.5°, **the margin of today's print**:
a sheet of cream paper with `CROSSHATCH` engraved across the top in New York, then
`PLATE 214 · 17 SEPTEMBER` in the plate caps. Under that the **hero number** — points cut — at
260 pt in intaglio black. Then **the proof strip**: one small mark per point in the order they
were cut, a filled **lozenge** for a forced cut and a **hairline scratch** for a slip, ranged
five to a group — so the shape of the solve is legible to anyone and the answer is not. Under
it, `LONGEST LINE 14 · NOT A SCAR`, or `LONGEST LINE 9 · TWO SCARS`. At the foot, the app's own
mark: a lozenge between two hatch strokes, and `CROSSHATCH`.

Text fallback: `Crosshatch · plate 214 · 22 points, longest line 14, not a scar.`

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
            canvas: Color(light: 0x96A199, dark: 0x0F1413),
            surface: Color(light: 0xF3EDDC, dark: 0x23231E),
            ink: Color(light: 0x15191A, dark: 0xEFE8D6),
            inkSoft: Color(light: 0x2F3634, dark: 0xA29D8C),
            accent: Color(light: 0x10525C, dark: 0x67CBD6),
            onAccent: Color(light: 0xF3EDDC, dark: 0x04191C),
            highlight: Color(light: 0x9E4E17, dark: 0xF0A257),
            success: Color(light: 0x286554, dark: 0x6FC6A4),
            miss: Color(light: 0x6E6455, dark: 0x9E9483),
            extras: [
                Color(light: 0x9E4E17, dark: 0xF0A257),   // copper
                Color(light: 0x1D4468, dark: 0x89B4E0),   // prussian
                Color(light: 0x286554, dark: 0x6FC6A4),   // verdigris
                Color(light: 0x8E3A33, dark: 0xDE8B80),   // sanguine
                Color(light: 0x6E5416, dark: 0xD7B15C),   // bistre
                Color(light: 0x3B454C, dark: 0xA3AEB6),   // payne's grey
            ]
        ),
        type: BrandType(display: .serif,
                        displayWidth: .standard,
                        displayWeight: .bold,
                        body: .default),
        corner: 3,
        canvas: .glow(Color(light: 0xB0BAB0, dark: 0x1C2422),
                      at: UnitPoint(x: 0.78, y: 0.06))
    )

    /// The plate is drawn from its own ramp, not from a palette role: copper under one lamp
    /// dims, it does not invert. Every value here was checked against the cut in both modes.
    enum Plate {
        static let faceTop    = Color(light: 0xE0A05E, dark: 0xB4793E)
        static let faceBottom = Color(light: 0xBE7A36, dark: 0xA87643)
        static let bevel      = Color(light: 0x7A4415, dark: 0x40240C)
        static let trough     = Color(light: 0x15191A, dark: 0x0B0705)
        static let lip        = Color(light: 0xFBDCB0, dark: 0xE3B87E)
    }
}
```

## Slop we are avoiding

1. **One accent on grey, with green and red for right and wrong the only other colour.** This is
   the whole genre: Cross Logic and Logic Grid Puzzles are both a white table with a green ✓ and
   a grey or red ✗, and Cross Logic's App Store icon is a crop of exactly that. Crosshatch has
   no checkmark and no cross anywhere. Ruled out is two cut strokes in copper's own shadow;
   fixed is a lozenge cut deep. Colour comes from six named cast inks, one per category, and by
   rule it never touches the plate — it lives on the paper, in the registration bands, the
   legend, the clue numerals, the day-book and the print.

2. **A result that is "8 out of 10" in a card, or a win shown as a `.sheet` at `.medium` with a
   checkmark seal.** Crosshatch's result is a plate being inked, wiped and printed over 1.3
   seconds, ending with the print going up on a line it stays on. Then the margin card names
   what is waiting — "Nine on the line. The aquatint box comes down at thirty." No sheet, no
   seal, and "come back tomorrow" is in none of the app's copy.

3. **The system-grey canvas with white rounded cards** — and this genre's own version of it, the
   hairline spreadsheet on white, which not one of the five leaders escapes. Instead: a zinc slab
   with a crosshatch ground drawn in `Canvas`, bed rails as the horizon, copper plates and cut
   paper at corner radius 3, New York Bold at 108 pt, and thirty-two engraved cast marks where
   the category puts rotated 8 pt text. Every screen here is recognisable from one crop.

Worth naming a fourth, because Nonogram.com is the polish bar and ships it: **hearts and a hint
currency.** Crosshatch's loupe is free, unlimited and forever, and the only thing at stake on a
plate is whether its margin comes out clean.

## Roads not taken

- **The night switchboard** — a 1950s telephone exchange at three in the morning: the matrix is
  a patch bay, a fixed pairing is a cord pushed home, a ruled-out one a brass blank capping the
  socket, and the clues are call slips coming in on a spike. Killed because a 6×6 patch bay with
  legible labels is denser than a phone screen holds, and pushing a jack home has one beat where
  the burin has three.
- **The plate-glass sky survey** — a nineteenth-century observatory: the matrix is a photographic
  plate of a star field, a fixed pairing is a star caught in the cross-wires, and the win draws
  the constellation between them and names it. Beautiful, and it would share well — but night sky
  and constellations is the most worn calm-app look there is, and scratching a glass plate has
  none of the copper's bite.
</content>
</invoke>
