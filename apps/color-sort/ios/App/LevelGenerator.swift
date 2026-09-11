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
    /// Spare tubes. Two is the standard of the genre and keeps boards humane; difficulty
    /// comes from the par bar below, not from taking the spares away.
    static let spareTubes = 2

    static func colorCount(forLevel n: Int) -> Int {
        switch n {
        case ..<4: return 3
        case ..<9: return 4
        case ..<16: return 5
        case ..<26: return 6
        default: return 7
        }
    }

    /// The move count a board has to reach before it is worth serving at this level.
    ///
    /// Difficulty is a function of how long the solution is, not of how many tubes are on
    /// screen. Water Sort's reviewers describe the opposite — "at roughly level 100, they
    /// keep doing the same beginner puzzle" — which is what a tube-count ladder produces.
    static func parBar(forLevel n: Int, colors: Int) -> Int {
        colors + 3 + min(n / 3, 12)
    }

    static func level(_ n: Int) -> Level {
        let colors = colorCount(forLevel: n)
        return make(seed: seed(forLevel: n),
                    colors: colors,
                    spares: spareTubes,
                    parBar: parBar(forLevel: n, colors: colors),
                    id: .numbered(n))
    }

    static func daily(_ dayKey: String) -> Level {
        // Six colors every day: hard enough to be worth five minutes, small enough that the
        // solver always proves it before the screen appears.
        make(seed: seed(forDayKey: dayKey),
             colors: 6,
             spares: spareTubes,
             parBar: 18,
             id: .daily(dayKey))
    }

    static func level(_ id: LevelID) -> Level {
        switch id {
        case .numbered(let n): return level(n)
        case .daily(let key): return daily(key)
        }
    }

    // MARK: - Dealing

    /// Attempts per level. A deal that the solver cannot finish is discarded and the next
    /// seed tried; the best verified board is kept in case none clears the par bar.
    static let attempts = 8

    static func make(seed: UInt64, colors: Int, spares: Int, parBar: Int, id: LevelID) -> Level {
        var best: Level?
        for attempt in 0..<attempts {
            let board = deal(seed: seed &+ UInt64(attempt) &* 0x1000_0000_01B3, colors: colors, spares: spares)
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
        return trivial(colors: colors, spares: spares, id: id)
    }

    private static func deal(seed: UInt64, colors: Int, spares: Int) -> Board {
        var rng = SeededRandom(seed: seed)
        var units: [Int] = []
        units.reserveCapacity(colors * Board.capacity)
        for color in 0..<colors {
            units.append(contentsOf: repeatElement(color, count: Board.capacity))
        }
        units.shuffle(using: &rng)
        var tubes: [[Int]] = []
        tubes.reserveCapacity(colors + spares)
        for start in stride(from: 0, to: units.count, by: Board.capacity) {
            tubes.append(Array(units[start..<(start + Board.capacity)]))
        }
        tubes.append(contentsOf: repeatElement([], count: spares))
        return Board(tubes: tubes)
    }

    /// A board one pour from finished. Only the last-resort path uses it.
    private static func trivial(colors: Int, spares: Int, id: LevelID) -> Level {
        var tubes: [[Int]] = (0..<colors).map { Array(repeating: $0, count: Board.capacity) }
        tubes.append(contentsOf: repeatElement([], count: spares))
        tubes[0].removeLast()
        tubes[colors] = [0]
        let board = Board(tubes: tubes)
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

    static func date(from key: String, calendar: Calendar = .current) -> Date? {
        let parts = key.split(separator: "-").compactMap { Int($0) }
        guard parts.count == 3 else { return nil }
        return calendar.date(from: DateComponents(year: parts[0], month: parts[1], day: parts[2]))
    }
}
