# Baize · design

## The idea

**A writing desk with a blue baize top, late, under one lamp: the day's deal laid out on the
cloth, a diary open beside it where every deal that came out is written down as the card you
had to dig for.**

Three words: **laid, kept, out.** ("It came out" is what people have said of a patience that
succeeds for two hundred years, and it is the only word this app has for winning.)

What it is NOT: **green felt.** All six leaders are one screenshot — a green cloth, white cards
with blue backs, `Score · Time · Moves` across the top, a lightbulb hint and an undo in circles
at the foot, "Train Your Brain" in the caption, and a daily challenge drawn as a month of gold
stars. Four of six icons are cards on green felt. Baize is the name of that cloth and the app
refuses the colour: the table is **Prussian blue** by day and **midnight** under the lamp, the
cards are **cream stock with serif indexes**, the wood of the desk shows at the edges, and
there is no score, no clock unless asked, no lightbulb anywhere. The one screenshot in the
category that is blue.

The polish bar the best of them set is MobilityWare's legibility — a card you can read from
arm's length, a drag that never drops — and Solitaire.com's calm. Baize clears both and adds
what none of them has: a table that knows which card was the hard one, and a diary that keeps it.

## Who and when

She is 54, plays patience to come down — in bed with the brightness low, in a waiting room, on
the sofa after the news — and has deleted three solitaire apps this year: one for an ad that
opened a website she did not want, one that froze mid-hand after an update, one whose "daily"
stopped loading when her VPN was on. She does not want to be trained, timed or sold to; she
wants the small order of fifty-two cards going up in sequence, and to know the deal was fair.

The feeling she comes for is the last run of cards going home by themselves — the table
clearing, the four kings on top, nothing left to do — and then one quiet line that says it came
out. Calm is the job. But calm is not weightless: the only thing at stake on any evening is
whether tonight's deal came out **clean** — without taking a card back — and **under the mark**,
and that costs tonight's deal and nothing else.

## The play

The loop: **lay a proved deal, play it up to the foundations, and write it in the diary.** What
she is chasing is a deal that comes out clean, under the mark, on a harder table than
yesterday's — and the day's one shared deal, which everyone else who opened the app today is
also sitting down to.

- **The session.** One deal: three to twelve minutes, ended by the last card going up. A deal
  has 52 cards to send home; the first ~21 are face down and each one **turned** is a small
  reward (see the signature interaction); each card to a foundation **climbs the scale**; the
  moment every card is face up the table **takes itself off** — the sweep — and the win is
  played. The day offers two tables: **today's deal**, seeded from the date so it is the same
  for everyone, and **the next deal in the ledger** — your own numbered sequence, the run. A
  session ends on the diary line (see "The ending"). Nothing counts down. The clock is off
  unless she turns it on in Settings, and it is never on the table by default.

- **At risk.** `Run`, for the length of one deal and nothing beyond it.

  - Each card placed on a foundation: `run.hit()`.
  - Each **undo** — "take it back" — one tap, whatever it reverses: `run.miss()`. Undo is
    free, unlimited, and costs exactly this: the chain and the clean sheet of *this deal*.
  - A **recycle** of the waste back onto the stock is not a miss. A pass through the stock
    with no card played is not a miss. Only taking back is.

  `run.chain` is **cards up without a take-back**; `run.isClean` is a deal that came out with
  none. The second thing at risk is **the mark**: every deal carries the dealer's line — the
  move count of the line the build's solver found — and the mark is that line plus a margin
  the ladder tightens (see below). Coming out *under the mark* is the deal's second honour,
  and every move over it costs only that.

  What a take-back costs: **this deal's clean sheet and this chain.** Not a life, not a hint,
  not the day, not an entry already in the diary, not tomorrow, and nothing that can be bought
  back. She always finishes the deal — every one is proved to come out. Taking back simply
  means this one was not clean, which is the truth and is all the clerk says.

  This is what makes looking before moving worth doing in a genre where the undo button
  usually does the thinking — and it does it with no timer, no lives and no score.

### The ladder

`Ladder`, keyed on **rung** — your own position in the ledger. A ledger deal that comes out
advances it by 1. It never goes down. Today's deal does not move it (see "Today's deal").

| Dial | From | By | Every | Opens at | Ceiling | What it is |
| --- | --- | --- | --- | --- | --- | --- |
| `grade` | 1 | 1 | 14 | 1 | 9 | Which ninth of the proved pack the deal comes from, by the build's difficulty rank (see *Grades*) |
| `draw` | 1 | 2 | 39 | 1 | 3 | Draw one from the stock, or draw three. Three from rung 40. |
| `tight` | 0 | 5 | 24 | 1 | 35 | How far the mark sits over the dealer's line: `mark = line × (140 − tight) / 100`. Forty percent over at rung 1; five percent over from rung 169. |

```swift
let ladder = Ladder([
    .init("grade", from: 1, by: 1, every: 14, opensAt: 1, ceiling: 9),
    .init("draw",  from: 1, by: 2, every: 39, opensAt: 1, ceiling: 3),
    .init("tight", from: 0, by: 5, every: 24, opensAt: 1, ceiling: 35),
])
```

**Grades, exactly.** The pack is built, not written (SPEC.md): `apps/solitaire/tools/pack.mjs`
shuffles from a seed, proves the deal comes out by search at the draw it will be served at,
records the **line** (the shortest winning move sequence the search found in its budget,
pruned of wasted moves), and ranks every proved deal by a difficulty score — the search's
effort, the depth of the deepest ace under face-down cards, the number of passes through the
stock the line needs, and the line's length, each as a rank over the proved pool. The pool is
cut into nine equal parts by that rank: grade 1 is the easiest ninth, grade 9 the hardest. A
grade is a *position in a real ranking of real deals*, so the ceiling is honest: grade 9 is as
hard as the pack has, and the pack is the hardest deals the build could prove.

**Where it stops, and what happens past it: `flattensAt` is 169** — `tight` reaches 35 at rung
169 — and `ladder.climbs(through: 150)` is true. That is an honest end, stated rather than
dodged with an open dial. Klondike has a hardest proved deal, and draw three is as blind as
the stock gets. Past rung 169 the dials are fixed and what still changes is the only thing
left: **which deal** — from the hardest ninth, at draw three, chosen by `Mastery` from the
**shape** her record says she is worst at (see "What comes next"), never one she has played.
Rung 300 and rung 900 are both the hardest table the pack has, laid against different
weaknesses, and that is said plainly here rather than hidden.

`draw` moves once, at 40, and it is the dial that changes the game qualitatively: with draw one
every card in the stock is reachable, so the puzzle is the tableau; with draw three only every
third card comes up on a pass, so the stock is a puzzle too and the order you play the waste
in matters. `tight` is the dial that keeps climbing after the others are spent — a mark at
forty percent over the line is forgiving, at five percent it means playing nearly the line
the machine found.

### Today's deal

Today's is **not** on your personal rung — someone joining on day 300 must not be handed a
rung-300 table, and someone at rung 300 must not be handed a rung-1 one. It runs a published
week, like a crossword, the same for everybody:

| Mon | Tue | Wed | Thu | Fri | Sat | Sun |
| --- | --- | --- | --- | --- | --- | --- |
| 4 | 18 | 32 | 46 | 74 | 102 | 150 |

Which gives, through the dials: Monday grade 1 at draw one with the mark forty percent over
the line; Wednesday grade 3; Thursday grade 4 and **draw three** from here to Sunday; Saturday
grade 8; Sunday grade 9 with the mark ten percent over. The day's deal is a fixed entry in the
pack keyed by the **day number** (days since Monday 19 October 2026), so it is the same cards
on every phone, exactly as the spec asks; its seed is printed on the table. Today's deal is
free forever at every rung, and it counts as an **entry** — for the diary, for `Earned`, for
the days running — without moving the ledger's rung.

### What comes next

Nothing here is `%` over a fixed list and nothing is drawn uniformly at random.

**The five shapes.** The build classifies every proved deal by *what makes it hard* — the first
of these that applies, in this order, so each deal has exactly one:

| # | Shape | The rule | What it asks of you |
| --- | --- | --- | --- |
| 1 | **Buried** | The deepest ace has four or more face-down cards over it | Dig: empty the column over it before anything else |
| 2 | **In the stock** | Two or more aces are in the stock | Turn the stock early and play the waste in order |
| 3 | **Kings up** | Two or more kings are face up at the deal, or are the second card of a column | Make an empty column, and spend it well |
| 4 | **Long passes** | The line needs three or more passes through the stock | Patience: nothing is lost by going round again |
| 5 | **Even** | None of the above | Read the whole table before the first move |

`Mastery<Shape>` over the five shape ids, **written on every deal that comes out and read to
choose the next deal in the ledger**:

- a deal that came out with at most two take-backs → `mastery.record(shape, correct: true)`
- a deal that came out with six or more take-backs, or was **gathered** (restarted) or laid
  over unfinished → `mastery.record(shape, correct: false)`
- three to five take-backs: nothing recorded — neither mastery nor a miss

Then, for the next deal in the ledger:

1. `let shape = mastery.next(from: Shape.allCases, count: 1, unseenShare: 0.3, avoiding: Set(lastTwoShapes)).first`
   — the shape she is weakest at, with a share of ones she has not met, and not one of the
   last two.
2. The engine takes the **first deal in pack order** whose `draw` and `grade` match
   `ladder.dials(at: rung)` and whose shape is the chosen one, skipping any deal already in the
   diary or on the table. If that shape is exhausted at this grade, the next shape in
   `Mastery`'s order; if the grade is exhausted, the nearest grade. The pack is shuffled once
   at build time, so "first in pack order" is deterministic and never comes round again.
3. **Loose deals** (free, from the table's menu, at the draw she picks) use the same rule with
   the *current* rung's grade and the draw she asked for, so a loose deal is as hard as the
   ledger is right now and never one she has played.

`grade`, `draw` and `tight` are read by the engine on every deal; `shape` is compared in
`Mastery.next`; the dealer's `line` is read to set the mark. Nothing here is a field that is
written, displayed and never read. The ledger table in the drawer (the spec's "lifetime stats")
is a *view* of the same entries `Mastery` reads.

### Earned

`Earned`, on **entries** — deals that came out, today's and the ledger's and loose ones
together. These arrive for playing, never for paying, and none of them is for sale: the drawer
(Pro) holds backs, cloths, the left-handed table, the archive and the whole count; the things
below cannot be bought at any price, which is what makes the second door a door.

| At | id | What opens | The line |
| --- | --- | --- | --- |
| 1 | `diary` | **The diary.** The first entry is written and the month page is kept. | "Your first entry. The diary keeps it." |
| 10 | `claret` | **The claret cloth.** Red baize, the kind on a bridge table — pick it in Settings or from the table's menu. | "Ten came out. There is a claret cloth folded in the desk now, if you want a change." |
| 25 | `lattice` | **The brass lattice back.** A second card back, cream with a brass lattice, drawn for this table. | "Twenty-five. A second back for the cards — the brass lattice. It is in Settings." |
| 50 | `gilt` | **Gilt edges.** Every card from here has a hairline of brass round its face, on the table and on the card you send. | "Fifty. The cards are gilt-edged from here on." |
| 100 | `seal` | **The seal.** A brass seal — the four pips in a ring — stamped on every diary page and on every card you send from here. | "A hundred entries. The clerk has had a seal cut. It goes on everything from here." |
| 365 | `volume` | **Volume two.** The diary's first year is hemmed at the top of the Diary screen as a shelf of twelve small pages; a fresh volume opens under it. | "A year of entries. Volume one is shelved; volume two is open." |

`earned.next(after: entries)` is what a session ends on. There is no hint anywhere in the app:
the table never says where a card goes, which is the whole point of patience.

### The ending

The exact words, on the diary line under the cleared table:

> **"It came out clean, in 118 moves — under the mark by 29. Twenty-three entries in the
> diary. The brass lattice comes at twenty-five."**
>
> **"Next in the ledger: No. 52, draw three, grade four."**

The shape, two lines: `"It came out {clean | with one taken back | with {n} taken back}, in
{moves} moves — {under the mark by {n} | over the mark by {n}}. {entries} entries in the diary.
{earned.next, shortened}."` then, for a ledger or loose deal, `"Next in the ledger: No. {n},
draw {one | three}, grade {g}."`, and for today's deal, `"Today's is in the diary. Tomorrow's
is laid at midnight."` Past the last milestone the first line names the record instead:
`"… {entries} entries in the diary, and {days} days running since the nineteenth of
October."` On a first-ever entry: **"Your first entry. It goes in the diary, and the table is
cleared for the next one."**

Specific, earned, true, and with no guilt in it. The words "come back tomorrow" appear nowhere
in the app.

### Sessions 5, 50 and 500

- **5.** Ledger No. 5: draw one, grade 1 — an easy ninth deal, aces near the top, the mark
  forty percent over the dealer's line. Four entries in the diary and the claret cloth six away.
  A clean deal is very possible, and the first one that is not clean is where she learns what
  the chain is.
- **50.** Ledger No. 50: **draw three** (from 40), grade 4, the mark thirty percent over the
  line, and the deal chosen in the shape her record is worst at — a *Buried* table if she keeps
  digging late, *In the stock* if she keeps turning the stock late. The claret cloth and the
  brass lattice are hers, forty-odd entries are on the pages, and a clean deal at draw three is
  genuinely worth protecting.
- **150.** Ledger No. 150: draw three, grade 9 — the hardest ninth of the pack — with the mark
  ten percent over the line, so every careless move over the line shows. Gilt edges, the seal
  on the page. The deal was picked against her record.
- **500.** Ledger No. 500: draw three, grade 9, the mark five percent over the line — nearly
  the machine's own line, under the lamp — in the shape she is worst at, which by now is a
  real finding about her and not a guess. Volume two of the diary. Session 5 and session 500
  are not the same game: at 5 she plays the obvious card and it comes out; at 500 she reads the
  whole table before touching it, counts the passes, and plays the waste in an order.

## The signature interaction

**Moving a run.** It is the verb she performs a hundred times a deal and a few thousand times
a week, and every one has the same three beats: it lifts, it goes, it lands.

### Dragging a run

| ms | what happens |
| --- | --- |
| finger down | On a face-up card. The card and every card below it in the column **lift** together: scale 1 → 1.04, the shadow grows (radius 2 → 14, y 1 → 8, `cardInk.opacity(0.35)`), on `.spring(response: 0.18, dampingFraction: 0.8)`. `Haptics.soft()`. |
| 0 → | **It goes.** The top card follows the finger with no lag. Each card under it follows the card above with a trailing spring — `.spring(response: 0.14 + 0.02 × i, dampingFraction: 0.85)` for the i-th card down — so a run of five **bends like a hand of cards** when the finger moves fast and straightens when it stops. The run is drawn above everything. |
| entering a target | When the run's centre enters a column or foundation where the move is legal, the target's top card **nudges** down 3 pt on `Motion.pop` and the spot shows a card-shaped ghost at `cardStock.opacity(0.22)`. `Haptics.selection()` — one detent per target entered. Nothing lights up anywhere else; there is no hint in this app. |
| release, legal | **It lands.** The run flies the remaining distance on `Motion.snappy` (response 0.3, damping 0.8), scale 1.04 → 1, the shadow collapses. `Haptics.rigid()` — card on cloth. `Tones.shared.play(.pop, volume: 0.4)`. |
| +80 | **A card turns.** If the column it left now shows a face-down card, that card **turns**: `rotation3DEffect` about the y axis, 0° → 90° with the back, swap, 90° → 0° with the face, 0.22 s total on `.spring(response: 0.22, dampingFraction: 0.9)`. `Haptics.tap()`, `Tones.shared.play(.tap, volume: 0.5)`. The clerk says nothing; the turn is its own reward. |
| landing on a foundation | As above, plus `Tones.shared.play(.step(rank − 1), volume: 0.5)` — ace low, king high, so **you can hear each suit climb** — and `Haptics.impact(0.25 + 0.04 × rank)`. `run.hit()`. The foundation's card shows a brass hairline for 300 ms. |
| release, illegal | The run **goes home** to where it came from on `Motion.bouncy`, settles with scale 1.04 → 1. `Haptics.soft()`. No tone, no shake, no red. A card that cannot go somewhere simply comes back. |
| 300 | Settled. Nothing about a landed card moves again until it is moved. |

### Tapping instead of dragging

A **tap** on a face-up card sends it to its best legal place — the foundation if it can go up,
else the longest legal column — with the same lift, flight on `Motion.snappy` over at most
0.35 s, and landing. A card with nowhere to go **shrugs**: rocks 2° and back on `Motion.pop`,
`Haptics.soft()`, no sound. This is what VoiceOver and Switch Control use, what someone with a
tremor uses, and what most people use most of the time; it is never mentioned in text. Every
card is an accessibility element — "Seven of hearts, face up, column 3" / "Face down" / "Stock,
twelve cards" — and a movable card carries the hint: "Double tap to play it up, or drag it to
a column."

### The stock

A tap on the stock turns **one** card (draw one) or **three** (draw three) onto the waste:
each card slides 60 pt right and turns in one motion, 0.2 s, staggered 60 ms, `Haptics.tap()`
once, `Tones.shared.play(.tap, volume: 0.3)` once. At draw three the waste shows the three
fanned 14 pt apart, the top one playable. When the stock is empty it shows a faint ring
(`arrow.counterclockwise` at 20 pt in `inkSoft.opacity(0.5)` — a glyph, not a hero); a tap
**gathers the waste back** in one sweep, the pile sliding left and turning over as one, 0.3 s
on `Motion.gentle`, `Haptics.soft()`. No count of passes is shown, and no pass is the last.

### Taking it back

"Take it back" — the toolbar's leading button — plays the last move **backwards**, the same
animation reversed over 0.25 s, including a turned card turning back down. `Haptics.soft()`,
`Tones.shared.play(.miss, volume: 0.3)` — two soft notes down, not a buzzer. `run.miss()`. The
head's caps change from `CLEAN · 31 UP` to `ONE TAKEN BACK · 31 UP`, and one line from the
near-miss pool sets at the foot for 2 s. Press and hold the button to take back one move every
120 ms; one hold is one miss.

**Why it holds up the thousandth time:** every move is three beats — lift, go, land — with a
detent under the finger for each; a run bends as it goes and straightens as it lands; a card
turning is a small event with its own sound; and the foundations play a scale you can hear
climbing all the way to the kings.

### The first deal

Nobody is told what to do. On a first launch the ledger's No. 1 is laid — grade 1, draw one —
and after the deal settles (0.9 s) the card that can go up first **breathes**
(`.breathing(amount: 0.06, period: 2.2)`), and a **ghost hand** — a fingertip's circle at
`cardStock.opacity(0.18)`, 44 pt — comes down on it, drags it to the foundation along a curve
over 0.8 s with a ghost of the card at 30 % following, and lifts off. It repeats every 4 s until
the first move. If no tableau card can move, the stock breathes instead and the hand taps it.
Both stop at the first move and never come back. The words "drag", "tap" and "swipe" appear
nowhere on the table.

Then, once No. 1 has come out, "Lay today's deal" is the next button, whatever today's weekday is.

## The reward

**It comes out.** The last face-down card turns and nothing on the table is hidden any more.
The app does not open a sheet with a checkmark on it — the table takes itself off while she
watches, and the diary is written.

| ms | what happens |
| --- | --- |
| 0 | The last card turns as normal. `Haptics.thud()`. The lamp **swells**: the canvas glow's radius grows 12 % on `Motion.gentle` and stays. |
| 200–1400 | **The sweep.** Every card still on the table flies to its foundation in rank order — all four aces, then the twos, and so on — one every `1.2 s / remaining` (floor 25 ms), each with the landing beats: `Tones.shared.play(.step(rank − 1), volume: 0.5)` and `Haptics.impact(0.2 + 0.6 × progress)`. A rising scale, repeated four times a step, that ends on four kings. Taking back is disabled from the first card of the sweep. This is the Windows cascade turned round: the cards come *home*, in order, and you can hear it. |
| 1400 | The last king lands. `Haptics.celebrate()`. `Tones.shared.play(.fanfare)`. |
| 1450–1950 | **The fans.** Each foundation **blooms** into a fan of its thirteen cards, 4° apart, the king on top, on `Motion.bouncy`, staggered 60 ms spade · heart · club · diamond, and the four fans drift to the centre of the table and overlap into one spread — the picture of a deal that came out. |
| 1500 | **Pips fall.** `.confetti(trigger: cameOut, colors: [cardStock, pipRed, brass, cardInk], from: UnitPoint(x: 0.5, y: 0.3), count: 44, power: 0.7)` — a small, heavy scatter of card-coloured flakes, gone fast. Never party confetti. |
| 1500–2100 | **The count.** Under the fans the moves rise at `.brandDisplay(size: 96)` in `ink`: `CountUp(to: moves, duration: 0.6, onTick:)`, each tick `Haptics.impact(0.25 + 0.03 × n)`, with `MOVES` in the caps beside it and `THE MARK 147` under. |
| 1700 | The tier headline sets in New York at 30 pt in `highlight`, then the clerk's line from the praise pool under it in `inkSoft`, italic. |
| 1900 | **The diary line** rises on `Motion.gentle` with the ending's two lines and the buttons; on it, a **strip of the month** with today's slot being written: the buried card pops in (`.popIn`) in the day's slot. |
| 2100 | Everything stops. The fans lie spread at the centre with their shadow under them; only the lamp keeps breathing. |

The sweep belongs to the game and the win to the reward; from the last king to the diary
line is 0.7 s, and the whole thing from the last turn is a little over two seconds.

**Tiers**, from `run.tier(score: marginPercent, beating: record.bestMargin)` where
`marginPercent = Int(100 × (mark − moves) / mark)` — how far under the mark, as a share of it,
so a rung-5 margin and a rung-500 margin are measured the same way:

| Tier | When | Headline | The difference |
| --- | --- | --- | --- |
| `best` | Further under the mark, as a share, than ever before | "It came out — further under the mark than you have ever been" | The fans bloom to 6° apart and take a **gilt edge** flash — a brass hairline round every card, 200 ms after the bloom; pips at `power: 1.1, count: 72`; `Haptics.celebrate()` twice, 200 ms apart; `.fanfare` then `.step(12)`. |
| `clean` | No take-back | "It came out clean" | `power: 0.8, count: 56`, `.fanfare`. The full bloom. |
| `good` | Up to thirteen take-backs — `hits / attempts ≥ 0.8` | "It came out. {One card | n cards} taken back, and nobody counts those" | `power: 0.5, count: 40`, `.success` in place of `.fanfare`; the fans bloom to 3°. |
| `finished` | The rest | "It came out. It took some taking back, and it is out all the same" | `power: 0.4, count: 26`, `.success`; 3°; no pips at all if the deal was gathered and laid again. |

*Under the mark* is a second honour independent of tier: the diary's slot takes a brass
underline, the ending says by how much, and the share card says `UNDER THE MARK`.

**Inside the loop**, the small rewards are the **turn** — a face-down card turning with its
tick — and the **climb** — each card up playing the next note of its suit's scale. A deal has
a sound you can follow without looking: ticks while she digs, the scale climbing as it opens
up, four kings at the end.

## Look

### Palette

Day is the desk by a window: a slate-Prussian baize, walnut round the edge, cream card stock,
brass fittings. Night is not that inverted: it is the same desk under one lamp — the baize goes
to midnight, the walnut darker, and **the cards, the brass and the lamp stay warm**, because
card stock under a lamp is still cream.

| Role | Light | Dark | Job |
| --- | --- | --- | --- |
| `canvas` | `#34547A` | `#14243A` | **The baize.** The cloth under everything, every screen. |
| `surface` | `#5E4432` | `#3A2A1F` | **The walnut.** The desk's wood: Settings rows, the paywall's rows, the diary line, the drawer. |
| `ink` | `#F4ECDC` | `#EDE3CF` | **Cream ink.** Type on the baize and the walnut. |
| `inkSoft` | `#D2C8B2` | `#A89F8B` | The caps, dates, the clerk's asides. |
| `accent` | `#D9B35C` | `#E2BD66` | **Brass.** The tint: primary actions, toggles, the selected tab, today's ring on the diary, the hairline on a foundation card as it lands. |
| `onAccent` | `#241A10` | `#1E150B` | Type on the brass. |
| `highlight` | `#FBB9A9` | `#F7A896` | **Vermilion under the lamp.** The second voice: the win's headline, the `best` tier, the days-running count on the hem. |
| `success` | `#A6D6AD` | `#95C9A0` | **Moss.** A clean deal's mark, "under the mark", the reminder laid. Never system green. |
| `miss` | `#B7CADD` | `#9DB1C7` | **Slate.** "Taken back" in the caps, the near-miss line. Never red, never an alarm. |

**`extras` — the card box**, in this order:

| # | Name | Light | Dark | What it is |
| --- | --- | --- | --- | --- |
| 0 | Card stock | `#F6EFE0` | `#EFE7D6` | The face of every card, the diary's page, the share card |
| 1 | Card ink | `#1E2532` | `#1E2532` | Indexes and pips of spades and clubs; type on the page |
| 2 | Pip red | `#B8372A` | `#B8372A` | Hearts and diamonds |
| 3 | Pip green | `#2F6B45` | `#2F6B45` | Clubs, when four-colour suits are on |
| 4 | Pip blue | `#2B5C9B` | `#2B5C9B` | Diamonds, when four-colour suits are on |
| 5 | Lamp | `#F3C37A` | `#F0B964` | The lamp's own colour: the glow's centre, the ring round the fans, the seal |
| 6 | Brass deep | `#A47E35` | `#8F6D2C` | The shadow side of anything brass: the desk's corners, the drawer's handle, the gilt edge |

**The rule that governs all of them: colour is on the cards, and the cards are on the cloth.**
The baize and the walnut carry no colour but their own; the cards carry cream, card ink and pip
red and nothing else; the one brass hairline appears for 300 ms when a card lands on a
foundation. The salmon, moss and slate appear as words and small marks on the baize — the
headline, the caps — never on a card. That rule is what keeps the table from becoming the
category's billboard, and it is checkable: any colour on a card that is not stock, card ink,
pip red (or the four-colour pips) or the earned gilt is a bug.

Checked with `node tools/design/contrast.mjs`:

```
ink       #F4ECDC on #34547A   6.63 AA     #EDE3CF on #14243A  12.28 AAA
ink       #F4ECDC on #5E4432   7.61 AAA    #EDE3CF on #3A2A1F  10.77 AAA
inkSoft   #D2C8B2 on #34547A   4.69 AA     #A89F8B on #14243A   5.95 AA
inkSoft   #D2C8B2 on #5E4432   5.38 AA     #A89F8B on #3A2A1F   5.22 AA
onAccent  #241A10 on #D9B35C   8.58 AAA    #1E150B on #E2BD66  10.03 AAA
accent    #D9B35C on #34547A   3.92 large  #E2BD66 on #14243A   8.71 AAA
highlight #FBB9A9 on #34547A   4.68 AA     #F7A896 on #14243A   8.19 AAA
success   #A6D6AD on #34547A   4.77 AA     #95C9A0 on #14243A   8.29 AAA
miss      #B7CADD on #34547A   4.64 AA     #9DB1C7 on #14243A   7.11 AAA
card ink  #1E2532 on #F6EFE0  13.43 AAA    #1E2532 on #EFE7D6  12.50 AAA
pip red   #B8372A on #F6EFE0   5.07 AA     #B8372A on #EFE7D6   4.72 AA
pip green #2F6B45 on #F6EFE0   5.54 AA     pip blue #2B5C9B on #F6EFE0  5.90 AA
lamp      #F3C37A on #34547A   4.79 AA     #F0B964 on #14243A   8.81 AAA
```

Every role that carries body text is AA or better on what it sits on, in both modes. Brass on
the day baize (3.92) is a glyph and a button fill there, never a word: wherever brass sets a
word it is `onAccent` on brass. A card's index is card ink or pip red on card stock at AA.

### Canvas

`BrandCanvas.glow(Color(light: 0x4B6E96, dark: 0x4A3F2E), at: UnitPoint(x: 0.12, y: 0.02))` —
window light from the upper **left** by day; **the lamp** on the same side at night, warm.
Small on purpose: a glow you can find reads as a lamp, one that floods reads as a vignette.

Over it, drawn once in a single `Canvas`: **the nap**. Baize has a nap, and the nap is what
makes a cloth look like a cloth rather than a flat fill: a seeded field of 1 pt flecks, about
one per 9 pt², at `white.opacity(0.03)` in light and `.white.opacity(0.025)` in dark, from a
fixed constant so every launch and every screenshot are identical; it never animates. After
`claret` is earned and chosen the canvas colour becomes `Color(light: 0x7A2E35, dark: 0x3C181D)`
and the glow `Color(light: 0x95464D, dark: 0x5A3230)`; the nap is the same. That is the only
difference between the two cloths. (The drawer's other cloths — moss and slate — are the same
again in `0x2F5A42 / 0x14291D` and `0x4A5563 / 0x232A33`.)

And **the desk's edge**: on the Table screen a 6 pt band of `surface` runs along the very top
of the content under the toolbar and along the bottom above the tab bar, with a 1 pt highlight
of `.white.opacity(0.08)` on its inner edge — the wood of the desk showing round the inset
cloth. Two brass corners (an L of 14 × 14 pt in `brassDeep` with a `lamp` highlight) sit at the
top-left and bottom-right of the cloth. Those two corners are in every screenshot of this app.

### Type

`BrandType(display: .serif, displayWidth: .standard, displayWeight: .semibold, body: .default)`
— **New York Semibold** for every display element: the card indexes, the moves, the month on
the page, the number of a ledger deal. A playing card's index has been a serif for two hundred
years and the category sets its cards in Helvetica Bold without exception; New York is free
and nobody else's here. *Semibold*, not bold: at 96 pt a bold serif numeral loses its
hairlines, and at 14 pt on a card a semibold one is still a card.

The third voice is **the caps**: `.caption2` with `.textCase(.uppercase)` and `.tracking(2)` in
`inkSoft` — the small letters on a desk diary's running head: `TODAY · MONDAY 12 OCTOBER`,
`DRAW ONE · GRADE 1`, `CLEAN · 31 UP`, `THE MARK 147`, `23 ENTRIES · 9 DAYS RUNNING · 14
CLEAN`. Never a sentence. And one **typewritten** line: the seed, in `scaledFont(size: 11,
weight: .medium, design: .monospaced)` at `inkSoft.opacity(0.75)` — `№ 285 · 2026-10-12 ·
7C3A-19B2` — because a serial is typed, not lettered.

Hero numbers, always through `.brandDisplay(size:)` so they scale with Dynamic Type:

- **moves, on the win — 96 pt**, the largest thing in the app
- the month's name on the diary page — 40 pt, with the year in the caps beside it
- **entries**, on the Diary screen above the page — 112 pt, the largest thing in the app
  after the win, sitting behind the top edge of the page
- the next ledger deal's number on the Table's done state — 76 pt (`No. 52`)
- moves, on the table's head — 34 pt (`118` with `MOVES` in the caps beside it)
- the share card's moves — 240 pt on the 1080 × 1350 card
- a card's index — `brandFont(.title3)` at the table's card width, `.largeTitle` on a full-size
  card, and the centre pip at 55 % of the card's width (70 % with large pips on)

Every screen has exactly one thing at 34 pt or over and nothing else competing with it. No
`.font(.system(size:))` anywhere, on any screen, including the share card: `scaledFont(size:)`
and `brandDisplay(size:)` say the same point size and still scale.

### Shape

**The card** is the one distinctive shape: a 5 : 7 rounded rectangle, corner radius 8 % of its
width, in card stock with a 0.5 pt rule of `cardInk.opacity(0.12)` just inside its edge. It is
the deal's unit, the diary's slot (an empty card outline for a day, a small card for a day that
came out), the page indicator in onboarding (`OnboardingView(indexMark: "▮")`, set in New York),
the bullet before every paywall line (`PaywallBullets.ruled(mark: "▮")`), the selection mark in
every picker — never a checkmark anywhere in the app — and the drawer's swatches.

**Corner radius 8**, for the whole brand. A card, a page and a drawer are stiff things with
small corners, not pillows; against the kit's 22 that alone changes how the app feels before
anything else is drawn.

**A card's face** is drawn one way everywhere, in `CardFace.swift`: the index (rank over suit)
at the top-left in New York Semibold, the same index **upside down at the bottom-right**, and
**one centre pip** at 55 % of the card's width — never the ten tiny pips of a printed ten;
a single big pip reads from arm's length, which is MobilityWare's legibility done with one
shape instead of ten. **Court cards** are the letter at the centre at 48 % of the width with
the suit's pip small beneath it and a **brass emblem** above — a crown of five points for the
king, a circlet with one gem for the queen, a single plume for the jack — drawn as `Path`s in
`brassDeep`, the only brass that ever appears on a card face (the emblems are 10 % of the
card's width, so they are an accent and not a colour). The **ace** is the pip alone at 62 %.
The four pips are four `Path`s in `Pips.swift`, drawn in card ink for spades and clubs and pip
red for hearts and diamonds, or in the four-colour set when that is on.

**A card's back** is card stock with a 3 pt inset border and, inside it, a **lattice**: two
fields of 1.2 pt lines at ±45° on an 8 pt pitch in the canvas's own blue (`#34547A` in both
modes, so the back is a blue lattice under the lamp too), with a small lozenge of the same at
the centre. The earned back is the same lattice in `brassDeep`; the drawer's backs are listed
under *The drawer*.

**The page** is the diary's shape: card stock, radius 8, a 1 pt rule of `cardInk.opacity(0.18)`
along its top 44 pt (the running head), the month in New York Semibold at 40 pt at the left of
that head and the year in the caps at the right, a 7-column grid of card slots under it with
`M T W T F S S` in the caps above, and a **ruled hem** at the foot. The same page, at 1080 ×
1350, is the share card.

**The ledger's number** — `No. 52` — is set in New York with the `No.` at 60 % of the numeral,
superscript-aligned. It appears on the Table's head, on the done state, in the ending, and in
the share card's running head.

### Art

Drawn as SVG in `design/art/` — generated by `node apps/solitaire/design/make-art.mjs` from
`cards.js`, so every card in the art is drawn by the same geometry as the mocks — rendered by
`node tools/design/art.mjs … --width 300` into the asset catalog and used as `Image("…")`. Each
has a 372 × 340 `viewBox`. No SF Symbol is ever the hero of a screen.

| File | Depicts | Where |
| --- | --- | --- |
| `desk.svg` | The desk from above at a slight angle: the blue baize inset in its walnut frame with two brass corners, the lamp's pool of light at the upper left, a deal half laid — four foundations, a few columns, a run of three cards in mid-air with their shadow — and the diary's edge showing at the right. | Onboarding 1, the Diary's empty state |
| `fans.svg` | Four fans of thirteen cards bloomed and overlapped at the centre of the cloth, kings on top, the lamp catching the top edges, a scatter of pips in the air. | Onboarding 2, the Table's "today's is in the diary" state |
| `diary.svg` | The diary open on the cloth: the month page with a dozen small cards written into its slots, a brass underline on one, a pen lying across the hem, the page's shadow on the baize. | Onboarding 3, the Diary's masthead when `volume` is earned |
| `drawer.svg` | The desk's drawer pulled open: six card backs in a row, four folded cloths (blue, claret, moss, slate), a bundle of past deals tied with a ribbon, the brass handle catching the lamp. | The paywall hero, the drawer's shut state |

Every piece is card stock, card ink, pip red, baize, walnut and brass, in the palette above and
nothing outside it. Anything that moves part by part — a card turning, a run bending, the
sweep — is drawn in SwiftUI; these are whole pictures that float.

### Motion

| Spring | For |
| --- | --- |
| `.spring(response: 0.18, dampingFraction: 0.8)` | A run lifting under the finger. |
| `.spring(response: 0.14 + 0.02 × i, dampingFraction: 0.85)` | The i-th card of a run trailing the one above. |
| `.spring(response: 0.22, dampingFraction: 0.9)` | A card turning face up, and back down on a take-back. |
| `Motion.snappy` | A run landing; a tapped card flying to its place; the stock turning; navigation, sheets, the diary's pages. |
| `Motion.pop` | A target nudging; a card shrugging; a milestone arriving in the diary line. |
| `Motion.bouncy` | A run going home after an illegal drop; the fans blooming. |
| `Motion.gentle` | The waste gathering back; the lamp swelling; the diary line rising; a month page turning. |

Ambient: the lamp **breathes**, `.breathing(amount: 0.03, period: 5)` on the glow; on a deal
with no move made, the first playable card breathes and the ghost hand loops, until the first
move. Nothing else is ambient; a card table at rest is still. All of it through FactoryKit or
behind `Motion.isStill`, so it stands still under `-stillFrames`.

Never moves: the nap, the desk's edge, the brass corners, a landed card, the page, the slots.
Motion belongs to a card in the hand and to the sweep.

### Sound

`Tones` throughout, on the ambient session, with `SoundsToggle()` in Settings. Everything is
quiet — this is played in bed.

| Tone | Volume | When |
| --- | --- | --- |
| `.tap` | 0.3 / 0.5 | The stock turning / a card turning face up |
| `.pop` | 0.4 | A run landing |
| `.step(rank − 1)` | 0.5 | A card going up: ace low, king high, the suit's scale |
| `.miss` | 0.3 | Taking it back |
| `.success` | 0.8 | A `good` or `finished` sweep's end |
| `.fanfare` | 0.8 | A clean sweep's end; `.step(12)` after it on a `best` |

## Voice

**The clerk** — the one who lays the table every morning, keeps the diary and counts the
moves. Precise, dry, fond of the cards; speaks in suits and numbers, never in praise. Has never
once said "great job".

Three rules:

1. **The clerk talks about the cards and the count, never about you.** "Fifty-two up, in
   order." Never "You're amazing!" and never "You're on a roll!"
2. **The clerk never counts what you missed.** A day not played is an empty slot; a take-back
   is a card taken back, which cards are for. Nothing the clerk says is a number that goes down.
3. **One sentence. It has to fit on the foot of the table.**

### Onboarding

`OnboardingView(pages:nextTitle: "Turn over", finishTitle: "Lay the table", indexMark: "▮")`,
each page `OnboardingPage(title:subtitle:art:)`.

| # | Title | Subtitle | Art |
| --- | --- | --- | --- |
| 1 | **One deal a day** | "Laid on the baize every morning — the same cards for everyone who sits down to it." | `desk.svg` |
| 2 | **Every deal comes out** | "Each one was played through before it was dealt, and its number is on the table so you can see which it was." | `fans.svg` |
| 3 | **The diary keeps it** | "A day that comes out is written in as the card you had to dig for. Clean, under the mark, or just out — it all goes down." | `diary.svg` |

Page 2 is the one onboarding page allowed to carry the promise, and it carries it as a fact
about the world rather than as a pitch.

### Praise pool — a deal came out

1. "Every card up. The table is bare."
2. "Fifty-two up, in order, the way they went."
3. "The six of hearts was the one to dig for, and you dug." *(the buried card is substituted)*
4. "Clean through. Not a card taken back."
5. "Under the mark by thirteen." *(the margin is substituted)*
6. "The kings are up and the baize is clear."
7. "The stock ran out and there was nothing left in it."
8. "Four suits, four stacks, done."
9. "The clubs went up without a wait."
10. "Out, and in good time."
11. "That is patience."
12. "The table takes itself off now."

### Near-miss pool — a take-back, or a stuck moment

1. "Taken back. The cards do not mind."
2. "Nothing moves. Turn the stock."
3. "Through the stock once. It is all still there."
4. "That seven wants a black eight, and there are two." *(the ranks are substituted)*
5. "Buried. Something above it has to move first."
6. "Back one. The deal has not changed."
7. "A king with nowhere to go, until a column empties."
8. "Taken back twice. Look at the stock before the columns."
9. "Round again. Nothing is lost by going round."

The near-miss line sets on a take-back; lines 2, 3, 7 and 9 set on their own — when no
tableau move is legal (2), when the waste is gathered for the first time (3) or again (9), and
when a king is the second card of a column with no empty column (7, once per deal).

### The win's headline, per tier

| Tier | Headline |
| --- | --- |
| `best` | "It came out — further under the mark than you have ever been" |
| `clean` | "It came out clean" |
| `good` | "It came out. {One card | n cards} taken back, and nobody counts those" |
| `finished` | "It came out. It took some taking back, and it is out all the same" |

### Empty states

| Where | Art | Headline | Line | Button |
| --- | --- | --- | --- | --- |
| Diary, nothing written | `desk.svg` | **Nothing written yet** | "Today's deal is laid. The first day that comes out goes here." | "Lay today's deal" |
| Table, today's already out | `fans.svg` | **Today's is in the diary** | "The ledger has the next one ready: No. 52, draw three." | "Lay No. 52" |
| Table, yesterday's still laid | — | — | The head reads `YESTERDAY'S · STILL LAID`; the menu offers "Lay today's deal", which gathers it. | — |
| Drawer, shut (free) | `drawer.svg` | **The drawer** | "Backs, cloths, the left-handed table, every past day's deal to lay again, and the whole count. $4.99, once." | "Open the drawer" |
| Month page, no days | — | **Nothing on this page** | "A day that comes out gets its card here." | — |
| A deal with no move made | — | — | Nothing. The first playable card breathes and the ghost hand shows the move. | — |

### What remembers you, instead of a streak

Along the hem of the diary page, in the caps, unasked:

`23 ENTRIES · 9 DAYS RUNNING · 14 CLEAN`

That is all. No flame, no number that goes back to zero, no red, and nothing anywhere that
mentions a day she did not play. A day missed is simply an empty slot on the page, which is the
truth and is not an accusation. "Days running" counts consecutive days with today's deal out;
the day it stops, the number quietly starts again from one and nothing is said. The spec's
"current streak" is this number, and it is shown this way.

### The reminder notification

Off unless she lays it. "Lay a reminder" is a system `Toggle` on the Diary screen and in
Settings; turning it on asks for permission then and only then, and schedules one local
notification a day at eight in the evening (a `DatePicker` under it sets the hour). It carries
this line and only this line:

> "Today's deal is laid."

No count of days missed, no question, no request, no "don't lose your streak".

### Paywall

`PaywallView(headline:bullets:bulletStyle:promise:subhead:cta:hero:onDone:)`, with
`bulletStyle: .ruled(mark: "▮")` — the card, set in New York, because this app's content is
cards on cloth and a `checkmark.circle.fill` in a rounded panel would be the one place the
design stops.

- Headline: **"The drawer"**
- Subhead: "One payment. The desk is yours."
- Bullets:
  - "Six card backs and four cloths drawn for this table — blue, claret, moss and slate.
    Green is in there, since you asked."
  - "The left-handed table: stock and waste on the left, foundations on the right."
  - "Every past day's deal, to lay again, and the whole count — by draw, by grade, and by
    what each deal asked of you."
- Promise: **"Today's deal stays free, every day, and every entry you have written stays in
  the diary."**
- `cta:` **"Open the drawer"** — one payment, no subscription and no trial, so the button says
  what the purchase does rather than naming a trial that does not exist.
- Dismiss: **"Leave it shut"**
- `hero:` `drawer.svg`

The spec puts the left-handed table in the drawer and it stays there; if the critic or the
owner reads it as an accessibility setting, it moves to Settings, free, with no other change.

### Button labels for every primary action

| Action | Label |
| --- | --- |
| Today's deal, not started | "Lay today's deal" |
| Today's deal, part played | "Back to the table" |
| The next deal in the ledger | "Lay No. 52" |
| A loose deal (menu) | "A loose deal · draw one" / "A loose deal · draw three" |
| Restart | "Gather the cards" |
| Confirm restart | "Gather them" |
| Undo (toolbar) | "Take it back" (`arrow.uturn.backward`, label shown to VoiceOver) |
| Share, from the win | "Send the card" |
| Share, from the diary | "Send the page" |
| Look at a past day (diary slot) | (a tap on the slot; VoiceOver "12 October, came out clean in 118 moves, the six of hearts") |
| Lay a past day again (drawer) | "Lay it again" |
| Onboarding next / finish | "Turn over" / "Lay the table" |
| Paywall | "Open the drawer" |
| Paywall dismiss | "Leave it shut" |
| The drawer, shut | "Open the drawer" |
| Reminder toggle | "Lay a reminder" |
| Clock toggle (Settings) | "Show the clock" |
| Four-colour suits (Settings) | "Four-colour suits" |
| Large pips (Settings) | "Large pips" |
| Left-handed (drawer) | "Left-handed table" |
| Cloth picker | "Cloth" (Blue · Claret · Moss · Slate) |
| Back picker | "Back" (Lattice · Brass lattice · Chevron · Houndstooth · Stars · Leaf · Seal) |
| Erase everything | "Clear the desk" |
| Confirm erase | "Clear it" |
| Settings upgrade row | "Open the drawer" (`upgradeTitle`) / "The drawer is open" (`activeTitle`) |

## Screens

Three tabs — **Table · Diary · Drawer** — and a gear on the Diary's toolbar to Settings. The
paywall is a sheet. Onboarding is three pages before any of it.

### 1. The table — Table (tab 1) · mock 1 shows it mid-deal

**Its one job:** the deal, and moving the cards.

**Hero:** the cloth with the deal on it — the stock and waste at the left of the top row, the
four foundations at the right, seven columns under them, and a run of cards in the hand with
its shadow on the cloth.

Top to bottom:

- `NavigationStack`, inline title: `Today` or `No. 52` (or `Loose`) in New York. Leading
  toolbar item: **Take it back**. Trailing: a `Menu` — "Gather the cards" (behind its
  confirmation), "A loose deal · draw one", "A loose deal · draw three", "Lay today's deal"
  (when yesterday's is still laid), "Cloth" (once claret is earned), and, once the deal is out,
  a `ShareLink`.
- The **desk's edge**: the 6 pt walnut band with its highlight, and the brass corner at the
  top-left of the cloth.
- The **head**, two columns so nothing wraps: at the left the caps `TODAY · MONDAY 12 OCTOBER`
  (or `LEDGER · NO. 52`) with the count under it — **118** at 34 pt in New York with `MOVES` in
  the caps beside it; at the right, ranged right, `DRAW ONE · GRADE 1` over `THE MARK 147`,
  and under that the run's caps: `CLEAN · 31 UP` in `success`, or `ONE TAKEN BACK · 31 UP` in
  `miss`. With the clock on, `4:12` in the monospaced caps joins the right column.
- The **top row**: the stock (a face-down card; a faint ring when empty), the waste (one card,
  or three fanned 14 pt apart at draw three), a gap of one card, and the **four foundations** —
  an empty one is a card-shaped outline at `cardStock.opacity(0.14)` with its suit's pip
  ghosted at the centre at `cardStock.opacity(0.18)`, spade · heart · club · diamond.
- The **tableau**: seven columns, 6 pt apart, each card `(width − 24 − 36) / 7` wide (about
  48 pt on a 393 pt phone, 54 on a 440) and 1.4 × as tall; face-down cards overlap by 8 pt and
  face-up by 28 % of the height, so a long column compresses toward 18 % as it grows. The run
  in the hand draws above everything with its shadow.
- The **foot**: the seed line `№ 285 · 2026-10-12 · 7C3A-19B2` typed small, and above it the
  clerk's most recent line in `inkSoft` at 15 pt italic, which changes on a take-back or a
  stuck moment and otherwise sits empty. Then the desk's edge again and the brass corner at the
  bottom-right.
- Once the deal is out, the foot becomes **the diary line** (see The reward) with the
  ending's two lines, "Send the card" and "Lay No. 52".

**Left-handed** (drawer): the top row mirrors — foundations left, waste and stock right — and
nothing else changes.

**What moves:** a run lifting, bending and landing; a card turning; the stock turning and
gathering; a tapped card flying; a take-back playing backwards; the ghost hand on a fresh deal;
the sweep and the fans. Nothing else.

**System controls:** `NavigationStack` and its toolbar, `Menu`, `ShareLink`, the confirmation
`alert`. The cloth and the cards are drawn: each card is a `CardFace` view positioned by the
table's layout, with a `DragGesture(minimumDistance: 4)` on face-up cards and a tap on every
card and pile, and every card an accessibility element with a label and the tap-to-play
fallback.

**Done state** (today's out, nothing laid): `fans.svg` small at the top of the cloth, **Today's
is in the diary** in New York, the next ledger deal's number at 76 pt — `No. 52` — with `DRAW
THREE · GRADE 4` in the caps, and "Lay No. 52".

**First launch:** the ledger's No. 1 with the ghost hand. See *The first deal*.

### 2. The diary — Diary (tab 2) · mock 4

**Its one job:** the days, and what each one asked for. This is the screen the first App Store
screenshot shows, per the spec's 4.3 note — the calendar and the seed, not a card table like
the other forty-six.

**Hero:** **entries** at 112 pt in New York Semibold in `ink`, sitting behind the top edge of
the page so the page overlaps its lower third.

Top to bottom:

- `NavigationStack`, large title `Diary`; trailing toolbar: the gear to Settings.
- The hero number with `ENTRIES` in the caps beside its foot.
- **The page**: card stock, radius 8, its running head — `October` at 40 pt in New York in
  card ink at the left, `2026` in the caps at the right — the rule under it, `M T W T F S S` in
  the caps, and the **grid**: a card slot per day (5 : 7, about 44 × 62 pt on a 393 pt phone,
  7 across with 6 pt gutters), drawn as a card outline at `cardInk.opacity(0.12)` with the day
  number small at its top-left in the caps. A day that came out carries **its buried card** —
  a small `CardFace` of the card the line had to dig for — with a brass underline if it was
  under the mark and a moss dot at its corner if it was clean. Today is ringed in brass. A day
  not played is the empty outline — no grey, no red, nothing. Under the grid, the **week's
  shape** in the caps: `MON DRAW ONE · 1   TUE · 2   WED · 3   THU DRAW THREE · 4   FRI · 6
  SAT · 8   SUN · 9`, wrapping to two lines, so the week is published on the page.
- The page's **hem**: `23 ENTRIES · 9 DAYS RUNNING · 14 CLEAN` in the caps along the ruled
  foot, and once the seal is earned, the seal at the hem's right.
- Swipe the page left or right for other months; a page turns on `Motion.gentle`. Past pages
  are free to read (they are her record); laying a past day's deal again is the drawer's.
- **Today** under the page: if today's is not out, `TODAY · MONDAY · DRAW ONE · GRADE 1` in the
  caps with "Lay today's deal" (or "Back to the table"); if it is, today's line — `OUT CLEAN ·
  118 MOVES · UNDER THE MARK BY 29 · THE SIX OF HEARTS`.
- "Lay a reminder" as a system `Toggle` with its hour, and `ShareLink` over `ShareImage.render`
  — "Send the page".
- Once `volume` is earned, a **shelf** above the page: twelve small pages of the first year in
  a row, each tappable.

**System:** `NavigationStack`, `ScrollView`, `TabView(.page)` for the months, `Toggle`,
`DatePicker` (hour), `ShareLink`.

### 3. The drawer — Drawer (tab 3)

**Its one job:** the things in the desk, and the whole count.

**Hero:** **the drawer** — a walnut panel (`surface`) the width of the screen less 16 pt, its
brass handle drawn at the top edge, pulled open to show its contents in rows. Not a `List` of
`Label`s.

- **Backs**: seven cards in a row (`Lattice · Brass lattice · Chevron · Houndstooth · Stars ·
  Leaf · Seal`), the chosen one lifted 6 pt with its shadow; a tap chooses it with
  `Haptics.selection()`. Each back is a small `Canvas` in `CardBack.swift`: *Lattice* the
  default; *Brass lattice* the earned one (also here, marked `EARNED AT 25` in the caps until
  it is); *Chevron* rows of 6 pt chevrons in the blue; *Houndstooth* a 10 pt houndstooth in
  card ink at 70 %; *Stars* a field of 3 pt four-point stars in brass on the blue; *Leaf* a
  single moss leaf outline at the centre with a hairline border; *Seal* the four pips in a ring
  in brass at the centre.
- **Cloths**: four swatches — blue, claret, moss, slate — each a 44 × 44 card of its canvas
  colour with its nap, the chosen one ringed in brass. Claret here is the earned one, marked
  `EARNED AT 10` until it is.
- **Left-handed table** as a system `Toggle`.
- **Past deals**: the archive — one row per past day, newest first, `12 OCTOBER · NO. 285 ·
  DRAW ONE` with its buried card at the left and its result in the caps, and "Lay it again".
- **The count** (the spec's lifetime stats): a ruled table on card stock — `laid · out · clean
  · under the mark` by draw, by grade and by shape — which is the same record `Mastery` reads.
- **Free tier:** the drawer drawn **shut**, the handle catching the lamp, `THE DRAWER` in the
  caps across its front, the line from *Empty states*, and "Open the drawer". Not a lock row
  and not a list of features.

**System:** `NavigationStack`, `ScrollView`, `Toggle`.

### 4. Settings (the gear on the Diary)

The kit's `SettingsView` under `.brand(AppBrand.brand)` and `.brandBackground()`, with
`upgradeTitle: "Open the drawer"` and `activeTitle: "The drawer is open"`, and an **On the
desk** section — `Entries`, `Days running`, `Clean` — then `SoundsToggle()`, "Lay a reminder"
with its hour, "Show the clock", "Four-colour suits", "Large pips", "Cloth" and "Back" as
`Picker`s (rows appear as they are earned or bought), and "Clear the desk" behind its
confirmation ("Clear the desk — every entry and every deal on this phone?"). Footers: free —
"Today's deal and the whole ledger. Every entry you have written stays in the diary.";
unlocked — "Everything you have played is on this phone and nowhere else."

The kit's restore, rate, share, support and privacy rows are unchanged.

### 5. The paywall · and 6. Onboarding · mock 3 shows onboarding page 1

Both the kit's, named in the clerk's voice as §Voice sets out, each with its art, the paywall
with `bulletStyle: .ruled(mark: "▮")` and `hero: Image("Drawer")`. Onboarding sets its title
in New York over the art, with `BAIZE` in the caps at the head of the screen between two
hairlines and a small card, and the page indicator drawn as the app's own mark: a small card
for the page you are on, an empty slot for each one you are not.

### The mocks

| Mock | Shows |
| --- | --- |
| `design/mock-1-play.html` | The table mid-deal: today's No. 285, draw one, nine up and clean, 41 moves against the mark 147, fifteen cards still face down, a seven-card run built on one column, a run of three cards lifted under the finger and bending, the target column's top card nudged with the drop ghost under it, three foundations started and the diamonds' outline waiting, the seed typed at the foot, the brass corners. |
| `design/mock-2-win.html` | The win at its peak, `clean` tier: the four fans bloomed and overlapped at the centre, pips frozen mid-fall, **118** at 96 pt with `MOVES` and `THE MARK 147`, "It came out clean" in salmon, the clerk's line, and the diary line with the month strip, today's slot being written, and both buttons above the tab bar. |
| `design/mock-3-first.html` | Onboarding page 1, the first thing a new user sees: the masthead, the desk drawn, "One deal a day", the card page indicator, "Turn over". |
| `design/mock-4-diary.html` | The Diary: entries at 112 pt, the October page with its buried cards, today ringed, the week's shape, the hem, today's line and "Send the page". This is the first App Store screenshot, per the spec's 4.3 note. |

All four are drawn by `design/cards.js`, which draws every card in the mocks and the art with
one geometry, so no mock contains a card the app would draw differently. `design/art.js` draws
the four art pieces and the icon from it, and `design/make-art.mjs` writes them to disk; mock 3
calls `Art.desk()` inline, so the onboarding mock and `art/desk.svg` are the same drawing.

### Captures

The critic sees motion through `qa.json`'s `moments`, so the app plays its own signature
interaction and its win on a launch flag. `-demo move` plays twelve moves of today's deal
along the dealer's line — three runs dragged, two cards turned, one card up — then one
take-back and the move again. `-demo win` plays the last four moves and the sweep. Both seed a
fixed record — ledger No. 51, twenty-three entries, nine days running, claret and the lattice
earned, today's deal part played — so every capture has a lived-in table rather than a
first-launch blank. `-rung 5|51|150|500` seeds the ledger for the ladder strip. The seed is
deterministic, which keeps the spec's promise that every deal is reproducible.

## Icon

**The concept:** the desk under the lamp with a run going home. The cloth, the light and the
cards — not a hand of four aces on green.

**The composition:** full-bleed Prussian blue baize with its nap, the **lamp's pool of light**
in the upper left as a warm radial that fades by the centre, a band of **walnut** along the
bottom edge and the right edge with a **brass corner** where they meet at the lower right —
the desk showing round the inset cloth. In the middle 70 %, **a run of three cards** —
the eight of spades, the seven of hearts, the six of clubs — fanned 9° apart and overlapping by
a third, lifted off the cloth with one soft shadow under them, the top card catching the lamp
along its upper edge: a run in the hand, mid-move. Their indexes are in New York Semibold, big
enough to read at 120 px; each face has its one centre pip. Nothing else: no diary, no
foundations, no text.

**The colours:** the baize `#34547A` → `#1E3650` toward the lower right; the lamp `#F3C37A`
at 55 % at the upper left fading to nothing by the centre; the walnut `#5E4432` with a
`#7A5A42` highlight on its inner edge; brass `#D9B35C` with `#A47E35` on its shadow side; the
cards `#F6EFE0` with `#1E2532` and `#B8372A`; the shadow `#0E1A2A` at 40 %.

Read at 120 px next to the leaders' icons: a deep blue square with a warm corner of light and
three cream cards fanned in it, next to MobilityWare's cards on green, Zynga's K · A · Q on
green, Solitaire.com's four aces on green, Disney's Stitch, the red spider and the cartoon dog.
The only blue one in the row, and the only one that is a picture of a table rather than a
hand of cards on a colour. No letter, no numeral, no glyph on a gradient. `design/icon.svg`,
rendered to `design/icon-1024.png`.

## Share card

1080 × 1350 through `ShareImage.render`. Two cards, one view in `ShareCard.swift`:

**The card** (from the win): the baize with its nap and the lamp's glow. On it, laid at 1.5°,
**a page** of card stock with `BAIZE` in the caps across its running head between two
hairlines and a small card, then `No. 285 · 12 OCTOBER · DRAW ONE · GRADE 1` in the caps. Under
that the **hero number** — moves — at 240 pt in New York Semibold in card ink, with `MOVES` in
the caps beside it and `THE MARK 147 · UNDER BY 29` under. Then **the buried card** drawn full
size at the centre — the six of hearts — with `THE ONE TO DIG FOR` in the caps under it, and
beside it the four kings fanned small. Under that, `CAME OUT CLEAN` in moss or `CAME OUT ·
THREE TAKEN BACK` in card ink, and `9 DAYS RUNNING`. At the foot, the seal once earned, and the
app's own mark: a small card between two short rules. Gilt edges on the page once earned. It
spoils nothing: the deal itself is never shown.

**The page** (from the diary): the month page exactly as the Diary draws it — the running head,
the grid with every day's buried card, the week's shape, the hem with the three counts — on the
baize, at 1.5°. A month of small cards is the picture; it is the one share in the category that
is not a score.

Text fallback: `Baize No. 285 · 12 October · came out clean in 118 moves, under the mark · 9
days running`.

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
            canvas: Color(light: 0x34547A, dark: 0x14243A),
            surface: Color(light: 0x5E4432, dark: 0x3A2A1F),
            ink: Color(light: 0xF4ECDC, dark: 0xEDE3CF),
            inkSoft: Color(light: 0xD2C8B2, dark: 0xA89F8B),
            accent: Color(light: 0xD9B35C, dark: 0xE2BD66),
            onAccent: Color(light: 0x241A10, dark: 0x1E150B),
            highlight: Color(light: 0xFBB9A9, dark: 0xF7A896),
            success: Color(light: 0xA6D6AD, dark: 0x95C9A0),
            miss: Color(light: 0xB7CADD, dark: 0x9DB1C7),
            extras: [
                Color(light: 0xF6EFE0, dark: 0xEFE7D6),   // card stock — every card's face, the page
                Color(hex: 0x1E2532),                     // card ink — indexes, spades, clubs, type on the page
                Color(hex: 0xB8372A),                     // pip red — hearts, diamonds
                Color(hex: 0x2F6B45),                     // pip green — clubs, four-colour suits
                Color(hex: 0x2B5C9B),                     // pip blue — diamonds, four-colour suits
                Color(light: 0xF3C37A, dark: 0xF0B964),   // lamp — the glow's centre, the seal
                Color(light: 0xA47E35, dark: 0x8F6D2C),   // brass deep — the shadow side of brass
            ]
        ),
        type: BrandType(display: .serif,
                        displayWidth: .standard,
                        displayWeight: .semibold,
                        body: .default),
        corner: 8,
        canvas: .glow(Color(light: 0x4B6E96, dark: 0x4A3F2E),
                      at: UnitPoint(x: 0.12, y: 0.02))
    )

    /// The card box by name, so no view indexes `extras` by number.
    enum CardBox {
        static let stock     = brand.palette.extras[0]
        static let ink       = brand.palette.extras[1]
        static let red       = brand.palette.extras[2]
        static let green     = brand.palette.extras[3]
        static let blue      = brand.palette.extras[4]
        static let lamp      = brand.palette.extras[5]
        static let brassDeep = brand.palette.extras[6]
    }

    /// The cloths. `brand` is blue; a chosen cloth swaps the canvas and the glow and nothing
    /// else. Each pair was checked against ink and inkSoft in both modes.
    enum Cloth: String, CaseIterable, Codable {
        case blue, claret, moss, slate

        var canvas: Color {
            switch self {
            case .blue:   return Color(light: 0x34547A, dark: 0x14243A)
            case .claret: return Color(light: 0x7A2E35, dark: 0x3C181D)
            case .moss:   return Color(light: 0x2F5A42, dark: 0x14291D)
            case .slate:  return Color(light: 0x4A5563, dark: 0x232A33)
            }
        }
        var glow: Color {
            switch self {
            case .blue:   return Color(light: 0x4B6E96, dark: 0x4A3F2E)
            case .claret: return Color(light: 0x95464D, dark: 0x5A3230)
            case .moss:   return Color(light: 0x45745A, dark: 0x3A4A30)
            case .slate:  return Color(light: 0x62707F, dark: 0x3E3E3E)
            }
        }
        var brand: Brand {
            var b = AppBrand.brand
            b.palette.canvas = canvas
            b.canvas = .glow(glow, at: UnitPoint(x: 0.12, y: 0.02))
            return b
        }
    }

    /// The lattice on the default back is the blue cloth's colour in both modes, so a back is
    /// a blue lattice under the lamp too.
    static let lattice = Color(hex: 0x34547A)
}
```

## Slop we are avoiding

1. **One accent on gray, with green and red for right and wrong the only other colour** — and
   this genre's own version of it, green felt with a `Score · Time · Moves` bar and a lightbulb.
   Baize has no score, no clock unless asked, no lightbulb, and no green unless she opens the
   drawer and asks for it. Right and wrong do not exist on a card table: there are cards, up or
   not yet, and the only colours on the cloth are the cards' own. Salmon, moss and slate live
   in the caps as words, never on a card.

2. **A win shown as a `.sheet` at `.medium` with a checkmark seal, and "Level cleared".**
   Baize's win is the table taking itself off — every card flying home in rank order up a scale
   you can hear, four fans blooming into one spread — ending with the diary line naming what is
   waiting: "Twenty-three entries in the diary. The brass lattice comes at twenty-five. Next in
   the ledger: No. 52, draw three, grade four." No sheet, no seal, and "come back tomorrow" is
   in none of the app's copy.

3. **Content chosen by `%` over a fixed array, and a ladder whose last rung arrives in the
   first week.** Every leader deals from a random shuffle and calls a third of them unwinnable;
   the ones with a "daily" show it as a month of gold stars that do nothing. Baize's pack is
   proved deal by deal and graded by a real ranking; the ledger climbs a `Ladder` that is still
   tightening at 150 and stops, honestly and stated, at 169; the next deal is picked by
   `Mastery` from the shape she is worst at; today's is keyed by the day number and never
   wraps; and what she is handed at 500 is the hardest ninth at draw three with a mark five
   percent over the machine's line, chosen against her record, which is not the game she was
   handed at 5.

Worth naming a fourth, because every leader ships it: **the hint button with a count.** Baize
has no hint. The table never says where a card goes; the only help is a ghost hand on the very
first deal, once, and a clerk who will tell you that a seven wants a black eight.

## Roads not taken

- **The card room on the night boat** — an ocean liner's card room in the small hours, deco
  cream and teal, brass portholes, a steward who lays the table and says "Next port, tomorrow."
  Warm and it would have shared well. Killed because the ship is a setting and not a mechanic
  — nothing about a liner changes what a deal is — and a route with ports is the level map the
  spec told us to skip.
- **Will it come out?** — the Victorian parlour where patience was an oracle: a question asked
  of the deck, velvet and a candle, and the answer written in a commonplace book. Strange and
  lovely, and "it came out" is the one word of it we kept. Killed because a fortune-telling
  frame makes a proved-winnable deal a lie — the answer is always yes — and because the person
  in §Who and when came for calm, not for omens.
