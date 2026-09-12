import Foundation

/// One question, whatever its source: the bundled daily pack or the practice API.
struct QuizItem: Identifiable, Hashable {
    let id: String
    let question: String
    let answers: [String]
    let correct: Int
    let explanation: String?
    let source: String?
    let category: String
    let difficulty: String

    var correctAnswer: String { answers[correct] }
}

// MARK: - Bundled pack

struct PackQuestion: Codable, Hashable {
    let id: String
    let question: String
    let answers: [String]
    let correct: Int
    let explanation: String
    let source: String
    let category: String
    let difficulty: String

    var item: QuizItem {
        QuizItem(id: id, question: question, answers: answers, correct: correct,
                 explanation: explanation, source: source, category: category, difficulty: difficulty)
    }
}

struct PackRound: Codable, Hashable {
    let round: Int
    let questions: [PackQuestion]
}

struct QuestionPack: Codable {
    let version: Int
    let rounds: [PackRound]
}

/// Loads the bundled pack and lays the day's candidates out in the order the date decides.
///
/// It used to pick the round with `dayNumber % rounds.count`, which meant day 31 dealt round 1's
/// ten questions back in the same order, forever. Nothing here cycles now: the date fixes the
/// order the whole pack is considered in, and `Desk` chooses the ten from it by what she has
/// already read and what keeps getting past her. The rounds in the JSON are how the pack was
/// written and checked, not how it is served.
enum DailyPack {
    /// Day 0 of the schedule. Editions are numbered from here.
    static let epoch = DateComponents(year: 2026, month: 1, day: 1)

    static let shared: QuestionPack = load()

    /// Every question in the pack, flat, in the order it was written.
    static let all: [QuizItem] = shared.rounds.flatMap { $0.questions.map(\.item) }

    static let byID: [String: QuizItem] = Dictionary(all.map { ($0.id, $0) },
                                                     uniquingKeysWith: { first, _ in first })

    private static func load() -> QuestionPack {
        guard let url = Bundle.main.url(forResource: "questions", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let pack = try? JSONDecoder().decode(QuestionPack.self, from: data),
              !pack.rounds.isEmpty
        else {
            assertionFailure("questions.json is missing or unreadable")
            return QuestionPack(version: 0, rounds: [])
        }
        return pack
    }

    /// Whole days between the schedule epoch and the given date, in the user's calendar.
    static func dayNumber(for date: Date, calendar: Calendar = .current) -> Int {
        guard let start = calendar.date(from: epoch) else { return 0 }
        let from = calendar.startOfDay(for: start)
        let to = calendar.startOfDay(for: date)
        return calendar.dateComponents([.day], from: from, to: to).day ?? 0
    }

    /// The whole pack in the order this date considers it. Deterministic — the same date lays
    /// the same slate out for everyone — and a different order every day, so no two editions
    /// start from the same end of the pack.
    static func slate(for date: Date, calendar: Calendar = .current) -> [QuizItem] {
        let day = dayNumber(for: date, calendar: calendar)
        if let cached = slateCache.value, cached.day == day { return cached.items }
        var items = all
        SeededShuffle.apply(&items, seed: UInt64(bitPattern: Int64(day)) &* 0x9E37_79B9_7F4A_7C15 &+ 0x51A7_1DA7)
        slateCache.value = (day, items)
        return items
    }

    /// Shuffling four hundred questions is cheap, but the selector asks for the slate once per
    /// difficulty, so hold the last one.
    private static let slateCache = Cache<(day: Int, items: [QuizItem])>()

    /// The edition's number, counting from the epoch. It only ever goes up: there is no round 1
    /// to come back to.
    static func editionNumber(for date: Date, calendar: Calendar = .current) -> Int {
        max(1, dayNumber(for: date, calendar: calendar) + 1)
    }

    /// Distinct categories in a set of questions, in the order they are asked. The section line
    /// on Today prints these, so it describes the edition she is about to read rather than a
    /// round from a list.
    static func categories(in items: [QuizItem]) -> [String] {
        var seen = Set<String>()
        return items.compactMap { item in
            seen.insert(item.category).inserted ? item.category : nil
        }
    }
}

/// A one-slot box, so a `static let` can memoise without a global var warning.
final class Cache<Value>: @unchecked Sendable {
    private let lock = NSLock()
    private var stored: Value?

    var value: Value? {
        get { lock.withLock { stored } }
        set { lock.withLock { stored = newValue } }
    }
}

// MARK: - Day keys

enum DayKey {
    static let formatter: DateFormatter = {
        let f = DateFormatter()
        f.calendar = Calendar(identifier: .gregorian)
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()

    static func key(for date: Date) -> String { formatter.string(from: date) }
    static func date(from key: String) -> Date? { formatter.date(from: key) }
}

// The share card — the front page as an image, with the text line as its fallback — is in
// ShareEdition.swift.
