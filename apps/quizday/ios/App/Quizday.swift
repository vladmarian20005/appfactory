import FactoryKit
import SwiftData
import SwiftUI

@main
struct Quizday: App {
    @StateObject private var store = Store(productIDs: AppInfo.config.productIDs)
    @AppStorage("factory.onboarded") private var onboarded = false

    private let container: ModelContainer

    init() {
        container = Self.makeContainer()
        // Runs before any view appears. Doing this in a .task raced with TodayView's
        // onAppear, which could wipe a result the view had just written.
        MainActor.assumeIsolated { Self.prepare(container) }
    }

    private static func makeContainer() -> ModelContainer {
        let schema = Schema([DayResult.self, CategoryStat.self, QuestionReport.self])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        do {
            return try ModelContainer(for: schema, configurations: configuration)
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
                } else {
                    OnboardingView(pages: AppInfo.onboarding) { onboarded = true }
                }
            }
            // On both, so the very first screen is already the paper.
            .brand(AppBrand.brand)
        }
        .modelContainer(container)
    }

    /// Screenshot and QA support only: fills a month of plausible history so the calendar
    /// and streak have something to show.
    @MainActor
    private static func prepare(_ container: ModelContainer) {
        let context = container.mainContext
        if LaunchOptions.resetData {
            for result in (try? context.fetch(FetchDescriptor<DayResult>())) ?? [] { context.delete(result) }
            for stat in (try? context.fetch(FetchDescriptor<CategoryStat>())) ?? [] { context.delete(stat) }
            for report in (try? context.fetch(FetchDescriptor<QuestionReport>())) ?? [] { context.delete(report) }
            try? context.save()
        }
        guard LaunchOptions.sampleData else { return }
        let existing = (try? context.fetch(FetchDescriptor<DayResult>())) ?? []
        guard existing.isEmpty else { return }

        let calendar = Calendar.current
        let scores = [9, 7, 10, 6, 8, 8, 5, 9, 7, 10, 8, 6, 9, 7, 8, 10, 4, 9, 8, 7]
        for (offset, score) in scores.enumerated() {
            // A gap at day 13 keeps the calendar honest: streaks do break.
            guard offset != 13 else { continue }
            guard let date = calendar.date(byAdding: .day, value: -(offset + 1), to: .now) else { continue }
            var flags = Array(repeating: true, count: score) + Array(repeating: false, count: 10 - score)
            // Seeded, not `shuffle()`: two captures of the same launch flags used to show
            // different squares, which makes a screenshot diff meaningless.
            SeededShuffle.apply(&flags, seed: UInt64(offset) &+ 11)
            context.insert(DayResult(dayKey: DayKey.key(for: date),
                                     roundNumber: DailyPack.roundNumber(for: date),
                                     flags: flags,
                                     playedAt: date))
        }
        let seeded: [(String, Int, Int)] = [
            ("Geography", 42, 35), ("Science", 40, 29), ("Nature", 31, 26), ("History", 22, 14),
            ("Art & Literature", 20, 15), ("Music", 18, 11), ("Sport", 16, 9), ("Food & Drink", 14, 12),
        ]
        for (category, asked, correct) in seeded {
            context.insert(CategoryStat(category: category, asked: asked, correct: correct))
        }
        try? context.save()
    }
}
