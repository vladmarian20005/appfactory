import FactoryKit
import Foundation

/// The night desk: what the paper has noticed about the reader, and what it sets for her next.
///
/// Before this existed the edition was `dayNumber % 30`, so day 31 dealt day 1's ten questions
/// back in the same order forever, and the `difficulty` printed on every sheet was compared by
/// nothing. Three things decide an edition now, and all three read something she has done:
///
/// - `ladder` says how many easy, medium and hard questions the sheet carries. It is keyed on
///   editions filed, so the paper hardens under her as she reads it.
/// - `mastery` says *which* questions: what got past her, what she has never seen, and what she
///   only just held on to. The pool is ordered by the day first — so the edition is still set on
///   a date rather than on a whim — and then by the sections that keep catching her, so her
///   worst section leads.
/// - `earned` says what playing has opened. The late edition is the first door in this app that
///   money cannot buy.
@MainActor
final class Desk: ObservableObject {
    /// The difficulty curve, keyed on editions filed.
    ///
    /// `settled` is how many of the ten are medium or harder; `hard` is how many of those are
    /// hard. Edition 1 sets 4 easy / 4 medium / 2 hard; edition 153 and after sets 1 / 3 / 6.
    /// It stops there, and that is said plainly in DESIGN.md: past 153 the sheet is as hard as
    /// the pack goes, and what keeps changing is which questions — by then the desk is setting
    /// almost entirely from what she has missed, so the paper is her own errata.
    nonisolated static let ladder = Ladder([
        .init("settled", from: 6, by: 1, every: 50, opensAt: 1, ceiling: 9),
        .init("hard", from: 2, by: 1, every: 38, opensAt: 1, ceiling: 6),
    ])

    /// What arrives because she played, not because she paid. The daily edition is free and
    /// always was; these are the doors behind it, and the paywall opens none of them.
    nonisolated static let earned = Earned([
        .init(id: "late",
              title: "The late edition",
              blurb: "The late edition opens at seven — five more, set from what got past you.",
              at: 7),
        .init(id: "longLate",
              title: "The long late edition",
              blurb: "At twenty-five the late edition runs to eight.",
              at: 25),
        .init(id: "ownSection",
              title: "The section of your choosing",
              blurb: "At sixty you pick the section the late edition is set from.",
              at: 60),
    ])

    /// How many questions the late edition carries at this many editions filed.
    nonisolated static func lateEditionCount(filed: Int) -> Int {
        earned.isUnlocked("longLate", at: filed) ? 8 : 5
    }

    // MARK: - What the desk remembers

    @Published private(set) var mastery = Mastery<String>()
    /// The ids of the last few editions, so a question does not come back the morning after.
    @Published private(set) var recent: [String] = []

    private let defaults: UserDefaults
    private static let masteryKey = "quizday.mastery"
    private static let recentKey = "quizday.recent"
    /// Fourteen editions' worth. Long enough that nothing repeats inside a fortnight, short
    /// enough that a reader who has seen the whole pack still gets her weakest back.
    private static let recentDepth = 140

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        load()
    }

    private func load() {
        if let data = defaults.data(forKey: Self.masteryKey),
           let saved = try? JSONDecoder().decode(Mastery<String>.self, from: data) {
            mastery = saved
        }
        recent = defaults.stringArray(forKey: Self.recentKey) ?? []
    }

    /// Set while a seeded history is being replayed, so two hundred editions cost one write
    /// rather than four hundred.
    private var quiet = false

    private func save() {
        guard !quiet else { return }
        if let data = try? JSONEncoder().encode(mastery) {
            defaults.set(data, forKey: Self.masteryKey)
        }
        defaults.set(recent, forKey: Self.recentKey)
    }

    /// Every answer, daily or practice, goes through here. This is the one place the app learns
    /// anything, and it is what makes the next edition different from this one.
    func record(_ id: String, correct: Bool, at date: Date = .now) {
        mastery.record(id, correct: correct, at: date)
        save()
    }

    func served(_ items: [QuizItem]) {
        recent = (items.map(\.id) + recent).prefix(Self.recentDepth).map { $0 }
        save()
    }

    func forget() {
        mastery = Mastery<String>()
        recent = []
        save()
    }

    /// Capture and QA support only: actually play `editions` editions through the desk, so a
    /// screenshot can reach the deep end of the ladder with a real history behind it rather than
    /// a number in a label. It is the only way anyone downstream can see that edition 200 is not
    /// edition 1 — `-editions 200` and the `ladder` strip in qa.json exist for this.
    ///
    /// The reader it invents is weak in three sections and solid elsewhere, so the front page's
    /// closing line has something true to say about what keeps catching her.
    func seed(editions: Int, endingOn date: Date, calendar: Calendar = .current) {
        guard editions > 0 else { return }
        quiet = true
        mastery = Mastery<String>()
        recent = []
        var rng = PaperRandom(seed: 0x0D1E_5CA1_F00D_BEEF)
        let shaky: Set<String> = ["Geography", "Music", "Sport"]
        for step in stride(from: editions, through: 1, by: -1) {
            guard let day = calendar.date(byAdding: .day, value: -step, to: date) else { continue }
            let items = edition(for: day, filed: editions - step)
            for item in items {
                mastery.record(item.id, correct: rng.unit() < (shaky.contains(item.category) ? 0.42 : 0.84), at: day)
            }
            served(items)
        }
        quiet = false
        save()
    }

    // MARK: - Setting the edition

    /// The ten questions for one date, for a reader who has filed `filed` editions.
    ///
    /// The mix comes from the ladder, the choice from mastery, and the sheet still ramps easy to
    /// hard the way a round of ten should read.
    func edition(for date: Date, filed: Int, count: Int = 10) -> [QuizItem] {
        let rung = max(1, filed + 1)
        let chosen = Self.difficulties(at: rung, count: count).flatMap { level, wanted -> [QuizItem] in
            pick(wanted, from: pool(for: date, difficulty: level), avoiding: recent)
        }
        return Self.ramped(chosen)
    }

    /// The late edition: the questions that got past her, whatever their difficulty, newest
    /// misses first. This is the round `CategoryStat` and every wrong answer she has ever given
    /// were quietly accumulating for.
    func lateEdition(for date: Date, filed: Int, section: String? = nil) -> [QuizItem] {
        let wanted = Self.lateEditionCount(filed: filed)
        var missed = DailyPack.all.filter { mastery.records[$0.id]?.missed ?? 0 > 0 }
        if let section { missed = missed.filter { $0.category == section } }
        let byWeakness = Self.byWeakSection(missed, mastery: mastery)
        var out = pick(wanted, from: byWeakness, avoiding: [])
        if out.count < wanted {
            // Nothing has got past her yet in that section. Take the ones she is holding on to
            // least firmly rather than handing back a short round.
            let rest = Self.byWeakSection(DailyPack.all.filter { item in
                !out.contains { $0.id == item.id } && mastery.hasSeen(item.id)
            }, mastery: mastery)
            out += pick(wanted - out.count, from: rest, avoiding: [])
        }
        return Self.ramped(out)
    }

    /// The sections that keep catching her, worst first. The late edition's picker is drawn
    /// from this, and so is the line the front page ends on.
    func weakestSections(limit: Int = 6) -> [String] {
        var totals: [String: (sum: Double, n: Int)] = [:]
        for item in DailyPack.all {
            guard let record = mastery.records[item.id] else { continue }
            var entry = totals[item.category] ?? (0, 0)
            entry.sum += record.strength
            entry.n += 1
            totals[item.category] = entry
        }
        return totals
            .filter { $0.value.n >= 3 }
            .sorted { ($0.value.sum / Double($0.value.n), $0.key) < ($1.value.sum / Double($1.value.n), $1.key) }
            .prefix(limit)
            .map(\.key)
    }

    /// How many times one section has got past her, for the line the edition ends on.
    func misses(in section: String) -> Int {
        DailyPack.all
            .filter { $0.category == section }
            .reduce(0) { $0 + (mastery.records[$1.id]?.missed ?? 0) }
    }

    // MARK: - The selection, part by part

    private func pick(_ count: Int, from pool: [QuizItem], avoiding recent: [String]) -> [QuizItem] {
        guard count > 0, !pool.isEmpty else { return [] }
        let byID = Dictionary(pool.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
        // Most of an edition is new material while the pack still has any; the rest is what she
        // is weakest on. Once she has read the whole pack the share turns itself off and the
        // paper becomes revision, which is the honest thing for a pack to do.
        let ids = mastery.next(from: pool.map(\.id), count: count, unseenShare: 0.7,
                               avoiding: Set(recent))
        return ids.compactMap { byID[$0] }
    }

    /// The day's candidates at one difficulty: the pack in an order the date fixes, then pulled
    /// forward by the sections that keep catching her.
    private func pool(for date: Date, difficulty: String) -> [QuizItem] {
        let slate = DailyPack.slate(for: date).filter { $0.difficulty == difficulty }
        return Self.byWeakSection(slate, mastery: mastery)
    }

    /// A stable sort that puts her weakest sections at the front. `Mastery.next` breaks its ties
    /// toward the front of the pool, so this is what makes "Geography keeps catching you" turn
    /// into Geography actually leading tomorrow's paper.
    nonisolated private static func byWeakSection(_ items: [QuizItem], mastery: Mastery<String>) -> [QuizItem] {
        var strength: [String: Double] = [:]
        var counts: [String: Int] = [:]
        for item in items {
            guard let record = mastery.records[item.id] else { continue }
            strength[item.category, default: 0] += record.strength
            counts[item.category, default: 0] += 1
        }
        // A section with nothing on record sits in the middle: neither owed nor owing.
        func weakness(_ category: String) -> Double {
            guard let n = counts[category], n > 0 else { return 0.5 }
            return strength[category]! / Double(n)
        }
        return items.enumerated()
            .sorted { a, b in
                let wa = weakness(a.element.category), wb = weakness(b.element.category)
                return wa == wb ? a.offset < b.offset : wa < wb
            }
            .map(\.element)
    }

    /// The mix the ladder asks for at one rung, as (difficulty, how many).
    nonisolated static func difficulties(at rung: Int, count: Int = 10) -> [(String, Int)] {
        let settled = min(count, ladder["settled", at: rung] ?? 6)
        let hard = min(settled, ladder["hard", at: rung] ?? 2)
        return [("easy", count - settled), ("medium", settled - hard), ("hard", hard)]
            .filter { $0.1 > 0 }
    }

    /// A round of ten reads easy to hard, the way the pack was written.
    nonisolated private static let rank = ["easy": 0, "medium": 1, "hard": 2]

    nonisolated static func ramped(_ items: [QuizItem]) -> [QuizItem] {
        items.enumerated()
            .sorted { a, b in
                let ra = rank[a.element.difficulty] ?? 1, rb = rank[b.element.difficulty] ?? 1
                return ra == rb ? a.offset < b.offset : ra < rb
            }
            .map(\.element)
    }
}

// MARK: - Spelling numbers

/// A newspaper spells its small numbers out. "Nineteen filed" is the desk talking; "19 filed"
/// is a dashboard.
enum Spelled {
    private static let ones = ["zero", "one", "two", "three", "four", "five", "six", "seven",
                               "eight", "nine", "ten", "eleven", "twelve", "thirteen", "fourteen",
                               "fifteen", "sixteen", "seventeen", "eighteen", "nineteen"]
    private static let tens = ["", "", "twenty", "thirty", "forty", "fifty", "sixty", "seventy",
                               "eighty", "ninety"]

    static func out(_ n: Int) -> String {
        switch n {
        case 0..<20: return ones[n]
        case 20..<100:
            let unit = n % 10
            return unit == 0 ? tens[n / 10] : "\(tens[n / 10])-\(ones[unit])"
        default: return "\(n)"
        }
    }

    /// Sentence-leading, so the editor's line starts in capitals like a printed one.
    static func leading(_ n: Int) -> String {
        let word = out(n)
        return word.prefix(1).uppercased() + word.dropFirst()
    }
}
