import FactoryKit
import SwiftData
import SwiftUI

@main
struct Tidepour: App {
    @StateObject private var store = Store(productIDs: AppInfo.config.productIDs)
    @AppStorage("factory.onboarded") private var onboarded = false

    private let container: ModelContainer

    init() {
        container = Self.makeContainer()
        // Before any view appears, so a seeded history cannot race the first read of it.
        MainActor.assumeIsolated { Self.prepare(container) }
    }

    private static func makeContainer() -> ModelContainer {
        let schema = Schema([LevelResult.self])
        do {
            return try ModelContainer(for: schema,
                                      configurations: ModelConfiguration(schema: schema, isStoredInMemoryOnly: false))
        } catch {
            // A device with no room to write is the only realistic cause. Keep the app
            // playable for the session rather than refusing to launch.
            return try! ModelContainer(for: schema,
                                       configurations: ModelConfiguration(schema: schema, isStoredInMemoryOnly: true))
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
                    OnboardingView(pages: AppInfo.onboarding,
                                   nextTitle: "Go on",
                                   finishTitle: "Start pouring") { onboarded = true }
                }
            }
            // The shore, from the very first screen: onboarding is already on it.
            .brand(AppBrand.brand)
        }
        .modelContainer(container)
    }

    /// `-reset` and `-sampleData`, for the screenshot and QA tooling. Neither runs on a
    /// launch from the Home screen.
    @MainActor
    private static func prepare(_ container: ModelContainer) {
        let context = container.mainContext
        let defaults = UserDefaults.standard

        if LaunchOptions.resetData {
            for result in (try? context.fetch(FetchDescriptor<LevelResult>())) ?? [] {
                context.delete(result)
            }
            try? context.save()
            GameModel.eraseSavedBoards()
            defaults.removeObject(forKey: "tidepour.currentLevel")
            defaults.removeObject(forKey: "tidepour.highestCleared")
        }

        if LaunchOptions.calm { defaults.set(true, forKey: "tidepour.calmMode") }
        if LaunchOptions.accessiblePalette {
            defaults.set(true, forKey: "tidepour.accessiblePalette")
            defaults.set(true, forKey: "tidepour.shapeMarkers")
        }

        guard LaunchOptions.sampleData else { return }
        guard ((try? context.fetch(FetchDescriptor<LevelResult>())) ?? []).isEmpty else { return }

        let calendar = Calendar.current
        // Eighteen days back with two missing. Streaks break, and a seeded calendar with no
        // break in it is a calendar nobody believes.
        for offset in 0..<18 where offset != 9 && offset != 10 {
            guard let date = calendar.date(byAdding: .day, value: -offset, to: .now) else { continue }
            let key = DayKey.key(for: date)
            let par = 18 + offset % 5
            context.insert(LevelResult(key: "daily.\(key)",
                                       number: nil,
                                       dayKey: key,
                                       moves: par + (offset % 4),
                                       par: par,
                                       clearedAt: date))
        }
        for level in 1...27 {
            // Kept inside the last week so the levels do not paper over the gap above.
            guard let date = calendar.date(byAdding: .day, value: -(level % 6), to: .now) else { continue }
            let par = LevelGenerator.parBar(forLevel: level,
                                            colors: LevelGenerator.colorCount(forLevel: level))
            context.insert(LevelResult(key: "level.\(level)",
                                       number: level,
                                       dayKey: DayKey.key(for: date),
                                       moves: par + (level % 5),
                                       par: par,
                                       clearedAt: date))
        }
        try? context.save()
        defaults.set(28, forKey: "tidepour.currentLevel")
        defaults.set(27, forKey: "tidepour.highestCleared")
    }
}
