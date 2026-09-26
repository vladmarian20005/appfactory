import FactoryKit
import Foundation

/// The lacemaker — old, unhurried, dry, and better at this than you will ever be. She talks
/// about the thread, the pins and the pillow, never about you, and never counts what you
/// missed. One sentence; it has to fit in the margin of the card.
enum Voice {
    static let praise = [
        "Off the pillow, and not a pin bare.",
        "That is lace. Hold it to the window.",
        "Every pin, once, and the thread came home.",
        "The pins are out and it holds its shape.",
        "Wound like you had done it before.",
        "One thread all the way round, and it lifts clean.",
        "The pattern is used up. Good.",
        "Into the sampler with that one.",
        "Not a knot in it.",
        "The card is empty and the piece is whole.",
        "Neat work. The gimp hardly had to hold you.",
        "Lift it. It is yours now.",
    ]

    static let nearMiss = [
        "Picked out. The thread does not mind.",
        "That pin was a dead end. Back to the last fork.",
        "Nowhere to go from there. Unwind a little.",
        "The thread came back on itself. It happens on every pillow.",
        "Wound short. Count the bare pins on that side before you go on.",
        "A pin skipped now is a pin bare later. Back up.",
        "The gimp says no. The thread goes round it, not through.",
        "Picked out twice. Look at the corners first — they only have one way in.",
        "Back a few. The pattern has not changed; only the thread has.",
    ]

    static let deadEnd = "Nowhere to go from there. Unwind a little."

    /// Said once each, the first time a pattern asks for something the first card did not show.
    static let noStart = "No brass pin on this one. The thread may begin at any pin — find one with only one way in."
    static let noFinish = "No ring on this card. The thread ends wherever the last bare pin is."
    static let window = "Where the card is cut away there is no pin. The thread goes round the window."

    /// `{n}` is the pins in the bar.
    static let plait = [
        "A plait.",
        "Straight and tight.",
        "{n} pins in a bar.",
        "That run will hold.",
        "Good and even.",
        "Plaited. The piece is firming up.",
    ]

    private static var last: [String: String] = [:]

    /// A line from a pool, never the same one twice running.
    static func pick(_ pool: [String], key: String) -> String {
        var options = pool.filter { $0 != last[key] }
        if options.isEmpty { options = pool }
        let line = options.randomElement() ?? pool[0]
        last[key] = line
        return line
    }

    static func praiseLine() -> String { pick(praise, key: "praise") }

    static func missLine(unpicks: Int) -> String {
        // The "twice" line is only true on the second.
        let pool = nearMiss.filter { unpicks == 2 || !$0.hasPrefix("Picked out twice") }
        return pick(pool, key: "miss")
    }

    static func plaitLine(pins: Int) -> String {
        pick(plait, key: "plait").replacingOccurrences(of: "{n}", with: Words.capitalised(pins))
    }

    static func headline(_ tier: Run.Tier, unpicks: Int) -> String {
        switch tier {
        case .best: "Clean, and the longest thread you have wound"
        case .clean: "Worked clean, in one thread"
        case .good: "Off the pillow. Picked out \(Words.times(unpicks)), and nobody will know"
        case .finished: "Off the pillow. It fought you, and it is lace all the same"
        }
    }

    /// The margin card's two lines: what was done, and what is waiting.
    static func ending(for piece: Piece, record: Record, next: (side: Int, ground: Ground)?) -> (String, String) {
        let pieces = record.pieces.count
        let first: String
        if pieces == 1 {
            first = "Your first piece. It goes in the sampler, and the pillow is cleared for the next one."
        } else {
            let how = piece.isClean ? "Off the pillow clean" : "Off the pillow, picked out \(Words.times(piece.unpicks))"
            let head = "\(how) — \(Words.number(piece.longestThread)) pins in one thread. \(Words.capitalised(pieces)) pieces in the sampler"
            if let m = Play.earned.next(after: pieces) {
                first = "\(head). \(Play.horizon(m))"
            } else {
                let days = record.daysRunning()
                first = "\(head), and \(Words.number(days)) days running."
            }
        }
        let second: String
        if piece.isToday {
            second = "Today's is in the sampler. Tomorrow's is pricked at midnight."
        } else if let next {
            second = "Next in the book: \(Words.size(next.side)), the \(next.ground.name) ground."
        } else {
            second = "The book goes on past the sixtieth."
        }
        return (first, second)
    }

    /// `THREAD 31 · PICKED OUT ONCE · TWO PLAITS`
    static func marginCaps(chain: Int, unpicks: Int, plaits: Int) -> String {
        var parts = ["Thread \(chain)"]
        if unpicks > 0 { parts.append("Picked out \(Words.times(unpicks))") }
        if plaits > 0 { parts.append(plaits == 1 ? "One plait" : "\(Words.capitalised(plaits)) plaits") }
        return parts.joined(separator: " · ")
    }

    static let reminder = "Today's pattern is pricked and pinned."
}
