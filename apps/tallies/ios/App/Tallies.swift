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
            for (offset, count) in spec.days.enumerated() {
                let dayStart = calendar.date(byAdding: .day, value: -(spec.days.count - 1 - offset), to: today) ?? today
                for tap in 0..<count {
                    // Spread the taps across the waking day so the history list reads like use.
                    let at = calendar.date(byAdding: .minute, value: 8 * 60 + tap * 37, to: dayStart) ?? dayStart
                    context.insert(Tap(delta: 1, at: min(at, .now), counter: counter))
                }
            }
        }
        try? context.save()
    }
}
