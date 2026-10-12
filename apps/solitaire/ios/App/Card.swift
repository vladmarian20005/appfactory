import Foundation

/// One card of fifty-two. `code` is suit × 13 + (rank − 1), the same number `pack.mjs` writes.
struct Card: Hashable, Codable, Identifiable {
    let code: UInt8

    init(code: UInt8) { self.code = code }
    init(suit: Suit, rank: Int) { code = UInt8(suit.rawValue * 13 + rank - 1) }

    var id: UInt8 { code }
    var suit: Suit { Suit(rawValue: Int(code) / 13)! }
    var rank: Int { Int(code) % 13 + 1 }
    var isRed: Bool { suit == .heart || suit == .diamond }

    /// "A", "2" … "10", "J", "Q", "K" — the index in a corner.
    var index: String {
        switch rank {
        case 1: return "A"
        case 11: return "J"
        case 12: return "Q"
        case 13: return "K"
        default: return String(rank)
        }
    }

    /// "the six of hearts"
    var name: String { "the \(rankName) of \(suit.plural)" }
    /// "Six of hearts", for VoiceOver.
    var spoken: String { "\(rankName.capitalized) of \(suit.plural)" }

    var rankName: String {
        ["ace", "two", "three", "four", "five", "six", "seven", "eight", "nine", "ten",
         "jack", "queen", "king"][rank - 1]
    }
}

enum Suit: Int, Codable, CaseIterable {
    case spade, heart, club, diamond

    var plural: String { ["spades", "hearts", "clubs", "diamonds"][rawValue] }
    var isRed: Bool { self == .heart || self == .diamond }
}

/// What makes a deal hard — the first that applies, so each deal has exactly one. Read by
/// `Mastery` to choose the next deal in the ledger.
enum Shape: String, Codable, CaseIterable, Hashable, Sendable {
    case buried, stock, kings, passes, even

    var title: String {
        switch self {
        case .buried: return "Buried"
        case .stock: return "In the stock"
        case .kings: return "Kings up"
        case .passes: return "Long passes"
        case .even: return "Even"
        }
    }
}

/// The card backs in the drawer.
enum Back: String, Codable, CaseIterable {
    case lattice, brassLattice, chevron, houndstooth, stars, leaf, seal

    var title: String {
        switch self {
        case .lattice: return "Lattice"
        case .brassLattice: return "Brass lattice"
        case .chevron: return "Chevron"
        case .houndstooth: return "Houndstooth"
        case .stars: return "Stars"
        case .leaf: return "Leaf"
        case .seal: return "Seal"
        }
    }
}

/// Numbers in words, for the clerk, who never writes "23" in a sentence when it can say it.
enum Words {
    static func number(_ n: Int) -> String {
        let f = NumberFormatter()
        f.numberStyle = .spellOut
        f.locale = Locale(identifier: "en_GB")
        return f.string(from: NSNumber(value: n)) ?? String(n)
    }

    static func capitalised(_ n: Int) -> String {
        let s = number(n)
        return s.prefix(1).uppercased() + s.dropFirst()
    }

    static func draw(_ d: Int) -> String { d == 3 ? "three" : "one" }
}
