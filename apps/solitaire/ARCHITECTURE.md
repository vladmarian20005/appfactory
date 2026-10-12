# Baize · architecture

How DESIGN.md is put together. Read DESIGN.md first; this says where each of its promises
lives in code so the builder never has to decide the app's shape twice.

Bundle id `com.starhiveconcept.solitaire`, product id `com.starhiveconcept.solitaire.unlock`
(one non-consumable, SPEC.md), scheme `Baize`, display name `Baize`, category
`public.app-category.card-games`. No network code anywhere — no `URLSession`, no
`import Network` — which is a thing the compliance gate can grep for and the spec's wedge.

## Model

Everything is value types, `Codable`, and it all lives in **one file**: `record.json` in the
app's Application Support directory, written atomically after every change (debounced 100 ms
on the main actor, and once more on `scenePhase` leaving `.active`). No SwiftData. The spec
suggests SwiftData for per-deal results; an entry is under 120 bytes, a thousand entries are
about 100 KB, a single Codable file survives an update with one integer, and Lacework shipped
this exact pattern through review. `@AppStorage` is used only for what the kit already keys
there: `factory.onboarded`, `factory.sounds`.

```swift
struct Record: Codable, Equatable {
    var schema = 1                            // bump on any breaking change; migrate in Record.load()
    var rung = 1                              // position in the ledger. +1 per ledger deal out. Never down.
    var looseLaid = 0                         // loose deals laid, for their seed order
    var entries: [Entry] = []                 // every deal that came out, oldest first
    var bestMargin: Int? = nil                // widest margin under the mark, as a percent — the `best` tier's bar
    var mastery = Mastery<Shape>()            // written on every deal out or gathered, read to pick the next shape
    var recentShapes: [Shape] = []            // the last two ledger shapes, for `avoiding:`
    var played: Set<String> = []              // deal ids ever laid as ledger or loose, so nothing comes round
    var cloth: Cloth = .blue                  // .blue | .claret | .moss | .slate
    var back: Back = .lattice                 // .lattice | .brassLattice | .chevron | .houndstooth | .stars | .leaf | .seal
    var leftHanded = false                    // drawer
    var fourColour = false                    // free
    var largePips = false                     // free
    var showClock = false                     // free; the clock is off unless asked
    var reminderHour: Int? = nil              // nil = not laid; else 0…23
    var table: SavedTable?                    // the ledger, loose or again deal in progress, if any
    var todayTable: SavedTable?               // today's (or yesterday's, still laid), if any
}

struct Entry: Codable, Equatable, Identifiable {
    var id: Int                               // 1-based, the order it came out
    var day: Int                              // Play.dayNumber of the day it was *dealt*
    var date: Date
    var kind: Kind                            // .today | .ledger(n) | .loose | .again(day)
    var dealID: String                        // the pack's id, printed on the table
    var draw: Int                             // 1 | 3
    var grade: Int                            // 1…9
    var shape: Shape
    var moves: Int                            // her count, the sweep included
    var line: Int                             // the dealer's line
    var mark: Int                             // line × (140 − tight) / 100, rounded
    var takenBack: Int
    var longestChain: Int
    var tier: Int                             // Run.Tier.rawValue
    var seconds: Int                          // elapsed while the table was on screen
    var buried: Card                          // the face-down card the line turned last
    var isClean: Bool { takenBack == 0 }
    var underMark: Bool { moves <= mark }
    var margin: Int { Int((Double(mark - moves) / Double(mark) * 100).rounded(.down)) }
}

enum Kind: Codable, Equatable { case today, ledger(Int), loose, again(day: Int) }

struct SavedTable: Codable, Equatable {
    var dealID: String
    var kind: Kind
    var day: Int                              // the day it was dealt (today's: the daily's day)
    var draw: Int
    var grade: Int
    var tight: Int
    var moves: [Move]                         // the whole history; the state is replayed from the deal
    var run: Run                              // FactoryKit's; Codable, so a relaunch keeps the chain
    var started: Date
    var seconds: Int                          // accumulated while active
    var gathered: Bool                        // "Gather the cards" was used: no pips on the win, a mastery miss
}

struct Card: Hashable, Codable { let code: UInt8 }          // 0…51: suit * 13 + (rank − 1)
extension Card {
    var suit: Suit { Suit(rawValue: Int(code) / 13)! }      // spade, heart, club, diamond
    var rank: Int { Int(code) % 13 + 1 }                    // ace = 1 … king = 13
    var isRed: Bool { suit == .heart || suit == .diamond }
}
enum Suit: Int, Codable, CaseIterable { case spade, heart, club, diamond }
enum Shape: String, Codable, CaseIterable { case buried, stock, kings, passes, even }
enum Cloth: String, Codable, CaseIterable { case blue, claret, moss, slate }   // AppBrand.Cloth
enum Back: String, Codable, CaseIterable { case lattice, brassLattice, chevron, houndstooth, stars, leaf, seal }
```

`Record.load()` reads the file, checks `schema`, and migrates forward field by field (a
missing field takes its default via a custom `init(from:)` that uses `decodeIfPresent`). A
record that fails to decode is renamed `record.broken.json` and a fresh one started — never a
crash on launch, never a silent wipe.

Derived, never stored: `entries.count`, `daysRunning` (consecutive days with a `.today` entry,
counting back from today or yesterday), `clean` (entries with `takenBack == 0`), the count in
the drawer (a `Dictionary(grouping:)` over `entries` by draw, grade and shape), and
`hasEarned(id)` via `Play.earned.isUnlocked(id, at: entries.count)`.

## The engine

Four pure files with no SwiftUI in them, so a test can drive them: `Card.swift`, `Deal.swift`,
`Table.swift`, `Pack.swift`, plus `Play.swift` which is the only thing that reads the ladder.
Everything is deterministic under a seed; the only random source anywhere is
`SplitMix64(seed:)` in `Deal.swift`, and nothing in the app draws from
`SystemRandomNumberGenerator`. The phone never searches: every deal it lays was proved by the
build, and the app only reshuffles from a seed and replays.

### The deal

```swift
enum Deal {
    /// The 52 cards in the order they are dealt, from a seed. Same seed → same order, on every
    /// device and in `pack.mjs`, forever. Fisher–Yates from the end over 0…51 with SplitMix64:
    /// for i in stride(from: 51, through: 1, by: -1) { j = Int(rng.unit() * Double(i + 1)); swap(i, j) }.
    static func cards(seed: UInt64) -> [Card]
    /// The laid table: columns 0…6 take 1…7 cards dealt row by row (column c gets a card on every
    /// row r ≤ c), the last card of each face up; the remaining 24 are the stock, top last.
    static func table(seed: UInt64, draw: Int) -> Table
}
```

`SplitMix64` is the one in FactoryKit's `Celebration.swift`, copied in name and constants —
`state &+= 0x9E37_79B9_7F4A_7C15`, the two mixes, `unit() = Double(next() >> 11) / 2^53` — and
`pack.mjs` implements the same with `BigInt`, so a seed means the same deal in both. The
builder's first test is that the pack's first daily, regenerated from its seed, matches the
pack's stored layout hash.

### The table

```swift
struct Table: Codable, Equatable {
    var draw: Int
    var stock: [Card]           // top is last
    var waste: [Card]           // top is last
    var foundations: [[Card]]   // 4, in Suit order; top is last
    var columns: [[Card]]       // 7; the first card is the deepest
    var faceDown: [Int]         // per column: how many at the start of the array are face down
    var passes = 0              // recycles so far

    enum Move: Codable, Equatable, Hashable {
        case turn                                   // stock → waste (1 or 3); or gather the waste back when the stock is empty
        case wasteUp                                // waste → foundation
        case wasteDown(col: Int)                    // waste → column
        case up(col: Int)                           // column top → foundation
        case run(from: Int, index: Int, to: Int)    // column from its index on → column
        case down(suit: Int, col: Int)              // foundation top → column
    }

    func isLegal(_ m: Move) -> Bool
    var legalMoves: [Move]                          // in the order above; runs by from-column, then index, then to
    /// Applies a legal move. If a column's top becomes face down it turns face up in the same
    /// step and `turned` is set, so the view can play the turn 80 ms after the landing.
    mutating func apply(_ m: Move) -> (turned: Card?, gathered: Bool)
    var allFaceUp: Bool { faceDown.allSatisfy { $0 == 0 } }
    var isOut: Bool { foundations.allSatisfy { $0.count == 13 } }
    /// Every card to its foundation in rank order, aces first then twos; stock and waste as they
    /// come up. Only meaningful when `allFaceUp`. This is the sweep.
    func sweepMoves() -> [Move]
    static func replay(_ deal: Table, _ moves: [Move]) -> Table
}
```

Rules are standard Klondike: a run moves onto a card one rank higher of the other colour, or
any run headed by a king onto an empty column; a card goes up onto its suit's next rank; a
foundation's top may come back down; draw one or three; unlimited passes. `turn` with an empty
stock gathers the waste back face down in order and increments `passes`. **Undo is replay:**
`SavedTable.moves` is the whole history, the state is `Table.replay(deal, moves)`, and taking
back is `moves.removeLast()` then replay — fifty-two cards and a few hundred moves is
microseconds, there is no undo bookkeeping to get wrong, and a relaunch restores the exact
table the same way. The view never holds table state of its own.

### The pack

```swift
struct Pack: Codable {
    let engine: Int                               // 1; a deal from another engine is never laid
    let epoch: String                             // "2026-10-19", the Monday day 0 is
    let dailies: [String: PackDeal]               // keyed by day number as a string: "0", "1", …
    let pool: [PackDeal]                          // shuffled once at build; "first in pack order" means this order
}
struct PackDeal: Codable {
    let id: String                                // 8 hex chars of the seed, printed on the table
    let seed: UInt64
    let draw: Int                                 // the draw it was proved at
    let grade: Int                                // 1…9, within its draw's pool
    let shape: Shape
    let line: [Table.Move]                        // the dealer's line, pruned; its count is the line
    let buried: Card                              // the face-down card the line turns last
    let hash: String                              // the laid table's layout hash, for the seed test
}
```

`Pack.load()` decodes `deals.json` from the bundle once, on a background task at launch, and
publishes; the first screen does not need it until a deal is laid, and laying waits for it
(the deal animation covers the wait on a slow device). About 2–3 MB; if it is over 4 MB,
gzip it in the build and inflate with `Compression` — do not shrink the pool.

### The one function

```swift
enum Play {
    static let ladder = Ladder([
        .init("grade", from: 1, by: 1, every: 14, opensAt: 1, ceiling: 9),
        .init("draw",  from: 1, by: 2, every: 39, opensAt: 1, ceiling: 3),
        .init("tight", from: 0, by: 5, every: 24, opensAt: 1, ceiling: 35),
    ])
    static let dailyWeek = [4, 18, 32, 46, 74, 102, 150]              // Mon…Sun
    static let epoch = DateComponents(year: 2026, month: 10, day: 19)  // Monday; day 0
    static func dayNumber(_ date: Date = .now) -> Int                  // calendar days since epoch, local time
    static func mark(line: Int, tight: Int) -> Int { Int((Double(line) * Double(140 - tight) / 100).rounded()) }

    /// The next deal in the ledger for `rung`, chosen by Mastery from what the record says, never
    /// one already played. Same record → same deal.
    static func ledgerDeal(rung: Int, record: Record, pack: Pack) -> PackDeal
    /// A loose deal at the current rung's grade and the asked-for draw, by the same rule.
    static func looseDeal(draw: Int, record: Record, pack: Pack) -> PackDeal
    /// Today's: the pack's daily for the day, or the stated fallback past the pack.
    static func todayDeal(day: Int, pack: Pack) -> PackDeal
    static func dailyRung(day: Int) -> Int       // dailyWeek[weekday], Monday = 0

    static let earned = Earned([...])            // DESIGN.md's six milestones
    static func horizon(_ m: Earned.Milestone) -> String   // the shortened line for the ending
}
```

`ledgerDeal` is where `Mastery` is **read**:

```swift
let dials = ladder.dials(at: rung)                       // ["grade": g, "draw": d, "tight": t]
let shape = record.mastery.next(from: Shape.allCases, count: 1, unseenShare: 0.3,
                                avoiding: Set(record.recentShapes)).first ?? .even
let order = Shape.allCases.sorted { record.mastery.strength(of: $0) < record.mastery.strength(of: $1) }
for s in [shape] + order where … {                        // chosen shape first, then weakest first
    if let d = pack.pool.first(where: { $0.draw == dials["draw"] && $0.grade == dials["grade"]
                                        && $0.shape == s && !record.played.contains($0.id) }) { return d }
}
// then the nearest grade, same draw, any shape; then the other draw. Never nil while the pool has
// an unplayed deal; when it has none, `secondPass` (below).
```

`todayDeal` is `pack.dailies[String(day)]`. **Past the packed dailies** — only reachable if no
update ships for over fourteen months — the daily is the first pool deal at the weekday's
draw and grade whose seed's low bits match the day under a fixed multiplier, which is
deterministic, shared by everyone, and stated here rather than hidden. **Past the pool** (the
ledger at a few thousand deals): the pool is walked again in a new order seeded from
`rung`, and the ending says so once: "The ledger has been through the whole pack once. The
second pass starts here." A Klondike deal played two thousand deals ago is not a repeat anyone
can feel, and saying it beats pretending.

**Test:** `EngineTests.swift` (an XCTest target `BaizeTests` in `project.yml`, sources
`ios/Tests`) proves: the same seed gives byte-identical tables twice; every daily in the pack,
regenerated from its seed, matches its `hash` and **replays its line to `isOut`**; every pool
deal replays its line to `isOut` (incremental `apply`, a few seconds for the whole pack);
`ledgerDeal(rung: 5)` and `ledgerDeal(rung: 150)` differ in `draw`, `grade`, `tight` and `id`
for the same fresh record; `Play.ladder.climbs(through: 150)`; and `sweepMoves()` from an
all-face-up table reaches `isOut`. The replay tests are the proof the spec asks for — every
deal the app can lay is shown, on the device's own engine, to come out.

### The pack tool

`apps/solitaire/tools/pack.mjs` — node, no dependencies, run by the builder once and whenever
the pool is grown; `deals.json` is **committed** to `ios/App/` so CI never depends on the
search. It is the whole of the spec's "content is generated by the build":

1. **Deal** from a seed with the same SplitMix64 and Fisher–Yates as `Deal.swift` (BigInt
   arithmetic for the 64-bit state). Seeds for the pool come from `SplitMix64(0xBA1ZE…)`; for
   the dailies from `SplitMix64(day × 0x9E37_79B9_7F4A_7C15)`, so a day's seed is a pure
   function of the day.
2. **Prove** at the draw it will be served at: best-first search over `Table` states —
   priority: cards up × 8 + face-up cards × 2 − passes × 4 — with a transposition set keyed by
   a canonical string (columns sorted when empty, stock and waste as one sequence with a
   cursor), the standard Klondike prunings (a safe card goes up at once: rank ≤ the lower of
   the two opposite-colour foundations + 2; never move a king-headed run between empty
   columns; never reverse the previous move), and a budget of 400,000 states. Unproved in
   budget means *not used*, never "unwinnable".
3. **Shorten the line**: greedy pruning — try dropping each move in turn, keep the drop if the
   remainder still replays to a win, repeat until no drop holds — then record `line`, the
   `buried` card (the face-down card turned last), and the `shape` by DESIGN.md's rules in
   its order.
4. **Grade** within each draw's pool: rank by search effort, by the deepest ace's cover, by the
   passes the line needs and by the line's length; composite = 0.45 · effort + 0.25 · cover +
   0.15 · passes + 0.15 · length over the ranks; cut into nine equal parts.
5. **Assign the dailies**: for day 0…449, the weekday's rung → `dials` → the first proved
   daily-stream deal at that draw and grade (the stream is searched in order until one proves
   and grades right; a daily never comes from the pool).
6. **Shuffle the pool** once with `SplitMix64(1)` and write `deals.json` with the engine
   number and the epoch. Print the count by draw × grade × shape so the builder can see the
   coverage.

Targets: **450 dailies** (through 11 January 2028), **600 at draw one, 1,800 at draw three** in
the pool. If the search falls short in the time the builder has: raise the budget to 1,000,000
for the shortfall; then accept a smaller pool with **no cell under 8** (draw × grade × shape);
and only then use the construction fallback — deal backwards from a solved table by legal
reverse moves (foundation → column, column → column, column → waste) until the layout is
1…7 cards a column and 24 in the stock, then prove it forward like any other deal, which it
will, quickly, because it was built to. Whatever the final counts, write them in STATUS.md.

## State and flow

**`Desk`** is the root `@MainActor final class Desk: ObservableObject` — one instance, made in
`Baize.swift`, injected as `@EnvironmentObject`. It owns `record` and `pack`, saves the record,
and is the only thing that mutates it. Views call `desk.lay(.today)`, `.lay(.ledger)`,
`.lay(.loose(draw:))`, `.lay(.again(day:))`, `desk.play(move)`, `desk.turn()`,
`desk.tap(card)`, `desk.drop(run:on:)`, `desk.takeBack()`, `desk.gather()`, and read
`desk.laid` (a `TableState` enum: `.none`, `.laid(SavedTable, Table)`, `.sweeping(SavedTable,
Table, phase: Int)`, `.out(Entry)`).

**Which table.** `Desk.current: Which` is `.today` or `.other`. The Table tab shows `.today`
when today's (or yesterday's still laid) exists and nothing else is laid; "Lay No. 52" and the
loose deals switch it to `.other`. Only one ledger-or-loose-or-again table is in progress at a
time (`record.table`), plus today's (`record.todayTable`).

**A session starts** on `lay`: `Desk` looks up the `PackDeal`, builds `Deal.table(seed:draw:)`,
saves a `SavedTable` with no moves and a fresh `Run()`, and the view **lays the cards**: the
28 tableau cards fly from the stock's place to their columns row by row, 30 ms apart over
0.9 s on `Motion.snappy`, face-down ones turning as they land, which covers the pack's decode
on a cold launch. The `played` set takes the id for ledger and loose deals.

**Playing**: the view works out the move — a drag's drop target, a tap's best place (foundation
first, else the legal column with the most cards), the stock — and calls `desk.play(move)`,
which appends it to `moves`, applies it to the current `Table`, calls `run.hit()` for a card
up, and saves. **Taking back** pops the last move, replays, calls `run.miss()` once per tap or
once per hold, and saves. **Gathering** clears `moves`, sets `gathered`, records a mastery
miss for the shape (once per deal), keeps the same deal laid.

**The sweep**: after any `play`, if `table.allFaceUp && !table.isOut`, `desk.sweep()` computes
`sweepMoves()`, appends them all to `moves` at once (so the record and the move count are
complete and honest — the sweep's moves are moves), and steps `.sweeping(phase:)` through
DESIGN.md's timeline with a `Task` that sleeps between phases, the view drawing each phase
from state. **Under `Motion.isStill` it jumps straight to the final phase** so a capture shows
the fans, the count, the headline and the diary line. At the last phase `desk.write()` builds
the `Entry` — `mark = Play.mark(line:tight:)`, `tier = run.tier(score: entry.margin, beating:
record.bestMargin ?? Int.min)`, mastery `correct: takenBack ≤ 2`, `incorrect: takenBack ≥ 6 ||
gathered`, nothing at 3…5 — appends it, advances `rung` for a ledger deal or `looseLaid` for
loose, updates `bestMargin`, notes `Earned.justUnlocked`, clears the table, and the state is
`.out(entry)`, which is also what a re-opened, already-out today's deal shows.

**Relaunch mid-session:** `Record.load()` restores `table` / `todayTable` by replay, the run
intact, the clock paused. **Day boundary:** on launch and on `scenePhase == .active`, if
`Play.dayNumber(.now) != todayTable?.day`, nothing is gathered: a finished yesterday is already
in `entries`, an unfinished one stays laid with its head reading `YESTERDAY'S · STILL LAID`
and the menu offering "Lay today's deal", which gathers it (a mastery miss, nothing else lost).
The Diary's Today block shows today's as not yet laid. **A month away:** nothing happens.
`daysRunning` is computed, not stored, so it simply reads one again the day she plays today's;
the ledger deal in progress is still on the table.

**Pro gate.** `store.isPro || LaunchOptions.forcePro`. Free: today's deal always, the whole
ledger, loose deals, the diary and all its pages, the reminder, the share, sounds, the clock,
four-colour suits, large pips, every earned thing. The drawer: the backs beyond lattice and the
earned brass lattice, the cloths beyond blue and the earned claret, the left-handed table,
"Lay it again" on a past day, and the count. Tapping the shut drawer opens the paywall. Product
id as SPEC.md says, in `AppInfo.config.productIDs` and `Products.storekit` both.

**Launch flags** (`LaunchOptions.swift`): `-onboarded`, `-reset`, `-sampleData` (ledger No. 51,
twenty-three entries with real pack deals and real lines, nine days running ending today,
claret and the lattice earned, today's deal played twelve moves along its line), `-pro`,
`-fakeProducts`, `-screen table|diary|drawer|settings|paywall|win`, `-board today|ledger|loose`,
`-fresh` (leave the deal unplayed), `-rung N` (and `-level N` as its alias), `-played N`
(N moves along the line), `-won` (the final phase of the win), `-done` (today's out, the
Table's done state), `-cloth claret|moss|slate`, `-demo move|win`, `-stillFrames` (the kit's).
`-demo` is driven by `Desk.demo(_:)`, which plays moves from the deal's `line` on a timer —
the same `play` the finger calls — including, for `move`, one take-back and the move again.

## Files

Under `ios/App/`:

- `Baize.swift` — `@main`; `Store`, `Desk`, the onboarding gate (`OnboardingView` with
  `nextTitle`, `finishTitle`, `indexMark: "▮"`), `.brand(desk.brand)` (the chosen cloth's
  brand), `factoryReviewPrompt`.
- `AppBrand.swift` — DESIGN.md's Tokens block, verbatim.
- `AppInfo.swift` — `AppConfig` (name, URLs, `["com.starhiveconcept.solitaire.unlock"]`), the
  three onboarding pages with `art:` images, the paywall headline, subhead, bullets, promise,
  CTA.
- `LaunchOptions.swift` — the flags above.
- `Play.swift` — `Ladder`, `dailyWeek`, `epoch`, `dayNumber`, `mark`, `Earned`, `horizon`, the
  three `*Deal` functions, `secondPass`.
- `Card.swift` — `Card`, `Suit`, `Shape`, `Back`, display names ("the six of hearts").
- `Deal.swift` — `SplitMix64`, `Deal.cards`, `Deal.table`, the layout hash.
- `Table.swift` — `Table`, `Move`, rules, `apply`, `legalMoves`, `sweepMoves`, `replay`,
  the best place for a tapped card.
- `Pack.swift` — `Pack`, `PackDeal`, `load()`, the move encoding shared with `pack.mjs`.
- `Record.swift` — `Record`, `Entry`, `SavedTable`, `Kind`, load/save/migrate, the derived
  counts.
- `Desk.swift` — the root state, every mutation, the sweep timeline, the day boundary, `demo`,
  `sampleData`, the clock.
- `Voice.swift` — every pool and line from DESIGN.md's Voice, `ending(for:)`,
  `headline(for:)`, the substitutions (the buried card, the margin, the ranks), a picker that
  never returns the same line twice running.
- `RootView.swift` — `TabView` (Table, Diary, Drawer), the Settings push, the paywall `.sheet`
  (`PaywallView` with `hero: Image("Drawer")`, `bulletStyle: .ruled(mark: "▮")`).
- `TableView.swift` — the Table tab: title, toolbar (take it back, the menu), the desk's edge
  and corners, the head, the foot with the seed and the clerk's line, the done state, and
  `TableLayout` — the function from a `Table` to the position, size and z of every card.
- `CardsView.swift` — the 52 card views, each a `CardFace` positioned by `TableLayout` and
  animated by `withMotion` on state change; the `DragGesture(minimumDistance: 4)` and taps;
  the lifted run drawn above everything; the target nudge and ghost; the ghost hand on a
  fresh deal; the accessibility elements for every card and pile.
- `CardFace.swift` — one card: stock, rule, indexes, centre pip or court emblem, the back
  (`CardBack`), the gilt edge, large pips, four colours. Used at every size by every screen.
- `Pips.swift` — the four suit `Path`s, the three court emblems, the lamp's seal.
- `CardBack.swift` — the seven backs as `Canvas` patterns.
- `WinView.swift` — the win overlay: the fans, the pips via `.confetti`, the `CountUp`, the
  headline, the clerk's line, the diary line with the month strip; phase-driven.
- `DiaryView.swift` — hero at 112, the page (`MonthPage`), the months as a `TabView(.page)`,
  the hem, the shelf, today's block, the reminder `Toggle` and hour, the share.
- `MonthPage.swift` — one month on card stock: running head, the grid of slots with buried
  cards, today's ring, the week's shape, the hem. Reused at fixed size by the share card.
- `DrawerView.swift` — the drawer open (backs, cloths, left-handed, past deals, the count) and
  shut (free).
- `SettingsScreen.swift` — `SettingsView` with the extra rows: the three counts,
  `SoundsToggle`, the reminder, the clock, four-colour, large pips, cloth and back `Picker`s,
  "Clear the desk".
- `ShareCard.swift` — the card and the page for `ShareImage.render`, and the text fallback.
- `Reminder.swift` — `UNUserNotificationCenter`: request on toggle, schedule one daily
  notification with DESIGN.md's line, cancel on toggle off.
- `Nap.swift` — the cloth's nap: one seeded `Canvas`, drawn once under every screen above
  `.brandBackground()`.
- `deals.json` — the pack, written by `tools/pack.mjs`, committed.
- `Assets.xcassets` — `AppIcon` from `design/icon-1024.png`; `Desk`, `Fans`, `Diary`, `Drawer`
  imagesets from `design/art/*.svg` via `tools/design/art.mjs`.
- `PrivacyInfo.xcprivacy`, `Products.storekit` — the template's, with the product id changed.

Under `ios/Tests/`: `EngineTests.swift` (the proofs above). `project.yml` gains a `BaizeTests`
target of type `bundle.unit-test` depending on the app target.

Under `apps/solitaire/tools/`: `pack.mjs` (the search, the grading, the dailies), with
`klondike.mjs` (the rules, shared with nothing in Swift but tested against it by the replay
test). Under `apps/solitaire/design/`: `cards.js` (the card, drawn once), `art.js` (the four
art pieces and the icon, drawn from it), `make-art.mjs` (writes them), the mocks, the icon and
the art. `CardFace.swift` and `Pips.swift` reproduce `cards.js`'s geometry and paths; when a
proportion is in doubt, `cards.js` is the reference.

Nothing in FactoryKit is copied into the app: `Ladder`, `Mastery`, `Run`, `Earned`, `Tones`,
`Haptics`, `Motion`, `CountUp`, `.confetti`, `ShareImage`, `OnboardingView`, `PaywallView`,
`SettingsView`, `Store` are all used from the package.

## Risks

1. **The drag.** Fifty-two views whose positions are a pure function of state is the whole
   trick: a move changes state, every card animates to its new place, and the only exception
   is the run in the hand, which draws at the finger's offset until it is dropped and then
   snaps to its state position. Do not animate cards imperatively. Hit-test the drop by the
   run's top card's centre against column frames (the full column height, so a drop below a
   short column still lands); a drop outside every legal frame is a no-op and the run goes
   home. Prove it with `-demo move`, which drives the same `play` the gesture does.

2. **The pack tool's throughput.** A JavaScript best-first Klondike search proves most draw-one
   deals in well under a second and most draw-three deals in a few seconds; the grade-9 end
   of the pool is where the budget bites. Run it in the background while building the views,
   with a `--limit` flag so a thousand-deal first pass lands early, and grow the pool after.
   The fallbacks are ordered above; never bundle an unproved deal, and never let the app search.

3. **The sweep under capture.** A phase timeline of sleeps is invisible to `-stillFrames`
   unless it short-circuits. `Desk.sweep()` must check `Motion.isStill` and set the final phase
   at once; `WinView` must draw every element of the final phase from state, not from an
   in-flight animation — the four fans spread at the centre, the count at its final value, the
   headline, the diary line with today's slot written. The filmstrip of `-demo win` is where
   the motion is judged; the still is where the composition is.

4. **Large text on the table.** The cards are sized from the screen width; the text around
   them scales. Cap the Table screen's `dynamicTypeSize` at `.accessibility2`, let the head's
   two columns stack when the caps would wrap, keep the foot's seed on one line by letting it
   truncate in the middle, and put the diary line's buttons in a bottom `safeAreaInset`. The
   Diary and the drawer scroll, so they need nothing; the page's slots keep their size and
   the day numbers inside them use `.caption2` with `minimumScaleFactor(0.7)`.

5. **Yesterday's still laid.** Two tables can exist across a day boundary, and the Diary's
   Today block has to say the right thing for each: today's not laid (button "Lay today's
   deal", which gathers yesterday's behind a confirmation if one is laid), today's laid and
   part played ("Back to the table"), today's out (the line). Keep it one computed
   `TodayState` enum in `Desk` that every view reads, decided in one place.
