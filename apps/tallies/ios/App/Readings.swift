import FactoryKit
import Foundation

/// The carver's sentence under the stave: one reading, drawn from the player's own record,
/// chosen at the start of a sitting and held for it.
///
/// This is the app's answer to "content that knows what it has already served". There is no
/// content pack to deal from: every line is computed from the `Tap` rows, and a reading that
/// would have to make something up is never shown. What comes next is chosen by three things
/// in order — what is true yet, what was not just shown, and what has *moved* since it was
/// last shown — and the strength `Mastery` keeps is read, not merely written: a reading that
/// keeps coming up unchanged loses strength and stops being served.
struct Reading: Identifiable {
    let id: String
    /// The line, or `nil` when the record cannot support it yet.
    let line: (Record, Int) -> String?
    /// The number the reading is about, so "has it moved since I last said it" is answerable.
    let value: (Record) -> Double
    /// What a meaningful change in that number looks like, for the ÷ spread.
    let spread: (Record) -> Double

    /// The twelve, in the order the ladder's `readings` dial opens them — one every twelve
    /// days kept. Index 0 is the first, available from day one.
    static let all: [Reading] = [
        Reading(id: "today", line: { record, _ in
            guard record.today > 0 else { return nil }
            return "\(Bench.capitalised(Bench.spelled(record.today))) today. \(Bench.capitalised(Bench.spelled(record.yesterday))) yesterday."
        }, value: { Double($0.today) }, spread: { _ in 3 }),

        Reading(id: "gate", line: { record, _ in
            let notches = record.notchesIntoStave
            guard notches >= notchesPerGate else { return nil }
            let gates = notches / notchesPerGate
            let over = notches % notchesPerGate
            let short = notchesPerStave - notches
            let head = over == 0
                ? "\(Bench.capitalised(Bench.spelled(gates))) gates."
                : "\(Bench.capitalised(Bench.spelled(gates))) gates and \(Bench.spelled(over))."
            return "\(head) \(Bench.capitalised(Bench.spelled(short))) short of a stave."
        }, value: { Double($0.notchesIntoStave) }, spread: { _ in 8 }),

        Reading(id: "best", line: { record, _ in
            guard record.daysKept >= 7, let deepest = record.deepestDay, deepest.count > 0 else { return nil }
            return "Your deepest day was \(Bench.spokenDate(deepest.day)) — \(Bench.spelled(deepest.count))."
        }, value: { Double($0.deepestDay?.count ?? 0) }, spread: { _ in 4 }),

        Reading(id: "clean", line: { record, _ in
            guard let sittings = record.sittingsSinceWax else { return nil }
            return sittings == 0
                ? "The last wax went in this sitting. It stays."
                : "\(Bench.capitalised(Bench.spelled(sittings))) sittings since the last wax."
        }, value: { Double($0.sittingsSinceWax ?? 0) }, spread: { _ in 3 }),

        Reading(id: "weekday", line: { record, span in
            let (totals, samples) = record.weekdays(span: span)
            let candidates = (1...7).filter { samples[$0] >= 4 }
            guard candidates.count >= 2 else { return nil }
            guard let top = candidates.max(by: { totals[$0] / max(1, samples[$0]) < totals[$1] / max(1, samples[$1]) }) else { return nil }
            let topRate = Double(totals[top]) / Double(max(1, samples[top]))
            let others = candidates.filter { $0 != top }
            let otherRate = others.reduce(0.0) { $0 + Double(totals[$1]) / Double(max(1, samples[$1])) } / Double(max(1, others.count))
            guard otherRate > 0, topRate > otherRate * 1.12 else { return nil }
            let names = ["", "Sundays", "Mondays", "Tuesdays", "Wednesdays", "Thursdays", "Fridays", "Saturdays"]
            let over = (topRate - otherRate) / otherRate
            let howMuch: String
            switch over {
            case ..<0.2: return "\(names[top]) run a little above the rest."
            case ..<0.4: howMuch = "a third"
            case ..<0.6: howMuch = "a half"
            case ..<1.1: howMuch = "twice"
            default: howMuch = "three times"
            }
            return howMuch == "twice" || howMuch == "three times"
                ? "\(names[top]) run \(howMuch) the rest."
                : "\(names[top]) run \(howMuch) above the rest."
        }, value: { record in
            let (totals, samples) = record.weekdays(span: 28)
            return (1...7).map { Double(totals[$0]) / Double(max(1, samples[$0])) }.max() ?? 0
        }, spread: { _ in 2 }),

        Reading(id: "kept", line: { record, _ in
            guard record.daysKept >= 3 else { return nil }
            return "\(Bench.capitalised(Bench.spelled(record.daysKept))) days kept. The longest you have gone is \(Bench.spelled(record.longestRunOfDays))."
        }, value: { Double($0.daysKept) }, spread: { _ in 5 }),

        Reading(id: "pace", line: { record, _ in
            guard let pace = record.todayPace else { return nil }
            let clock = DateFormatter()
            clock.dateFormat = "H:mm"
            let rate = pace.perHour >= 1
                ? "\(Bench.capitalised(Bench.spelled(Int(pace.perHour.rounded())))) an hour"
                : "One every couple of hours"
            return "\(rate) since the first cut at \(clock.string(from: pace.first))."
        }, value: { $0.todayPace?.perHour ?? 0 }, spread: { _ in 1.5 }),

        Reading(id: "stave", line: { record, _ in
            guard record.stavesScored >= 2 else { return nil }
            let head = "\(Bench.capitalised(Bench.spelled(record.stavesScored))) in the rack."
            guard let speeds = record.staveSpeeds else { return head }
            if speeds.current < speeds.best {
                let by = speeds.best - speeds.current
                return "\(head) This one is your fastest by \(Bench.spelled(by)) \(by == 1 ? "day" : "days")."
            }
            return "\(head) The quickest took \(Bench.spelled(speeds.best)) days."
        }, value: { Double($0.stavesScored) }, spread: { _ in 1 }),

        Reading(id: "hour", line: { record, span in
            guard Bench.ladder["grain", at: record.daysKept] ?? 1 >= 3 else { return nil }
            let hours = record.hours(span: span)
            guard let peak = hours.indices.max(by: { hours[$0] < hours[$1] }), hours[peak] > 0 else { return nil }
            let names = ["midnight", "one", "two", "three", "four", "five", "six", "seven",
                         "eight", "nine", "ten", "eleven", "twelve", "one", "two", "three",
                         "four", "five", "six", "seven", "eight", "nine", "ten", "eleven"]
            let part = peak < 12 ? "in the morning" : (peak < 18 ? "in the afternoon" : "in the evening")
            return "You cut most between \(names[peak]) and \(names[(peak + 1) % 24]) \(part)."
        }, value: { record in
            let hours = record.hours(span: 90)
            return Double(hours.indices.max(by: { hours[$0] < hours[$1] }) ?? 0)
        }, spread: { _ in 1 }),

        Reading(id: "month", line: { record, _ in
            guard let pair = record.monthPair else { return nil }
            let gap = pair.thisMonth - pair.lastMonth
            if gap == 0 { return "\(pair.thisName) is level with \(pair.lastName)." }
            return gap > 0
                ? "\(pair.thisName) is \(Bench.spelled(gap)) ahead of \(pair.lastName)."
                : "\(pair.thisName) is \(Bench.spelled(-gap)) behind \(pair.lastName)."
        }, value: { Double(($0.monthPair?.thisMonth ?? 0) - ($0.monthPair?.lastMonth ?? 0)) }, spread: { _ in 6 }),

        Reading(id: "quiet", line: { record, _ in
            guard let quiet = record.longestQuiet, quiet.days >= 3 else { return nil }
            let month = DateFormatter()
            month.dateFormat = "LLLL"
            return "Your longest quiet stretch was \(Bench.spelled(quiet.days)) days, in \(month.string(from: quiet.from))."
        }, value: { Double($0.longestQuiet?.days ?? 0) }, spread: { _ in 2 }),

        Reading(id: "first", line: { record, _ in
            guard let first = record.firstCut else { return nil }
            let days = Calendar.current.dateComponents([.day], from: first, to: .now).day ?? 0
            guard days > 0 else { return nil }
            return "\(Bench.capitalised(Bench.spelled(days))) days since the first cut, on \(Bench.spokenDate(first))."
        }, value: { record in
            guard let first = record.firstCut else { return 0 }
            return Double(Calendar.current.dateComponents([.day], from: first, to: .now).day ?? 0)
        }, spread: { _ in 10 }),
    ]
}

/// What the rota remembers between sittings: the strength of each reading, the last three
/// shown, and what each one said last time, which is how "moved most" is answerable at all.
struct RotaState: Codable {
    var mastery = Mastery<String>()
    var recent: [String] = []
    var lastValues: [String: Double] = [:]
}

enum Readings {
    /// One store per counter, so a stave's readings are about that stave.
    private static func key(for counter: Counter) -> String {
        "tallies.rota.\(counter.persistentModelID.hashValue)"
    }

    static func load(for counter: Counter) -> RotaState {
        guard let data = UserDefaults.standard.data(forKey: key(for: counter)),
              let state = try? JSONDecoder().decode(RotaState.self, from: data) else { return RotaState() }
        return state
    }

    static func save(_ state: RotaState, for counter: Counter) {
        guard let data = try? JSONEncoder().encode(state) else { return }
        UserDefaults.standard.set(data, forKey: key(for: counter))
    }

    /// The reading for this sitting, and the rota state that remembers having said it.
    ///
    /// 1. Drop anything that is not true yet — the ladder has not opened it, or the record
    ///    cannot compute it.
    /// 2. Drop the last three shown.
    /// 3. Order what is left by how much it has moved since it was last said, so a number
    ///    that changed speaks before one that did not, and hand that order to `Mastery`,
    ///    which serves the weakest first and breaks ties toward the front of the pool.
    /// 4. Record whether it had in fact moved, so a reading that keeps coming up unchanged
    ///    loses strength and falls out of the rota.
    static func next(for counter: Counter, record: Record, state: RotaState) -> (line: String, id: String, state: RotaState)? {
        let daysKept = record.daysKept
        let open = Bench.ladder["readings", at: max(1, daysKept)] ?? 1
        let span = Bench.ladder["span", at: max(1, daysKept)] ?? 14

        let available = Reading.all.prefix(open).filter { $0.line(record, span) != nil }
        guard !available.isEmpty else { return nil }

        func movement(_ reading: Reading) -> Double {
            let now = reading.value(record)
            guard let then = state.lastValues[reading.id] else { return 1 }
            return abs(now - then) / max(0.001, reading.spread(record))
        }

        // Ties break toward the reading the ladder opened most recently, so a new arrival
        // gets its moment rather than sitting behind eleven older ones.
        let ordered = available.enumerated()
            .sorted { a, b in
                let ma = movement(a.element), mb = movement(b.element)
                if ma != mb { return ma > mb }
                return a.offset > b.offset
            }
            .map(\.element.id)

        let recent = Set(state.recent.suffix(3))
        guard let chosen = state.mastery.next(from: ordered, count: 1, unseenShare: 0.34, avoiding: recent).first,
              let reading = Reading.all.first(where: { $0.id == chosen }),
              let line = reading.line(record, span) else { return nil }

        var next = state
        next.mastery.record(chosen, correct: movement(reading) > 0.15)
        next.lastValues[chosen] = reading.value(record)
        next.recent = Array((next.recent + [chosen]).suffix(3))
        return (line, chosen, next)
    }
}
