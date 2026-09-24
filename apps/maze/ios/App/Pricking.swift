import Foundation

/// One pattern: which pins are on the card, where the gimp lies between them, where the
/// thread starts and ends, and the one way through that the solver proved.
struct Pricking: Codable, Equatable, Hashable, Sendable {
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
    var loose: Int { start == nil ? 2 : (finish == nil ? 1 : 0) }

    func row(_ cell: Int) -> Int { cell / side }
    func col(_ cell: Int) -> Int { cell % side }

    /// Grid neighbours of `cell` that are on the card, in the fixed order up, right, down, left.
    func gridNeighbours(_ cell: Int) -> [Int] {
        var out: [Int] = []
        let r = row(cell), c = col(cell)
        if r > 0, open[cell - side] { out.append(cell - side) }
        if c < side - 1, open[cell + 1] { out.append(cell + 1) }
        if r < side - 1, open[cell + side] { out.append(cell + side) }
        if c > 0, open[cell - 1] { out.append(cell - 1) }
        return out
    }

    /// Neighbours the thread may reach from `cell`: on the card, and no gimp between.
    func neighbours(_ cell: Int) -> [Int] {
        gridNeighbours(cell).filter { !gimp.contains(Edge(cell, $0)) }
    }

    func canStep(from a: Int, to b: Int) -> Bool {
        guard a >= 0, b >= 0, a < open.count, b < open.count, open[a], open[b] else { return false }
        let dr = abs(row(a) - row(b)), dc = abs(col(a) - col(b))
        guard dr + dc == 1 else { return false }
        return !gimp.contains(Edge(a, b))
    }
}

/// A wall between two neighbouring pins, normalised so `a < b`.
struct Edge: Codable, Hashable, Sendable {
    let a: UInt8
    let b: UInt8

    init(_ x: Int, _ y: Int) {
        a = UInt8(min(x, y))
        b = UInt8(max(x, y))
    }
}

/// A pricking's character: where the generator removes gimp first, and so what kind of
/// thinking the pattern asks for. Real lace grounds, in the order the book opens them.
enum Ground: String, Codable, CaseIterable, Hashable, Sendable {
    case tulle, bar, rose, torchon, spider, fan, honeycomb, valenciennes

    var name: String {
        switch self {
        case .tulle: "tulle"
        case .bar: "bar"
        case .rose: "rose"
        case .torchon: "torchon"
        case .spider: "spider"
        case .fan: "fan"
        case .honeycomb: "honeycomb"
        case .valenciennes: "Valenciennes"
        }
    }

    /// "The rose ground" — the pattern's title.
    var title: String { "The \(name) ground" }
}

enum ThreadColour: String, Codable, CaseIterable, Sendable {
    case indigo, rose, gold
}

enum Cover: String, Codable, CaseIterable, Sendable {
    case linen, ticking
}

/// The only random source in the engine. Same seed, same pattern, on every device, forever.
struct SplitMix64: RandomNumberGenerator, Sendable {
    private var state: UInt64

    init(seed: UInt64) { state = seed }

    mutating func next() -> UInt64 {
        state &+= 0x9E37_79B9_7F4A_7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
        z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
        return z ^ (z >> 31)
    }

    mutating func below(_ n: Int) -> Int {
        guard n > 1 else { return 0 }
        return Int(next() % UInt64(n))
    }

    mutating func unit() -> Double { Double(next() >> 11) / Double(1 << 53) }

    /// Mix two numbers into one seed.
    static func mix(_ a: UInt64, _ b: UInt64) -> UInt64 {
        var g = SplitMix64(seed: a &* 0x9E37_79B9_7F4A_7C15 ^ b)
        return g.next()
    }
}

/// Numbers in words, for the lacemaker, who does not use digits.
enum Words {
    private static let small = ["zero", "one", "two", "three", "four", "five", "six", "seven",
                                "eight", "nine", "ten", "eleven", "twelve", "thirteen", "fourteen",
                                "fifteen", "sixteen", "seventeen", "eighteen", "nineteen"]
    private static let tens = ["", "", "twenty", "thirty", "forty", "fifty", "sixty", "seventy",
                               "eighty", "ninety"]

    static func number(_ n: Int) -> String {
        if n < 0 { return "\(n)" }
        if n < 20 { return small[n] }
        if n < 100 {
            let t = tens[n / 10]
            return n % 10 == 0 ? t : "\(t)-\(small[n % 10])"
        }
        if n < 1000 {
            let h = "\(small[n / 100]) hundred"
            return n % 100 == 0 ? (n / 100 == 1 ? "a hundred" : h) : (n / 100 == 1 ? "a hundred and " : "\(h) and ") + number(n % 100)
        }
        return "\(n)"
    }

    static func capitalised(_ n: Int) -> String {
        let s = number(n)
        return s.prefix(1).uppercased() + s.dropFirst()
    }

    /// "nine by nine"
    static func size(_ side: Int) -> String { "\(number(side)) by \(number(side))" }

    /// "once", "twice", "three times"
    static func times(_ n: Int) -> String {
        switch n {
        case 1: "once"
        case 2: "twice"
        default: "\(number(n)) times"
        }
    }
}
