import FactoryKit
import SwiftUI

/// The root state: one instance, the only thing that mutates the record, and the owner of
/// every beat of the winding and the lift.
@MainActor
final class Bench: ObservableObject {
    enum Which: String, Equatable { case today, book, loose }

    /// A line in the margin, and what kind of moment set it.
    struct MarginLine: Equatable {
        enum Kind { case plait, miss, deadEnd }
        var kind: Kind
        var text: String
        var id = UUID()
    }

    /// The piece coming off the pillow, and how far through the lift it is.
    struct Lift: Equatable {
        var piece: Piece
        var pricking: Pricking
        var tier: Run.Tier
        var headline: String
        var praise: String
        var ending: (String, String)
        var unlocked: [Earned.Milestone]
        /// 0 thud · 1 the thread tightens · 2 pins out · 3 the lace lifts · 4 the count ·
        /// 5 snips · 6 the headline · 7 the margin card.
        var phase: Int

        static func == (a: Lift, b: Lift) -> Bool {
            a.piece == b.piece && a.phase == b.phase && a.tier == b.tier
        }
    }

    static let finalPhase = 7

    @Published private(set) var record: Record
    @Published private(set) var which: Which = .today
    @Published private(set) var generating = false
    @Published var lift: Lift?
    @Published var line: MarginLine?
    /// The pin the thread stopped on, while its crease ring shows.
    @Published private(set) var deadEnd: Int?
    @Published private(set) var tugs = 0
    /// The pin that just sprang back up, and a counter to replay the spring.
    @Published private(set) var sprung: Int?
    @Published private(set) var springs = 0
    @Published private(set) var plaitFlash: Range<Int>?
    @Published private(set) var plaitTick = 0
    /// Each pin taken bumps this, so the newest segment's reach replays.
    @Published private(set) var reachTick = 0
    @Published var winding = false
    @Published var wantsPaywall = false

    var isPro = false
    private var gestureMissed = false
    private var saveTask: Task<Void, Never>?
    private var liftTask: Task<Void, Never>?
    private var lineTask: Task<Void, Never>?

    init() {
        if LaunchOptions.resetData { try? FileManager.default.removeItem(at: Record.url) }
        record = Record.load()
        if LaunchOptions.sampleData || LaunchOptions.demo != nil { seedSample() }
        if let rung = LaunchOptions.rung { seedRung(rung) }
        if let t = LaunchOptions.thread.flatMap(ThreadColour.init(rawValue:)) { record.thread = t }
        if LaunchOptions.board == "book" { which = .book }
        if LaunchOptions.board == "loose" { which = .loose }
        if LaunchOptions.rung != nil && LaunchOptions.board == nil { which = .book }
        rollDay()
        ensurePillow(sync: LaunchOptions.sampleData || LaunchOptions.rung != nil || LaunchOptions.demo != nil)
        if let wound = LaunchOptions.wound { wind(upTo: wound) }
        if LaunchOptions.won { finishAndLift() }
    }

    // MARK: - Reading

    var current: SavedPillow? {
        which == .today ? record.todayPillow : record.pillow
    }

    var todayPiece: Piece? { record.todayPiece() }

    /// Today's pattern is already in the sampler and nothing is being lifted.
    var todayDone: Bool { which == .today && todayPiece != nil && lift == nil }

    var bookOpen: Bool { isPro || LaunchOptions.forcePro || record.rung <= Play.freePatterns }

    var nextBookGround: Ground { Play.nextGround(rung: record.rung, record: record) }

    func isOnThread(_ cell: Int) -> Bool {
        current?.path.contains(UInt8(cell)) ?? false
    }

    // MARK: - The day

    /// On launch and on becoming active: a new day replaces today's pillow. A finished
    /// yesterday stays in the sampler; an unfinished one was never lifted, so nothing is lost
    /// but its thread.
    func rollDay() {
        let today = Play.dayNumber()
        guard record.todayDay != today else { return }
        record.todayDay = today
        record.todayPillow = nil
        if which == .today { lift = nil }
        if let t = record.tomorrow, t.seed == Play.daySeed(today) {
            record.todayPillow = SavedPillow(pricking: t, kind: .today)
            record.tomorrow = nil
        }
        scheduleSave()
    }

    // MARK: - Pinning a pattern

    /// Show `which`, pricking its pattern if there is none yet.
    func show(_ w: Which) {
        if w == .book && !bookOpen {
            wantsPaywall = true
            return
        }
        if w == .loose && !(isPro || LaunchOptions.forcePro) {
            wantsPaywall = true
            return
        }
        if w != which || lift != nil {
            withMotion(Motion.gentle) {
                which = w
                lift = nil
                line = nil
            }
        }
        if w == .loose, let p = record.pillow, p.kind != .loose(n: record.loosePiecesWorked + 1) {
            record.pillow = nil
        }
        if w == .book, let p = record.pillow, p.kind != .book(rung: record.rung) {
            record.pillow = nil
        }
        ensurePillow()
    }

    func pinNext() { show(.book) }
    func workLoose() { show(.loose) }
    func backToToday() { show(.today) }

    /// The pricking is generated off the main actor; the pins arriving in a wave covers it.
    func ensurePillow(sync: Bool = false) {
        guard current == nil, !generating else { return }
        if which == .today && todayPiece != nil { return }
        let day = Play.dayNumber()
        let rung = record.rung
        let salt = record.salt
        let loose = record.loosePiecesWorked + 1
        let which = self.which
        let ground = nextBookGround
        let cached = record.nextBook
        let make: @Sendable () -> (Pricking, Piece.Kind) = {
            switch which {
            case .today:
                return (Play.todayPricking(day: day), .today)
            case .book:
                if let cached, cached.rung == rung, cached.ground == ground { return (cached, .book(rung: rung)) }
                return (Play.bookPricking(rung: rung, ground: ground, salt: salt), .book(rung: rung))
            case .loose:
                return (Play.loosePricking(n: loose, rung: rung, ground: ground, salt: salt), .loose(n: loose))
            }
        }
        if sync {
            let (p, kind) = make()
            place(SavedPillow(pricking: p, kind: kind), for: which)
            return
        }
        generating = true
        Task.detached(priority: .userInitiated) {
            let (p, kind) = make()
            await MainActor.run {
                self.generating = false
                guard self.which == which, self.current == nil else { return }
                withMotion(Motion.gentle) {
                    self.place(SavedPillow(pricking: p, kind: kind), for: which)
                }
            }
        }
    }

    private func place(_ pillow: SavedPillow, for which: Which) {
        if which == .today { record.todayPillow = pillow } else { record.pillow = pillow }
        if which == .book { record.nextBook = nil }
        scheduleSave()
    }

    private func mutate(_ change: (inout SavedPillow) -> Void) {
        if which == .today {
            guard var p = record.todayPillow else { return }
            change(&p)
            record.todayPillow = p
        } else {
            guard var p = record.pillow else { return }
            change(&p)
            record.pillow = p
        }
        scheduleSave()
    }

    // MARK: - Winding

    /// Whether the thread may take `cell` next.
    func canTake(_ cell: Int) -> Bool {
        guard let p = current, lift == nil else { return false }
        let pr = p.pricking
        guard cell >= 0, cell < pr.open.count, pr.open[cell], !p.path.contains(UInt8(cell)) else { return false }
        guard let head = p.head else {
            if let s = pr.start { return cell == Int(s) }
            return true
        }
        return pr.canStep(from: head, to: cell)
    }

    /// Take one pin: the reach, the wrap, the sink, a detent and a note on the phrase.
    @discardableResult
    func take(_ cell: Int) -> Bool {
        guard canTake(cell) else { return false }
        var plaited: Range<Int>?
        var runLength = 1
        var complete = false
        var stuck = false
        mutate { p in
            p.path.append(UInt8(cell))
            p.run.hit()
            let path = p.path.map(Int.init)
            let n = path.count - 1
            // The straight run the new pin extends, for the rising phrase.
            if n >= 1 {
                let dir = path[n] - path[n - 1]
                var i = n - 1
                while i >= 1 && path[i] - path[i - 1] == dir { i -= 1 }
                runLength = n - i + 1
            }
            // A turn at the previous pin closes the run before it: four or more pins, a plait.
            if n >= 2, path[n] - path[n - 1] != path[n - 1] - path[n - 2] {
                let dir = path[n - 1] - path[n - 2]
                var i = n - 2
                while i >= 1 && path[i] - path[i - 1] == dir { i -= 1 }
                if n - 1 - i + 1 >= 4 {
                    plaited = i..<n
                    p.plaits.append(i..<n)
                }
            }
            complete = p.path.count == p.pricking.pins
            if !complete {
                let open = p.pricking.neighbours(cell).contains { !p.path.contains(UInt8($0)) }
                stuck = !open
            }
        }
        reachTick += 1
        deadEnd = nil
        Haptics.selection()
        Tones.shared.play(.step(runLength % 5), volume: 0.35)
        if let plaited {
            withMotion(Motion.pop) {
                plaitFlash = plaited
                plaitTick += 1
            }
            Haptics.tap()
            Tones.shared.play(.pop, volume: 0.5)
            say(.plait, Voice.plaitLine(pins: plaited.count), for: 1.5)
        }
        if complete {
            startLift()
        } else if stuck {
            deadEnd = cell
            tugs += 1
            Haptics.rigid()
            Tones.shared.play(.miss, volume: 0.4)
            say(.deadEnd, Voice.deadEnd, for: 2)
            Task { @MainActor in
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                if self.deadEnd == cell { withMotion(Motion.gentle) { self.deadEnd = nil } }
            }
        }
        return true
    }

    /// Unwind the thread back to `index` (the pin at `index` stays). One miss per gesture,
    /// however many pins come off.
    func unpick(to index: Int) {
        guard let p = current, index >= 0, index < p.path.count - 1, lift == nil else { return }
        let freed = Int(p.path[index + 1])
        mutate { p in
            p.path.removeSubrange((index + 1)...)
            p.plaits.removeAll { $0.upperBound >= p.path.count }
            if !gestureMissed { p.run.miss() }
        }
        let first = !gestureMissed
        gestureMissed = true
        deadEnd = nil
        sprung = freed
        springs += 1
        reachTick += 1
        Haptics.soft()
        Tones.shared.play(.tap, volume: 0.3)
        if first {
            say(.miss, Voice.missLine(unpicks: current?.run.misses ?? 1), for: 2)
        }
    }

    func unpickLast() {
        guard let p = current, p.path.count >= 2 else { return }
        unpick(to: p.path.count - 2)
    }

    /// The finger lifted: the gesture's miss is spent, the bobbin drops.
    func endGesture() {
        gestureMissed = false
        withMotion(Motion.bouncy) { winding = false }
    }

    /// "Pull the pins": the thread comes off and the pattern starts over. The piece will not
    /// be clean, and the lift will have no snips.
    func pullPins() {
        mutate { p in
            p.path = []
            p.plaits = []
            p.markers = []
            p.run = Run()
            p.restarted = true
        }
        deadEnd = nil
        line = nil
        Haptics.soft()
    }

    /// A marking pin beside a bare hole: a note to yourself. It knows nothing.
    func toggleMarker(_ cell: Int) {
        guard record.hasEarned("pin"), let p = current, !p.path.contains(UInt8(cell)) else { return }
        mutate { p in
            if let i = p.markers.firstIndex(of: UInt8(cell)) {
                p.markers.remove(at: i)
            } else if p.markers.count < 3 {
                p.markers.append(UInt8(cell))
            }
        }
        Haptics.tap()
        Tones.shared.play(.pop, volume: 0.5)
    }

    private func say(_ kind: MarginLine.Kind, _ text: String, for seconds: Double) {
        withMotion(Motion.gentle) { line = MarginLine(kind: kind, text: text) }
        lineTask?.cancel()
        let id = line?.id
        lineTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
            guard !Task.isCancelled else { return }
            // The line sets in the margin and stays until the next one; only a plait's
            // passes, because a plait is a flourish, not news.
            if kind == .plait, self.line?.id == id {
                withMotion(Motion.gentle) { self.line = nil }
            }
        }
    }

    // MARK: - The lift

    private func startLift() {
        guard let p = current else { return }
        let before = record.pieces.count
        var tier = p.run.tier(score: p.run.longestChain, beating: record.bestThread)
        // The loudest headline says "clean"; a longer thread with an unpick in it is not.
        if tier == .best && !p.run.isClean { tier = p.run.tier(score: 0, beating: .max) }
        let piece = Piece(id: before + 1, day: Play.dayNumber(), date: .now, kind: p.kind,
                          side: p.pricking.side, shape: p.pricking.shape, ground: p.pricking.ground,
                          pins: p.pricking.pins, path: p.path, plaits: p.plaits,
                          unpicks: p.run.misses, longestThread: p.run.longestChain,
                          tier: tier.rawValue, thread: record.threadInHand,
                          picot: record.hasEarned("gold"), initials: record.initials,
                          restarted: p.restarted)

        // What was done is written where the next pattern is chosen from.
        if p.run.misses <= 1 && !p.restarted {
            record.mastery.record(p.pricking.ground, correct: true)
        } else if p.run.misses >= 3 || p.restarted {
            record.mastery.record(p.pricking.ground, correct: false)
        }
        record.pieces.append(piece)
        record.bestThread = max(record.bestThread, p.run.longestChain)
        switch p.kind {
        case .today:
            record.todayPillow = nil
        case .book:
            record.rung += 1
            record.recentGrounds = Array((record.recentGrounds + [p.pricking.ground]).suffix(3))
            record.pillow = nil
        case .loose:
            record.loosePiecesWorked += 1
            record.pillow = nil
        }
        scheduleSave()

        let next: (Int, Ground)? = bookOpen ? (Play.dials(at: record.rung).side, nextBookGround) : nil
        let unlocked = Play.earned.justUnlocked(from: before, to: record.pieces.count)
        var praise = Voice.praiseLine()
        if let m = unlocked.last { praise = m.blurb }
        let lift = Lift(piece: piece, pricking: p.pricking, tier: tier,
                        headline: Voice.headline(tier, unpicks: piece.unpicks),
                        praise: praise,
                        ending: Voice.ending(for: piece, record: record, next: next),
                        unlocked: unlocked,
                        phase: Motion.isStill ? Self.finalPhase : 0)
        self.lift = lift
        prickAhead(after: p.kind)
        if !Motion.isStill { runLift(tier: tier) }
    }

    /// DESIGN.md's timeline, beat by beat. Under `-stillFrames` the lift is set at its last
    /// phase at once, so a capture shows the lace lifted, the pricks, the numeral and the card.
    private func runLift(tier: Run.Tier) {
        liftTask?.cancel()
        liftTask = Task { @MainActor in
            @MainActor func at(_ ms: Int, _ phase: Int, _ beat: () -> Void = {}) async {
                try? await Task.sleep(nanoseconds: UInt64(ms) * 1_000_000)
                guard !Task.isCancelled, lift != nil else { return }
                withMotion(phase == 3 ? Motion.bouncy : Motion.gentle) { lift?.phase = phase }
                beat()
            }
            Haptics.thud()
            await at(120, 1)
            try? await Task.sleep(nanoseconds: 80_000_000)
            Tones.shared.play(tier >= .clean ? .success : .success, volume: 0.8)
            await at(60, 2) {
                // Four beats spaced through the pins coming out.
                for beat in 0..<4 {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.11 * Double(beat)) {
                        Haptics.impact(0.25 + 0.15 * CGFloat(beat))
                        Tones.shared.play(.step(beat), volume: 0.6)
                    }
                }
            }
            await at(460, 3) {
                Haptics.celebrate()
                Tones.shared.play(tier >= .clean ? .fanfare : .success, volume: 0.8)
                if tier == .best {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { Haptics.celebrate() }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) { Tones.shared.play(.step(7), volume: 0.6) }
                }
            }
            await at(180, 4)
            await at(100, 5)
            await at(150, 6)
            await at(170, 7)
        }
    }

    /// The next book pattern, and tomorrow's, pricked in the background so nobody waits.
    private func prickAhead(after kind: Piece.Kind) {
        let rung = record.rung, salt = record.salt, ground = nextBookGround
        let tomorrow = Play.dayNumber() + 1
        let wantTomorrow = kind == .today && record.tomorrow?.seed != Play.daySeed(tomorrow)
        let wantBook = bookOpen && record.nextBook?.rung != rung
        guard wantTomorrow || wantBook else { return }
        Task.detached(priority: .utility) {
            let book = wantBook ? Play.bookPricking(rung: rung, ground: ground, salt: salt) : nil
            let day = wantTomorrow ? Play.todayPricking(day: tomorrow) : nil
            await MainActor.run {
                if let book { self.record.nextBook = book }
                if let day { self.record.tomorrow = day }
                self.scheduleSave()
            }
        }
    }

    // MARK: - The workbox

    func setThread(_ t: ThreadColour) { record.thread = t; scheduleSave() }
    func setCover(_ c: Cover) { record.cover = c; scheduleSave() }
    func setInitials(_ s: String) { record.initials = String(s.uppercased().prefix(2)); scheduleSave() }
    func setReminder(_ hour: Int?) { record.reminderHour = hour; scheduleSave() }

    func emptyWorkbox() {
        let salt = Record.fresh().salt
        record = Record(salt: salt)
        record.todayDay = Play.dayNumber()
        lift = nil
        line = nil
        which = .today
        Reminder.cancel()
        scheduleSave()
        ensurePillow()
    }

    // MARK: - Saving

    func scheduleSave() {
        saveTask?.cancel()
        saveTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: 100_000_000)
            guard !Task.isCancelled else { return }
            self.record.save()
        }
    }

    func saveNow() {
        saveTask?.cancel()
        record.save()
    }

    // MARK: - Tooling

    /// Wind the current pattern along its answer, up to `count` pins.
    func wind(upTo count: Int) {
        guard let p = current else { return }
        let answer = orientedAnswer(p.pricking).map(Int.init)
        let target = min(count, p.pricking.pins - 1)
        let saved = Motion.isStill
        _ = saved
        for cell in answer.dropFirst(p.path.count).prefix(max(0, target - p.path.count)) {
            silentTake(cell)
        }
        line = nil
    }

    /// The answer, starting from the published start.
    func orientedAnswer(_ p: Pricking) -> [UInt8] {
        if let s = p.start, p.answer.first != s { return p.answer.reversed() }
        return p.answer
    }

    /// Take without sound or haptics — for seeding a capture.
    private func silentTake(_ cell: Int) {
        guard canTake(cell) else { return }
        mutate { p in
            p.path.append(UInt8(cell))
            p.run.hit()
            let path = p.path.map(Int.init)
            let n = path.count - 1
            if n >= 2, path[n] - path[n - 1] != path[n - 1] - path[n - 2] {
                let dir = path[n - 1] - path[n - 2]
                var i = n - 2
                while i >= 1 && path[i] - path[i - 1] == dir { i -= 1 }
                if n - i >= 4 { p.plaits.append(i..<n) }
            }
        }
    }

    /// Lift the current pattern at once: wind it to the last pin and take that.
    private func finishAndLift() {
        guard let p = current else { return }
        wind(upTo: p.pricking.pins - 1)
        let answer = orientedAnswer(p.pricking).map(Int.init)
        if let last = answer.last { take(last) }
    }

    /// `-demo wind` and `-demo lift`: the app performs its own signature interaction.
    func demo(_ name: String) {
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 1_500_000_000)
            guard let p = current else { return }
            let answer = orientedAnswer(p.pricking).map(Int.init)
            if name == "lift" {
                wind(upTo: p.pricking.pins - 3)
                try? await Task.sleep(nanoseconds: 400_000_000)
                for cell in answer.suffix(3) {
                    winding = true
                    take(cell)
                    try? await Task.sleep(nanoseconds: 320_000_000)
                }
                winding = false
                return
            }
            // Wind: fourteen pins with a wrong turn, its unpick, and the re-wind.
            var taken = 0
            winding = true
            while taken < 14, let cur = current, cur.path.count < cur.pricking.pins - 1 {
                let next = answer[cur.path.count]
                if taken == 6, let head = cur.head,
                   let wrong = cur.pricking.neighbours(head).first(where: { $0 != next && !cur.path.contains(UInt8($0)) }) {
                    take(wrong)
                    try? await Task.sleep(nanoseconds: 520_000_000)
                    unpickLast()
                    endGesture()
                    winding = true
                    try? await Task.sleep(nanoseconds: 420_000_000)
                }
                take(next)
                taken += 1
                try? await Task.sleep(nanoseconds: 230_000_000)
            }
            endGesture()
        }
    }

    // MARK: - Seeded records

    /// Rung 51, nineteen pieces with real threads, twelve days running ending yesterday, the
    /// silk and the marking pin earned, today's pattern half wound along its answer.
    private func seedSample() {
        var r = Record(salt: 0x5EED_1ACE)
        let today = Play.dayNumber()
        r.todayDay = today
        r.rung = 51
        var pieces: [Piece] = []
        var rng = SplitMix64(seed: 19)
        let grounds: [Ground] = [.tulle, .bar, .rose, .torchon, .spider]
        for i in 0..<19 {
            let isDay = i % 2 == 0 || i >= 13
            let day = today - (19 - i)
            let rung = isDay ? Play.dailyRung(day: day) : 44 + i / 2
            let side = Play.dials(at: rung).side
            let unpicks = [0, 0, 1, 0, 2, 0, 3, 0, 0, 1][rng.below(10)]
            let g = isDay ? Play.todayGround(day: day) : grounds[rng.below(grounds.count)]
            pieces.append(Self.samplePiece(id: i + 1, day: day, kind: isDay ? .today : .book(rung: rung),
                                           side: side, ground: g, unpicks: unpicks,
                                           thread: i >= 6 && i % 3 == 1 ? .rose : .indigo, seed: UInt64(i + 7)))
            if unpicks <= 1 { r.mastery.record(g, correct: true, at: Play.date(ofDay: day)) }
            if unpicks >= 3 { r.mastery.record(g, correct: false, at: Play.date(ofDay: day)) }
        }
        // Twelve days running, ending yesterday: every one of the last twelve days has its piece.
        let dayPieces = Set(pieces.filter(\.isToday).map(\.day))
        for d in (today - 12)..<today where !dayPieces.contains(d) {
            pieces.append(Self.samplePiece(id: 0, day: d, kind: .today, side: Play.dials(at: Play.dailyRung(day: d)).side,
                                           ground: Play.todayGround(day: d), unpicks: 0, thread: .indigo, seed: UInt64(d)))
        }
        pieces.sort { $0.day < $1.day }
        pieces = Array(pieces.suffix(19))
        for i in pieces.indices { pieces[i].id = i + 1 }
        r.pieces = pieces
        // The sample's best thread is short of a full eight by eight, so a clean lift of
        // today's is the loudest one — the lift the win's capture and its mock show.
        r.bestThread = min(pieces.map(\.longestThread).max() ?? 0, 49)
        r.recentGrounds = pieces.suffix(3).map(\.ground)
        record = r
        which = .today
        if !LaunchOptions.fresh && LaunchOptions.demo != "lift" {
            ensurePillow(sync: true)
            if let p = current {
                // Picked out once, a third of the way in, so the thread standing is the rest.
                let target = p.pricking.pins * 2 / 3
                if LaunchOptions.demo == nil && !LaunchOptions.won {
                    wind(upTo: target / 3)
                    mutate { $0.run.miss() }
                }
                wind(upTo: target)
                if LaunchOptions.demo == nil, let run = current?.plaits.last {
                    line = MarginLine(kind: .plait, text: "Plaited. \(Words.capitalised(run.count)) pins in a bar.")
                }
            }
        }
    }

    /// A book at `rung`, with a sampler of the size someone that far in would have.
    private func seedRung(_ rung: Int) {
        var r = Record(salt: 0x1ADD_E500)
        let today = Play.dayNumber()
        r.todayDay = today
        r.rung = rung
        let count = min(rung - 1 + rung / 3, 600)
        var pieces: [Piece] = []
        var rng = SplitMix64(seed: UInt64(rung))
        for i in 0..<count {
            let at = max(1, rung * i / max(count, 1))
            let day = today - (count - i)
            let open = Play.groundsOpen(at: at)
            let g = open[rng.below(open.count)]
            let unpicks = [0, 0, 1, 0, 2, 0, 3, 0, 1, 0][rng.below(10)]
            let thread: ThreadColour = i >= 40 && i % 4 == 0 ? .gold : (i >= 6 && i % 3 == 0 ? .rose : .indigo)
            pieces.append(Self.samplePiece(id: i + 1, day: day, kind: i % 3 == 0 ? .today : .book(rung: at),
                                           side: Play.dials(at: at).side, ground: g, unpicks: unpicks,
                                           thread: thread, seed: UInt64(i * 31 + rung), picot: i >= 40))
            if unpicks <= 1 { r.mastery.record(g, correct: true, at: Play.date(ofDay: day)) }
            if unpicks >= 3 { r.mastery.record(g, correct: false, at: Play.date(ofDay: day)) }
        }
        r.pieces = pieces
        r.bestThread = pieces.map(\.longestThread).max() ?? 0
        r.recentGrounds = pieces.suffix(3).map(\.ground)
        if r.hasEarned("gold") { r.thread = .gold } else if r.hasEarned("silk") { r.thread = .rose }
        if r.hasEarned("ticking") { r.cover = .ticking }
        record = r
    }

    private static func samplePiece(id: Int, day: Int, kind: Piece.Kind, side: Int, ground: Ground,
                                    unpicks: Int, thread: ThreadColour, seed: UInt64, picot: Bool = false) -> Piece {
        let path = Generator.thread(side: side, seed: seed)
        let plaits = ThreadGeometry.plaits(in: path, taken: path.count)
        let longest = unpicks == 0 ? path.count : path.count * 2 / 3
        let tier: Run.Tier = unpicks == 0 ? .clean : (unpicks == 1 ? .good : .finished)
        return Piece(id: id, day: day, date: Play.date(ofDay: day), kind: kind, side: side, shape: 1,
                     ground: ground, pins: path.count, path: path.map { UInt8($0) }, plaits: plaits,
                     unpicks: unpicks, longestThread: longest, tier: tier.rawValue, thread: thread,
                     picot: picot)
    }
}
