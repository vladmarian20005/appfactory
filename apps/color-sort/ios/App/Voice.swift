import Foundation

/// The keeper of the pool. He has walked this shore every evening for years, he is calm, a
/// little mystical, and he is pleased for you without making a performance of it.
///
/// Pools rather than fixed strings, and never the same line twice running, so the tenth win
/// does not read like the first. Nothing here states the deal — the paywall's promise is the
/// one place allowed to do that.
enum Voice {
    /// Fewer pours than the charted line.
    static let underPar = [
        "Shorter than the charted line.",
        "You found a way I had not.",
        "The line bends for you.",
        "Fewer pours than the water needed.",
        "That is the shortest route beaten.",
        "Nobody walks it that clean by accident.",
    ]

    /// Exactly the charted line.
    static let atPar = [
        "The rack is clean.",
        "Every light found its glass.",
        "Exactly the charted line.",
        "Straight down the line, no wasted pour.",
        "That is the shortest line there is.",
        "Clean as the flat at low tide.",
    ]

    /// Over the line. Warm, never a scold: the job is still done.
    static let overPar = [
        "The rack is clean. The line was shorter.",
        "You got there. The water knows a quicker way.",
        "Every glass holds one light — that is the job done.",
        "A few pours over the line, and still lit.",
        "Not the short way, but the right end.",
        "Done is done. The line will keep.",
    ]

    /// A vial that just came good, said once and quietly, under the rack.
    static let vialCleared = [
        "One light home.",
        "That glass is done.",
        "Settled.",
        "Clean glass.",
        "It found its own.",
        "Lit and left alone.",
    ]

    /// What the keeper says over the shore when nothing has been poured yet.
    static let waiting = [
        "The rack is set.",
        "Low tide. The glass is waiting.",
        "Six lights, six glasses.",
        "The flat is quiet.",
    ]

    private static var last: [String: String] = [:]

    /// A line from `pool`, never the one it gave last time for the same `key`.
    static func line(from pool: [String], key: String = "default") -> String {
        guard pool.count > 1 else { return pool.first ?? "" }
        var choice = pool.randomElement() ?? pool[0]
        var guard_ = 0
        while choice == last[key], guard_ < 8 {
            choice = pool.randomElement() ?? pool[0]
            guard_ += 1
        }
        last[key] = choice
        return choice
    }

    /// The verdict for a finished level, by tier.
    static func verdict(moves: Int, par: Int) -> String {
        if moves < par { return line(from: underPar, key: "verdict") }
        if moves == par { return line(from: atPar, key: "verdict") }
        return line(from: overPar, key: "verdict")
    }
}

/// How loud a finish is. A clean sweep has to be louder than a finish, or neither means
/// anything.
enum WinTier {
    case underPar, atPar, overPar

    init(moves: Int, par: Int) {
        if moves < par { self = .underPar }
        else if moves == par { self = .atPar }
        else { self = .overPar }
    }

    /// What `confetti(power:)` gets. Over par sets no confetti off at all — it gets a warm
    /// glow behind the rack instead.
    var confettiPower: CGFloat {
        switch self {
        case .underPar: return 1.4
        case .atPar: return 1.0
        case .overPar: return 0
        }
    }

    var fires: Bool { confettiPower > 0 }
}
