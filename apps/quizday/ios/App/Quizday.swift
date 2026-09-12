import FactoryKit
import SwiftData
import SwiftUI

@main
struct Quizday: App {
    @StateObject private var store = Store(productIDs: AppInfo.config.productIDs)
    /// What the paper has noticed. Everything the app serves is decided here.
    @StateObject private var desk = Desk()
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
                        .environmentObject(desk)
                        .task { seedDesk() }
                } else {
                    OnboardingView(pages: AppInfo.onboarding,
                                   nextTitle: "Turn the page",
                                   finishTitle: "Read today's edition") { onboarded = true }
                }
            }
            // On both, so the very first screen is already the paper.
            .brand(AppBrand.brand)
        }
        .modelContainer(container)
    }

    /// The desk's side of the same seeding: `-reset` clears what it remembers, `-editions N`
    /// replays that many editions through it. Neither runs in a normal launch.
    @MainActor
    private func seedDesk() {
        if let editions = LaunchOptions.editions {
            desk.seed(editions: editions, endingOn: .now)
        } else if LaunchOptions.resetData {
            desk.forget()
        }
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
        // `-editions 200` files that many past editions, so the ladder is read at rung 201 and
        // the doors that open by playing are all open. The scores are seeded, not random: two
        // captures of the same flags have to show the same squares.
        if let editions = LaunchOptions.editions {
            let calendar = Calendar.current
            let existing = Set(((try? context.fetch(FetchDescriptor<DayResult>())) ?? []).map(\.dayKey))
            var rng = PaperRandom(seed: 0xED17_10_45)
            for step in stride(from: editions, through: 1, by: -1) {
                guard let date = calendar.date(byAdding: .day, value: -step, to: .now) else { continue }
                let key = DayKey.key(for: date)
                guard !existing.contains(key) else { continue }
                let score = 4 + Int(rng.unit() * 7)
                var flags = Array(repeating: true, count: min(score, 10))
                    + Array(repeating: false, count: max(0, 10 - score))
                SeededShuffle.apply(&flags, seed: UInt64(step) &+ 29)
                context.insert(DayResult(dayKey: key,
                                         roundNumber: DailyPack.editionNumber(for: date),
                                         flags: flags,
                                         playedAt: date))
            }
            try? context.save()
            return
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
                                     roundNumber: DailyPack.editionNumber(for: date),
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
