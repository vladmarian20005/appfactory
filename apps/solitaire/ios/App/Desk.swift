import FactoryKit
import SwiftUI

/// The root state: owns the record and the pack, and is the only thing that mutates either.
/// Views call `lay`, `play`, `takeBack`, `gather` and read `table`, `won` and `todayState`.
@MainActor
final class Desk: ObservableObject {
    enum Which { case today, other }
    enum Lay: Equatable { case today, ledger, loose(draw: Int), again(day: Int) }
    enum TodayState: Equatable { case notLaid, laid(started: Bool), out(Entry), yesterdayLaid }
    enum Tab: Hashable { case table, diary, drawer }

    @Published private(set) var record: Record
    let pack: Pack
    @Published private(set) var which: Which = .today
    /// The shown deal, replayed from its moves.
    @Published private(set) var table: Table?
    /// The win on the cloth, until another deal is laid.
    @Published private(set) var won: Entry?
    @Published private(set) var justEarned: Earned.Milestone?
    @Published private(set) var sweeping = false
    @Published private(set) var lampSwell = false
    /// The clerk's line at the foot of the table; sits empty unless something is worth saying.
    @Published private(set) var clerk: String?
    /// Ticks on every lay, so the view can deal the cards out.
    @Published private(set) var dealt = 0
    /// The move the demo is about to make: its cards lift before they go.
    @Published private(set) var holding: Table.Move?
    @Published var tab: Tab = .table
    @Published var isPro = false
    @Published var showPaywall = false

    private var resumedAt = Date()
    private var quiet = false
    private var clerkTask: Task<Void, Never>?

    init() {
        if LaunchOptions.resetData { Record.erase() }
        pack = Pack.load()
        record = LaunchOptions.resetData ? Record() : Record.load()
        if LaunchOptions.seeds { seedForCapture() } else { bootstrap() }
    }

    // MARK: - Reading

    var saved: SavedTable? { which == .today ? record.todayTable : record.table }
    var brand: Brand { record.clothInUse(pro: isPro).brand }
    var cloth: Cloth { record.clothInUse(pro: isPro) }
    var back: Back { record.backInUse(pro: isPro) }
    var today: Int { Play.dayNumber() }

    var todayState: TodayState {
        let day = today
        if let e = record.todayEntry(day: day) { return .out(e) }
        if let t = record.todayTable { return t.day == day ? .laid(started: !t.moves.isEmpty) : .yesterdayLaid }
        return .notLaid
    }

    /// The next deal in the ledger, as the ending and the done state name it.
    var nextLedger: (number: Int, draw: Int, grade: Int) {
        let d = Play.dials(at: record.rung)
        return (record.rung, d.draw, d.grade)
    }

    /// Today's dials, for the Diary's Today block.
    var todayDials: (grade: Int, draw: Int, tight: Int) { Play.dials(at: Play.dailyRung(day: today)) }

    /// A fresh deal with no move made, on a first launch: the ghost hand shows the first move.
    var teaching: Bool { !record.taught && saved?.moves.isEmpty == true && !LaunchOptions.seeds }

    var elapsed: Int { (saved?.seconds ?? 0) + Int(Date.now.timeIntervalSince(resumedAt)) }

    // MARK: - Laying

    private func bootstrap() {
        if record.table != nil {
            which = .other
        } else if record.entries.isEmpty && record.todayTable == nil {
            lay(.ledger)
            return
        } else {
            which = .today
            if record.todayTable == nil, record.todayEntry(day: today) == nil { lay(.today); return }
        }
        refresh()
    }

    func lay(_ what: Lay) {
        won = nil
        justEarned = nil
        clerk = nil
        lampSwell = false
        let day = today
        switch what {
        case .today:
            which = .today
            if let t = record.todayTable, t.day == day { break }
            if let t = record.todayTable { abandon(t) }
            record.todayTable = nil
            guard record.todayEntry(day: day) == nil else { break }
            guard let d = Play.todayDeal(day: day, pack: pack) else { assertionFailure("pack empty"); break }
            record.todayTable = SavedTable(deal: d, kind: .today, day: day,
                                           tight: Play.dials(at: Play.dailyRung(day: day)).tight)
        case .ledger:
            which = .other
            if let t = record.table, case .ledger = t.kind { break }
            if let t = record.table { abandon(t) }
            guard let d = Play.ledgerDeal(rung: record.rung, record: record, pack: pack) else { assertionFailure("pack empty"); break }
            record.table = SavedTable(deal: d, kind: .ledger(record.rung), day: day,
                                      tight: Play.dials(at: record.rung).tight)
            record.played.insert(d.id)
        case .loose(let draw):
            which = .other
            if let t = record.table { abandon(t) }
            guard let d = Play.looseDeal(draw: draw, record: record, pack: pack) else { break }
            record.looseLaid += 1
            record.table = SavedTable(deal: d, kind: .loose, day: day, tight: Play.dials(at: record.rung).tight)
            record.played.insert(d.id)
        case .again(let past):
            which = .other
            if let t = record.table { abandon(t) }
            guard let d = Play.todayDeal(day: past, pack: pack) else { break }
            record.table = SavedTable(deal: d, kind: .again(day: past), day: past,
                                      tight: Play.dials(at: Play.dailyRung(day: past)).tight)
        }
        resumedAt = .now
        dealt += 1
        refresh()
        save()
    }

    /// Shows today's table, or the other one, without laying anything.
    func show(_ w: Which) {
        guard w != which else { return }
        won = nil
        which = w
        refresh()
    }

    /// A deal left unfinished — laid over, or yesterday's gathered — is a mastery miss for its
    /// shape, and nothing else is lost.
    private func abandon(_ t: SavedTable) {
        guard !t.moves.isEmpty, !t.gathered else { return }
        record.mastery.record(t.shape, correct: false)
    }

    private func refresh() {
        table = saved.map { Table.replay($0.deal, $0.moves) }
    }

    private func store(_ s: SavedTable) {
        if which == .today { record.todayTable = s } else { record.table = s }
    }

    // MARK: - Playing

    /// Plays a legal move: the finger's drop, a tap's best place, the stock, or the demo.
    @discardableResult
    func play(_ m: Table.Move, instant: Bool = false) -> Bool {
        guard var s = saved, var t = table, !sweeping, won == nil, t.isLegal(m) else { return false }
        let before = t.foundations.map(\.count)
        let result = t.apply(m)
        s.moves.append(m)
        let upCard = (0..<4).first { t.foundations[$0].count > before[$0] }.flatMap { t.foundations[$0].last }
        if upCard != nil { s.run.hit() }
        record.taught = true
        store(s)
        table = t

        if !instant { feedback(m, upCard: upCard, result: result) }
        if result.gathered {
            say(t.passes == 1 ? Voice.firstGather : Voice.againGather)
        } else if !t.hasTableMove, !t.allFaceUp, !t.stock.isEmpty || !t.waste.isEmpty, !s.heard.contains("stuck") {
            s.heard.insert("stuck"); store(s)
            say(Voice.stuck)
        } else if kingWaits(t), !s.heard.contains("king") {
            s.heard.insert("king"); store(s)
            say(Voice.kingWaits)
        }

        if t.allFaceUp && !t.isOut {
            if instant || Motion.isStill { sweepNow() } else { Task { await sweep() } }
        } else if t.isOut {
            write()
        } else {
            save()
        }
        return true
    }

    private func kingWaits(_ t: Table) -> Bool {
        guard !t.columns.contains(where: \.isEmpty) else { return false }
        return t.columns.indices.contains { c in
            t.columns[c].count >= 2 && t.faceDown[c] == 1 && t.columns[c][1].rank == 13
        }
    }

    private func feedback(_ m: Table.Move, upCard: Card?, result: (turned: Card?, gathered: Bool)) {
        guard !quiet else { return }
        if case .turn = m {
            if result.gathered { Haptics.soft() } else { Haptics.tap(); Tones.shared.play(.tap, volume: 0.3) }
        } else if let card = upCard {
            Tones.shared.play(.step(card.rank - 1), volume: 0.5)
            Haptics.impact(0.25 + 0.04 * CGFloat(card.rank))
        } else {
            Haptics.rigid()
            Tones.shared.play(.pop, volume: 0.4)
        }
        if result.turned != nil {
            Task { @MainActor in
                try? await Task.sleep(nanoseconds: 80_000_000)
                Haptics.tap()
                Tones.shared.play(.tap, volume: 0.5)
            }
        }
    }

    func takeBack() {
        guard var s = saved, !s.moves.isEmpty, !sweeping, won == nil else { return }
        s.moves.removeLast()
        s.run.miss()
        s.takenBack += 1
        store(s)
        refresh()
        Haptics.soft()
        Tones.shared.play(.miss, volume: 0.3)
        if let t = table {
            say(Voice.takeBackLine(table: t, count: s.takenBack, salt: s.takenBack + s.moves.count))
        }
        save()
    }

    /// "Gather the cards": the same deal, laid again from the start. A mastery miss for its
    /// shape, once, and no pips on the win.
    func gather() {
        guard var s = saved, !sweeping, won == nil else { return }
        if !s.gathered, !s.moves.isEmpty { record.mastery.record(s.shape, correct: false) }
        s.moves = []
        s.gathered = true
        s.run = Run()
        s.run.miss()
        store(s)
        dealt += 1
        refresh()
        Haptics.soft()
        save()
    }

    /// The tap: a card to its best place, or a shrug.
    func tapColumn(_ col: Int, index: Int) -> Bool {
        guard let t = table, let m = t.bestMove(forColumn: col, index: index) else { shrug(); return false }
        return play(m)
    }

    func tapWaste() -> Bool {
        guard let t = table, let m = t.bestMoveForWaste() else { shrug(); return false }
        return play(m)
    }

    func tapFoundation(_ suit: Int) -> Bool {
        guard let t = table, let m = t.bestMoveForFoundation(suit) else { shrug(); return false }
        return play(m)
    }

    private func shrug() { Haptics.soft() }

    private func say(_ line: String) {
        clerk = line
        clerkTask?.cancel()
        guard !Motion.isStill else { return }
        clerkTask = Task { @MainActor [weak self] in
            try? await Task.sleep(nanoseconds: 2_600_000_000)
            guard !Task.isCancelled else { return }
            withMotion(Motion.gentle) { self?.clerk = nil }
        }
    }

    // MARK: - The sweep and the win

    /// Every card left flies home in rank order, one every 1.2 s / remaining, up a scale you
    /// can hear, ending on four kings.
    private func sweep() async {
        guard var t = table, var s = saved else { return }
        sweeping = true
        Haptics.thud()
        withMotion(Motion.gentle) { lampSwell = true }
        let moves = t.sweepMoves()
        try? await Task.sleep(nanoseconds: 200_000_000)
        let gap = max(0.025, 1.2 / Double(max(1, moves.count)))
        for (i, m) in moves.enumerated() {
            t.apply(m)
            s.moves.append(m)
            s.run.hit()
            withMotion(Motion.snappy) { table = t }
            if case .home(let code) = m {
                Tones.shared.play(.step(Card(code: code).rank - 1), volume: 0.5)
            }
            Haptics.impact(0.2 + 0.6 * CGFloat(i + 1) / CGFloat(moves.count))
            try? await Task.sleep(nanoseconds: UInt64(gap * 1_000_000_000))
        }
        store(s)
        write()
    }

    private func sweepNow() {
        guard var t = table, var s = saved else { return }
        for m in t.sweepMoves() {
            t.apply(m)
            s.moves.append(m)
            s.run.hit()
        }
        table = t
        lampSwell = true
        store(s)
        write()
    }

    /// The diary is written: the entry, the mastery, the rung, the best margin.
    private func write() {
        guard let s = saved else { return }
        let n = record.entries.count + 1
        var e = Entry(id: n, day: s.kind == .today ? s.day : today, date: .now, kind: s.kind,
                      dealID: s.dealID, draw: s.draw, grade: s.grade, shape: s.shape,
                      moves: s.moves.count, line: s.line, mark: s.mark, takenBack: s.takenBack,
                      longestChain: s.run.longestChain, tier: 0,
                      seconds: s.seconds + Int(Date.now.timeIntervalSince(resumedAt)),
                      buried: s.buried, gathered: s.gathered)
        // A best is further under the mark than ever before, and only ever under it.
        let bar = record.bestMargin.map { max($0, 0) } ?? Int.max
        let tier = s.run.tier(score: e.margin, beating: bar)
        e.tier = tier.rawValue
        if e.margin > 0 { record.bestMargin = max(record.bestMargin ?? 0, e.margin) }
        if s.takenBack <= 2 && !s.gathered {
            record.mastery.record(s.shape, correct: true)
        } else if s.takenBack >= 6 || s.gathered {
            record.mastery.record(s.shape, correct: false)
        }
        if case .ledger = s.kind {
            record.rung += 1
            record.recentShapes = Array((record.recentShapes + [s.shape]).suffix(2))
        }
        record.entries.append(e)
        if which == .today { record.todayTable = nil } else { record.table = nil }
        justEarned = Play.earned.justUnlocked(from: n - 1, to: n).first
        sweeping = false
        won = e
        save()
        celebrate(tier)
    }

    private func celebrate(_ tier: Run.Tier) {
        guard !quiet, !Motion.isStill else { return }
        Haptics.celebrate()
        switch tier {
        case .best:
            Tones.shared.play(.fanfare, volume: 0.8)
            Task { @MainActor in
                try? await Task.sleep(nanoseconds: 200_000_000)
                Haptics.celebrate()
                try? await Task.sleep(nanoseconds: 300_000_000)
                Tones.shared.play(.step(12), volume: 0.8)
            }
        case .clean: Tones.shared.play(.fanfare, volume: 0.8)
        case .good, .finished: Tones.shared.play(.success, volume: 0.8)
        }
    }

    /// Off the cloth after a win: the next deal, as the ending named it.
    func layNext() {
        if case .today = won?.kind { lay(.ledger) } else { lay(.ledger) }
    }

    // MARK: - Settings and the drawer

    func update(_ change: (inout Record) -> Void) {
        change(&record)
        save()
    }

    func clearDesk() {
        Record.erase()
        record = Record()
        won = nil
        table = nil
        bootstrap()
    }

    // MARK: - Life cycle

    func pause() {
        if var s = saved, table != nil, won == nil {
            s.seconds += Int(Date.now.timeIntervalSince(resumedAt))
            store(s)
        }
        resumedAt = .now
        save()
    }

    func resume() {
        resumedAt = .now
        // A new day: nothing is gathered. Yesterday's, if laid, stays laid and says so.
        if which == .today, record.todayTable == nil, won == nil,
           record.todayEntry(day: today) == nil, record.table == nil {
            lay(.today)
        }
    }

    func save() {
        guard !quiet else { return }
        record.save()
    }

    // MARK: - Demo

    /// Plays moves from the deal's line on a timer — the same `play` the finger calls.
    func demo(_ name: String) async {
        guard let s = saved else { return }
        let line = PackLine.line(for: s, pack: pack)
        try? await Task.sleep(nanoseconds: 1_400_000_000)
        switch name {
        case "win":
            for m in line.dropFirst(s.moves.count) {
                guard won == nil, !sweeping else { break }
                await hold(m)
                play(m)
                try? await Task.sleep(nanoseconds: 650_000_000)
            }
        default:
            // Round and round, so whenever the tooling starts filming, something is moving.
            while won == nil {
                var played = 0
                for m in line.dropFirst(s.moves.count).prefix(12) {
                    await hold(m)
                    play(m)
                    played += 1
                    try? await Task.sleep(nanoseconds: 700_000_000)
                    if played == 8 {
                        takeBack()
                        try? await Task.sleep(nanoseconds: 900_000_000)
                        await hold(m)
                        play(m)
                        try? await Task.sleep(nanoseconds: 700_000_000)
                    }
                }
                try? await Task.sleep(nanoseconds: 1_200_000_000)
                guard won == nil else { break }
                withMotion(Motion.gentle) {
                    store(s)
                    refresh()
                    clerk = nil
                }
                try? await Task.sleep(nanoseconds: 900_000_000)
            }
        }
    }

    /// Where along the line twelve moves do the most on the cloth: turning the stock barely
    /// changes the table, so the demo starts where cards lift, land and go up.
    /// It ends before every card is face up, so the demo never sets off the sweep.
    private static func busiestWindow(_ line: [Table.Move], from deal: Table, length: Int = 12) -> Int {
        var t = deal
        var open = line.count
        for (i, m) in line.enumerated() {
            t.apply(m)
            if t.allFaceUp { open = i; break }
        }
        guard open > length else { return 0 }
        func busy(_ m: Table.Move) -> Int { if case .turn = m { return 0 }; return 1 }
        var best = 0, bestScore = -1
        for k in 0...(open - length) {
            let score = line[k..<(k + length)].reduce(0) { $0 + busy($1) }
            if score > bestScore { best = k; bestScore = score }
        }
        return best
    }

    private func hold(_ m: Table.Move) async {
        guard case .turn = m else {
            withAnimation(.spring(response: 0.18, dampingFraction: 0.8)) { holding = m }
            Haptics.soft()
            try? await Task.sleep(nanoseconds: 260_000_000)
            holding = nil
            return
        }
    }

    // MARK: - Capture seeds

    /// A lived-in desk for the tooling: a ledger at `rung`, a diary to match — built by the
    /// same chooser and the same `write` rules, so the drawer's count and Mastery agree.
    private func seedForCapture() {
        quiet = true
        defer { quiet = false }
        record = Record()
        let rung = LaunchOptions.rung ?? (LaunchOptions.sampleData || LaunchOptions.demo != nil
                                          || LaunchOptions.won || LaunchOptions.done ? 51 : 1)
        simulate(to: rung, daysRunning: rung > 1 ? min(9, rung) : 0)
        if let c = LaunchOptions.cloth.flatMap(Cloth.init(rawValue:)) { record.cloth = c }
        else if record.hasEarned("claret") && LaunchOptions.sampleData { record.cloth = .blue }
        record.taught = true

        let board = LaunchOptions.board ?? (LaunchOptions.rung != nil && !LaunchOptions.sampleData ? "ledger" : "today")
        switch board {
        case "ledger": lay(.ledger)
        case "loose": lay(.loose(draw: 3))
        default: lay(.today)
        }
        guard let s = saved else { return }
        let line = PackLine.line(for: s, pack: pack)

        if LaunchOptions.won || LaunchOptions.done {
            for m in line where won == nil { play(m, instant: true) }
            if LaunchOptions.done { won = nil; justEarned = nil; which = .today; refresh() }
            return
        }
        var count = LaunchOptions.fresh ? 0 : (LaunchOptions.played ?? (LaunchOptions.rung != nil ? 10 : 12))
        if LaunchOptions.demo == "win" {
            // Up to four moves before every card is face up, so the demo plays the end.
            var t = s.deal
            var k = 0
            for (i, m) in line.enumerated() {
                t.apply(m)
                if t.allFaceUp { k = i + 1; break }
            }
            count = max(0, k - 4)
        } else if LaunchOptions.demo == "move" {
            count = Self.busiestWindow(line, from: s.deal)
        }
        for m in line.prefix(count) { play(m, instant: true) }
        clerk = nil
    }

    /// Climbs the ledger to `rung` as a player would — Mastery choosing each deal, a player
    /// who digs late and turns the stock late — and writes a run of today's deals to yesterday.
    private func simulate(to rung: Int, daysRunning: Int) {
        let day = today
        let ledgerCount = rung - 1
        let spanDays = ledgerCount + daysRunning + 1
        var rng = SplitMix64(seed: UInt64(rung) &* 0x9E37_79B9_7F4A_7C15 &+ 7)
        func write(_ d: PackDeal, kind: Kind, onDay: Int, tight: Int) {
            let weak: Int
            switch d.shape {
            case .buried: weak = 4
            case .stock: weak = 3
            case .passes: weak = 1
            default: weak = 0
            }
            let takenBack = max(0, weak + Int(rng.unit() * 5) - 2)
            let mark = Play.mark(line: d.lineCount, tight: tight)
            let moves = Int(Double(d.lineCount) * (1.0 + rng.unit() * 0.45))
            let n = record.entries.count + 1
            var e = Entry(id: n, day: onDay, date: Play.date(ofDay: onDay), kind: kind, dealID: d.id,
                          draw: d.draw, grade: d.grade, shape: d.shape, moves: moves, line: d.lineCount,
                          mark: mark, takenBack: takenBack, longestChain: 52 - takenBack * 3, tier: 0,
                          seconds: 180 + Int(rng.unit() * 420), buried: d.buried)
            var run = Run()
            for _ in 0..<52 { run.hit() }
            for _ in 0..<takenBack { run.miss() }
            let bar = record.bestMargin.map { max($0, 0) } ?? Int.max
            e.tier = run.tier(score: e.margin, beating: bar).rawValue
            if e.margin > 0 { record.bestMargin = max(record.bestMargin ?? 0, e.margin) }
            if takenBack <= 2 { record.mastery.record(d.shape, correct: true, at: e.date) }
            else if takenBack >= 6 { record.mastery.record(d.shape, correct: false, at: e.date) }
            record.entries.append(e)
        }
        // The ledger, oldest first, one deal a day before the run of dailies.
        for r in 1..<max(1, rung) {
            guard let d = Play.ledgerDeal(rung: r, record: record, pack: pack) else { break }
            record.played.insert(d.id)
            let onDay = day - spanDays + r
            write(d, kind: .ledger(r), onDay: onDay, tight: Play.dials(at: r).tight)
            record.rung = r + 1
            record.recentShapes = Array((record.recentShapes + [d.shape]).suffix(2))
        }
        for k in stride(from: daysRunning, through: 1, by: -1) {
            let onDay = day - k
            guard let d = Play.todayDeal(day: onDay, pack: pack) else { continue }
            write(d, kind: .today, onDay: onDay, tight: Play.dials(at: Play.dailyRung(day: onDay)).tight)
        }
        record.entries.sort { ($0.day, $0.id) < ($1.day, $1.id) }
        for i in record.entries.indices { record.entries[i].id = i + 1 }
        record.rung = max(1, rung)
    }
}

/// The dealer's line for a table on the cloth.
enum PackLine {
    static func line(for s: SavedTable, pack: Pack) -> [Table.Move] {
        pack.deal(id: s.dealID)?.line ?? []
    }
}
