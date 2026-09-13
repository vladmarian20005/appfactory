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
        // Before any view appears, so a seeded record is already there when the first @Query
        // runs rather than arriving a frame later and animating in under a capture.
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
                    OnboardingView(pages: AppInfo.onboarding,
                                   nextTitle: AppInfo.onboardingNext,
                                   finishTitle: AppInfo.onboardingFinish) { onboarded = true }
                }
            }
            .brand(AppBrand.brand)
        }
        .modelContainer(container)
    }

    /// Screenshot and QA support only: a bench with a real record on it.
    ///
    /// `-days n` says how deep — five days, fifty, five hundred — which is the only way
    /// anything downstream can photograph a first sitting next to one half a year in. The
    /// seed is deterministic, so two runs of the screenshot pass draw the same strip, the
    /// same rack and the same reading.
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

        let daysKept = max(1, LaunchOptions.days ?? 61)
        // Where the leading stave should end up, so a `-demo` flag has somewhere to go: three
        // short of scored for the win, and mid-gate for the cut.
        let landOn: Int = {
            // `-screen win` takes the fiftieth cut itself rather than being posed as one, so
            // the headline, the count, the rack and the sitting card in that capture are all
            // true of the same record.
            if LaunchOptions.screen == "win" { return notchesPerStave - 1 }
            switch LaunchOptions.demo {
            case "score": return notchesPerStave - 3
            case "cut": return 36
            // Far enough into a stave that the shoulder reads as filling and the next gate is
            // in sight. An almost-bare stave photographs as an empty board.
            default: return 38
            }
        }()

        let calendar = Calendar.current
        let today = calendar.startOfDay(for: .now)

        let staves: [(name: String, pigment: String, goal: Int, perDay: Int, seed: UInt64)] = [
            ("Pull-ups", "keel", 12, 8, 0x9E37_7A11),
            ("Glasses of water", "chalk", 8, 6, 0x1234_5678),
            ("Cars past the window", "graphite", 0, 4, 0xABCD_1234),
        ]

        for (index, spec) in staves.enumerated() {
            // Only the first stave carries the whole record; the other two are shallower, the
            // way a real bench is.
            let depth = index == 0 ? daysKept : min(daysKept, 24)
            let counter = Counter(name: spec.name,
                                  colorID: spec.pigment,
                                  dailyGoal: spec.goal,
                                  createdAt: calendar.date(byAdding: .day, value: -depth, to: today) ?? today)
            context.insert(counter)

            var rng = Seeded(seed: spec.seed)
            var counts: [Int] = []
            for offset in (0..<depth).reversed() {
                guard let day = calendar.date(byAdding: .day, value: -offset, to: today) else { continue }
                // Thursdays run above the rest, which is what the weekday reading is for, and
                // it has to be true in the record before the carver will say it.
                let weekday = calendar.component(.weekday, from: day)
                let lift = weekday == 5 ? 1.6 : 1.0
                // A gap is a gap in the strip, not an accusation — and a long record needs a
                // few for the quiet reading to have anything to say.
                let quiet = depth > 30 && offset > 2 && rng.unit() < 0.07
                let base = Double(spec.perDay) * lift * (0.7 + rng.unit() * 0.6)
                counts.append(quiet ? 0 : max(1, Int(base.rounded())))
            }

            // A short record is left exactly as it fell: the first rung of the ladder strip
            // has to be an honest first week, not one bent to land on a round number.
            if index == 0, counts.count >= 20 {
                // Land the leading stave exactly where the demo needs it, by adding one cut
                // to each of a run of days rather than piling the whole correction onto today.
                // Today at eighty-seven against a goal of twelve is not a record anybody has,
                // and it flattened the strip and saturated the gauge in one go.
                let need = (((landOn - counts.reduce(0, +)) % notchesPerStave) + notchesPerStave) % notchesPerStave
                for step in 0..<need {
                    counts[(counts.count / 3 + step) % counts.count] += 1
                }
            }

            for (position, count) in counts.enumerated() where count > 0 {
                let offset = counts.count - 1 - position
                let dayStart = calendar.date(byAdding: .day, value: -offset, to: today) ?? today
                let (open, close) = window(for: dayStart, today: today, calendar: calendar)
                // The last few of today land inside the sitting window, so the face opens on
                // a sitting in progress rather than on a bench nobody has touched.
                let inSitting = offset == 0 ? min(count - 1, 6) : 0
                for tap in 0..<count {
                    let at: Date
                    if tap >= count - inSitting {
                        let step = Double(count - tap)
                        at = Date.now.addingTimeInterval(-12 * step)
                    } else {
                        let spread = max(1, count - inSitting)
                        let fraction = spread == 1 ? 0.5 : Double(tap) / Double(spread - 1)
                        at = open.addingTimeInterval(close.timeIntervalSince(open) * fraction)
                    }
                    context.insert(Tap(delta: 1, at: at, counter: counter))
                }
                // A wax every so often, so an honest stave has a few and the clean reading
                // has something to count from.
                if index == 0, offset > 0, offset % 17 == 3 {
                    context.insert(Tap(delta: -1, at: close.addingTimeInterval(30), counter: counter))
                }
            }
        }
        try? context.save()
    }

    /// The stretch of a day the seeded cuts are spread over. A past day gets 8am to 10pm; the
    /// current day gets the last six hours up to now, so no seeded cut is in the future and
    /// the run still has a window wide enough to give every one its own minute — and the last
    /// few land inside the sitting window, so the face opens on a sitting in progress.
    private static func window(for dayStart: Date, today: Date, calendar: Calendar) -> (open: Date, close: Date) {
        guard dayStart >= today else {
            let open = calendar.date(byAdding: .hour, value: 8, to: dayStart) ?? dayStart
            let close = calendar.date(byAdding: .hour, value: 22, to: dayStart) ?? dayStart
            return (open, close)
        }
        let now = Date.now
        let open = max(dayStart, calendar.date(byAdding: .hour, value: -6, to: now) ?? dayStart)
        return (open, max(open.addingTimeInterval(60), now.addingTimeInterval(-20)))
    }
}
