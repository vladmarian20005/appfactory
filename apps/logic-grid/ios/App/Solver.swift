import Foundation

/// One mark the evidence forces, and what forced it.
struct Deduction: Equatable {
    var x: Cell
    var y: Cell
    var mark: Mark
    /// The clue that forced it, or nil when the plate itself did — a row with its point
    /// already cut, or a chain through a third category.
    var clue: Int?
}

/// The whole of the app's honesty. Every plate served is closed by this solver before it is
/// ruled, so "solvable by pure deduction" is a property of the binary rather than a promise in
/// a description; and the same code decides, at the moment of a cut, whether the clues forced
/// it — which is what a scar records and what the loupe names.
enum Solver {

    // MARK: - What the plate itself forces

    /// What the plate forces on its own, in one pass and without chaining: a row that has its
    /// point cannot have another, a row with one cell left standing has found its point, and a
    /// pairing with nothing in a third category able to stand between cannot hold.
    ///
    /// These are hers to spot, the same as a clue's — a cut forced by the plate itself takes
    /// just as cleanly. Only the first of the three is done *for* her, by the assist below.
    static func fromPlate(_ grid: Grid) -> [Deduction] {
        var found: [Deduction] = []
        let categories = grid.categories, members = grid.members

        for x in 0..<categories {
            for y in 0..<categories where y != x {
                for i in 0..<members {
                    var pointAt: Int?
                    var blanks: [Int] = []
                    for j in 0..<members {
                        switch grid.at(x, i, y, j) {
                        case .point: pointAt = j
                        case .blank: blanks.append(j)
                        case .ruled: break
                        }
                    }
                    if pointAt != nil {
                        for j in blanks {
                            found.append(Deduction(x: Cell(category: x, member: i), y: Cell(category: y, member: j), mark: .ruled, clue: nil))
                        }
                    } else if blanks.count == 1 {
                        found.append(Deduction(x: Cell(category: x, member: i), y: Cell(category: y, member: blanks[0]), mark: .point, clue: nil))
                    }
                }
            }
        }

        // Through a third category: if nothing in y can stand between (x,i) and (z,k), they
        // cannot be the same entity; if something in y is fixed to both, they are.
        for x in 0..<categories {
            for z in (x + 1)..<categories {
                for y in 0..<categories where y != x && y != z {
                    for i in 0..<members {
                        for k in 0..<members where grid.at(x, i, z, k) == .blank {
                            var support = false
                            var forced = false
                            for j in 0..<members {
                                let first = grid.at(x, i, y, j)
                                if first == .ruled { continue }
                                let second = grid.at(y, j, z, k)
                                if second == .ruled { continue }
                                support = true
                                if first == .point && second == .point { forced = true; break }
                            }
                            if forced || !support {
                                found.append(Deduction(x: Cell(category: x, member: i), y: Cell(category: z, member: k),
                                                       mark: forced ? .point : .ruled, clue: nil))
                            }
                        }
                    }
                }
            }
        }
        return found
    }

    /// The assist, and the whole of it: a fixed pairing rules out every other cell in its row
    /// and its column of that sub-grid, and the plate cuts them itself. That is the
    /// bookkeeping — it is not the puzzle, and it is all the plate does for her. Everything
    /// else on this page she spots or she does not.
    @discardableResult
    static func assist(_ grid: inout Grid, collecting: Bool = true) -> [Deduction] {
        var found: [Deduction] = []
        let categories = grid.categories, members = grid.members
        var changed = true
        while changed {
            changed = false
            for x in 0..<categories {
                for y in 0..<categories where y != x {
                    for i in 0..<members {
                        guard let pointAt = (0..<members).first(where: { grid.at(x, i, y, $0) == .point }) else { continue }
                        for j in 0..<members where j != pointAt && grid.at(x, i, y, j) == .blank {
                            grid.set(x, i, y, j, .ruled)
                            if collecting {
                                found.append(Deduction(x: Cell(category: x, member: i),
                                                       y: Cell(category: y, member: j), mark: .ruled, clue: nil))
                            }
                            changed = true
                        }
                    }
                }
            }
        }
        return found
    }

    /// One pass of the plate's own rules, applied. The proof engine's step; never the player's.
    @discardableResult
    static func closeOnce(_ grid: inout Grid) -> Bool {
        var changed = false
        for step in fromPlate(grid) where grid.at(step.x, step.y) == .blank {
            grid.set(step.x, step.y, step.mark)
            changed = true
        }
        return changed
    }

    /// Everything the plate forces, chained to a fixpoint. This is how a clue set is proved.
    static func close(_ grid: inout Grid) {
        while closeOnce(&grid) { }
    }

    // MARK: - What the clues force

    /// One pass of every legible clue over a settled plate. Nothing here chains: these are the
    /// marks the evidence forces *now*, which is exactly the set a cut has to be in to take
    /// cleanly.
    static func fromClues(_ grid: Grid, clues: [Clue], includingSealed: Bool = false) -> [Deduction] {
        var found: [Deduction] = []
        for (index, clue) in clues.enumerated() where includingSealed || !clue.sealed {
            append(&found, from: clue, index: index, in: grid)
        }
        return found
    }

    private static func append(_ found: inout [Deduction], from clue: Clue, index: Int, in grid: Grid) {
        func put(_ x: Cell, _ y: Cell, _ mark: Mark) {
            guard grid.at(x, y) == .blank else { return }
            guard !found.contains(where: { $0.x == x && $0.y == y && $0.mark == mark }) else { return }
            found.append(Deduction(x: x, y: y, mark: mark, clue: index))
        }

        switch clue.kind {
        case .direct:
            put(clue.a, clue.b, .point)

        case .negative:
            put(clue.a, clue.b, .ruled)

        case .either:
            guard let c = clue.c else { return }
            // Whatever else that category holds, it is not the answer to this one.
            let members = grid.members
            for m in 0..<members where m != clue.b.member && m != c.member {
                put(clue.a, Cell(category: clue.b.category, member: m), .ruled)
            }
            if grid.at(clue.a, clue.b) == .ruled { put(clue.a, c, .point) }
            if grid.at(clue.a, c) == .ruled { put(clue.a, clue.b, .point) }
            if grid.at(clue.a, clue.b) == .point { put(clue.a, c, .ruled) }
            if grid.at(clue.a, c) == .point { put(clue.a, clue.b, .ruled) }

        case .relational, .arithmetic, .adjacency:
            let ordered = clue.ordered
            let left = grid.possible(clue.a, in: ordered)
            let right = grid.possible(clue.b, in: ordered)
            for position in left where !supports(clue, position: position, otherSide: right, isLeft: true) {
                put(clue.a, Cell(category: ordered, member: position), .ruled)
            }
            for position in right where !supports(clue, position: position, otherSide: left, isLeft: false) {
                put(clue.b, Cell(category: ordered, member: position), .ruled)
            }

        case .exclusive:
            guard let c = clue.c, let d = clue.d else { return }
            switch grid.at(clue.a, clue.b) {
            case .point: put(c, d, .ruled)
            case .ruled: put(c, d, .point)
            case .blank: break
            }
            switch grid.at(c, d) {
            case .point: put(clue.a, clue.b, .ruled)
            case .ruled: put(clue.a, clue.b, .point)
            case .blank: break
            }
        }
    }

    /// Is there a position left on the other side that would let this one stand?
    private static func supports(_ clue: Clue, position: Int, otherSide: [Int], isLeft: Bool) -> Bool {
        switch clue.kind {
        case .relational:
            // a comes before b.
            return isLeft ? otherSide.contains { $0 > position } : otherSide.contains { $0 < position }
        case .arithmetic:
            // position(a) == position(b) + n.
            return isLeft ? otherSide.contains(position - clue.n) : otherSide.contains(position + clue.n)
        case .adjacency:
            return otherSide.contains(position - 1) || otherSide.contains(position + 1)
        default:
            return true
        }
    }

    // MARK: - Solving

    struct Attempt {
        var grid: Grid
        /// How many chained waves the plate needed. This is what `depth` means on the margin,
        /// and it is compared — it is how the generator picks between two minimal clue sets.
        var waves: Int
        var solved: Bool
    }

    /// Cut everything the clues force, over and over, until the plate stops giving. A plate is
    /// only ever served if this reaches every point on it.
    static func solve(_ start: Grid, clues: [Clue], from existing: Grid? = nil) -> Attempt {
        var grid = existing ?? start
        close(&grid)
        var waves = 0
        while !grid.isPulled {
            let forced = fromClues(grid, clues: clues, includingSealed: true)
            var moved = false
            for step in forced where grid.at(step.x, step.y) == .blank {
                grid.set(step.x, step.y, step.mark)
                moved = true
            }
            guard moved else { break }
            close(&grid)
            waves += 1
        }
        return Attempt(grid: grid, waves: max(waves, 1), solved: grid.isPulled)
    }

    /// Does this set of clues prove exactly one answer, by deduction alone?
    static func proves(_ clues: [Clue], categories: Int, members: Int) -> Attempt {
        solve(Grid(categories: categories, members: members), clues: clues)
    }

    /// How many rounds of inference the plate actually needs: one pass of the clues, one pass
    /// of the plate's own rules, over and over. This is what the margin means by `depth`, and
    /// it is compared — the generator picks between two minimal clue sets on it.
    static func depth(of clues: [Clue], categories: Int, members: Int) -> Int {
        var grid = Grid(categories: categories, members: members)
        var rounds = 0
        while !grid.isPulled, rounds < 60 {
            var moved = false
            for step in fromClues(grid, clues: clues, includingSealed: true)
            where grid.at(step.x, step.y) == .blank {
                grid.set(step.x, step.y, step.mark)
                moved = true
            }
            if closeOnce(&grid) { moved = true }
            rounds += 1
            if !moved { break }
        }
        return max(1, rounds)
    }
}
