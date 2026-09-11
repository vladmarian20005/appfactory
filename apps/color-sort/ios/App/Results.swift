import Foundation
import SwiftData

/// One finished puzzle. The row is keyed by the puzzle, not by the attempt, so beating a
/// level again in fewer moves improves the record instead of adding noise to it.
@Model
final class LevelResult {
    /// `level.12` or `daily.2026-09-11`.
    @Attribute(.unique) var key: String
    /// The level number, or nil for a daily puzzle.
    var number: Int?
    /// The day it was cleared on, `yyyy-MM-dd`. What the calendar and the streak count.
    var dayKey: String
    var moves: Int
    var par: Int
    var clearedAt: Date

    init(key: String, number: Int?, dayKey: String, moves: Int, par: Int, clearedAt: Date = .now) {
        self.key = key
        self.number = number
        self.dayKey = dayKey
        self.moves = moves
        self.par = par
        self.clearedAt = clearedAt
    }

    var isDaily: Bool { number == nil }

    static func key(for id: LevelID) -> String {
        switch id {
        case .numbered(let n): return "level.\(n)"
        case .daily(let day): return "daily.\(day)"
        }
    }
}

/// Turns a set of days played into the two numbers the Progress screen shows.
///
/// Derived rather than stored: a counter that is incremented by hand drifts the first time a
/// write is lost, and a streak that is wrong is worse than no streak at all.
enum Streaks {
    static func current(days: Set<String>, today: Date = .now, calendar: Calendar = .current) -> Int {
        let todayKey = DayKey.key(for: today, calendar: calendar)
        // A day that has not been played yet must not break the streak until it is over.
        var cursor = days.contains(todayKey)
            ? today
            : calendar.date(byAdding: .day, value: -1, to: today) ?? today
        if !days.contains(DayKey.key(for: cursor, calendar: calendar)) { return 0 }
        var run = 0
        while days.contains(DayKey.key(for: cursor, calendar: calendar)) {
            run += 1
            guard let previous = calendar.date(byAdding: .day, value: -1, to: cursor) else { break }
            cursor = previous
        }
        return run
    }

    static func longest(days: Set<String>, calendar: Calendar = .current) -> Int {
        let dates = days.compactMap { DayKey.date(from: $0, calendar: calendar) }.sorted()
        guard !dates.isEmpty else { return 0 }
        var best = 1
        var run = 1
        for i in 1..<dates.count {
            let gap = calendar.dateComponents([.day], from: dates[i - 1], to: dates[i]).day ?? 0
            run = gap == 1 ? run + 1 : 1
            best = max(best, run)
        }
        return best
    }
}
