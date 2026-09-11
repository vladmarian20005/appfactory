import Foundation

/// One pour: the whole top run of `from` moves onto `to`, as far as it fits.
struct Move: Equatable, Hashable, Codable, Sendable {
    var from: Int
    var to: Int
}

/// A rack of tubes. Each tube holds up to `Board.capacity` units of colored liquid, stored
/// bottom first, and every value is an index into `Palette`.
///
/// Deliberately free of SwiftUI and of any reference type: the solver runs this off the main
/// actor thousands of times per generated level, and a value type with no identity is what
/// makes that safe and fast.
struct Board: Equatable, Hashable, Codable, Sendable {
    static let capacity = 4

    var tubes: [[Int]]

    init(tubes: [[Int]]) { self.tubes = tubes }

    var count: Int { tubes.count }

    /// Every tube is either empty or a full stack of one color.
    var isSolved: Bool {
        for t in tubes {
            if t.isEmpty { continue }
            if t.count != Board.capacity { return false }
            if t.contains(where: { $0 != t[0] }) { return false }
        }
        return true
    }

    /// Full and a single color — finished, and nothing should ever pour out of it again.
    func isComplete(_ i: Int) -> Bool {
        let t = tubes[i]
        return t.count == Board.capacity && !t.contains { $0 != t[0] }
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
        guard tubes[to].count < Board.capacity else { return false }
        if let dst = tubes[to].last, dst != src { return false }
        return true
    }

    /// How many units a pour would actually move. Zero when the pour is illegal.
    func pourAmount(from: Int, to: Int) -> Int {
        guard canPour(from: from, to: to) else { return 0 }
        return min(topRun(from), Board.capacity - tubes[to].count)
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
    /// one tube packs into 16 bits (four 4-bit slots, 0 = empty), and the codes are kept
    /// sorted so the tube order is thrown away.
    ///
    /// A SIMD vector rather than an array because the search hashes millions of these; an
    /// `[UInt16]` key heap-allocates once per position visited, which cost more than the
    /// search itself.
    var key: BoardKey {
        var codes = BoardKey()
        var n = 0
        for t in tubes {
            var code: UInt16 = 0
            for (slot, color) in t.enumerated() {
                code |= UInt16(truncatingIfNeeded: color &+ 1) << UInt16(slot &* 4)
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
typealias BoardKey = SIMD16<UInt16>
