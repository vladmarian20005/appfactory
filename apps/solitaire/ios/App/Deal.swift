import Foundation

/// The only random source in the app, and it is not random: the same seed gives the same
/// numbers here and in `tools/pack.mjs`, forever. Constants as FactoryKit's `Celebration`.
struct SplitMix64 {
    private var state: UInt64
    init(seed: UInt64) { state = seed }

    mutating func next() -> UInt64 {
        state &+= 0x9E37_79B9_7F4A_7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
        z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
        return z ^ (z >> 31)
    }

    mutating func unit() -> Double { Double(next() >> 11) / Double(UInt64(1) << 53) }
}

enum Deal {
    /// The 52 cards in the order they are dealt. Fisher–Yates from the end with SplitMix64.
    static func cards(seed: UInt64) -> [Card] {
        var deck = (0..<52).map { Card(code: UInt8($0)) }
        var rng = SplitMix64(seed: seed)
        for i in stride(from: 51, through: 1, by: -1) {
            let j = Int(rng.unit() * Double(i + 1))
            deck.swapAt(i, j)
        }
        return deck
    }

    /// Columns 0…6 take 1…7 cards dealt row by row, the last of each face up; the other 24
    /// are the stock, top last.
    static func table(seed: UInt64, draw: Int) -> Table {
        let deck = cards(seed: seed)
        var columns = Array(repeating: [Card](), count: 7)
        var i = 0
        for r in 0..<7 {
            for c in r..<7 {
                columns[c].append(deck[i])
                i += 1
            }
        }
        return Table(draw: draw,
                     stock: Array(deck[28...]),
                     waste: [],
                     foundations: Array(repeating: [], count: 4),
                     columns: columns,
                     faceDown: Array(0..<7))
    }

    /// FNV-1a over the dealt order, the check `pack.mjs` stores as `hash`.
    static func hash(seed: UInt64) -> String {
        var h: UInt32 = 0x811C_9DC5
        for c in cards(seed: seed) {
            h ^= UInt32(c.code)
            h = h &* 0x0100_0193
        }
        return String(format: "%08x", h)
    }
}
