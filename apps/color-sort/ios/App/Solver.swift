import Foundation

/// What the solver could prove about a board.
enum SolveResult: Equatable, Sendable {
    /// A verified sequence of pours that finishes the board. `optimal` is true when the
    /// breadth-first pass found it, so the move count is the shortest possible — that number
    /// becomes the level's par.
    case solved(moves: [Move], optimal: Bool)
    /// The whole state space was searched and none of it ends in a finished board.
    case unsolvable
    /// Neither search finished inside its budget. The generator throws these boards away
    /// too: a board nobody has solved is not a board anyone should be handed.
    case unknown
}

/// Breadth-first search over tube states, with a depth-first fallback for the few boards
/// whose breadth-first frontier does not fit in the budget.
///
/// Nothing here is random, so the same board always yields the same solution and the same
/// par — which is what lets the daily puzzle be the same puzzle, with the same par, for
/// everyone who opens the app on a given day.
enum Solver {
    /// Positions expanded before breadth-first gives up. Reached only by the widest boards;
    /// five or six colors and two spare tubes normally finish in a few thousand.
    static let breadthBudget = 400_000
    /// Positions visited before the depth-first fallback gives up.
    static let depthBudget = 200_000

    static func solve(_ board: Board,
                      breadthBudget: Int = Solver.breadthBudget,
                      depthBudget: Int = Solver.depthBudget) -> SolveResult {
        switch breadthFirst(board, budget: breadthBudget) {
        case .solved(let moves): return .solved(moves: moves, optimal: true)
        case .exhausted: return .unsolvable
        case .outOfBudget: break
        }
        if let moves = depthFirst(board, budget: depthBudget) {
            return .solved(moves: moves, optimal: false)
        }
        return .unknown
    }

    // MARK: - Breadth-first

    private enum BreadthOutcome {
        case solved([Move])
        case exhausted
        case outOfBudget
    }

    private static func breadthFirst(_ start: Board, budget: Int) -> BreadthOutcome {
        if start.isSolved { return .solved([]) }
        let startKey = start.key
        var visited: Set<BoardKey> = [startKey]
        var came: [BoardKey: (parent: BoardKey, move: Move)] = [:]
        var frontier: [(board: Board, key: BoardKey)] = [(start, startKey)]
        var expanded = 0

        while !frontier.isEmpty {
            var next: [(board: Board, key: BoardKey)] = []
            for (board, key) in frontier {
                for move in board.searchMoves() {
                    let child = board.applying(move)
                    let childKey = child.key
                    guard visited.insert(childKey).inserted else { continue }
                    came[childKey] = (key, move)
                    if child.isSolved {
                        return .solved(path(from: startKey, to: childKey, came: came))
                    }
                    next.append((child, childKey))
                    expanded += 1
                    if expanded > budget { return .outOfBudget }
                }
            }
            frontier = next
        }
        return .exhausted
    }

    /// Walks the parent links back to the start. Safe despite the order-independent key,
    /// because only the first board to reach a key is ever expanded, so replaying these
    /// moves from the start board reproduces exactly the boards the search saw.
    private static func path(from start: BoardKey,
                             to goal: BoardKey,
                             came: [BoardKey: (parent: BoardKey, move: Move)]) -> [Move] {
        var moves: [Move] = []
        var cursor = goal
        while cursor != start, let step = came[cursor] {
            moves.append(step.move)
            cursor = step.parent
        }
        return moves.reversed()
    }

    // MARK: - Depth-first fallback

    private struct Frame {
        let board: Board
        let options: [Move]
        var index: Int
    }

    private static func depthFirst(_ start: Board, budget: Int, depthLimit: Int = 400) -> [Move]? {
        if start.isSolved { return [] }
        var visited: Set<BoardKey> = [start.key]
        var path: [Move] = []
        var frames: [Frame] = [Frame(board: start, options: ordered(start), index: 0)]
        var visits = 0

        while !frames.isEmpty {
            let top = frames.count - 1
            if frames[top].index >= frames[top].options.count || frames.count > depthLimit {
                frames.removeLast()
                if !path.isEmpty { path.removeLast() }
                continue
            }
            let move = frames[top].options[frames[top].index]
            frames[top].index += 1
            let child = frames[top].board.applying(move)
            let childKey = child.key
            guard visited.insert(childKey).inserted else { continue }
            visits += 1
            if visits > budget { return nil }
            path.append(move)
            if child.isSolved { return path }
            frames.append(Frame(board: child, options: ordered(child), index: 0))
        }
        return nil
    }

    /// Try the moves that finish a tube first, then the ones that at least land on their own
    /// color, and only then the ones that spend a spare tube. Ordering is what makes the
    /// depth-first pass a fallback worth having rather than a random walk.
    private static func ordered(_ board: Board) -> [Move] {
        board.searchMoves()
            .map { move -> (Move, Int) in (move, rank(move, on: board)) }
            .sorted { a, b in
                a.1 == b.1 ? (a.0.from, a.0.to) < (b.0.from, b.0.to) : a.1 < b.1
            }
            .map(\.0)
    }

    private static func rank(_ move: Move, on board: Board) -> Int {
        if board.tubes[move.to].isEmpty { return 3 }
        let amount = board.pourAmount(from: move.from, to: move.to)
        if board.tubes[move.to].count + amount == board.capacity { return 0 }
        if amount == board.topRun(move.from) { return 1 }
        return 2
    }
}
