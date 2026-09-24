# Lacework · architecture

How DESIGN.md is put together. Read DESIGN.md first; this says where each of its promises
lives in code so the builder never has to decide the app's shape twice.

## Model

Everything is value types, `Codable`, and it all lives in **one file**: `record.json` in the
app's Application Support directory, written atomically after every change (debounced 100 ms
on the main actor, and once more on `scenePhase` leaving `.active`). No SwiftData. The spec
suggests SwiftData for solved boards; a thread is at most 196 bytes and five hundred pieces are
about 100 KB, a single Codable file survives an update with one integer, and Crosshatch shipped
this exact pattern through review. `@AppStorage` is used only for what the kit already keys
there: `factory.onboarded`, `factory.sounds`.

```swift
struct Record: Codable, Equatable {
    var schema = 1                          // bump on any breaking change; migrate in Record.load()
    var salt: UInt64                        // random at first launch; the book is seeded from (rung, salt)
    var rung = 1                            // position in the book. +1 per book pattern lifted. Never down.
    var loosePiecesWorked = 0               // the loose-work counter; seeds (loosePiecesWorked, salt)
    var pieces: [Piece] = []                // every lifted piece, oldest first
    var bestThread = 0                      // longest chain ever, any pattern — the `best` tier's bar
    var mastery = Mastery<Ground>()         // written on every lifted piece, read to pick the next ground
    var recentGrounds: [Ground] = []        // the last three book grounds, for `avoiding:`
    var thread: ThreadColour = .indigo      // .indigo | .rose | .gold — the workbox choice
    var cover: Cover = .linen               // .linen | .ticking
    var initials = ""                       // two letters, from 200 pieces
    var reminderHour: Int? = nil            // nil = not pinned; else 0…23
    var pillow: SavedPillow?                // the book or loose pattern in progress, if any
    var todayPillow: SavedPillow?           // today's pattern in progress, if any
    var todayDay = 0                        // dayNumber the daily pillow belongs to
    var tomorrow: Pricking?                 // tomorrow's pattern, pricked ahead when today's lifts
}

struct Piece: Codable, Equatable, Identifiable {
    var id: Int                             // 1-based, the order it was lifted
    var day: Int                            // Play.dayNumber
    var date: Date
    var kind: Kind                          // .today | .book(rung: Int) | .loose(n: Int)
    var side: Int
    var shape: Int
    var ground: Ground
    var pins: Int                           // cells on the pattern
    var path: [UInt8]                       // the thread, as cell indices row-major (side*side ≤ 196)
    var plaits: [Range<Int>]                // runs that were plaited, as index ranges into `path`
    var unpicks: Int
    var longestThread: Int
    var tier: Int                           // Run.Tier.rawValue
    var thread: ThreadColour
    var isClean: Bool { unpicks == 0 }
}

struct SavedPillow: Codable, Equatable {
    var pricking: Pricking
    var path: [UInt8]                       // pins taken so far, in order
    var plaits: [Range<Int>]
    var markers: [UInt8]                    // marking pins (≤ 3), once earned
    var run: Run                            // FactoryKit's; Codable, so tomorrow's pillow is the same run
    var started: Date
    var restarted: Bool                     // "Pull the pins" was used: no snips on the lift, mastery miss
}

struct Pricking: Codable, Equatable, Hashable {
    var side: Int                           // 5…14
    var open: [Bool]                        // side*side; false = a window (no pin, no card)
    var gimp: Set<Edge>                     // walls between neighbouring open cells
    var start: UInt8?                       // nil when loose ≥ 2
    var finish: UInt8?                      // nil when loose ≥ 1
    var ground: Ground
    var shape: Int
    var rung: Int
    var seed: UInt64
    var answer: [UInt8]                     // the one path. Never shown; used to prove, to demo, and to plait the lift
    var pins: Int { open.filter { $0 }.count }
}

struct Edge: Codable, Hashable { let a: UInt8; let b: UInt8 }   // normalised a < b

enum Ground: String, Codable, CaseIterable { case tulle, bar, rose, torchon, spider, fan, honeycomb, valenciennes }
enum ThreadColour: String, Codable { case indigo, rose, gold }
enum Cover: String, Codable { case linen, ticking }
```

`Record.load()` reads the file, checks `schema`, and migrates forward field by field (a
missing field takes its default via a custom `init(from:)` that uses `decodeIfPresent`). A
record that fails to decode is renamed `record.broken.json` and a fresh one started — never a
crash on launch, never a silent wipe.

Derived, never stored: `piecesWorked = pieces.count`, `daysRunning` (consecutive days with a
`.today` piece, counting back from today or yesterday), `largestSide`, the per-size and
per-ground ledger (a `Dictionary(grouping:)` over `pieces`), and `hasEarned(id)` via
`Play.earned.isUnlocked(id, at: pieces.count)`.

## The engine

Three pure files with no SwiftUI in them, so a test can drive them: `Pricking.swift` (above),
`Generator.swift`, `Solver.swift`. Everything is deterministic under a seed; the only random
source anywhere is `SplitMix64(seed:)` in `Generator.swift`, and `Record.salt` is the only
thing ever drawn from `SystemRandomNumberGenerator`.

### The one function

```swift
enum Generator {
    /// The pattern for a rung of the book, or a loose pattern, or today's.
    /// Same (dials, ground, seed) → same pattern, on every device, forever.
    static func pricking(side: Int, open: Int, shape: Int, loose: Int,
                         ground: Ground, seed: UInt64) -> Pricking
}
```

`Play.swift` is the only caller and passes `AppPlay.ladder.dials(at: rung)`:

```swift
enum Play {
    static let ladder = Ladder([
        .init("side",  from: 5,  by: 1, every: 12, opensAt: 1,  ceiling: 14),
        .init("open",  from: 40, by: 5, every: 7,  opensAt: 1,  ceiling: 100),
        .init("shape", from: 1,  by: 1, every: 45, opensAt: 30, ceiling: 4),
        .init("loose", from: 0,  by: 1, every: 90, opensAt: 41, ceiling: 2),
    ])
    static let dailyWeek = [6, 14, 26, 40, 58, 82, 120]          // Mon…Sun
    static let freePatterns = 60
    static let groundOpens: [Ground: Int] = [.tulle: 1, .bar: 1, .rose: 10, .torchon: 22,
                                             .spider: 36, .fan: 52, .honeycomb: 70, .valenciennes: 90]
    static func groundsOpen(at rung: Int) -> [Ground]              // in CaseIterable order
    static func bookPricking(rung: Int, record: Record) -> Pricking // ground from mastery, seed (rung, salt)
    static func loosePricking(n: Int, record: Record) -> Pricking   // ground from mastery, seed (n, salt ^ 0x1005E)
    static func todayPricking(day: Int) -> Pricking                 // rung from weekday, ground from day, seed = day
    static let earned = Earned([...])                               // DESIGN.md's seven milestones
    static func horizon(_ m: Earned.Milestone) -> String            // the shortened line for the ending
}
```

`bookPricking` is where `Mastery` is **read**: `record.mastery.next(from: groundsOpen(at:
rung), count: 1, unseenShare: 0.3, avoiding: Set(record.recentGrounds)).first ?? .tulle`.
`todayPricking` draws its ground with a seeded shuffle of the grounds open at that weekday's
rung, rejecting any ground used by the previous three days (computed the same way, so it is
shared). The daily's seed is `UInt64(day) &* 0x9E37_79B9_7F4A_7C15`, nothing personal in it.

**Test:** `EngineTests.swift` (an XCTest target `LaceworkTests` in `project.yml`, sources
`ios/Tests`) proves: the same inputs give byte-identical `Pricking`s twice; `pricking(rung: 5)`
and `pricking(rung: 150)` differ in `side`, `shape`, `loose` and `gimp.count / pins` (the
open ratio); every one of the next sixty dailies proves unique under budget; and Sunday's
daily (rung 120) generates in under 1.5 s on the simulator in Debug. That last one is the
timing gate the spec asks for, and it is the first thing to run once the engine compiles.

### Generating

1. **The mask.** From `side` and `shape`, via the ground's template:
   shape 1 the full square; 2 the corners clipped (`r + c < k`, and the three rotations, with
   `k = 2` under ten a side and `3` from ten); 3 one window — a 2×2 hole under ten a side, 3×3
   from ten — at the ground's place (Spider centre, Fan the far corner, Valenciennes and
   Honeycomb as DESIGN.md says, the rest seeded, never touching the border); 4 the ground's
   field of windows. Then the **parity check**: colour the mask like a chessboard; if the two
   counts differ by more than one, drop one window cell of the majority colour and re-check.
   Confirm the mask is connected (one flood fill). A mask that still fails is a template bug —
   assert in Debug, fall back to the square in Release.
2. **The answer.** A Hamiltonian path over the mask: randomised DFS with **Warnsdorff
   ordering** (try the neighbour with the fewest free neighbours first, ties broken by the
   seed), pruning any state whose free region is disconnected or has more than one dead end.
   Budget 200,000 nodes; on failure, re-seed (`seed &+ attempt`) and try again, at most six
   times. Then **backbite** it 3 × pins times for mixing (pick an end, pick one of its free
   grid neighbours already on the path, reverse the segment beyond it). Both ends of the result
   are `start` and `finish`; `loose` decides which are published.
3. **The gimp.** Every pair of neighbouring open cells not consecutive on the answer is a
   candidate wall. Order the candidates by the ground: Tulle a seeded shuffle; Bar with walls
   lying across a straight run of the answer sorted last; Rose the four walls of each 2×2 block
   first, blocks in seeded order; Torchon by distance from the nearest main diagonal; Spider by
   distance from the centre; Fan by distance from the seeded corner; Honeycomb the seeded
   shuffle restricted to a checker of candidates; Valenciennes by distance from the border.
   Start with every candidate laid. For the first `open` % of the order, remove the wall and
   ask the solver; keep it removed if the pattern is still **unique**, otherwise put it back.
4. **Publish.** `start`/`finish` per `loose`; the final solver run's result is cached as
   `answer` (the path found, which equals step 2's up to reversal).

### Proving

```swift
enum Solver {
    enum Verdict { case unique, multiple, none, unproved }
    /// Counts Hamiltonian paths through every open cell honouring the gimp, up to 2, from the
    /// given start (or every cell when nil) to the given finish (or any). A loose pattern is
    /// counted up to reversal. Stops at `budget` nodes and says so — never guesses.
    static func prove(_ p: Pricking, budget: Int) -> Verdict
}
```

Depth-first over cell indices with the visited set as four `UInt64`s. At every node: the
**free region** must be one connected component (flood fill on the bitset, cheap at ≤196
cells); no free cell may have zero free neighbours other than the head; at most one free cell
may have exactly one (and if `finish` is fixed it must be that one). Neighbour order is fixed
(up, right, down, left) so the count is deterministic. **Budget:** 12,000 nodes per proof
during gimp removal — a removal the solver cannot settle in that many nodes is simply not made,
which is what makes `open: 100` an honest ceiling — and 250,000 for the final publish proof and
for tests. The generator's worst case is therefore bounded (candidates × 12,000 nodes, about 2 M
at fourteen a side) and measured, not hoped for.

Where that measurement lands is the spec's timing gate. If Sunday's daily rules in under 1.5 s
on the simulator nothing more is needed. If it does not, do these in order, stopping when it
passes: (a) drop the per-removal budget to 8,000; (b) prick tomorrow's daily when today's is
lifted (`Record.tomorrow`, already in the model) and the next book pattern on lift, both off
the main actor, so the user never waits for the generator at all — the only cold generation
left is a first launch on a Sunday; (c) as a last resort, drop Sunday's rung to 96. Do not
bundle a JSON of patterns: the daily is derived from the date on every device so that it is
shared, and bundling would freeze it to a build.

## State and flow

**`Bench`** is the root `@MainActor final class Bench: ObservableObject` — one instance, made
in `Lacework.swift`, injected as `@EnvironmentObject`. It owns `record`, saves it, and is the
only thing that mutates it. Views call `bench.take(cell)`, `bench.unpick(to:)`,
`bench.cutBack(to:)`, `bench.pullPins()`, `bench.setMarker(cell)`, `bench.lift()`,
`bench.pinNext()`, `bench.workLoose()`, and read `bench.pillow` (a `PillowState` enum:
`.none`, `.winding(SavedPillow)`, `.lifting(SavedPillow, Piece, phase: Int)`, `.lifted(Piece)`).

**Which pillow.** `Bench.current: Which` is `.today` or `.book` or `.loose`. The Today tab
always shows `.today`; "Pin the next pattern" and "Work a loose pattern" switch it. Only one
book-or-loose pattern is in progress at a time (`record.pillow`), plus today's
(`record.todayPillow`).

**A session starts** when a pillow is shown with no `SavedPillow`: `Bench` generates the
pricking off the main actor (`Task.detached`), shows the pins arriving in a wave over 0.5 s as
they come (the pricking animation covers the generator's latency), and saves a `SavedPillow`
with an empty path and a fresh `Run()`.

**Taking a pin**: `CardView` turns the drag point into a cell (inner 64 % hysteresis), walks
Bresenham from the head to it, and calls `bench.take(cell)` per legal step; `take` appends,
`run.hit()`, detects a plait (a straight run of ≥ 4 that just turned), and saves. If the head
now has no bare neighbour and pins remain, `bench.deadEnd = true` for the tug. **Unpicking**:
entering the previous cell calls `bench.unpick(to: previous)`; a drag that *starts* on a thread
cell that is not the head calls `bench.cutBack(to:)`. Both call `run.miss()` once per gesture
(`Bench.gestureMissed` is reset on finger-up).

**The lift**: when `path.count == pricking.pins`, `bench.lift()` builds the `Piece`, computes
`tier = run.tier(score: run.longestChain, beating: record.bestThread)`, writes mastery
(`correct: unpicks ≤ 1`, `incorrect: unpicks ≥ 3 || restarted`, nothing at 2), appends the
piece, advances `rung` for a book pattern or `loosePiecesWorked` for loose, updates
`bestThread`, notes `Earned.justUnlocked`, pricks the next book pattern and (for today)
tomorrow's in the background, and steps `.lifting(phase:)` through DESIGN.md's timeline with a
`Task` that sleeps between phases. **Under `Motion.isStill` it jumps straight to the last
phase** so a capture shows the lace lifted, the pricks, the numeral and the margin card.
`.lifted` is what a re-opened, already-worked today's pattern shows.

**Relaunch mid-session:** `Record.load()` restores `pillow` / `todayPillow` with the thread as
it was, the bobbin lying at the head. **Day boundary:** on launch and on `scenePhase ==
.active`, if `Play.dayNumber(.now) != record.todayDay`, today's pillow is replaced: a finished
yesterday stays in `pieces`, an unfinished one is dropped (it was never lifted, so nothing was
earned and nothing is lost but its thread), `todayPillow = nil`, `todayDay = now`, and if
`record.tomorrow` matches the new day it becomes today's pricking without generating. **A month
away:** nothing happens. `daysRunning` is computed, not stored, so it simply reads one again
the day he works a piece; the book pattern in progress is still on the pillow.

**Pro gate.** `store.isPro || LaunchOptions.forcePro`. Free: today's pattern always, the book
through `Play.freePatterns` (60), no loose work, no ledger. "Pin the next pattern" at rung 61
without Pro shows the blank card and opens the paywall. Product id as SPEC.md says:
`com.factory.maze.pro`, one non-consumable, in `AppInfo.config.productIDs` and
`Products.storekit` both.

**Launch flags** (`LaunchOptions.swift`): `-onboarded`, `-reset`, `-sampleData` (rung 51,
nineteen pieces with real generated paths, twelve days running ending today, silk and pin
earned, today's pattern half wound along its answer), `-pro`, `-fakeProducts`,
`-screen pillow|sampler|book|workbox|paywall|win`, `-board today|book|loose`, `-fresh` (leave
the pattern unwound), `-rung N` (and `-level N` as its alias), `-thread rose|gold`,
`-demo wind|lift`, `-stillFrames` (the kit's). `-demo` is driven by `Bench.demo(_:)`, which
takes pins along `pricking.answer` on a timer — the same `take` the finger calls — including,
for `wind`, one deliberate wrong pin and its unpick.

## Files

Under `ios/App/`:

- `Lacework.swift` — `@main`; `Store`, `Bench`, the onboarding gate (`OnboardingView` with
  `nextTitle`, `finishTitle`, `indexMark: "●"`), `.brand(AppBrand.brand)`, `factoryReviewPrompt`.
- `AppBrand.swift` — DESIGN.md's Tokens block, verbatim.
- `AppInfo.swift` — `AppConfig` (name, URLs, `["com.factory.maze.pro"]`), the three onboarding
  pages with `art:` images, the paywall headline, subhead, bullets, promise, CTA.
- `LaunchOptions.swift` — the flags above.
- `Play.swift` — `Ladder`, `dailyWeek`, `freePatterns`, `groundOpens`, `Earned`, `horizon`,
  the three `*Pricking` functions, `dayNumber`.
- `Pricking.swift` — `Pricking`, `Edge`, `Ground` (with its display name and its candidate
  ordering and window template), `ThreadColour`, `Cover`, `SplitMix64`.
- `Generator.swift` — mask, Warnsdorff path, backbite, gimp removal.
- `Solver.swift` — `prove(_:budget:)`.
- `Record.swift` — `Record`, `Piece`, `SavedPillow`, load/save/migrate, the derived counts.
- `Bench.swift` — the root state, every mutation, the lift timeline, the day boundary, the
  prefetch, `demo`, `sampleData`.
- `Voice.swift` — every pool and line from DESIGN.md's Voice, `ending(for:)`, `headline(for:)`,
  a picker that never returns the same line twice running.
- `RootView.swift` — `TabView` (Pillow, Sampler, Book, Workbox), the paywall `.sheet`
  (`PaywallView` with `hero: Image("Book")`, `bulletStyle: .ruled(mark: "●")`).
- `PillowView.swift` — the Today screen: title, caps line, count, the pillow with `CardView`,
  the margin, the margin card, the toolbar `Menu`, the empty state.
- `CardView.swift` — one `Canvas` (parchment, windows, pricks, pins, gimp, thread, plaits,
  markers, the bobbin) + `DragGesture(minimumDistance: 0)` + the accessibility grid with
  tap-to-take. The thread is drawn from `ThreadPath`.
- `ThreadPath.swift` — `Path` for a thread through cells at a pitch: wraps on turns, outer
  passes on straights, a second dashed strand for plaits. Used by the card, the sampler's
  small laces, the swatch, the lift and the icon-like hero in the book.
- `LiftView.swift` — the win overlay: the tightening wave, pins out, the lift and shadow, the
  ghost `CountUp`, snips via `.confetti`, the headline, the margin card; phase-driven.
- `SamplerView.swift` — hero at 112, today's piece, the cloth (`LazyVGrid`, five across, each
  a small `Canvas`), the month card, the hem caps, the reminder `Toggle` and hour, the share.
- `PieceView.swift` — one piece full size on parchment with its ending line (pushed from the
  sampler and the book).
- `BookView.swift` — the stack of cards, the number at 76, the chapters, the cushion
  (`Earned`), the blank locked card, the ledger.
- `WorkboxView.swift` — `SettingsView` with the extra rows: the three counts, `SoundsToggle`,
  the reminder, thread and cover `Picker`s, initials, "Empty the workbox".
- `ShareCard.swift` — the swatch card for `ShareImage.render`, and the text fallback.
- `Reminder.swift` — `UNUserNotificationCenter`: request on toggle, schedule one daily
  notification with DESIGN.md's line, cancel on toggle off.
- `Assets.xcassets` — `AppIcon` from `design/icon-1024.png`; `Pillow`, `Bobbins`, `Lace`,
  `Book` imagesets from `design/art/*.svg` via `tools/design/art.mjs`.
- `PrivacyInfo.xcprivacy`, `Products.storekit` — the template's, with the product id changed.

Under `ios/Tests/`: `EngineTests.swift` (the four proofs above). `project.yml` gains a
`LaceworkTests` target of type `bundle.unit-test` depending on the app target.

Nothing in FactoryKit is copied into the app: `Ladder`, `Mastery`, `Run`, `Earned`, `Tones`,
`Haptics`, `Motion`, `CountUp`, `.confetti`, `ShareImage`, `OnboardingView`, `PaywallView`,
`SettingsView`, `Store` are all used from the package.

## Risks

1. **The solver's time at fourteen a side, fully open.** It is bounded by design (candidates ×
   12,000 nodes) but the bound may still be a couple of seconds on an old phone. The way
   through is already in the model: the timing test runs first; the next pattern and
   tomorrow's daily are pricked in the background on every lift; the pricking animation covers
   half a second; and the three fallbacks above are ordered. Never let the generator run on the
   main actor, and never show a spinner — the pins arriving in a wave *is* the loading state.

2. **The drag.** A fast finger skips cells, a slow one jitters on a boundary, and a finger that
   starts on the thread means "cut back" only if it starts there. The simplest way through:
   hysteresis (a cell is entered only inside its inner 64 %), a Bresenham walk from the head to
   the finger's cell taking each legal step in order and stopping at the first illegal one, and
   `gestureMissed` reset on finger-up so one backwards drag is one miss however far it goes.
   Prove it with `-demo wind`, which drives the same `take` and `unpick` the gesture does.

3. **The lift under capture.** A phase timeline of sleeps is invisible to `-stillFrames` unless
   it short-circuits. `Bench.lift()` must check `Motion.isStill` and set the final phase at
   once; `LiftView` must draw every element of the final phase from state, not from an
   in-flight animation — the lace risen 14 pt with its shadow, the pricks, the numeral at its
   final value, the headline, the card. The filmstrip of `-demo lift` is where the motion is
   judged; the still is where the composition is.

4. **Large text on the pillow.** The card is drawn at a fixed size from the screen width; the
   text around it scales. Cap the Pillow screen's `dynamicTypeSize` at `.accessibility2`, put
   the margin card's buttons in a bottom `safeAreaInset`, and let the caps line wrap to two
   lines rather than truncate. The sampler and the book scroll, so they need nothing.
