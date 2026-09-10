import FactoryKit
import SwiftData
import SwiftUI

/// A thing the user counts. Its value is not stored: it is the sum of its entries, so the
/// number on the card and the bars on the detail screen can never disagree.
@Model
final class Counter {
    var name: String = ""
    /// A `CounterPalette` id. A name rather than a colour so the store stays portable.
    var colorID: String = CounterPalette.default.id
    /// Taps wanted per day. Zero means no goal, which is the default.
    var dailyGoal: Int = 0
    var createdAt: Date = Date.now

    @Relationship(deleteRule: .cascade, inverse: \Tap.counter)
    var entries: [Tap] = []

    init(name: String, colorID: String = CounterPalette.default.id, dailyGoal: Int = 0, createdAt: Date = .now) {
        self.name = name
        self.colorID = colorID
        self.dailyGoal = dailyGoal
        self.createdAt = createdAt
    }

    var swatch: CounterPalette { CounterPalette.named(colorID) }

    var total: Int { entries.reduce(0) { $0 + $1.delta } }

    func total(since date: Date) -> Int {
        entries.reduce(0) { $0 + ($1.at >= date ? $1.delta : 0) }
    }

    var todayTotal: Int { total(since: Calendar.current.startOfDay(for: .now)) }

    /// Daily sums for the last `days` days, oldest first. Days with no entries are kept as
    /// zeroes so the chart shows a gap rather than silently closing it up.
    func dailyTotals(days: Int, calendar: Calendar = .current) -> [DayTotal] {
        let today = calendar.startOfDay(for: .now)
        var buckets: [Date: Int] = [:]
        for entry in entries {
            let day = calendar.startOfDay(for: entry.at)
            buckets[day, default: 0] += entry.delta
        }
        return (0..<days).reversed().compactMap { offset in
            guard let day = calendar.date(byAdding: .day, value: -offset, to: today) else { return nil }
            return DayTotal(day: day, count: max(0, buckets[day] ?? 0))
        }
    }
}

/// One tap. Kept individually rather than as a running number because the history screen and
/// the chart both need to know *when*, not just how many.
///
/// Named `Tap` and not `Entry`: SwiftUI exports an `Entry()` macro, and a model type of that
/// name resolves to the macro instead, with errors that point everywhere but here.
@Model
final class Tap {
    /// +1 for a tap up, -1 for a tap down.
    var delta: Int = 1
    var at: Date = Date.now
    var counter: Counter?

    init(delta: Int, at: Date = .now, counter: Counter? = nil) {
        self.delta = delta
        self.at = at
        self.counter = counter
    }
}

struct DayTotal: Identifiable, Hashable {
    let day: Date
    let count: Int
    var id: Date { day }
}

/// The fixed palette a new counter picks from. Fixed rather than a colour well so every
/// counter stays legible on both appearances and in a screenshot.
struct CounterPalette: Identifiable, Hashable {
    let id: String
    let label: String
    let color: Color

    static let all: [CounterPalette] = [
        CounterPalette(id: "tangerine", label: "Tangerine", color: Color(red: 0.90, green: 0.45, blue: 0.13)),
        CounterPalette(id: "ocean", label: "Ocean", color: Color(red: 0.13, green: 0.47, blue: 0.83)),
        CounterPalette(id: "forest", label: "Forest", color: Color(red: 0.13, green: 0.58, blue: 0.40)),
        CounterPalette(id: "grape", label: "Grape", color: Color(red: 0.49, green: 0.33, blue: 0.83)),
        CounterPalette(id: "rose", label: "Rose", color: Color(red: 0.85, green: 0.27, blue: 0.44)),
        CounterPalette(id: "slate", label: "Slate", color: Color(red: 0.35, green: 0.40, blue: 0.48)),
    ]

    static var `default`: CounterPalette { all[0] }

    static func named(_ id: String) -> CounterPalette {
        all.first { $0.id == id } ?? .default
    }
}

extension Store {
    /// Pro from a real entitlement, or forced by `-pro` so QA and the screenshot pass can
    /// reach the Pro screens without a purchase no runner can make.
    var isProUnlocked: Bool { isPro || LaunchOptions.forcePro }
}
