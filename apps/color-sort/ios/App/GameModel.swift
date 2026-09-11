import FactoryKit
import Foundation
import SwiftUI

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
        save()
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
    }

    // MARK: - Playing

    /// One tap: pick a tube up, put it back, or pour it into the tube just tapped.
    func tap(_ index: Int) {
        guard !isSolved, index < board.tubes.count else { return }
        guard let from = selection else {
            if !board.tubes[index].isEmpty { selection = index }
            return
        }
        if from == index {
            selection = nil
            return
        }
        if board.canPour(from: from, to: index) {
            pour(from: from, to: index)
        } else if !board.tubes[index].isEmpty {
            // Tapping another full tube picks that one up instead of failing silently.
            selection = index
        } else {
            selection = nil
        }
    }

    func pour(from: Int, to: Int) {
        guard board.pourAmount(from: from, to: to) > 0 else { return }
        history.append(board)
        board.pour(from: from, to: to)
        moves += 1
        selection = nil
        hint = nil
        Haptics.tap()

        if solutionFollows, let level, solutionCursor < level.solution.count,
           level.solution[solutionCursor] == Move(from: from, to: to) {
            solutionCursor += 1
        } else {
            solutionFollows = false
        }

        if board.isSolved {
            isSolved = true
            Haptics.success()
            if let level {
                pendingResult = FinishedLevel(levelID: level.id, moves: moves, par: level.par,
                                              dayKey: DayKey.key())
            }
        }
        save()
    }

    var canUndo: Bool { !history.isEmpty }

    func undo() {
        guard let previous = history.popLast() else { return }
        board = previous
        moves = max(0, moves - 1)
        selection = nil
        hint = nil
        isSolved = false
        solutionFollows = false
        save()
    }

    func restart() {
        guard let level else { return }
        board = level.board
        moves = 0
        history = []
        selection = nil
        hint = nil
        isSolved = false
        solutionCursor = 0
        solutionFollows = true
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
    func autoPlay(_ count: Int) {
        guard let level else { return }
        for move in level.solution.prefix(count) {
            pour(from: move.from, to: move.to)
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
