import Foundation

/// A small deterministic generator, so a plate is reproducible: rung 5 photographs the same
/// twice, and the daily is the same plate for everybody who opens it.
struct Seeded: RandomNumberGenerator {
    private var state: UInt64

    init(seed: UInt64) { state = seed == 0 ? 0x9E37_79B9_7F4A_7C15 : seed }

    mutating func next() -> UInt64 {
        state &+= 0x9E37_79B9_7F4A_7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
        z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
        return z ^ (z >> 31)
    }

    mutating func int(_ bound: Int) -> Int { bound <= 0 ? 0 : Int(next() % UInt64(bound)) }
}

/// Seeded assignment, emit candidate clues, solve, prune while the answer stays proved — and
/// among the minimal sets keep the one that leans hardest on the kinds the player's own record
/// says she is weakest at, with its measured depth as close under the rung's target as it can
/// get. A plate that cannot be proved is discarded and never served.
enum Generator {

    struct Shape {
        var categories: Int
        var members: Int
        var kinds: Int
        var depth: Int
        var sealed: Int
    }

    static func plate(theme: Theme,
                      shape: Shape,
                      want: [ClueKind],
                      rung: Int,
                      number: Int,
                      isDaily: Bool,
                      seed: UInt64) -> Plate {
        var rng = Seeded(seed: seed)
        let categories = min(shape.categories, theme.blocks.count)
        let members = shape.members
        let allowed = Array(ClueKind.allCases.prefix(max(2, shape.kinds)))

        // The answer: one permutation per category, with the people as the plate's own order.
        var assign: [[Int]] = [Array(0..<members)]
        for _ in 1..<categories {
            var order = Array(0..<members)
            for i in stride(from: members - 1, to: 0, by: -1) {
                order.swapAt(i, rng.int(i + 1))
            }
            assign.append(order)
        }
        let solution = Solution(assign: assign)
        let draft = PlateDraft(theme: theme, categories: categories, members: members,
                               solution: solution, orderedCategory: categories - 1)

        var pool = candidates(draft, allowed: allowed, rng: &rng)
        shuffle(&pool, rng: &rng)

        var best: [Clue] = []
        var bestDepth = 0
        var bestScore = -Double.infinity
        for attempt in 0..<3 {
            var order = pool
            if attempt > 0 { shuffle(&order, rng: &rng) }
            let built = minimalSet(from: order, draft: draft, want: want, target: shape.depth)
            let proof = Solver.proves(built, categories: categories, members: members)
            guard proof.solved else { continue }
            let leaning = Double(built.filter { want.contains($0.kind) }.count) / Double(max(1, built.count))
            let miss = Double(abs(proof.waves - shape.depth)) + (proof.waves > shape.depth ? 1.5 : 0)
            let score = leaning * 3 - miss * 0.6 - Double(built.count) * 0.04
            if score > bestScore {
                bestScore = score
                best = built
                bestDepth = proof.waves
            }
        }

        if best.isEmpty {
            // Nothing minimal proved out — serve the whole truth rather than an unproved plate.
            best = candidates(draft, allowed: [.direct], rng: &rng)
            bestDepth = Solver.proves(best, categories: categories, members: members).waves
        }

        // Number them as they are set, and hand each its category's ink.
        var clues = best
        for i in clues.indices {
            clues[i].id = i
            clues[i].leadCategory = clues[i].a.category
            clues[i].text = Clue.phrase(clues[i].kind, a: clues[i].a, b: clues[i].b, c: clues[i].c,
                                        d: clues[i].d, n: clues[i].n, ordered: clues[i].ordered, plate: draft)
        }
        clues = seal(clues, count: isDaily ? max(0, shape.sealed - 2) : shape.sealed,
                     categories: categories, members: members)

        return Plate(rung: rung,
                     themeID: theme.id,
                     title: theme.title,
                     casting: casting(theme: theme, categories: categories, members: members),
                     categories: categories,
                     members: members,
                     clues: clues,
                     solution: solution,
                     depth: bestDepth,
                     isDaily: isDaily,
                     number: number)
    }

    // MARK: - The clue pool

    private static func candidates(_ draft: PlateDraft, allowed: [ClueKind], rng: inout Seeded) -> [Clue] {
        let categories = draft.categories, members = draft.members
        let solution = draft.solution
        let ordered = draft.orderedCategory
        func cell(_ category: Int, of entity: Int) -> Cell {
            Cell(category: category, member: solution.member(category, of: entity))
        }
        func position(_ entity: Int) -> Int { solution.member(ordered, of: entity) }

        var out: [Clue] = []
        func add(_ kind: ClueKind, _ a: Cell, _ b: Cell, c: Cell? = nil, d: Cell? = nil, n: Int = 0) {
            guard allowed.contains(kind) else { return }
            out.append(Clue(id: out.count, kind: kind, a: a, b: b, c: c, d: d, n: n, ordered: ordered))
        }

        for x in 0..<categories {
            for y in (x + 1)..<categories {
                for e in 0..<members {
                    add(.direct, cell(x, of: e), cell(y, of: e))
                    // Two false pairings per row: enough to make negatives useful without
                    // drowning the pool in them.
                    for _ in 0..<2 {
                        let j = rng.int(members)
                        if solution.member(y, of: e) != j {
                            add(.negative, cell(x, of: e), Cell(category: y, member: j))
                        }
                    }
                }
            }
        }

        // Either/or: the true partner and one that is not.
        for x in 0..<categories {
            for y in 0..<categories where y != x {
                for e in 0..<members {
                    let wrong = (solution.member(y, of: e) + 1 + rng.int(members - 1)) % members
                    add(.either, cell(x, of: e), cell(y, of: e), c: Cell(category: y, member: wrong))
                }
            }
        }

        // The three that compare positions, between any two cells that are not the ordering
        // itself. Both may be in the same category — "the ferry goes out before the packet".
        for x in 0..<categories where x != ordered {
            for y in 0..<categories where y != ordered {
                for e in 0..<members {
                    for f in 0..<members where f != e {
                        guard x != y || e < f else { continue }
                        let (early, late) = position(e) < position(f) ? (e, f) : (f, e)
                        add(.relational, cell(x, of: early), cell(y, of: late))
                        let gap = position(late) - position(early)
                        if gap >= 1 { add(.arithmetic, cell(y, of: late), cell(x, of: early), n: gap) }
                        if gap == 1 { add(.adjacency, cell(x, of: early), cell(y, of: late)) }
                    }
                }
            }
        }

        // Exclusive: one that holds and one that does not, about the same subject.
        for x in 0..<categories {
            for e in 0..<members {
                for y in 0..<categories where y != x {
                    for z in 0..<categories where z != x && z != y {
                        let wrong = (solution.member(z, of: e) + 1 + rng.int(members - 1)) % members
                        add(.exclusive, cell(x, of: e), cell(y, of: e),
                            c: cell(x, of: e), d: Cell(category: z, member: wrong))
                    }
                }
            }
        }

        return out
    }

    private static func shuffle(_ clues: inout [Clue], rng: inout Seeded) {
        for i in stride(from: clues.count - 1, to: 0, by: -1) {
            clues.swapAt(i, rng.int(i + 1))
        }
    }

    // MARK: - Build, then prune while it still proves

    private static func minimalSet(from pool: [Clue], draft: PlateDraft, want: [ClueKind], target: Int) -> [Clue] {
        let categories = draft.categories, members = draft.members
        var chosen: [Clue] = []
        var index = 0
        // Add in twos until the plate proves out; testing after every single clue doubles the
        // solving for no better a set.
        while index < pool.count {
            chosen.append(pool[index])
            index += 1
            if index % 2 == 0 || index == pool.count {
                if Solver.proves(chosen, categories: categories, members: members).solved { break }
            }
        }
        guard Solver.proves(chosen, categories: categories, members: members).solved else { return [] }

        // Prune the kinds she is already good at first, so what survives is the plate leaning
        // on the kinds her own record asked for.
        let order = chosen.indices.sorted { a, b in
            let wa = want.contains(chosen[a].kind), wb = want.contains(chosen[b].kind)
            if wa != wb { return !wa }
            return a < b
        }
        var dropped = Set<Int>()
        for i in order {
            var trial: [Clue] = []
            for (j, clue) in chosen.enumerated() where j != i && !dropped.contains(j) { trial.append(clue) }
            if Solver.proves(trial, categories: categories, members: members).solved {
                dropped.insert(i)
            }
        }
        var kept = chosen.enumerated().filter { !dropped.contains($0.offset) }.map(\.element)

        // A minimal set is as deep as this shape gets. If that is deeper than the rung asks
        // for, put a clue back — depth is compared here, not merely stored.
        var putBack = chosen.enumerated().filter { dropped.contains($0.offset) }.map(\.element)
        while Solver.proves(kept, categories: categories, members: members).waves > target, !putBack.isEmpty {
            kept.append(putBack.removeFirst())
        }
        return kept
    }

    // MARK: - Sealing

    /// The clues that scratch over. They are the ones the solve reaches for last, so a sealed
    /// plate is played on partial information at the start and can never deadlock: the moment
    /// there is no forced move without one, it bites open.
    private static func seal(_ clues: [Clue], count: Int, categories: Int, members: Int) -> [Clue] {
        guard count > 0, clues.count > count + 2 else { return clues }
        var grid = Grid(categories: categories, members: members)
        Solver.cascade(&grid, collecting: false)
        var firstUse = [Int: Int](minimumCapacity: clues.count)
        var wave = 0
        while !grid.isPulled {
            let forced = Solver.fromClues(grid, clues: clues, includingSealed: true)
            var moved = false
            for step in forced where grid.at(step.x, step.y) == .blank {
                grid.set(step.x, step.y, step.mark)
                if let clue = step.clue, firstUse[clue] == nil { firstUse[clue] = wave }
                moved = true
            }
            guard moved else { break }
            Solver.cascade(&grid, collecting: false)
            wave += 1
        }
        let latest = clues.indices.sorted { (firstUse[$0] ?? .max) > (firstUse[$1] ?? .max) }.prefix(count)
        var out = clues
        for index in latest { out[index].sealed = true }
        return out
    }

    // MARK: - The cast

    /// Every member of a plate gets its own figure: its block's preferred mark where that is
    /// still free, and the next unused one where it is not. No two members of one plate ever
    /// wear the same glyph, and the clocks stay with the hours.
    private static func casting(theme: Theme, categories: Int, members: Int) -> [[Glyph]] {
        var used = Set<Glyph>()
        var out: [[Glyph]] = []
        let spare = Glyph.allCases.filter { $0.clockHour == nil }
        for category in 0..<categories {
            var row: [Glyph] = []
            for member in 0..<members {
                let preferred = theme.blocks[category].members[member].preferred
                if !used.contains(preferred) {
                    used.insert(preferred)
                    row.append(preferred)
                } else if let free = spare.first(where: { !used.contains($0) }) {
                    used.insert(free)
                    row.append(free)
                } else {
                    row.append(preferred)
                }
            }
            out.append(row)
        }
        return out
    }
}
