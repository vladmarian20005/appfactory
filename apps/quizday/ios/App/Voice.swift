import SwiftUI

/// The night editor who set tomorrow's paper: dry, brisk, quietly proud of the edition. He
/// talks in the newsroom's terms and never explains them, he never mentions what the app does
/// not have, and praise is eight words or fewer.
enum Voice {
    /// On the stamp when she is right.
    static let praise = [
        "Filed.",
        "Clean copy.",
        "That one's yours.",
        "Straight to the front page.",
        "No correction needed.",
        "Set and printed.",
        "Good ear.",
        "The desk agrees.",
        "Ink dry already.",
        "Bang on.",
    ]

    /// On the stamp when she is not. Still red, still the editor, never a buzzer.
    static let nearMiss = [
        "Correction on page two.",
        "Close. The desk has it here.",
        "Not this edition.",
        "Pencil it out.",
        "We'll run the right one.",
        "Half a lead, no story.",
        "The subeditor caught it.",
        "That one got away.",
    ]

    /// What the ribbon and the unplayed sheet say about the run.
    static func streak(_ days: Int, todayPlayed: Bool) -> String? {
        guard days > 0 else { return nil }
        if !todayPlayed { return "\(days) days running. Today keeps it." }
        switch days {
        case 1: return "Day one on the desk."
        case 7: return "A full week in print."
        case 30: return "A month of editions."
        default: return "\(days) days running."
        }
    }

    static func runEnded(at days: Int) -> String { "The run ended at \(days). Start another." }
}

/// A pool drawn without replacement, so no line repeats inside the same ten and the tenth win
/// does not read like the first.
struct VoicePool {
    private let lines: [String]
    private var bag: [String]

    init(_ lines: [String]) {
        self.lines = lines
        bag = lines.shuffled()
    }

    mutating func next() -> String {
        if bag.isEmpty { bag = lines.shuffled() }
        return bag.removeLast()
    }
}

/// One round's worth of the editor's voice.
struct RoundVoice {
    private var praise = VoicePool(Voice.praise)
    private var nearMiss = VoicePool(Voice.nearMiss)

    mutating func line(correct: Bool) -> String {
        correct ? praise.next() : nearMiss.next()
    }
}

// MARK: - The tiers

/// What the edition looks like when it comes off the press. A clean sweep is a different front
/// page from a pass, and a blank sheet is a different one again.
enum Tier {
    case extra, stopThePress, filed, tomorrow, blank

    static func forScore(_ score: Int, total: Int = 10) -> Tier {
        switch score {
        case total: return .extra
        case 8...: return .stopThePress
        case 5...: return .filed
        case 1...: return .tomorrow
        default: return .blank
        }
    }

    var headline: String {
        switch self {
        case .extra: return "Extra! Extra!"
        case .stopThePress: return "Stop the press"
        case .filed: return "The edition is filed"
        case .tomorrow: return "Tomorrow's is already set"
        case .blank: return "A blank sheet"
        }
    }

    func subline(score: Int, total: Int = 10) -> String {
        switch self {
        case .extra: return "Ten for ten. The desk is speechless."
        case .stopThePress:
            return score == total - 1
                ? "One got past you. One."
                : "Two slipped through. The rest are yours."
        case .filed:
            let missed = total - score
            return "\(score) of ten, and the other \(missed) are explained below."
        case .tomorrow: return "A hard sheet. You still read ten reasons."
        case .blank: return "It happens on the night desk too."
        }
    }

    /// Shredded newsprint and ticker tape, or nothing at all. A proof never gets a burst.
    var burst: (count: Int, power: CGFloat, rain: Bool)? {
        switch self {
        case .extra: return (130, 1.5, false)
        case .stopThePress: return (70, 0.9, false)
        case .filed: return (14, 0.4, true)
        case .tomorrow, .blank: return nil
        }
    }

    /// The headline stamps at an angle on a good edition and merely sets on a hard one.
    var stamps: Bool {
        switch self {
        case .extra, .stopThePress, .filed: return true
        case .tomorrow, .blank: return false
        }
    }

    var fanfare: Bool {
        switch self {
        case .extra, .stopThePress: return true
        default: return false
        }
    }

    /// A clean sweep doubles the rule under the masthead and stamps twice.
    var doubleImpression: Bool { self == .extra }
}
