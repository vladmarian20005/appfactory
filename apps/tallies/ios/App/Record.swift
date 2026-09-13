import FactoryKit
import Foundation

/// One mark on a stave. A wax is a cut that was taken back: the number changes, the mark
/// stays. That is what a real tally stick does, and it is why `−` is not a delete here.
enum Mark: Int, Equatable, Codable {
    case cut, wax
}

/// Fifty notches — ten gates of five — and then the stave is scored, dated and stood up.
let notchesPerStave = 50
let notchesPerGate = 5

/// Everything the carver can read off one counter, replayed from the `Tap` rows the app has
/// always stored. Nothing here is persisted: the taps are the record, and the comment at
/// `Model.swift`'s `Tap` gives the reason. All twelve readings, the strip, the rack and the
/// sitting come out of this with no schema change.
struct Record {
    /// Every mark ever laid on this counter, oldest first.
    let marks: [Mark]
    /// The taps that produced them, oldest first.
    let taps: [(delta: Int, at: Date)]
    let calendar: Calendar

    init(taps rows: [Tap], calendar: Calendar = .current) {
        self.calendar = calendar
        let sorted = rows.sorted { $0.at < $1.at }
        self.taps = sorted.map { (delta: $0.delta, at: $0.at) }

        // Replay: a cut lays a mark, a wax fills the most recent mark still standing. The
        // stave keeps its length either way, which is the whole point of the wax.
        var laid: [Mark] = []
        for tap in sorted {
            if tap.delta > 0 {
                laid.append(.cut)
            } else if let last = laid.lastIndex(of: .cut) {
                laid[last] = .wax
            }
        }
        self.marks = laid
    }

    // MARK: The stave

    /// Marks cut on this counter across its whole life, waxed ones included.
    var cuts: Int { marks.count }
    /// The running total: every mark still standing.
    var total: Int { marks.reduce(0) { $0 + ($1 == .cut ? 1 : 0) } }
    var waxes: Int { cuts - total }

    var stavesScored: Int { cuts / notchesPerStave }
    /// How far into the stave on the bench, 0…49.
    var notchesIntoStave: Int { cuts % notchesPerStave }
    /// The marks on the stave currently lying on the bench.
    var currentStave: [Mark] { Array(marks.suffix(notchesIntoStave)) }
    var staveHasWax: Bool { currentStave.contains(.wax) }

    /// The dates each scored stave was finished on, oldest first — the end-grain stamps.
    var scoredStaveDates: [Date] {
        (1...max(1, stavesScored)).compactMap { n -> Date? in
            guard stavesScored >= n else { return nil }
            let index = n * notchesPerStave - 1
            return markDates.indices.contains(index) ? markDates[index] : nil
        }
    }

    /// When each mark was laid. A wax does not lay a mark, so this lines up with `marks`.
    private var markDates: [Date] { taps.filter { $0.delta > 0 }.map(\.at) }

    // MARK: Days

    var days: [Date: Int] {
        var out: [Date: Int] = [:]
        for tap in taps { out[calendar.startOfDay(for: tap.at), default: 0] += tap.delta }
        return out
    }

    /// Distinct days with at least one cut on this counter.
    var daysKept: Int { Set(taps.filter { $0.delta > 0 }.map { calendar.startOfDay(for: $0.at) }).count }

    /// The longest unbroken run of days with a cut in it. This is what replaces a streak: it
    /// is a fact about the record, it never goes back to zero, and nothing anywhere counts
    /// the days it did not happen.
    var longestRunOfDays: Int {
        let all = Set(taps.filter { $0.delta > 0 }.map { calendar.startOfDay(for: $0.at) }).sorted()
        var best = 0, run = 0
        var previous: Date?
        for day in all {
            if let previous, calendar.dateComponents([.day], from: previous, to: day).day == 1 {
                run += 1
            } else {
                run = 1
            }
            best = max(best, run)
            previous = day
        }
        return best
    }

    var firstCut: Date? { taps.first { $0.delta > 0 }?.at }

    func total(onDayOf date: Date) -> Int {
        let start = calendar.startOfDay(for: date)
        return max(0, days[start] ?? 0)
    }

    var today: Int { total(onDayOf: .now) }

    var yesterday: Int {
        guard let day = calendar.date(byAdding: .day, value: -1, to: .now) else { return 0 }
        return total(onDayOf: day)
    }

    // MARK: The strip

    struct StripDay: Identifiable, Hashable {
        let day: Date
        let count: Int
        /// Counts inside the day, finest first cell to last, as the ladder's `grain` allows.
        let cells: [Int]
        let waxed: Bool
        var id: Date { day }
    }

    /// The last `span` days, oldest first, each cut into `cells` sub-windows by `grain`.
    func strip(span: Int, grain: Int) -> [StripDay] {
        let cellsPerDay = Record.cells(forGrain: grain)
        let today = calendar.startOfDay(for: .now)
        var byDay: [Date: [Int]] = [:]
        var waxDays: Set<Date> = []
        for tap in taps {
            let day = calendar.startOfDay(for: tap.at)
            guard let hour = calendar.dateComponents([.hour], from: day, to: tap.at).hour else { continue }
            let cell = min(cellsPerDay - 1, max(0, hour * cellsPerDay / 24))
            var cells = byDay[day] ?? Array(repeating: 0, count: cellsPerDay)
            cells[cell] += tap.delta
            byDay[day] = cells
            if tap.delta < 0 { waxDays.insert(day) }
        }
        return (0..<span).reversed().compactMap { offset in
            guard let day = calendar.date(byAdding: .day, value: -offset, to: today) else { return nil }
            let cells = (byDay[day] ?? Array(repeating: 0, count: cellsPerDay)).map { max(0, $0) }
            return StripDay(day: day, count: cells.reduce(0, +), cells: cells, waxed: waxDays.contains(day))
        }
    }

    static func cells(forGrain grain: Int) -> Int {
        switch max(1, min(4, grain)) {
        case 1: return 1
        case 2: return 2
        case 3: return 4
        default: return 24
        }
    }

    /// Cuts by hour of the day across the last `span` days. The portrait `grain` 3 and up
    /// earns: an hourly histogram of one week is noise, of half a year it is a person.
    func hours(span: Int) -> [Int] {
        let cutoff = calendar.date(byAdding: .day, value: -span, to: calendar.startOfDay(for: .now)) ?? .distantPast
        var out = Array(repeating: 0, count: 24)
        for tap in taps where tap.delta > 0 && tap.at >= cutoff {
            out[calendar.component(.hour, from: tap.at)] += 1
        }
        return out
    }

    /// Cuts by weekday, 1 = Sunday, across the last `span` days, and how many of each weekday
    /// the record covers — reading 5 refuses to speak before it has four of them.
    func weekdays(span: Int) -> (totals: [Int], samples: [Int]) {
        let cutoff = calendar.date(byAdding: .day, value: -span, to: calendar.startOfDay(for: .now)) ?? .distantPast
        var totals = Array(repeating: 0, count: 8)
        var seen: [Int: Set<Date>] = [:]
        for tap in taps where tap.delta > 0 && tap.at >= cutoff {
            let weekday = calendar.component(.weekday, from: tap.at)
            totals[weekday] += 1
            seen[weekday, default: []].insert(calendar.startOfDay(for: tap.at))
        }
        let samples = (0..<8).map { seen[$0]?.count ?? 0 }
        return (totals, samples)
    }

    /// The deepest single day on record, for reading 3.
    var deepestDay: (day: Date, count: Int)? {
        days.filter { $0.value > 0 }.max { $0.value < $1.value }.map { (day: $0.key, count: $0.value) }
    }

    /// The longest stretch with no cut in it, and when it started, for reading 11.
    var longestQuiet: (days: Int, from: Date)? {
        let all = Set(taps.filter { $0.delta > 0 }.map { calendar.startOfDay(for: $0.at) }).sorted()
        guard all.count > 1 else { return nil }
        var best: (days: Int, from: Date)?
        for (a, b) in zip(all, all.dropFirst()) {
            let gap = (calendar.dateComponents([.day], from: a, to: b).day ?? 1) - 1
            if gap > 0, gap > (best?.days ?? 0) { best = (gap, a) }
        }
        return best
    }

    /// Totals for the current month and the one before it, for reading 10.
    var monthPair: (thisMonth: Int, lastMonth: Int, thisName: String, lastName: String)? {
        let now = Date.now
        guard let thisStart = calendar.dateInterval(of: .month, for: now)?.start,
              let lastStart = calendar.date(byAdding: .month, value: -1, to: thisStart) else { return nil }
        let this = taps.filter { $0.at >= thisStart }.reduce(0) { $0 + max(0, $1.delta) }
        let last = taps.filter { $0.at >= lastStart && $0.at < thisStart }.reduce(0) { $0 + max(0, $1.delta) }
        guard last > 0 else { return nil }
        let name = DateFormatter()
        name.dateFormat = "LLLL"
        return (this, last, name.string(from: now), name.string(from: lastStart))
    }

    /// How long the current stave took, and the fastest one before it, for reading 8.
    var staveSpeeds: (current: Int, best: Int)? {
        let dates = markDates
        guard stavesScored >= 2 else { return nil }
        var spans: [Int] = []
        for n in 0..<stavesScored {
            let from = dates[n * notchesPerStave]
            let to = dates[(n + 1) * notchesPerStave - 1]
            spans.append(max(1, calendar.dateComponents([.day], from: from, to: to).day ?? 1))
        }
        guard let last = spans.last, let best = spans.dropLast().min() else { return nil }
        return (last, best)
    }

    /// Sittings since the last wax, for reading 4.
    var sittingsSinceWax: Int? {
        guard waxes > 0 else { return nil }
        guard let lastWax = taps.last(where: { $0.delta < 0 })?.at else { return nil }
        return Record.sittings(in: taps.filter { $0.at > lastWax }, calendar: calendar)
    }

    /// Cuts today and the hour the first one landed, for reading 7.
    var todayPace: (perHour: Double, first: Date)? {
        let start = calendar.startOfDay(for: .now)
        let todays = taps.filter { $0.at >= start && $0.delta > 0 }
        guard todays.count >= 3, let first = todays.first?.at else { return nil }
        let hours = max(0.5, Date.now.timeIntervalSince(first) / 3600)
        return (Double(todays.count) / hours, first)
    }

    // MARK: Sittings

    /// A sitting runs from the first cut to two minutes after the last one. Two minutes
    /// because that is roughly when somebody puts the phone down and the thing they were
    /// counting stops.
    static let sittingGap: TimeInterval = 120

    static func sittings(in taps: [(delta: Int, at: Date)], calendar: Calendar) -> Int {
        var count = 0
        var previous: Date?
        for tap in taps {
            if let previous, tap.at.timeIntervalSince(previous) <= sittingGap {
                // same sitting
            } else {
                count += 1
            }
            previous = tap.at
        }
        return count
    }

    /// The sitting still open, if the last tap was recent enough — replayed as a `Run` so a
    /// relaunch, a `-demo` flag and a seeded capture all see the same one the player would.
    var sitting: Run {
        var run = Run()
        guard let last = taps.last?.at, Date.now.timeIntervalSince(last) <= Record.sittingGap * 60 else { return run }
        var group: [(delta: Int, at: Date)] = []
        for tap in taps.reversed() {
            if let previous = group.last, previous.at.timeIntervalSince(tap.at) > Record.sittingGap { break }
            group.append(tap)
        }
        for tap in group.reversed() {
            if tap.delta > 0 { run.hit() } else { run.miss() }
        }
        return run
    }
}

extension Record {
    /// Just the dates the staves were closed on. A wax never closes one, so this needs no
    /// replay — which matters on the bench, where it is asked of every counter at once.
    static func scoredDates(for counter: Counter) -> [Date] {
        let cuts = counter.entries.filter { $0.delta > 0 }.map(\.at).sorted()
        guard cuts.count >= notchesPerStave else { return [] }
        return stride(from: notchesPerStave - 1, to: cuts.count, by: notchesPerStave).map { cuts[$0] }
    }
}

/// One replay of the tap log per change, rather than one per question asked of it.
///
/// `Record` is built by sorting and replaying every row, and the face asks it about fifteen
/// things in a single pass of `body` — the marks, the days kept, the span, the rack, the
/// strip, the sitting. At five hundred days that is fifteen replays of four thousand rows for
/// one redraw, which is what made the `-demo cut` filmstrip crawl: the cuts were landing on
/// time and the screen could not keep up with them.
@MainActor
final class RecordBox {
    private var count = -1
    private var cached: Record?

    /// Keyed on the number of rows, which is the only way this app's record ever changes: a
    /// cut and a wax each add one, and planing a stave takes many away.
    func record(for counter: Counter) -> Record {
        if counter.entries.count != count || cached == nil {
            count = counter.entries.count
            cached = Record(taps: counter.entries)
        }
        return cached!
    }
}

// MARK: - The ladder

enum Bench {
    /// DESIGN.md §The ladder, keyed on days kept. `flattensAt` is 217 — about seven months —
    /// and `climbs(through: 150)` is true. Past it the instrument is complete and the record
    /// takes over: every reading drawn from half a year of the player's own counting.
    static let ladder = Ladder([
        .init("readings", from: 1, by: 1, every: 12, opensAt: 1, ceiling: 12),
        .init("span", from: 14, by: 7, every: 9, opensAt: 1, ceiling: 182),
        .init("grain", from: 1, by: 1, every: 38, opensAt: 64, ceiling: 4),
    ])

    /// DESIGN.md §Earned, on staves scored. Earned by counting, never by paying.
    static let earned = Earned([
        .init(id: "rack", title: "The rack",
              blurb: "Your first stave is scored. It stands in the rack behind you now.", at: 1),
        .init(id: "chalk", title: "The chalk",
              blurb: "Three in the rack. There is chalk on the bench if you want to name them.", at: 3),
        .init(id: "gauge", title: "The brass gauge",
              blurb: "Eight staves. The gauge is worth fitting now — you have enough to measure against.", at: 8),
        .init(id: "oil", title: "The oil",
              blurb: "Twenty staves. The bench has taken on a colour. That was you.", at: 20),
        .init(id: "mark", title: "The carver's mark",
              blurb: "Fifty. Your mark goes on the end of every stave from here.", at: 50),
        .init(id: "wall", title: "The long wall",
              blurb: "A hundred and twenty. They do not fit the rack any more — there is a wall for them.", at: 120),
    ])

    /// What the sitting card's tail says: the next thing waiting, shortened.
    static func horizon(stavesScored: Int, daysKept: Int, inRack: Int) -> String {
        if let next = earned.next(after: stavesScored) {
            return "\(capitalised(spelled(inRack))) in the rack — \(tail(for: next))"
        }
        return "\(capitalised(spelled(inRack))) in the rack, and \(spelled(daysKept)) days kept."
    }

    private static func tail(for milestone: Earned.Milestone) -> String {
        switch milestone.id {
        case "rack": return "the first one stands up at one."
        case "chalk": return "the chalk comes out at three."
        case "gauge": return "the gauge goes on the bench at eight."
        case "oil": return "the bench takes its colour at twenty."
        case "mark": return "your own mark goes on the ends at fifty."
        default: return "the wall goes up at a hundred and twenty."
        }
    }

    private static let units = ["none", "one", "two", "three", "four", "five", "six", "seven",
                                "eight", "nine", "ten", "eleven", "twelve", "thirteen",
                                "fourteen", "fifteen", "sixteen", "seventeen", "eighteen",
                                "nineteen"]
    private static let tens = ["", "", "twenty", "thirty", "forty", "fifty", "sixty",
                               "seventy", "eighty", "ninety"]

    /// The carver counts in words, not digits: "Forty-three into this stave." Past a thousand
    /// he gives up and uses the numeral, which is what anybody does.
    static func spelled(_ n: Int) -> String {
        switch n {
        case 0..<20: return units[n]
        case 20..<100:
            let rest = n % 10
            return rest == 0 ? tens[n / 10] : "\(tens[n / 10])-\(units[rest])"
        case 100..<1000:
            let rest = n % 100
            let head = "\(units[n / 100]) hundred"
            return rest == 0 ? head : "\(head) and \(spelled(rest))"
        default: return "\(n)"
        }
    }

    static func capitalised(_ s: String) -> String { s.prefix(1).uppercased() + s.dropFirst() }

    /// "the 4th of March" — how a date is said out loud, and how it is stamped on an end-grain.
    static func spokenDate(_ date: Date) -> String {
        let day = Calendar.current.component(.day, from: date)
        let suffix: String
        switch day % 100 {
        case 11, 12, 13: suffix = "th"
        default:
            switch day % 10 {
            case 1: suffix = "st"
            case 2: suffix = "nd"
            case 3: suffix = "rd"
            default: suffix = "th"
            }
        }
        let month = DateFormatter()
        month.dateFormat = "LLLL"
        return "the \(day)\(suffix) of \(month.string(from: date))"
    }
}
