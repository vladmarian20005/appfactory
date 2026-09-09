import Foundation
import SwiftData

/// One completed daily round. The day key is the local calendar date, so a result
/// belongs to the day the player actually played it.
@Model
final class DayResult {
    @Attribute(.unique) var dayKey: String
    var roundNumber: Int
    var flags: [Bool]
    var playedAt: Date

    init(dayKey: String, roundNumber: Int, flags: [Bool], playedAt: Date = .now) {
        self.dayKey = dayKey
        self.roundNumber = roundNumber
        self.flags = flags
        self.playedAt = playedAt
    }

    var score: Int { flags.filter { $0 }.count }
    var total: Int { flags.count }
}

/// Running accuracy for one category, counting both daily and practice answers.
@Model
final class CategoryStat {
    @Attribute(.unique) var category: String
    var asked: Int
    var correct: Int

    init(category: String, asked: Int = 0, correct: Int = 0) {
        self.category = category
        self.asked = asked
        self.correct = correct
    }

    var accuracy: Double { asked == 0 ? 0 : Double(correct) / Double(asked) }
}

/// A question the player flagged as wrong or unclear. Kept on device; Settings lists them
/// so the player can send them on from the support page.
@Model
final class QuestionReport {
    @Attribute(.unique) var questionID: String
    var questionText: String
    var reportedAt: Date

    init(questionID: String, questionText: String, reportedAt: Date = .now) {
        self.questionID = questionID
        self.questionText = questionText
        self.reportedAt = reportedAt
    }
}

// MARK: - Streaks

enum Streaks {
    /// Consecutive days played, counting back from today. Yesterday still counts, so a
    /// streak is only lost once a whole day has been missed.
    static func current(from results: [DayResult], today: Date = .now, calendar: Calendar = .current) -> Int {
        let keys = Set(results.map(\.dayKey))
        guard !keys.isEmpty else { return 0 }
        var cursor = calendar.startOfDay(for: today)
        if !keys.contains(DayKey.key(for: cursor)) {
            guard let yesterday = calendar.date(byAdding: .day, value: -1, to: cursor),
                  keys.contains(DayKey.key(for: yesterday)) else { return 0 }
            cursor = yesterday
        }
        var streak = 0
        while keys.contains(DayKey.key(for: cursor)) {
            streak += 1
            guard let previous = calendar.date(byAdding: .day, value: -1, to: cursor) else { break }
            cursor = previous
        }
        return streak
    }

    /// Longest run of consecutive days ever played.
    static func best(from results: [DayResult], calendar: Calendar = .current) -> Int {
        let days = results.compactMap { DayKey.date(from: $0.dayKey) }
            .map { calendar.startOfDay(for: $0) }
            .sorted()
        guard !days.isEmpty else { return 0 }
        var best = 1
        var run = 1
        for i in 1..<days.count {
            let gap = calendar.dateComponents([.day], from: days[i - 1], to: days[i]).day ?? 0
            if gap == 1 {
                run += 1
                best = max(best, run)
            } else if gap > 1 {
                run = 1
            }
        }
        return best
    }
}
