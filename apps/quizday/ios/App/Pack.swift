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

/// Loads the bundled pack and decides which round belongs to which calendar day.
///
/// The round is a pure function of the local date, so every player who opens the app
/// on the same day gets the same ten questions with no server involved.
enum DailyPack {
    /// Day 0 of the schedule. Rounds cycle from here.
    static let epoch = DateComponents(year: 2026, month: 1, day: 1)

    static let shared: QuestionPack = load()

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

    /// Zero-based index into `rounds` for the given date.
    static func roundIndex(for date: Date, calendar: Calendar = .current) -> Int {
        let count = shared.rounds.count
        guard count > 0 else { return 0 }
        let n = dayNumber(for: date, calendar: calendar)
        return ((n % count) + count) % count
    }

    static func round(for date: Date, calendar: Calendar = .current) -> PackRound? {
        let rounds = shared.rounds
        guard !rounds.isEmpty else { return nil }
        return rounds[roundIndex(for: date, calendar: calendar)]
    }

    static func items(for date: Date, calendar: Calendar = .current) -> [QuizItem] {
        round(for: date, calendar: calendar)?.questions.map(\.item) ?? []
    }

    /// Human round number shown in the app, counting from 1.
    static func roundNumber(for date: Date, calendar: Calendar = .current) -> Int {
        (round(for: date, calendar: calendar)?.round) ?? 1
    }

    /// Distinct categories in the given day's round, in the order they are asked.
    static func categories(for date: Date, calendar: Calendar = .current) -> [String] {
        var seen = Set<String>()
        return items(for: date, calendar: calendar).compactMap { item in
            seen.insert(item.category).inserted ? item.category : nil
        }
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
