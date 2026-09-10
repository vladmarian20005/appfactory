import FactoryKit
import SwiftData
import SwiftUI

@main
struct Tallies: App {
    @StateObject private var store = Store(productIDs: AppInfo.config.productIDs)
    @AppStorage("factory.onboarded") private var onboarded = false

    private let container: ModelContainer

    init() {
        container = Self.makeContainer()
        // Before any view appears, so a seeded counter is already there when the first
        // @Query runs rather than arriving a frame later and animating in under a capture.
        MainActor.assumeIsolated { Self.prepare(container) }
    }

    private static func makeContainer() -> ModelContainer {
        let schema = Schema([Counter.self, Tap.self])
        do {
            return try ModelContainer(for: schema, configurations: ModelConfiguration(schema: schema, isStoredInMemoryOnly: false))
        } catch {
            // A device with no room to write is the only realistic cause. Keep the app usable
            // for the session rather than refusing to launch.
            return try! ModelContainer(for: schema, configurations: ModelConfiguration(schema: schema, isStoredInMemoryOnly: true))
        }
    }

    var body: some Scene {
        WindowGroup {
            Group {
                if onboarded || LaunchOptions.onboarded {
                    RootView()
                        .environmentObject(store)
                        .factoryReviewPrompt(afterSessions: 3)
                } else {
                    OnboardingView(pages: AppInfo.onboarding) { onboarded = true }
                }
            }
        }
        .modelContainer(container)
    }

    /// Screenshot and QA support only: three counters with a fortnight of plausible taps, so
    /// the cards, the chart and the history screen all have something real to draw.
    @MainActor
    private static func prepare(_ container: ModelContainer) {
        let context = container.mainContext
        if LaunchOptions.resetData {
            for counter in (try? context.fetch(FetchDescriptor<Counter>())) ?? [] { context.delete(counter) }
            for entry in (try? context.fetch(FetchDescriptor<Tap>())) ?? [] { context.delete(entry) }
            try? context.save()
        }
        guard LaunchOptions.sampleData else { return }
        guard ((try? context.fetch(FetchDescriptor<Counter>())) ?? []).isEmpty else { return }

        // Fixed counts, not random ones: two runs of the screenshot pass have to produce the
        // same chart or every capture looks like a change.
        let seed: [(name: String, color: String, goal: Int, days: [Int])] = [
            ("Glasses of water", "ocean", 8, [7, 8, 6, 8, 5, 9, 7, 8, 6, 7, 8, 4, 9, 6]),
            ("Push-ups", "tangerine", 30, [30, 25, 0, 30, 32, 28, 30, 0, 26, 30, 30, 24, 31, 18]),
            ("Coffees", "slate", 0, [3, 2, 3, 4, 2, 1, 3, 3, 2, 4, 3, 2, 3, 2]),
        ]

        let calendar = Calendar.current
        let today = calendar.startOfDay(for: .now)
        for (index, spec) in seed.enumerated() {
            let counter = Counter(name: spec.name,
                                  colorID: spec.color,
                                  dailyGoal: spec.goal,
                                  createdAt: calendar.date(byAdding: .day, value: -20 + index, to: today) ?? today)
            context.insert(counter)
            // days is oldest-first; the last element is today.
            for (offset, count) in spec.days.enumerated() where count > 0 {
                let dayStart = calendar.date(byAdding: .day, value: -(spec.days.count - 1 - offset), to: today) ?? today
                // Spread the taps evenly across a window that has actually happened, so the
                // history list reads like use. Clamping each tap to `now` instead stacked
                // every one of today's onto the same minute, which looks like a bug.
                let (open, close) = window(for: dayStart, today: today, calendar: calendar)
                for tap in 0..<count {
                    let fraction = count == 1 ? 0.5 : Double(tap) / Double(count - 1)
                    let at = open.addingTimeInterval(close.timeIntervalSince(open) * fraction)
                    context.insert(Tap(delta: 1, at: at, counter: counter))
                }
            }
        }
        try? context.save()
    }

    /// The stretch of a day the seeded taps are spread over. A past day gets 8am to 10pm; the
    /// current day gets the last six hours up to now, so no seeded tap is in the future and
    /// the run still has a window wide enough to give every tap its own minute.
    private static func window(for dayStart: Date, today: Date, calendar: Calendar) -> (open: Date, close: Date) {
        guard dayStart >= today else {
            let open = calendar.date(byAdding: .hour, value: 8, to: dayStart) ?? dayStart
            let close = calendar.date(byAdding: .hour, value: 22, to: dayStart) ?? dayStart
            return (open, close)
        }
        let now = Date.now
        let open = max(dayStart, calendar.date(byAdding: .hour, value: -6, to: now) ?? dayStart)
        return (open, max(open.addingTimeInterval(60), now))
    }
}
