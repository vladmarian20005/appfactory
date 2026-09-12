import Foundation
import SwiftData
import SwiftUI

/// How a tile came out of the kiln this time.
enum Grade: Int, CaseIterable {
    /// Back to the bench, unglazed. Never an error, never red.
    case again = 0
    case good = 1
    case easy = 2
}

/// How far a word has got. It is the tile's finish on the wall, not a score.
enum Firing {
    /// Raw clay: never turned over.
    case bare
    /// On the bench: turned at least once, not yet fired three times clean.
    case drying
    /// Glazed, in the wall, and it cannot go back to bare.
    case set
}

/// One word's place in the schedule. The only thing this app writes down.
@Model
final class CardState {
    var rank: Int = 0
    var due: Date = Date()
    /// Days until the word comes back. 0 while it is still on the bench.
    var intervalDays: Double = 0
    /// SM-2's ease factor: how fast this particular word's interval grows.
    var ease: Double = 2.5
    var reps: Int = 0
    var lapses: Int = 0
    /// Clean firings in a row. Three and the tile is glazed for good.
    var streak: Int = 0
    /// When the tile last went into the wall, which is what draws the day's amber mortar.
    var lastSet: Date?

    init(rank: Int, due: Date = Date()) {
        self.rank = rank
        self.due = due
    }

    var firing: Firing {
        if streak >= 3 { return .set }
        return reps > 0 ? .drying : .bare
    }
}

/// Everything the app knows about the wall: what is set, what is drying, what is due, and what
/// happens to a tile when the setter says how it went.
///
/// The whole thousand fits in memory several times over, so this holds every card state and
/// writes through to SwiftData rather than asking the store a question per tile.
@MainActor
final class Library: ObservableObject {
    /// New words introduced in one day. A session is due work plus this many first firings —
    /// never padding, so a swept bench stays swept.
    static let newPerDay = 12
    /// Three clean firings and a word is in the wall.
    static let firingsToSet = 3

    private let container: ModelContainer
    private let context: ModelContext
    @Published private(set) var states: [Int: CardState] = [:]
    /// Bumped whenever the wall changes, so views that draw a thousand tiles redraw once.
    @Published private(set) var revision = 0

    private let defaults = UserDefaults.standard
    private let introducedDayKey = "thousand.introduced.day"
    private let introducedCountKey = "thousand.introduced.count"

    init() {
        let schema = Schema([CardState.self])
        // A store that cannot open must not be the reason a language app will not start: fall
        // back to memory, where the app still works for the session it is in.
        if let disk = try? ModelContainer(for: schema) {
            container = disk
        } else {
            // swiftlint:disable:next force_try
            container = try! ModelContainer(for: schema,
                                            configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        }
        context = ModelContext(container)
        reload()

        if LaunchOptions.resetData { wipe() }
        if LaunchOptions.sampleData { seedSample() }
    }

    private func reload() {
        let rows = (try? context.fetch(FetchDescriptor<CardState>())) ?? []
        states = Dictionary(rows.map { ($0.rank, $0) }, uniquingKeysWith: { a, _ in a })
    }

    private func save() {
        try? context.save()
        revision &+= 1
    }

    // MARK: - Reading the wall

    func state(_ rank: Int) -> CardState? { states[rank] }

    func firing(_ word: Word) -> Firing { states[word.rank]?.firing ?? .bare }

    var setCount: Int { states.values.filter { $0.firing == .set }.count }
    var dryingCount: Int { states.values.filter { $0.firing == .drying }.count }

    /// Tiles that went into the wall today. They keep an amber mortar ring until midnight.
    var setToday: Set<Int> {
        let day = Calendar.current.startOfDay(for: Date())
        return Set(states.values.filter { st in
            guard st.firing == .set, let last = st.lastSet else { return false }
            return last >= day
        }.map(\.rank))
    }

    func setCount(theme: Int) -> Int {
        Deck.panel(theme).filter { firing($0) == .set }.count
    }

    /// Themes with at least one tile in the wall, longest first — what the Progress bars draw.
    var panelsStanding: Int {
        (0..<Deck.themes.count).filter { setCount(theme: $0) > 0 }.count
    }

    func dueCount(on day: Date, pro: Bool) -> Int {
        let cal = Calendar.current
        let start = cal.startOfDay(for: day)
        guard let end = cal.date(byAdding: .day, value: 1, to: start) else { return 0 }
        return pool(pro: pro).filter { word in
            guard let st = states[word.rank] else { return false }
            return st.due < end && st.due >= start
        }.count
    }

    /// Everything ready now, including anything overdue from an earlier day.
    func dueNow(pro: Bool) -> [Word] {
        let now = Date()
        return pool(pro: pro)
            .filter { states[$0.rank].map { $0.due <= now } ?? false }
            .sorted { (states[$0.rank]?.due ?? now) < (states[$1.rank]?.due ?? now) }
    }

    func readyTomorrow(pro: Bool) -> Int {
        guard let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Date()) else { return 0 }
        return dueCount(on: tomorrow, pro: pro)
    }

    private func pool(pro: Bool) -> [Word] {
        pro ? Deck.words : Deck.freeWords
    }

    // MARK: - Building a session

    /// Today's remaining allowance of words never seen before.
    func newAllowance() -> Int {
        let day = Calendar.current.startOfDay(for: Date())
        let stored = defaults.object(forKey: introducedDayKey) as? Date
        if stored != day { return Self.newPerDay }
        return max(0, Self.newPerDay - defaults.integer(forKey: introducedCountKey))
    }

    private func countIntroduction() {
        let day = Calendar.current.startOfDay(for: Date())
        if defaults.object(forKey: introducedDayKey) as? Date != day {
            defaults.set(day, forKey: introducedDayKey)
            defaults.set(0, forKey: introducedCountKey)
        }
        defaults.set(defaults.integer(forKey: introducedCountKey) + 1, forKey: introducedCountKey)
    }

    /// The tiles waiting on the bench: what is due, then as many first firings as the day has
    /// left. Nothing is invented to make the number look better.
    func plannedSession(pro: Bool) -> [Word] {
        let due = dueNow(pro: pro)
        let unseen = pool(pro: pro).filter { states[$0.rank] == nil }.prefix(newAllowance())
        return due + unseen
    }

    // MARK: - Writing

    /// Records how a firing went and returns whether the word reached the wall on this turn.
    @discardableResult
    func record(_ word: Word, _ grade: Grade) -> Bool {
        let now = Date()
        let existing = states[word.rank]
        if existing == nil { countIntroduction() }
        let card = existing ?? make(word.rank)
        let wasSet = card.firing == .set

        switch grade {
        case .again:
            card.lapses += 1
            card.streak = 0
            card.intervalDays = 0
            card.due = now.addingTimeInterval(600)
        case .good:
            card.streak += 1
            card.intervalDays = card.reps == 0 ? 1 : max(1, card.intervalDays * card.ease)
            card.due = now.addingTimeInterval(card.intervalDays * 86_400)
        case .easy:
            card.streak += 1
            card.ease = min(2.9, card.ease + 0.15)
            card.intervalDays = card.reps == 0 ? 3 : max(3, card.intervalDays * card.ease * 1.3)
            card.due = now.addingTimeInterval(card.intervalDays * 86_400)
        }
        card.reps += 1
        if grade != .again { card.lastSet = now }
        save()
        return !wasSet && card.firing == .set
    }

    /// "Set it now": a word fetched off the wall deliberately, which is the only way the app
    /// ever adds work to a bench that is otherwise swept.
    func summon(_ word: Word) {
        let card = states[word.rank] ?? make(word.rank)
        card.due = Date()
        summons &+= 1
        save()
    }

    /// Bumped by `summon`, so the bench knows to build its session again.
    @Published private(set) var summons = 0

    private func make(_ rank: Int) -> CardState {
        let card = CardState(rank: rank)
        context.insert(card)
        states[rank] = card
        return card
    }

    // MARK: - The tooling's launch flags

    /// Settings' "Take the wall down". The wall only ever existed on this phone, so this is
    /// the whole of it.
    func eraseEverything() {
        wipe()
        UserDefaults.standard.removeObject(forKey: "thousand.turnedOne")
    }

    private func wipe() {
        for card in states.values { context.delete(card) }
        states = [:]
        defaults.removeObject(forKey: introducedDayKey)
        defaults.removeObject(forKey: introducedCountKey)
        save()
    }

    /// A believable wall, because nothing on a runner can drill for a fortnight: the early
    /// ranks glazed and in courses, a band behind them still drying, and a session waiting.
    private func seedSample() {
        wipe()
        let now = Date()
        let target = min(213, max(12, Deck.total - Deck.total / 4))
        var glazed = 0
        for word in Deck.words {
            // Set tiles cluster at the front of each panel, the way a wall is laid course by
            // course, with a few gaps where a word did not take.
            let awkward = word.rank % 7 == 3
            if glazed < target, !awkward {
                let card = make(word.rank)
                card.streak = Self.firingsToSet + word.rank % 2
                card.reps = card.streak + word.rank % 3
                card.ease = 2.4 + Double(word.rank % 5) * 0.05
                card.intervalDays = Double(4 + word.rank % 21)
                // A real session is mostly words already in the wall coming round again, so
                // about one set tile in six is ready now.
                card.due = word.rank % 6 == 4
                    ? now.addingTimeInterval(-Double(word.rank % 900))
                    : now.addingTimeInterval(card.intervalDays * 86_400)
                // Two dozen of them went in today, which is what the amber mortar shows.
                card.lastSet = word.rank % 9 == 1 ? now : now.addingTimeInterval(-Double(2 + word.rank % 20) * 86_400)
                glazed += 1
            } else if glazed < target + 46 {
                let card = make(word.rank)
                card.streak = word.rank % 3
                card.reps = 1 + word.rank % 4
                card.lapses = word.rank % 2
                card.intervalDays = Double(1 + word.rank % 3)
                // Fifteen of them are ready right now; the rest come back over the next days.
                let ready = word.rank % 3 == 0
                card.due = ready
                    ? now.addingTimeInterval(-Double(word.rank % 400))
                    : now.addingTimeInterval(Double(1 + word.rank % 3) * 86_400)
                card.lastSet = now.addingTimeInterval(-Double(1 + word.rank % 6) * 86_400)
                glazed += 1
            } else {
                break
            }
        }
        // The day's new-word allowance is spent, so a sample bench shows review work only and
        // the swept bench stays reachable with -swept.
        defaults.set(Calendar.current.startOfDay(for: now), forKey: introducedDayKey)
        defaults.set(Self.newPerDay, forKey: introducedCountKey)
        save()
    }
}
