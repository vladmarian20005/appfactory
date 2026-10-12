import FactoryKit
import Foundation

/// The clerk: lays the table every morning, keeps the diary, counts the moves. Precise, dry,
/// fond of the cards; talks about the cards and the count, never about you, and never counts
/// what you missed.
enum Voice {
    static let praise = [
        "Every card up. The table is bare.",
        "Fifty-two up, in order, the way they went.",
        "{buried} was the one to dig for, and you dug.",
        "Clean through. Not a card taken back.",
        "Under the mark by {margin}.",
        "The kings are up and the baize is clear.",
        "The stock ran out and there was nothing left in it.",
        "Four suits, four stacks, done.",
        "The clubs went up without a wait.",
        "Out, and in good time.",
        "That is patience.",
        "The table takes itself off now.",
    ]

    static let takenBack = [
        "Taken back. The cards do not mind.",
        "Back one. The deal has not changed.",
        "That {rank} wants a {colour} {higher}, and there are two.",
        "Buried. Something above it has to move first.",
        "Taken back twice. Look at the stock before the columns.",
    ]

    static let stuck = "Nothing moves. Turn the stock."
    static let firstGather = "Through the stock once. It is all still there."
    static let againGather = "Round again. Nothing is lost by going round."
    static let kingWaits = "A king with nowhere to go, until a column empties."

    private static var last: [String: String] = [:]

    /// A line from `pool`, never the same one twice running.
    static func pick(_ pool: [String], key: String, salt: Int) -> String {
        var candidates = pool.filter { $0 != last[key] }
        if candidates.isEmpty { candidates = pool }
        // Step through the pool from a salt the deal supplies (its entry number, its moves),
        // so a capture is repeatable and successive deals read differently.
        let line = candidates[Int((salt &* 7 &+ 3).magnitude) % candidates.endIndex]
        last[key] = line
        return line
    }

    /// The clerk's line for a deal that came out.
    static func praiseLine(for e: Entry, salt: Int) -> String {
        var pool = praise
        if !e.isClean { pool.removeAll { $0.hasPrefix("Clean through") } }
        if !e.underMark || e.mark - e.moves < 2 { pool.removeAll { $0.contains("{margin}") } }
        if e.buried.suit != .club { pool.removeAll { $0.hasPrefix("The clubs") } }
        return pick(pool, key: "praise", salt: salt)
            .replacingOccurrences(of: "{buried}", with: capital(e.buried.name))
            .replacingOccurrences(of: "{margin}", with: Words.number(e.mark - e.moves))
    }

    /// The near-miss line on a take-back, with the ranks substituted from the table.
    static func takeBackLine(table: Table, count: Int, salt: Int) -> String {
        var pool = takenBack
        if count < 2 { pool.removeAll { $0.hasPrefix("Taken back twice") } }
        // "That seven wants a black eight" only when there is a seven on top of a column.
        let tops = table.columns.compactMap(\.last).filter { $0.rank < 13 }
        if let c = tops.first {
            pool = pool.map {
                $0.replacingOccurrences(of: "{rank}", with: c.rankName)
                    .replacingOccurrences(of: "{colour}", with: c.isRed ? "black" : "red")
                    .replacingOccurrences(of: "{higher}", with: Card(suit: .spade, rank: c.rank + 1).rankName)
            }
        } else {
            pool.removeAll { $0.contains("{rank}") }
        }
        return pick(pool, key: "back", salt: salt)
    }

    // MARK: - The win

    static func headline(_ tier: Run.Tier, takenBack: Int) -> String {
        switch tier {
        case .best: return "It came out — further under the mark than you have ever been"
        case .clean: return "It came out clean"
        case .good:
            let n = takenBack == 1 ? "One card" : "\(Words.capitalised(takenBack)) cards"
            return "It came out. \(n) taken back, and nobody counts those"
        case .finished: return "It came out. It took some taking back, and it is out all the same"
        }
    }

    /// The ending's first line: how it came out, the count, and what is waiting.
    static func ending(_ e: Entry, entries: Int, daysRunning: Int) -> String {
        if entries == 1 {
            return "Your first entry. It goes in the diary, and the table is cleared for the next one."
        }
        let how: String
        switch e.takenBack {
        case 0 where !e.gathered: how = "clean"
        case 1: how = "with one taken back"
        default: how = "with \(Words.number(max(1, e.takenBack))) taken back"
        }
        let markText = e.underMark
            ? (e.mark == e.moves ? "on the mark" : "under the mark by \(Words.number(e.mark - e.moves))")
            : "over the mark by \(Words.number(e.moves - e.mark))"
        let count = "\(Words.capitalised(entries)) entries in the diary"
        if let next = Play.earned.next(after: entries) {
            return "It came out \(how), in \(e.moves) moves — \(markText). \(count). \(Play.horizon(next))"
        }
        return "It came out \(how), in \(e.moves) moves — \(markText). \(count), and \(Words.number(daysRunning)) days running since the nineteenth of October."
    }

    /// The ending's second line.
    static func nextLine(after e: Entry, next: (number: Int, draw: Int, grade: Int)?) -> String {
        if e.kind == .today { return "Today's is in the diary. Tomorrow's is laid at midnight." }
        guard let next else { return "The ledger has been through the whole pack once. The second pass starts here." }
        return "Next in the ledger: No. \(next.number), draw \(Words.draw(next.draw)), grade \(Words.number(next.grade))."
    }

    static func capital(_ s: String) -> String { s.prefix(1).uppercased() + s.dropFirst() }

    // MARK: - Caps

    static func dateCaps(_ date: Date) -> String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_GB")
        f.dateFormat = "EEEE d MMMM"
        return f.string(from: date).uppercased()
    }

    static func shortDate(_ date: Date) -> String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_GB")
        f.dateFormat = "d MMMM"
        return f.string(from: date)
    }

    static func isoDate(_ date: Date) -> String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "yyyy-MM-dd"
        return f.string(from: date)
    }
}
