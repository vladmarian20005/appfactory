import FactoryKit
import Foundation

/// Which puzzle a board came from.
enum LevelID: Equatable, Hashable, Codable, Sendable {
    case numbered(Int)
    /// A day key, `yyyy-MM-dd`. The seed is the date, so the board is the same for everyone.
    case daily(String)

    var isDaily: Bool { if case .daily = self { return true }; return false }

    var number: Int? { if case .numbered(let n) = self { return n }; return nil }
}

/// A generated board together with the solution that proved it can be finished.
struct Level: Equatable, Codable, Sendable {
    let id: LevelID
    let board: Board
    /// The verified solution. Its length is par, and the hint replays it one move at a time.
    let solution: [Move]
    let colorCount: Int
    /// True when par is the provable minimum, false when the depth-first fallback found the
    /// solution and par is an upper bound.
    let parIsOptimal: Bool

    var par: Int { solution.count }
}

/// SplitMix64. Small, fast, and identical on every device, which is the only property that
/// matters here: two phones opening the same day's puzzle must deal the same tubes.
struct SeededRandom: RandomNumberGenerator {
    private var state: UInt64

    init(seed: UInt64) { state = seed }

    mutating func next() -> UInt64 {
        state = state &+ 0x9E37_79B9_7F4A_7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
        z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
        return z ^ (z >> 31)
    }
}

/// Deals random boards and hands back only the ones the solver has finished.
///
/// This is the app's whole argument. Every competitor in the niche is accused by its own
/// reviewers of serving levels that cannot be won; here a board is dealt, solved, and thrown
/// away if the solver cannot end it — so no unsolvable board can reach a player, and the
/// solver's move count is what par means.
enum LevelGenerator {
    /// The shape of the climb, and the thing this app got wrong for its whole first life.
    ///
    /// The old curve stepped colours 3→7 by level 26 and added `min(n / 3, 12)` to the par
    /// bar, which saturates at level 36. From level 36 to level 10,000 every board was seven
    /// colours, two spares, par 22 — the same puzzle, for as long as anyone kept playing. The
    /// file's own comment mocked Water Sort for exactly that ("at roughly level 100, they keep
    /// doing the same beginner puzzle") a few lines above the `min` that caused it. Nobody
    /// downstream could see it: a screenshot of level 40 and a screenshot of level 400 are the
    /// same screenshot.
    ///
    /// Now each dimension opens when the one before it runs out of room. Colours climb to nine
    /// by level 31; the vials then start getting deeper, five at 50 and six at 125; and the par
    /// bar tightens within each of those bands. The rack stops changing shape at level 200,
    /// which `ladder.flattensAt` will tell you and which DESIGN.md's "The play" answers for.
    ///
    /// It stops there because this app's own promise stops there, and the first three versions
    /// of this ladder found every wall the hard way. All three were measured, not reasoned:
    ///
    /// - **Nine colours, six deep is what the solver can still *prove*.** Every board is dealt,
    ///   solved, and thrown away if the solver cannot finish it, and par is the solver's own
    ///   optimal move count. At seven deep the search starts hitting its budget and returning a
    ///   path it cannot call optimal — level 260 came out with a par of 93 against a bar of 49 —
    ///   so `par` quietly stops meaning what the app tells the player it means. At six deep a
    ///   level verifies in well under a second and par is still exact.
    /// - **The last spare cannot be taken away.** A dial that dropped the rack to one spare at
    ///   level 240 made nine-colour boards effectively unsolvable: every deal failed, `make`
    ///   fell through to `trivial`, and levels 300 and 400 came out as *one-pour* boards. The
    ///   hardest rung in the game was the easiest one in it. Two spares stay.
    /// - **A dial with no ceiling is not the same as a curve that climbs.** The par bar used to
    ///   be the open dial, demanding `n / 3` more moves forever. Past level 100 it was asking
    ///   for longer solutions than any deal of that shape contains, so `make` burned all its
    ///   attempts on full solves and served the best it had found anyway: par went 40, 40, 37,
    ///   48, 49 over levels 100 to 300 — flat, noisy, and 5 to 6.7 seconds per level. The bar
    ///   tracks the shape now and the shape is what climbs.
    ///
    /// Rebuilt and measured 12 Sep 2026 — the table is in DESIGN.md's "The play".
    static let ladder = Ladder([
        Ladder.Dial("colours", from: 3, every: 5, opensAt: 1, ceiling: 9),
        Ladder.Dial("depth", from: 4, every: 75, opensAt: 50, ceiling: 6),
        Ladder.Dial("par", from: 9, by: 1, every: 3, opensAt: 1, ceiling: 30),
    ])

    /// Spare tubes. Two is the standard of the genre, and it is not a difficulty dial: taking
    /// one away does not make the game harder, it makes it unsolvable. Difficulty comes from
    /// the colours, the depth and the length of the solution.
    static let spareTubes = 2

    static func colorCount(forLevel n: Int) -> Int {
        ladder["colours", at: n] ?? 3
    }

    static func capacity(forLevel n: Int) -> Int {
        ladder["depth", at: n] ?? Board.baseCapacity
    }

    static func spares(forLevel n: Int) -> Int { spareTubes }

    /// The move count a board has to reach before it is worth serving at this level.
    ///
    /// Difficulty is a function of how long the solution is, not of how many tubes are on
    /// screen — but how long a solution *can* be is set by how much liquid is in play, so the
    /// bar is a fraction of that, tightened by the level's own rung within its depth band.
    ///
    /// The first version of this ladder let the bar climb `n / 3` forever, on the theory that a
    /// dial with no ceiling is a ladder that never flattens. Measuring it said otherwise. Past
    /// about level 100 the bar was higher than any deal of that shape reaches, so `make` spent
    /// every one of its attempts on a full solve and then served the best it had found anyway:
    /// par went 40, 40, 37, 48, 49 across levels 100 to 300 — flat, and noisy — while a single
    /// level took 5 to 6.7 seconds to generate. An unreachable demand is not difficulty, it is
    /// a slow way of dealing at random. The bar tracks the shape now, the generator finds a
    /// board that clears it in an attempt or two, and the shape is what climbs.
    static func parBar(forLevel n: Int, colors: Int) -> Int {
        let units = colors * capacity(forLevel: n)
        let reach = units * 2 / 3
        let within = min((ladder["par", at: n] ?? 9) - 9, units / 8)
        return reach + within
    }

    /// How many deals to look through for one that clears the bar. The bar is reachable, so
    /// this is a margin for unlucky seeds rather than a search.
    static func attempts(forLevel n: Int) -> Int { 10 }

    static func level(_ n: Int) -> Level {
        let colors = colorCount(forLevel: n)
        return make(seed: seed(forLevel: n),
                    colors: colors,
                    spares: spares(forLevel: n),
                    capacity: capacity(forLevel: n),
                    parBar: parBar(forLevel: n, colors: colors),
                    attempts: attempts(forLevel: n),
                    id: .numbered(n))
    }

    /// The daily used to be six colours and par 18 on every date the app would ever see, which
    /// made the one board everybody plays together the flattest thing in the game. It climbs
    /// over a season now — a fortnight of getting harder, then back to the shallow end — so a
    /// player who comes for the daily alone still meets a different puzzle in March.
    static func daily(_ dayKey: String) -> Level {
        // The rung has to come from the date alone. `String.hashValue` is seeded per process,
        // so a board derived from it would differ between two phones — and between two
        // launches of the same phone — which is the one thing the daily cannot do.
        let n = 6 + (DayKey.ordinal(of: dayKey) % 14) * 3
        let colors = colorCount(forLevel: n)
        return make(seed: seed(forDayKey: dayKey),
                    colors: colors,
                    spares: spares(forLevel: n),
                    capacity: capacity(forLevel: n),
                    parBar: parBar(forLevel: n, colors: colors),
                    attempts: attempts(forLevel: n),
                    id: .daily(dayKey))
    }

    static func level(_ id: LevelID) -> Level {
        switch id {
        case .numbered(let n): return level(n)
        case .daily(let key): return daily(key)
        }
    }

    // MARK: - Dealing

    static func make(
        seed: UInt64,
        colors: Int,
        spares: Int,
        capacity: Int = Board.baseCapacity,
        parBar: Int,
        attempts: Int = 8,
        id: LevelID
    ) -> Level {
        var best: Level?
        for attempt in 0..<attempts {
            let board = deal(seed: seed &+ UInt64(attempt) &* 0x1000_0000_01B3,
                             colors: colors, spares: spares, capacity: capacity)
            guard !board.isSolved else { continue }
            switch Solver.solve(board) {
            case .unsolvable, .unknown:
                continue
            case .solved(let moves, let optimal):
                let candidate = Level(id: id, board: board, solution: moves,
                                      colorCount: colors, parIsOptimal: optimal)
                // Relax the bar as the attempts run down rather than dealing forever.
                let bar = parBar - (attempt / 3)
                if candidate.par >= bar { return candidate }
                if candidate.par > (best?.par ?? 0) { best = candidate }
            }
        }
        if let best { return best }
        // Never reached in practice: a random deal of full tubes is nearly always solvable,
        // and twelve of them failing would need the solver to run out of budget every time.
        // Serving the solved-by-construction fallback is still better than serving nothing.
        return trivial(colors: colors, spares: spares, capacity: capacity, id: id)
    }

    private static func deal(seed: UInt64, colors: Int, spares: Int, capacity: Int) -> Board {
        var rng = SeededRandom(seed: seed)
        var units: [Int] = []
        units.reserveCapacity(colors * capacity)
        for color in 0..<colors {
            units.append(contentsOf: repeatElement(color, count: capacity))
        }
        units.shuffle(using: &rng)
        var tubes: [[Int]] = []
        tubes.reserveCapacity(colors + spares)
        for start in stride(from: 0, to: units.count, by: capacity) {
            tubes.append(Array(units[start..<(start + capacity)]))
        }
        tubes.append(contentsOf: repeatElement([], count: spares))
        return Board(tubes: tubes, capacity: capacity)
    }

    /// A board one pour from finished. Only the last-resort path uses it.
    private static func trivial(colors: Int, spares: Int, capacity: Int, id: LevelID) -> Level {
        var tubes: [[Int]] = (0..<colors).map { Array(repeating: $0, count: capacity) }
        tubes.append(contentsOf: repeatElement([], count: spares))
        tubes[0].removeLast()
        tubes[colors] = [0]
        let board = Board(tubes: tubes, capacity: capacity)
        let solution = Solver.solve(board)
        if case .solved(let moves, let optimal) = solution {
            return Level(id: id, board: board, solution: moves, colorCount: colors, parIsOptimal: optimal)
        }
        return Level(id: id, board: board, solution: [Move(from: colors, to: 0)],
                     colorCount: colors, parIsOptimal: true)
    }

    // MARK: - Seeds

    /// A level's seed is its number, so level 41 is the same board on every device and in
    /// every install — a player who reinstalls gets their levels back, not new ones.
    static func seed(forLevel n: Int) -> UInt64 {
        var h: UInt64 = 0xCBF2_9CE4_8422_2325
        h = (h ^ UInt64(bitPattern: Int64(n))) &* 0x1000_0000_01B3
        return h ^ 0x5464_6570_6F75_72A1
    }

    /// FNV-1a over the day key. `2026-09-11` is one puzzle, everywhere.
    static func seed(forDayKey key: String) -> UInt64 {
        var h: UInt64 = 0xCBF2_9CE4_8422_2325
        for byte in key.utf8 {
            h = (h ^ UInt64(byte)) &* 0x1000_0000_01B3
        }
        return h
    }
}

/// `yyyy-MM-dd` in the device's own calendar. Used as the daily seed and as the key the
/// streak calendar counts.
enum DayKey {
    static func key(for date: Date = .now, calendar: Calendar = .current) -> String {
        let c = calendar.dateComponents([.year, .month, .day], from: date)
        return String(format: "%04d-%02d-%02d", c.year ?? 0, c.month ?? 0, c.day ?? 0)
    }

    /// Days since 2026-01-01, from the key's own digits so that every device agrees. Used to
    /// walk the daily up and down its own ladder over a fortnight.
    static func ordinal(of key: String) -> Int {
        let parts = key.split(separator: "-").compactMap { Int($0) }
        guard parts.count == 3 else { return 0 }
        return (parts[0] - 2026) * 372 + (parts[1] - 1) * 31 + (parts[2] - 1)
    }

    static func date(from key: String, calendar: Calendar = .current) -> Date? {
        let parts = key.split(separator: "-").compactMap { Int($0) }
        guard parts.count == 3 else { return nil }
        return calendar.date(from: DateComponents(year: parts[0], month: parts[1], day: parts[2]))
    }
}
