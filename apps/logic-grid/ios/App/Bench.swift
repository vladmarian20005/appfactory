import FactoryKit
import SwiftUI

/// One pairing on the plate, whichever way round it is named.
struct Pairing: Hashable {
    var a: Cell
    var b: Cell

    init(_ x: Cell, _ y: Cell) {
        if (x.category, x.member) <= (y.category, y.member) { a = x; b = y } else { a = y; b = x }
    }
}

/// A mark she made, as opposed to one the plate cut itself. The plate is rebuilt from these
/// from bare copper whenever one is taken back or changed, which is the only honest way to
/// undo a cascade: replay it.
struct Action: Codable, Equatable {
    var x: Cell
    var y: Cell
    var mark: Mark
    /// The clues forced it at the moment she made it.
    var forced: Bool
    /// A mark that contradicts the clues does not take; it still leaves its scratch.
    var applied: Bool
}

/// A plate on the bed, mid-cut.
struct Session: Equatable {
    var plate: Plate
    var grid: Grid
    var run = Run()
    var actions: [Action] = []
    /// Where the burin skidded, as a fraction along the margin. They print.
    var scars: [Double] = []
    var opened: Set<Int> = []
    /// The figures stamped into the margin, one per block that has closed itself.
    var figures: [[Glyph]] = []
    var closedPairs: Set<Int> = []
    var isDaily: Bool
    var burnished = false
    /// Until the first cut the burin lies beside the bed and floats, and the cell the first
    /// clue forces carries a ghost crosshatch with a copper thread to that clue.
    var hasCut: Bool { !actions.isEmpty }
    var started = Date()

    /// One mark per cut she made, in order: the proof strip on the share card.
    var strip: [Bool] { actions.map(\.forced) }
    var pointsCut: Int { grid.pointsCut() }
    var isPulled: Bool { grid.isPulled }

    /// The clues the plate will read from right now — everything not still scratched over.
    var readable: [Clue] {
        plate.clues.map { clue in
            var out = clue
            out.sealed = clue.sealed && !opened.contains(clue.id)
            return out
        }
    }

    func isLegible(_ clue: Clue) -> Bool { !clue.sealed || opened.contains(clue.id) }

    func mine(_ x: Cell, _ y: Cell) -> Bool {
        actions.contains { Pairing($0.x, $0.y) == Pairing(x, y) }
    }
}

/// Where the pull has got to. The whole of it is 1.5 seconds; a still capture freezes on the
/// print, which is the frame worth photographing.
enum PullStage: Int, Comparable {
    case none, stilling, inking, wiping, paper, press, peel, settled
    static func < (a: PullStage, b: PullStage) -> Bool { a.rawValue < b.rawValue }
}

/// What the loupe named: a clue, and the cell it forces.
struct Loupe: Equatable {
    var clue: Int
    var pairing: Pairing
}

/// The bench. It owns the record, rules the plates, judges every cut against the solver and
/// pulls the print.
@MainActor
final class Bench: ObservableObject {
    @Published private(set) var record: Record
    @Published private(set) var session: Session?
    /// A line set in the margin for a couple of seconds: a slip, a block closing, a seal
    /// biting open, the loupe naming its clue.
    @Published var marginLine: String?
    @Published private(set) var stage: PullStage = .none
    @Published private(set) var pulled: Pull?
    @Published private(set) var tier: Run.Tier = .finished
    @Published private(set) var earnedNow: Earned.Milestone?
    @Published var loupe: Loupe?
    /// Triggers: swarf on every cut, the shake on a slip, filings on the pull.
    @Published var cuts = 0
    @Published var slips = 0
    @Published var pullBursts = 0
    @Published var closes = 0
    /// What the plate is still cutting itself, so the cascade arrives cell by cell.
    @Published var cascading: Set<Pairing> = []
    /// The mark under her thumb, not yet judged.
    @Published private(set) var pending: Action?

    private static let storeKey = "crosshatch.record"
    private var demoTask: Task<Void, Never>?
    private var marginTask: Task<Void, Never>?
    private var cascadeTask: Task<Void, Never>?
    private var judgeTask: Task<Void, Never>?

    var isPro: Bool { LaunchOptions.forcePro || proByPurchase }
    private var proByPurchase = false

    init() {
        if LaunchOptions.resetData { UserDefaults.standard.removeObject(forKey: Self.storeKey) }
        if let data = UserDefaults.standard.data(forKey: Self.storeKey),
           let saved = try? JSONDecoder().decode(Record.self, from: data) {
            record = saved
        } else {
            record = Record()
        }
        if LaunchOptions.sampleData { seedBench() }
        if let rung = LaunchOptions.level { record.rung = max(1, rung) }
    }

    func note(pro: Bool) { proByPurchase = pro }

    // MARK: - Ruling a plate

    /// The next plate in her own run. The three kinds her record says she is weakest at, with
    /// a share she has not met yet and not the ones the last plate leaned on; a subject that
    /// has not come round lately; then the generator's pipeline, which discards anything it
    /// cannot prove.
    func rule(daily: Bool) {
        let rung = daily ? Play.dailyRung(for: .now) : max(1, record.rung)
        let open = Play.kindsOpen(at: rung).map(\.rawValue)
        // Never the whole vocabulary: asking for every kind that is open is asking for
        // nothing in particular.
        let wanted = record.mastery.next(from: open, count: min(3, max(1, open.count - 1)),
                                         unseenShare: 0.34, avoiding: Set(record.recentKinds))
        let want = wanted.compactMap(ClueKind.init(rawValue:))
        let themeID = record.themes.next(from: Themes.ids, count: 1, unseenShare: 0.34,
                                         avoiding: Set(record.recentThemes)).first ?? Themes.ids[0]

        let seed: UInt64 = daily
            ? UInt64(bitPattern: Int64(Play.dayNumber(for: .now))) &* 0x2545_F491_4F6C_DD1D
            : (record.salt ^ (UInt64(rung) &* 0x9E37_79B9_7F4A_7C15))

        let plate = Generator.plate(theme: Themes.theme(id: themeID),
                                    shape: Play.shape(at: rung),
                                    want: want,
                                    rung: rung,
                                    number: daily ? max(1, Play.dayNumber(for: .now) % 9000) : record.platesPulled + 1,
                                    isDaily: daily,
                                    seed: seed)

        var fresh = Session(plate: plate,
                            grid: Grid(categories: plate.categories, members: plate.members),
                            isDaily: daily)
        Solver.assist(&fresh.grid, collecting: false)
        session = fresh
        record.recentThemes = Array((record.recentThemes + [themeID]).suffix(3))
        record.themes.record(themeID, correct: true)
        record.recentKinds = Array(Set(plate.clues.map(\.kind.rawValue))).sorted()
        stage = .none
        pulled = nil
        loupe = nil
        save()
    }

    /// Whatever is on the bed: the plate she left there, or a new one ruled for her.
    func openBed(daily: Bool) {
        let today = Play.dayNumber(for: .now)
        if daily, record.lastDailyDay == today, record.dailyBed == nil {
            // Today's is already pulled; the bench opens on the next plate in her own run.
            openBed(daily: false)
            return
        }
        if let saved = daily ? record.dailyBed : record.bed, saved.plate.isDaily == daily,
           !daily || saved.plate.number == max(1, today % 9000) {
            var restored = Session(plate: saved.plate, grid: saved.grid, run: saved.run,
                                   actions: saved.actions, scars: saved.scars,
                                   opened: Set(saved.openedSeals), isDaily: daily,
                                   started: saved.started)
            settle(&restored)
            session = restored
        } else {
            rule(daily: daily)
        }
        if LaunchOptions.sampleData || LaunchOptions.demo != nil || LaunchOptions.won { poseForCapture() }
    }

    // MARK: - The cut

    /// What the evidence forces right now. A cut has to be in this set to take cleanly — which
    /// is the only thing anyone can get wrong in a puzzle that is pure deduction, and it is
    /// what makes deduction worth doing in a genre where trial and error usually works too.
    var forcedNow: [Deduction] { forced(in: session) }

    private func forced(in session: Session?) -> [Deduction] {
        guard let session else { return [] }
        // A cut the plate itself forces — the last cell standing in a row, a pairing with
        // nothing able to stand between it and a third category — takes just as cleanly as one
        // a clue forces. Spotting those is half of what the game is.
        let fromClues = Solver.fromClues(session.grid, clues: session.readable)
        let fromPlate = Solver.fromPlate(session.grid)
        return (fromClues + fromPlate).filter { session.grid.at($0.x, $0.y) == .blank }
    }

    /// Bare copper → ruled out (two cut strokes) → fixed (one deep point) → bare copper. There
    /// is no checkmark in this app, and no cross.
    ///
    /// The mark she is making is judged when it settles rather than on the tap, because fixing
    /// a pairing is two strokes and then a point: judging the first of the two would call the
    /// stroke on the way to a point a guess, which it is not. A quarter of a second of nothing
    /// further on that cell, or a touch anywhere else, and the burin is committed.
    func cut(_ x: Cell, _ y: Cell) {
        guard let current = session, stage == .none else { return }
        // A mark waiting on another cell is committed before this one begins.
        if let waiting = pending, Pairing(waiting.x, waiting.y) != Pairing(x, y) { commit(waiting) }

        let was = pending.map(\.mark) ?? current.grid.at(x, y)
        // What the plate cut for itself is not hers to re-cut.
        guard was == .blank || pending != nil || current.mine(x, y) else {
            Haptics.soft()
            return
        }
        let next: Mark = was == .blank ? .ruled : (was == .ruled ? .point : .blank)
        loupe = nil

        // Changing or lifting a mark she already committed: the plate is replayed without it,
        // so what follows is judged against the evidence she actually had in front of her.
        if pending == nil, was != .blank {
            var probe = current
            probe.actions.removeAll { Pairing($0.x, $0.y) == Pairing(x, y) }
            rebuild(&probe)
            session = probe
        }
        guard next != .blank else {
            pending = nil
            Haptics.tap()
            save()
            return
        }

        pending = Action(x: x, y: y, mark: next, forced: false, applied: true)
        cuts += 1
        if next == .point {
            Haptics.thud()
            Tones.shared.play(.pop)
        } else {
            Haptics.rigid()
            Haptics.tap()
        }
        Tones.shared.play(.step((session?.run.chain ?? 0) % 5))

        judgeTask?.cancel()
        guard !Motion.isStill else {
            if let waiting = pending { commit(waiting) }
            return
        }
        judgeTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: 260_000_000)
            guard !Task.isCancelled, let waiting = pending else { return }
            commit(waiting)
        }
    }

    /// The burin is in. Was the mark forced by something legible on this plate at the moment
    /// she made it?
    private func commit(_ action: Action) {
        pending = nil
        judgeTask?.cancel()
        guard var out = session, stage == .none else { return }
        let x = action.x, y = action.y
        guard out.grid.at(x, y) == .blank else { return }

        let available = forced(in: out)
        let isForced = available.contains { Pairing($0.x, $0.y) == Pairing(x, y) && $0.mark == action.mark }
        let contradicts = (action.mark == .point) != out.plate.solution.holds(x, y)

        out.actions.append(Action(x: x, y: y, mark: action.mark, forced: isForced, applied: !contradicts))
        if isForced {
            if let index = available.first(where: { Pairing($0.x, $0.y) == Pairing(x, y) })?.clue {
                record.mastery.record(out.plate.clues[index].kind.rawValue, correct: true)
            }
        } else {
            out.scars.append(Double((out.scars.count * 37 + 11) % 83) / 83)
            if let index = available.first(where: { $0.clue != nil })?.clue {
                record.mastery.record(out.plate.clues[index].kind.rawValue, correct: false)
            }
        }

        // Her mark takes, unless it contradicts the clues; then the plate cuts the rest of the
        // crossing out itself.
        var grid = out.grid
        if !contradicts { grid.set(x, y, action.mark) }
        let steps = (record.assist || !isPro) ? Solver.assist(&grid) : []
        out.grid = grid
        out.run = replayRun(out.actions)
        session = out

        if isForced {
            Tones.shared.play(.step(out.run.chain % 5))
        } else {
            slips += 1
            Haptics.soft()
            Tones.shared.play(.miss)
            setMargin(AppInfo.line(from: AppInfo.nearMiss, seed: out.actions.count * 3))
        }
        arrive(steps)
    }

    /// The cascade: each crosshatch opens twenty-two milliseconds after the last, radiating
    /// out along the row and then the column, every second one answering with a haptic and a
    /// step up the scale.
    private func arrive(_ steps: [Deduction]) {
        cascadeTask?.cancel()
        guard !steps.isEmpty, !Motion.isStill else {
            cascading = []
            if let now = session { land(now) }
            return
        }
        cascading = Set(steps.map { Pairing($0.x, $0.y) })
        cascadeTask = Task { @MainActor in
            for (index, step) in steps.enumerated() {
                try? await Task.sleep(nanoseconds: 22_000_000)
                guard !Task.isCancelled else { return }
                withMotion(AppBrand.Cut.bite) { cascading.remove(Pairing(step.x, step.y)) }
                if index % 2 == 0 {
                    Haptics.impact(0.18)
                    Tones.shared.play(.step(index % 5))
                }
            }
            cascading = []
            if let now = session { land(now) }
        }
    }

    /// A block that has closed itself, a seal that has bitten open, and the pull.
    private func land(_ current: Session) {
        var out = current
        let closed = closedPairs(in: out.grid)
        let newly = closed.subtracting(out.closedPairs)
        stampFigures(&out, closed: closed)
        if !newly.isEmpty {
            closes += 1
            Haptics.soft()
            Tones.shared.play(.pop)
            setMargin(AppInfo.line(from: AppInfo.categoryClosed, seed: out.figures.count))
        }
        session = out

        if out.isPulled {
            pull()
            return
        }
        // A sealed clue bites open the moment the plate has no forced move without it — which
        // the solver knows exactly, so a sealed plate can never deadlock.
        if forced(in: out).isEmpty,
           let next = out.plate.clues.first(where: { $0.sealed && !out.opened.contains($0.id) }) {
            out.opened.insert(next.id)
            session = out
            Tones.shared.play(.success)
            setMargin(AppInfo.line(from: AppInfo.sealedOpened, seed: next.id))
        }
        save()
    }

    /// Replay from bare copper: the plate, her marks in order, and the plate's own crossing
    /// out after each.
    private func rebuild(_ session: inout Session) {
        var grid = Grid(categories: session.plate.categories, members: session.plate.members)
        for action in session.actions {
            if action.applied { grid.set(action.x, action.y, action.mark) }
            if record.assist || !isPro { Solver.assist(&grid, collecting: false) }
        }
        session.grid = grid
        session.run = replayRun(session.actions)
        session.scars = session.actions.filter { !$0.forced }.enumerated().map { index, _ in
            Double((index * 37 + 11) % 83) / 83
        }
        settle(&session)
    }

    private func settle(_ session: inout Session) {
        session.closedPairs = closedPairs(in: session.grid)
        stampFigures(&session, closed: session.closedPairs)
    }

    private func replayRun(_ actions: [Action]) -> Run {
        var run = Run()
        for action in actions {
            if action.forced { run.hit() } else { run.miss() }
        }
        return run
    }

    private func closedPairs(in grid: Grid) -> Set<Int> {
        var out = Set<Int>()
        for x in 0..<grid.categories {
            for y in (x + 1)..<grid.categories {
                var points = 0
                for i in 0..<grid.members {
                    for j in 0..<grid.members where grid.at(x, i, y, j) == .point { points += 1 }
                }
                if points == grid.members { out.insert(x * grid.categories + y) }
            }
        }
        return out
    }

    /// One small engraved figure of the pairing per block that has closed, so the margin fills
    /// with the print as she goes.
    private func stampFigures(_ session: inout Session, closed: Set<Int>) {
        let categories = session.plate.categories
        session.closedPairs = closed
        session.figures = closed.sorted().map { pair in
            let x = pair / categories, y = pair % categories
            let entity = 0
            return [session.plate.glyph(Cell(category: x, member: session.plate.solution.member(x, of: entity))),
                    session.plate.glyph(Cell(category: y, member: session.plate.solution.member(y, of: entity)))]
        }
    }

    // MARK: - The loupe, the burnisher, the rag

    /// Free, unlimited and forever. It names the clue and what it forces — never an
    /// instruction about the interface.
    func nameTheClue() {
        guard let current = session else { return }
        let available = forcedNow
        guard let step = available.first(where: { $0.clue != nil }) ?? available.first else { return }
        Haptics.tap()
        Tones.shared.play(.tap)
        if let index = step.clue {
            loupe = Loupe(clue: index, pairing: Pairing(step.x, step.y))
            record.mastery.record(current.plate.clues[index].kind.rawValue, correct: false)
            let one = current.plate.member(step.x).short
            let two = current.plate.member(step.y).short
            setMargin("Read \(Spelled.out(index + 1)) again. It settles \(one) and \(two).", seconds: 6)
        } else {
            loupe = Loupe(clue: -1, pairing: Pairing(step.x, step.y))
            setMargin("The plate settles that one itself — the row has its point already.", seconds: 6)
        }
        save()
    }

    var canTakeBack: Bool { !(session?.actions.isEmpty ?? true) && stage == .none }

    /// Take it back: the mark, the plate's own crossing out with it, and the run put back.
    func takeItBack() {
        pending = nil
        judgeTask?.cancel()
        guard var current = session, !current.actions.isEmpty else { return }
        current.actions.removeLast()
        rebuild(&current)
        session = current
        loupe = nil
        Haptics.tap()
        save()
    }

    /// Earned at twelve plates: one scar a plate can be polished out by hand, leaving a faint
    /// bloom where it was. It takes the scratch off the print. It does not restore the line or
    /// the clean sheet, and a burnished plate can never be a best.
    var canBurnish: Bool {
        guard let session else { return false }
        return record.hasEarned("burnisher") && !session.scars.isEmpty && !session.burnished && stage == .none
    }

    func burnish() {
        guard var current = session, canBurnish else { return }
        current.scars.removeLast()
        current.burnished = true
        session = current
        Haptics.soft()
        Tones.shared.play(.pop)
        setMargin("Polished out. The print comes up clean; the plate remembers.", seconds: 4)
        save()
    }

    /// Wipe the plate: the same plate, bare copper again.
    func wipe() {
        guard let current = session else { return }
        var fresh = Session(plate: current.plate,
                            grid: Grid(categories: current.plate.categories, members: current.plate.members),
                            isDaily: current.isDaily)
        Solver.assist(&fresh.grid, collecting: false)
        session = fresh
        loupe = nil
        Haptics.thud()
        save()
    }

    // MARK: - The pull

    private func pull() {
        guard let current = session else { return }
        var finalTier = current.run.tier(score: current.run.longestChain, beating: record.bestLine)
        // A best here has to be clean as well, and a burnished plate can never be one.
        if finalTier == .best, !current.run.isClean || current.burnished {
            let accuracy = current.run.attempts > 0 ? Double(current.run.hits) / Double(current.run.attempts) : 0
            finalTier = current.run.isClean ? .clean : (accuracy >= 0.8 ? .good : .finished)
        }
        tier = finalTier

        let day = Play.dayNumber(for: .now)
        let rows = (0..<current.plate.members).map { entity in
            (0..<current.plate.categories).map { category in
                current.plate.glyph(Cell(category: category, member: current.plate.solution.member(category, of: entity)))
            }
        }
        let print = Pull(number: current.plate.number,
                         day: day,
                         date: .now,
                         title: current.plate.title,
                         themeID: current.plate.themeID,
                         points: current.plate.totalPoints,
                         longestLine: current.run.longestChain,
                         scars: current.scars.count,
                         burnished: current.burnished,
                         tier: finalTier.rawValue,
                         rows: rows,
                         names: (0..<current.plate.members).map { current.plate.member(Cell(category: 0, member: $0)).short },
                         ink: current.plate.number % 6)

        let before = record.platesPulled
        record.pulls.append(print)
        record.pointsCut += print.points
        record.bestLine = max(record.bestLine, print.longestLine)
        // A plate pulled advances the rung by one; a plate pulled clean advances it by two, so
        // someone who deduces rather than guesses climbs twice as fast.
        record.rung += current.run.isClean ? 2 : 1
        if current.isDaily {
            record.lastDailyDay = day
            record.dailyBed = nil
        } else {
            record.bed = nil
        }
        earnedNow = Play.earned.justUnlocked(from: before, to: record.platesPulled).last
        pulled = print
        persist()
        choreograph()
    }

    /// Inked, wiped, printed, and the print goes up on the line. Never a sheet with a
    /// checkmark on it.
    private func choreograph() {
        pullBursts += 1
        guard !Motion.isStill else {
            stage = .settled
            return
        }
        Task { @MainActor in
            let beats: [(PullStage, UInt64)] = [
                (.stilling, 120_000_000),
                (.inking, 80_000_000),
                (.wiping, 220_000_000),
                (.paper, 140_000_000),
                (.press, 220_000_000),
                (.peel, 120_000_000),
                (.settled, 400_000_000),
            ]
            for (next, wait) in beats {
                try? await Task.sleep(nanoseconds: wait)
                withMotion(next == .peel ? Motion.bouncy : Motion.gentle) { stage = next }
                switch next {
                case .inking: Haptics.soft()
                case .wiping: Haptics.tap()
                case .press: Haptics.thud()
                case .settled:
                    Haptics.celebrate()
                    Tones.shared.play(tier >= .clean ? .fanfare : .success)
                    if tier == .best {
                        try? await Task.sleep(nanoseconds: 200_000_000)
                        Haptics.celebrate()
                        Tones.shared.play(.step(7))
                    }
                default: break
                }
            }
        }
    }

    var headline: String {
        switch tier {
        case .best: return "Not a scar, and your longest line"
        case .clean: return "Pulled clean. Nothing guessed on it"
        case .good:
            let scars = pulled?.scars ?? 0
            return "Pulled. \(Spelled.capitalised(scars)) scar\(scars == 1 ? "" : "s"), and they print"
        case .finished: return "Pulled. It gave up in the end"
        }
    }

    var praise: String {
        AppInfo.line(from: AppInfo.praise, seed: record.platesPulled * 7 + (pulled?.longestLine ?? 0))
    }

    /// The margin card: specific, earned, true, and with no guilt in it.
    var marginCard: String {
        guard let print = pulled else { return "" }
        if record.platesPulled <= 1 {
            return "Your first pull. It goes up to dry, and the plate is wiped for tomorrow."
        }
        let opening = print.isClean
            ? "Pulled clean"
            : "Pulled, \(Spelled.out(print.scars)) scar\(print.scars == 1 ? "" : "s") in the margin"
        let body = "\(opening) — \(Spelled.out(print.points)) points, longest line \(Spelled.out(print.longestLine)). \(Spelled.capitalised(record.platesPulled)) on the line."
        if let next = Play.earned.next(after: record.platesPulled) {
            return "\(body) \(Play.horizon(next))."
        }
        // Past the last milestone it names the record instead.
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM"
        let first = record.pulls.first?.date ?? print.date
        let day = Calendar.current.component(.day, from: first)
        return "\(body) The book runs back to the \(Spelled.ordinal(day)) of \(formatter.string(from: first))."
    }

    var shareLine: String {
        guard let print = pulled ?? record.pulls.last else { return "Crosshatch" }
        let scars = print.isClean ? "not a scar" : "\(Spelled.out(print.scars)) scar\(print.scars == 1 ? "" : "s")"
        return "Crosshatch · plate \(print.number) · \(Spelled.out(print.points)) points, longest line \(Spelled.out(print.longestLine)), \(scars)."
    }

    // MARK: - The shop

    func setCalm(_ on: Bool) { record.calmInk = on; persist() }
    func setAssist(_ on: Bool) { record.assist = on; persist() }

    func scrapThePlates() {
        record = Record()
        session = nil
        pulled = nil
        stage = .none
        UserDefaults.standard.removeObject(forKey: Self.storeKey)
        Haptics.warning()
    }

    var todaysPull: Pull? {
        let today = Play.dayNumber(for: .now)
        return record.pulls.last { $0.day == today }
    }

    /// The rung the next plate in her run would be ruled at, and whether the run has reached
    /// the fortieth, where the unlock stands.
    var nextRung: Int { max(1, record.rung) }
    var runIsLocked: Bool { nextRung > Play.freeRungs && !isPro }

    func setMargin(_ line: String, seconds: Double = 2.4) {
        withMotion(Motion.gentle) { marginLine = line }
        marginTask?.cancel()
        guard !Motion.isStill else { return }
        marginTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
            guard !Task.isCancelled else { return }
            withMotion(Motion.gentle) { marginLine = nil }
        }
    }

    private func save() {
        if let current = session {
            let saved = SavedPlate(plate: current.plate, grid: current.grid, run: current.run,
                                   actions: current.actions, scars: current.scars,
                                   openedSeals: Array(current.opened), started: current.started)
            if current.isDaily { record.dailyBed = saved } else { record.bed = saved }
        }
        persist()
    }

    private func persist() {
        guard let data = try? JSONEncoder().encode(record) else { return }
        UserDefaults.standard.set(data, forKey: Self.storeKey)
    }

    // MARK: - What the tooling has to be able to reach

    /// A bench with a real record on it — prints on the line, a month of the day-book inked,
    /// thirty-one days running — seeded deterministically, so every capture has the same bench
    /// in it and the ladder strip can photograph rung 5 next to rung 500.
    private func seedBench() {
        let rung = LaunchOptions.level ?? 51
        var rng = Seeded(seed: 0x4352_4F53_5348_4154)
        // Yesterday backwards: today's plate is still on the bed, which is the state the line's
        // mock shows — today ringed on the day-book with the registration cross in it.
        let today = Play.dayNumber(for: .now) - 1
        let total = max(1, min(214, rung * 4 + 10))
        var pulls: [Pull] = []
        var day = today
        var made = 0
        while made < total {
            let theme = Themes.all[rng.int(Themes.all.count)]
            let members = 4 + made % 2
            let categories = 4
            let rows = (0..<members).map { entity in
                (0..<categories).map { category in
                    theme.blocks[category].members[(entity + category * 2) % 6].preferred
                }
            }
            pulls.append(Pull(number: total - made,
                              day: day,
                              date: Date(timeIntervalSince1970: Double(day) * 86_400 + 32_400),
                              title: theme.title,
                              themeID: theme.id,
                              points: members * (categories - 1),
                              longestLine: 6 + rng.int(14),
                              scars: made % 4 == 1 ? 1 + rng.int(2) : 0,
                              burnished: false,
                              tier: made % 4 == 1 ? Run.Tier.good.rawValue : Run.Tier.clean.rawValue,
                              rows: rows,
                              names: (0..<members).map { theme.blocks[0].members[$0].short },
                              ink: (total - made) % 6))
            made += 1
            // The last thirty-one days are unbroken; behind that a day is sometimes missed,
            // and a missed day is a square of bare copper rather than an accusation.
            day -= (made < 31 || rng.int(5) > 0) ? 1 : 2
        }
        record.pulls = pulls.reversed()
        record.rung = rung
        record.bestLine = 58
        record.pointsCut = pulls.reduce(0) { $0 + $1.points }
        // A record with an opinion in it: the two kinds she is solid at and the rest she is
        // not, so `Mastery.next` asks the generator for something in particular.
        for kind in Play.kindsOpen(at: rung) {
            let solid = kind == .direct || kind == .negative
            for _ in 0..<3 { record.mastery.record(kind.rawValue, correct: solid) }
        }
        for theme in Themes.ids.prefix(6) { record.themes.record(theme, correct: true) }
        record.recentThemes = Array(Themes.ids.prefix(3))
    }

    /// Nine of twelve points cut, a block closed and a scar in the margin — the state mock 1
    /// shows, reached by cutting the plate rather than by posing it.
    private func poseForCapture() {
        guard let current = session else { return }
        let whole = stepsToPull(current)
        let target: Int
        if LaunchOptions.won {
            target = whole
        } else if LaunchOptions.demo == "pull" {
            target = max(0, whole - 3)
        } else if LaunchOptions.demo == "cut" {
            target = max(0, whole / 3)
        } else {
            // Mid-cut: two thirds of the way down the plate, one block closed, a scar in the
            // margin — which is the state the mock shows.
            target = max(1, whole * 3 / 5)
        }
        // The win capture is a clean pull: the tier the reward is loudest at, and the one the
        // mock shows. A demo of the pull keeps its hairline, because a scar printing is the
        // other half of what the margin is for.
        advance(to: target, slipAt: LaunchOptions.won ? nil : min(4, max(1, target - 2)))
        if LaunchOptions.won { pull() }
    }

    /// How many forced marks a whole plate takes, so a capture can stop part of the way down
    /// one rather than guessing at a number of points.
    private func stepsToPull(_ session: Session) -> Int {
        var grid = session.grid
        var opened = session.opened
        var steps = 0
        while !grid.isPulled, steps < 400 {
            let clues = session.plate.clues.map { clue -> Clue in
                var out = clue
                out.sealed = clue.sealed && !opened.contains(clue.id)
                return out
            }
            let available = (Solver.fromClues(grid, clues: clues) + Solver.fromPlate(grid))
                .filter { grid.at($0.x, $0.y) == .blank }
            guard let step = available.first(where: { $0.mark == .point }) ?? available.first else {
                if let next = session.plate.clues.first(where: { $0.sealed && !opened.contains($0.id) }) {
                    opened.insert(next.id)
                    continue
                }
                break
            }
            grid.set(step.x, step.y, step.mark)
            Solver.assist(&grid, collecting: false)
            steps += 1
        }
        return steps
    }

    /// Cut what the clues force, one mark at a time, `target` marks deep.
    private func advance(to target: Int, slipAt: Int? = nil) {
        guard var current = session else { return }
        var made = 0
        while made < target, made < 240 {
            let available = forced(in: current)
            // Points first, so a posed plate fills the way a played one does rather than
            // spending its marks on rule-outs the assist would have made anyway.
            guard let step = available.first(where: { $0.mark == .point }) ?? available.first else {
                if let next = current.plate.clues.first(where: { $0.sealed && !current.opened.contains($0.id) }) {
                    current.opened.insert(next.id)
                    continue
                }
                break
            }
            // A slip early on, so the margin in every capture has a hairline in it and the
            // line she is protecting is a real one.
            if made == slipAt, let wrong = wrongCut(in: current) {
                current.actions.append(Action(x: wrong.0, y: wrong.1, mark: .ruled, forced: false, applied: false))
            }
            current.actions.append(Action(x: step.x, y: step.y, mark: step.mark, forced: true, applied: true))
            current.grid.set(step.x, step.y, step.mark)
            Solver.assist(&current.grid, collecting: false)
            made += 1
        }
        current.run = replayRun(current.actions)
        current.scars = current.actions.filter { !$0.forced }.enumerated().map { index, _ in
            Double((index * 37 + 11) % 83) / 83
        }
        settle(&current)
        session = current
    }

    /// A pairing the clues do not force and the answer does not hold: what a guess looks like.
    private func wrongCut(in session: Session) -> (Cell, Cell)? {
        for i in 0..<session.plate.members {
            for j in 0..<session.plate.members {
                let x = Cell(category: 0, member: i)
                let y = Cell(category: session.plate.categories - 1, member: j)
                if session.grid.at(x, y) == .blank, !session.plate.solution.holds(x, y) { return (x, y) }
            }
        }
        return nil
    }

    // MARK: - Demo

    /// Nothing on a runner can touch the screen, so the app cuts its own plate. `-demo cut`
    /// runs three crosshatches and a point with its full cascade; `-demo pull` runs the last
    /// points and the pull.
    func startDemo(_ name: String) {
        demoTask?.cancel()
        demoTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: 600_000_000)
            for _ in 0..<(name == "pull" ? 6 : 4) {
                let available = forcedNow
                let next = name == "pull" ? (available.first { $0.mark == .point } ?? available.first) : available.first
                guard stage == .none, let step = next else { break }
                cut(step.x, step.y)
                if step.mark == .point {
                    // Bare copper to ruled out to fixed: the second tap is the point going in.
                    try? await Task.sleep(nanoseconds: 200_000_000)
                    cut(step.x, step.y)
                }
                try? await Task.sleep(nanoseconds: 460_000_000)
            }
        }
    }
}
