import FactoryKit
import Foundation
import SwiftUI
import UIKit

/// A pour in the air: which vial is tipped, where it is tipping, what colour is falling and how
/// much of it. Held apart from `board`, which is always the current truth — the flight is what
/// the eye follows between one truth and the next.
struct PourFlight: Equatable {
    let from: Int
    let to: Int
    let color: Int
    let amount: Int
    /// How full the destination was before the pour. The new units stack on top of these.
    let landing: Int
    var stage: Stage

    /// lift → the vial leaves the rack and tips; stream → the arc draws and the level rises;
    /// land → the level overshoots and settles; the flight then ends and the vial swings back.
    enum Stage { case lift, stream, land }
}

/// Everything a level in progress consists of. Written to disk after every pour, so a crash,
/// a kill or a phone that runs out of battery costs nothing — the complaint Water Sort's
/// reviewers make most often is losing hundreds of levels to exactly this.
private struct SavedGame: Codable {
    var level: Level
    var board: Board
    var moves: Int
    var history: [Board]
}

/// The board on screen, what has been done to it, and how to get it finished.
@MainActor
final class GameModel: ObservableObject {
    @Published private(set) var level: Level?
    @Published private(set) var board = Board(tubes: [])
    @Published private(set) var moves = 0
    @Published private(set) var isDealing = false
    @Published private(set) var isSolved = false
    /// The tube the next pour comes out of. Tapping it again puts it back.
    @Published var selection: Int?
    /// The move the hint is pointing at, straight out of the verified solution.
    @Published private(set) var hint: Move?
    @Published private(set) var isThinking = false
    /// Set when a level is finished, and cleared once the screen has recorded it.
    @Published var pendingResult: FinishedLevel?

    // MARK: - The pour, as the eye sees it

    /// The pour currently in the air, or nil when the rack is at rest.
    @Published private(set) var flight: PourFlight?
    /// The arc, drawn 0 → 1 out of the tipped mouth.
    @Published private(set) var stream: Double = 0
    /// How far the newly arrived units have risen in the receiving vial, 0 → 1 with an
    /// overshoot on `Motion.bouncy`.
    @Published private(set) var rise: Double = 1
    /// The vial that just came good, and a counter so its burst can be triggered again.
    @Published private(set) var completedTube: Int?
    @Published private(set) var completions = 0
    /// A refusal: the vial has no room. It shakes, warmly, and nothing else happens.
    @Published private(set) var refusedTube: Int?
    @Published private(set) var refusals = 0

    /// The timings the board is being drawn with — calm mode pours more slowly. Set by the
    /// screen, since the settings live there.
    var timing = BoardStyle()

    /// The first move of the verified solution, while the player has never poured at all. The
    /// vial breathes; nothing anywhere says "tap a tube".
    var teaching: Move? {
        guard !UserDefaults.standard.bool(forKey: Self.hasPouredKey) else { return nil }
        guard moves == 0, flight == nil, let level, !isDealing else { return nil }
        return level.solution.first
    }

    static let hasPouredKey = "tidepour.hasPoured"

    /// A capture with `-stillFrames`, or Reduce Motion, resolves the pour in one frame: a
    /// screenshot of a half-poured arc is a broken screenshot, and travel is exactly what
    /// Reduce Motion asks not to see.
    private var animates: Bool { !Motion.isStill && !UIAccessibility.isReduceMotionEnabled }

    private var history: [Board] = []
    /// How far the player has followed the stored solution. Once they step off it the
    /// solution no longer applies and the next hint re-solves from where they actually are.
    private var solutionCursor = 0
    private var solutionFollows = true

    struct FinishedLevel: Equatable, Identifiable {
        let levelID: LevelID
        let moves: Int
        let par: Int
        let dayKey: String

        /// Includes the move count so replaying and beating a level presents a fresh card.
        var id: String { LevelResult.key(for: levelID) + "-\(moves)" }
    }

    var par: Int { level?.par ?? 0 }
    var levelID: LevelID? { level?.id }

    var title: String {
        switch level?.id {
        case .numbered(let n): return "Level \(n)"
        case .daily: return "Daily puzzle"
        case nil: return "Tidepour"
        }
    }

    // MARK: - Loading

    /// Opens a level, resuming the saved board if there is one. Generation runs off the main
    /// actor: dealing and solving a board is the one thing here that is not instant.
    func open(_ id: LevelID, force: Bool = false) {
        if !force, level?.id == id, !board.tubes.isEmpty { return }
        if !force, let saved = Storage.savedGame(for: id) {
            apply(saved)
            return
        }
        isDealing = true
        hint = nil
        selection = nil
        isSolved = false
        Task {
            let level = await Task.detached(priority: .userInitiated) { () -> Level in
                if let cached = Storage.cachedLevel(for: id) { return cached }
                let fresh = LevelGenerator.level(id)
                Storage.cacheLevel(fresh)
                return fresh
            }.value
            self.begin(level)
        }
    }

    private func begin(_ level: Level) {
        self.level = level
        board = level.board
        moves = 0
        history = []
        solutionCursor = 0
        solutionFollows = true
        isSolved = false
        selection = nil
        hint = nil
        isDealing = false
        clearFlight()
        save()
    }

    /// Nothing in the air, nothing lit, nothing shaking.
    private func clearFlight() {
        flight = nil
        stream = 0
        rise = 1
        completedTube = nil
        refusedTube = nil
    }

    private func apply(_ saved: SavedGame) {
        level = saved.level
        board = saved.board
        moves = saved.moves
        history = saved.history
        solutionCursor = 0
        solutionFollows = saved.board == saved.level.board
        isSolved = saved.board.isSolved
        selection = nil
        hint = nil
        isDealing = false
        clearFlight()
    }

    // MARK: - Playing

    /// One tap: pick a vial up, put it back, or pour it into the vial just tapped.
    func tap(_ index: Int) {
        guard !isSolved, flight == nil, index < board.tubes.count else { return }
        guard let from = selection else {
            if !board.tubes[index].isEmpty {
                withMotion(Motion.snappy) { selection = index }
                Haptics.selection()
                Tones.shared.play(.tap)
            }
            return
        }
        if from == index {
            withMotion(Motion.snappy) { selection = nil }
            return
        }
        if board.canPour(from: from, to: index) {
            pour(from: from, to: index)
        } else if board.tubes[index].count >= Board.capacity {
            // No room. A warm refusal: the glass shakes once and keeps what it has.
            refusedTube = index
            refusals += 1
            Tones.shared.play(.miss, volume: 0.5)
            Haptics.soft()
        } else if !board.tubes[index].isEmpty {
            // A different colour with room in it: pick that one up instead of failing silently.
            withMotion(Motion.snappy) { selection = index }
            Haptics.selection()
        } else {
            withMotion(Motion.snappy) { selection = nil }
        }
    }

    /// Decant one glow into another, in four beats: the vial leaves the rack and tips, an arc
    /// draws from its mouth, the receiving level overshoots and settles, the vial swings back.
    func pour(from: Int, to: Int) {
        let amount = board.pourAmount(from: from, to: to)
        guard amount > 0, flight == nil, let color = board.tubes[from].last else { return }
        let landing = board.tubes[to].count

        history.append(board)
        hint = nil
        withMotion(Motion.snappy) { selection = nil }

        guard animates else {
            applyPour(from: from, to: to)
            rise = 1
            settle(after: Move(from: from, to: to))
            return
        }

        withMotion(Motion.snappy) {
            flight = PourFlight(from: from, to: to, color: color, amount: amount,
                                landing: landing, stage: .lift)
        }
        stream = 0
        Haptics.soft()

        let lift = timing.liftDuration
        let arc = timing.pourDuration
        let land = timing.landDuration

        Task { @MainActor in
            // Anticipation: the vial out of the rack and tipped toward where it is going.
            try? await Task.sleep(nanoseconds: nanos(lift))
            guard flight != nil else { return }
            applyPour(from: from, to: to)
            rise = 0
            flight?.stage = .stream
            withAnimation(.linear(duration: arc)) { stream = 1 }

            // The arc lands: the level rises past where it belongs and comes back.
            try? await Task.sleep(nanoseconds: nanos(arc))
            guard flight != nil else { return }
            flight?.stage = .land
            withMotion(Motion.bouncy) { rise = 1 }
            Haptics.rigid()
            Tones.shared.play(.step(min(Board.capacity, landing + amount) - 1))
            withAnimation(.easeOut(duration: 0.16)) { stream = 0 }
            noteCompletion(of: to)

            // The vial swings back into the rack.
            try? await Task.sleep(nanoseconds: nanos(land))
            withMotion(Motion.bouncy) { flight = nil }
            settle(after: Move(from: from, to: to))
        }
    }

    private func nanos(_ seconds: Double) -> UInt64 { UInt64(max(0, seconds) * 1_000_000_000) }

    /// The board's truth, the move counter and the fact that this player has now poured once.
    private func applyPour(from: Int, to: Int) {
        board.pour(from: from, to: to)
        moves += 1
        UserDefaults.standard.set(true, forKey: Self.hasPouredKey)
    }

    /// A vial that just came good: full, one colour, and never to be poured out of again.
    private func noteCompletion(of index: Int) {
        guard board.isComplete(index) else { return }
        completedTube = index
        completions += 1
        Haptics.impact(0.75)
        Tones.shared.play(.success)
    }

    /// Everything that happens once the liquid is where it is going.
    private func settle(after move: Move) {
        if !animates { noteCompletion(of: move.to) }

        if solutionFollows, let level, solutionCursor < level.solution.count,
           level.solution[solutionCursor] == move {
            solutionCursor += 1
        } else {
            solutionFollows = false
        }

        if board.isSolved {
            isSolved = true
            if let level {
                pendingResult = FinishedLevel(levelID: level.id, moves: moves, par: level.par,
                                              dayKey: DayKey.key())
            }
        }
        save()
    }

    var canUndo: Bool { !history.isEmpty && flight == nil }

    func undo() {
        guard flight == nil, let previous = history.popLast() else { return }
        withMotion(Motion.bouncy) {
            board = previous
            selection = nil
        }
        moves = max(0, moves - 1)
        hint = nil
        isSolved = false
        solutionFollows = false
        completedTube = nil
        Haptics.soft()
        Tones.shared.play(.pop, volume: 0.5)
        save()
    }

    func restart() {
        guard flight == nil, let level else { return }
        withMotion(Motion.gentle) {
            board = level.board
            selection = nil
        }
        moves = 0
        history = []
        hint = nil
        isSolved = false
        solutionCursor = 0
        solutionFollows = true
        completedTube = nil
        Haptics.thud()
        save()
    }

    /// Points at the next move of a solution this app has already verified.
    ///
    /// While the player is still on the stored line the answer is free. The moment they take
    /// their own route it re-solves from the board in front of them, which is the only honest
    /// way to keep the promise: there is always a way out, and here it is.
    func requestHint() {
        guard !isSolved, let level else { return }
        if solutionFollows, solutionCursor < level.solution.count {
            hint = level.solution[solutionCursor]
            selection = nil
            return
        }
        let current = board
        isThinking = true
        Task {
            let result = await Task.detached(priority: .userInitiated) { Solver.solve(current) }.value
            self.isThinking = false
            guard case .solved(let moves, _) = result, let next = moves.first else { return }
            self.hint = next
            self.selection = nil
        }
    }

    func clearHint() { hint = nil }

    // MARK: - Screenshot and QA support

    /// Plays the opening of the verified solution so a capture shows a board in mid-sort.
    ///
    /// Synchronous for a still capture, and paced for a filmstrip: nothing on a runner can
    /// touch the screen, so this is how the pour is seen to move at all.
    func autoPlay(_ count: Int, gap: Double = 0.12) {
        guard let level else { return }
        play(Array(level.solution.prefix(count)), gap: gap)
    }

    private func play(_ moves: [Move], gap: Double) {
        guard animates else {
            for move in moves { pour(from: move.from, to: move.to) }
            return
        }
        Task { @MainActor in
            for move in moves {
                while flight != nil { try? await Task.sleep(nanoseconds: 40_000_000) }
                guard !isSolved else { return }
                pour(from: move.from, to: move.to)
                try? await Task.sleep(nanoseconds: nanos(flightLength + gap))
            }
        }
    }

    /// Puts the board all but `remaining` moves along its verified solution, without animating
    /// any of it — so a demo of the *win* spends its frames on the win and not on the solve.
    private func fastForward(leaving remaining: Int) {
        guard let level, level.solution.count > remaining else { return }
        for move in level.solution.dropLast(remaining) {
            board.pour(from: move.from, to: move.to)
            moves += 1
        }
        solutionCursor = level.solution.count - remaining
        save()
    }

    /// How many pours the charted line takes.
    var solutionLength: Int { level?.solution.count ?? 0 }

    /// How long one whole pour takes from the lift to the vial back in the rack.
    var flightLength: Double {
        timing.liftDuration + timing.pourDuration + timing.landDuration
    }

    /// Waits for the board to be dealt. The generator solves every board before serving it,
    /// which on the widest racks is the one thing here that is not instant.
    func waitForBoard() async {
        for _ in 0..<60 where isDealing || board.tubes.isEmpty {
            try? await Task.sleep(nanoseconds: 100_000_000)
        }
    }

    /// `-demo <moment>`: the app performs its own signature interaction, and reaches its own
    /// win, with nobody to touch the screen.
    func playDemo(_ moment: String) {
        Task { @MainActor in
            await waitForBoard()
            try? await Task.sleep(nanoseconds: 250_000_000)
            switch moment {
            case "win":
                // Down the charted line to two pours from home, then the last two in front of
                // the camera: the filmstrip should spend its frames on the win, not the solve.
                fastForward(leaving: 2)
                guard let level else { return }
                play(Array(level.solution.suffix(2)), gap: 0.1)
            default:
                // Slowly, one at a time: the filmstrip has to catch the tilt, the arc and the
                // level coming up.
                autoPlay(4, gap: 0.5)
            }
        }
    }

    private func save() {
        guard let level else { return }
        Storage.save(SavedGame(level: level, board: board, moves: moves, history: history), for: level.id)
    }

    // MARK: - Storage

    /// UserDefaults, because a level in progress is small, is rewritten on every pour, and
    /// must survive a kill. SwiftData holds the finished levels.
    fileprivate enum Storage {
        private static let defaults = UserDefaults.standard

        static func key(_ id: LevelID) -> String {
            switch id {
            case .numbered(let n): return "level.\(n)"
            case .daily(let day): return "daily.\(day)"
            }
        }

        static func savedGame(for id: LevelID) -> SavedGame? {
            guard let data = defaults.data(forKey: "tidepour.game.\(key(id))") else { return nil }
            return try? JSONDecoder().decode(SavedGame.self, from: data)
        }

        static func save(_ game: SavedGame, for id: LevelID) {
            guard let data = try? JSONEncoder().encode(game) else { return }
            defaults.set(data, forKey: "tidepour.game.\(key(id))")
        }

        static func cachedLevel(for id: LevelID) -> Level? {
            guard let data = defaults.data(forKey: "tidepour.board.\(key(id))") else { return nil }
            return try? JSONDecoder().decode(Level.self, from: data)
        }

        static func cacheLevel(_ level: Level) {
            guard let data = try? JSONEncoder().encode(level) else { return }
            defaults.set(data, forKey: "tidepour.board.\(key(level.id))")
        }

        static func eraseEverything() {
            for k in defaults.dictionaryRepresentation().keys where k.hasPrefix("tidepour.") {
                defaults.removeObject(forKey: k)
            }
        }
    }

    /// Used by `-reset` and by Settings' erase button.
    static func eraseSavedBoards() { Storage.eraseEverything() }
}

extension Store {
    /// The one-time unlock, or the `-pro` flag the screenshot tooling uses to reach the
    /// unlocked screens on a simulator, where a real purchase cannot be completed.
    var isUnlocked: Bool { isPro || LaunchOptions.forcePro }
}
