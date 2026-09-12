import Foundation

/// One pour: the whole top run of `from` moves onto `to`, as far as it fits.
struct Move: Equatable, Hashable, Codable, Sendable {
    var from: Int
    var to: Int
}

/// A rack of tubes. Each tube holds up to `capacity` units of colored liquid, stored bottom
/// first, and every value is an index into `Palette`.
///
/// Deliberately free of SwiftUI and of any reference type: the solver runs this off the main
/// actor thousands of times per generated level, and a value type with no identity is what
/// makes that safe and fast.
///
/// `capacity` used to be a constant 4 for every board the app would ever deal, which is the
/// reason Tidepour's difficulty stopped: with the vials four deep and colours capped at seven,
/// there is a hardest board, the generator reached it around level 36, and every level after
/// that was the same puzzle in a different order. Depth is the dimension that opens when
/// colours run out — see `LevelGenerator.ladder`. Changed 12 Sep 2026.
struct Board: Equatable, Hashable, Codable, Sendable {
    /// The shallowest rack the app deals, and what a board saved before depth existed had.
    static let baseCapacity = 4
    /// Four bits a slot in `key`, in a UInt32 code: eight is as deep as a tube can be
    /// fingerprinted, and deeper than anything playable.
    static let maxCapacity = 8

    var tubes: [[Int]]
    /// How deep this board's vials are. Part of the board, not of the app, so a rack saved
    /// mid-pour reloads at the depth it was dealt at.
    var capacity: Int

    init(tubes: [[Int]], capacity: Int = Board.baseCapacity) {
        self.tubes = tubes
        self.capacity = min(max(2, capacity), Board.maxCapacity)
    }

    /// A board written before vials had a depth is four deep; without this, every rack saved
    /// mid-pour by a shipped build fails to decode and the player loses it.
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let tubes = try c.decode([[Int]].self, forKey: .tubes)
        let capacity = try c.decodeIfPresent(Int.self, forKey: .capacity) ?? Board.baseCapacity
        self.init(tubes: tubes, capacity: capacity)
    }

    var count: Int { tubes.count }

    /// A rack with every vial full and a single colour — the souvenir a finished board leaves
    /// behind, for the share card of a day whose own board is no longer in memory.
    static func cleared(colors: Int, capacity: Int = Board.baseCapacity) -> Board {
        Board(tubes: (0..<max(1, colors)).map { Array(repeating: $0, count: capacity) },
              capacity: capacity)
    }

    /// Every tube is either empty or a full stack of one color.
    var isSolved: Bool {
        for t in tubes {
            if t.isEmpty { continue }
            if t.count != capacity { return false }
            if t.contains(where: { $0 != t[0] }) { return false }
        }
        return true
    }

    /// Full and a single color — finished, and nothing should ever pour out of it again.
    func isComplete(_ i: Int) -> Bool {
        let t = tubes[i]
        return t.count == capacity && !t.contains { $0 != t[0] }
    }

    /// Non-empty and a single color, whether or not it is full.
    func isUniform(_ i: Int) -> Bool {
        let t = tubes[i]
        return !t.isEmpty && !t.contains { $0 != t[0] }
    }

    /// How many units sit in the top run of tube `i`.
    func topRun(_ i: Int) -> Int {
        let t = tubes[i]
        guard let top = t.last else { return 0 }
        var n = 0
        var k = t.count - 1
        while k >= 0, t[k] == top { n += 1; k -= 1 }
        return n
    }

    func canPour(from: Int, to: Int) -> Bool {
        guard from != to else { return false }
        guard let src = tubes[from].last else { return false }
        guard tubes[to].count < capacity else { return false }
        if let dst = tubes[to].last, dst != src { return false }
        return true
    }

    /// How many units a pour would actually move. Zero when the pour is illegal.
    func pourAmount(from: Int, to: Int) -> Int {
        guard canPour(from: from, to: to) else { return 0 }
        return min(topRun(from), capacity - tubes[to].count)
    }

    @discardableResult
    mutating func pour(from: Int, to: Int) -> Int {
        let n = pourAmount(from: from, to: to)
        guard n > 0, let color = tubes[from].last else { return 0 }
        tubes[from].removeLast(n)
        tubes[to].append(contentsOf: repeatElement(color, count: n))
        return n
    }

    func applying(_ m: Move) -> Board {
        var b = self
        b.pour(from: m.from, to: m.to)
        return b
    }

    /// The moves the solver is allowed to consider, already pruned.
    ///
    /// Two prunings do most of the work, and without them the search over eight colors does
    /// not finish: pouring out of a tube that is already one color achieves nothing, and all
    /// empty tubes are interchangeable, so only the first is worth trying as a destination.
    func searchMoves() -> [Move] {
        var out: [Move] = []
        out.reserveCapacity(tubes.count * 2)
        for i in tubes.indices {
            guard !tubes[i].isEmpty, !isComplete(i) else { continue }
            let uniformSource = isUniform(i)
            var usedAnEmpty = false
            for j in tubes.indices where j != i {
                if tubes[j].isEmpty {
                    if uniformSource || usedAnEmpty { continue }
                    usedAnEmpty = true
                    out.append(Move(from: i, to: j))
                } else if canPour(from: i, to: j) {
                    out.append(Move(from: i, to: j))
                }
            }
        }
        return out
    }

    /// Every legal move a player could make, unpruned. Used to tell a dead board from a
    /// merely awkward one.
    var hasAnyMove: Bool {
        for i in tubes.indices where !tubes[i].isEmpty && !isComplete(i) {
            for j in tubes.indices where j != i {
                if canPour(from: i, to: j) { return true }
            }
        }
        return false
    }

    /// Order-independent fingerprint. Two boards that differ only in which tube holds which
    /// stack are the same position, and collapsing them is what keeps the search finite:
    /// one tube packs into 32 bits (eight 4-bit slots, 0 = empty), and the codes are kept
    /// sorted so the tube order is thrown away.
    ///
    /// The code was 16 bits — four slots — while every vial in the app was four deep. That
    /// made the fingerprint, not the game, the thing that capped depth: a fifth unit would
    /// have shifted straight off the top of the code, so two genuinely different positions
    /// would have hashed the same and the solver would have called a solvable board
    /// unsolvable, silently. Widened 12 Sep 2026 alongside `Board.capacity`.
    ///
    /// A SIMD vector rather than an array because the search hashes millions of these; a
    /// `[UInt32]` key heap-allocates once per position visited, which cost more than the
    /// search itself.
    var key: BoardKey {
        var codes = BoardKey()
        var n = 0
        for t in tubes {
            var code: UInt32 = 0
            for (slot, color) in t.enumerated() {
                code |= UInt32(truncatingIfNeeded: color &+ 1) << UInt32(slot &* 4)
            }
            var j = n
            while j > 0, codes[j - 1] > code {
                codes[j] = codes[j - 1]
                j -= 1
            }
            codes[j] = code
            n += 1
        }
        return codes
    }
}

/// Sixteen packed tubes, which is more than any board the generator deals.
typealias BoardKey = SIMD16<UInt32>
