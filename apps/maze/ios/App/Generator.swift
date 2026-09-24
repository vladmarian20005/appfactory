import Foundation

/// Pricks a pattern: the card's outline, one thread through every pin, then the gimp laid
/// between every pair of neighbours the thread does not join, and lifted again — in the
/// ground's order — wherever the solver can still prove there is exactly one way through.
enum Generator {
    /// Nodes one removal may cost the solver. A removal it cannot settle in that many is
    /// simply not made, which is what makes `open: 100` an honest ceiling.
    static let removalBudget = 12_000

    /// The pattern for a rung of the book, or a loose pattern, or today's.
    /// Same (dials, ground, seed) → same pattern, on every device, forever.
    static func pricking(side: Int, open: Int, shape: Int, loose: Int,
                         ground: Ground, seed: UInt64, rung: Int = 0) -> Pricking {
        var rng = SplitMix64(seed: seed)
        var mask = self.mask(side: side, shape: shape, ground: ground, rng: &rng)
        var answer = hamiltonian(side: side, mask: mask, rng: &rng)
        if answer == nil {
            // A template that cannot be threaded is a template bug; the square always can.
            assertionFailure("mask for shape \(shape) \(ground) could not be threaded")
            mask = Array(repeating: true, count: side * side)
            answer = hamiltonian(side: side, mask: mask, rng: &rng)
        }
        var path = answer ?? serpentine(side: side)
        backbite(&path, side: side, mask: mask, times: 3 * path.count, rng: &rng)

        let start = path.first!, finish = path.last!
        let pubStart: Int? = loose >= 2 ? nil : start
        let pubFinish: Int? = loose >= 1 ? nil : finish

        // Every neighbouring pair the thread does not join is a candidate wall; all laid, the
        // pattern is a corridor and the thread leads itself.
        var joined = Set<Edge>()
        for i in 1..<path.count { joined.insert(Edge(path[i - 1], path[i])) }
        var candidates: [Edge] = []
        for c in 0..<(side * side) where mask[c] {
            if c % side < side - 1, mask[c + 1], !joined.contains(Edge(c, c + 1)) { candidates.append(Edge(c, c + 1)) }
            if c / side < side - 1, mask[c + side], !joined.contains(Edge(c, c + side)) { candidates.append(Edge(c, c + side)) }
        }
        let ordered = order(candidates, ground: ground, side: side, path: path, rng: &rng)
        var walls = Set(candidates)
        var graph = Graph(side: side, open: mask, walls: walls)
        let tries = Int((Double(ordered.count) * Double(open) / 100).rounded())
        for e in ordered.prefix(tries) {
            let a = Int(e.a), b = Int(e.b)
            graph.setWall(a, b, false)
            if Solver.prove(&graph, start: pubStart, finish: pubFinish, budget: removalBudget) == .unique {
                walls.remove(e)
            } else {
                graph.setWall(a, b, true)
            }
        }

        return Pricking(side: side, open: mask, gimp: walls,
                        start: pubStart.map { UInt8($0) }, finish: pubFinish.map { UInt8($0) },
                        ground: ground, shape: shape, rung: rung, seed: seed,
                        answer: path.map { UInt8($0) })
    }

    /// A single thread through every cell of a mask, with nothing else to it — for the
    /// sampler's seeded pieces, which keep only the thread.
    static func thread(side: Int, seed: UInt64) -> [Int] {
        var rng = SplitMix64(seed: seed)
        var path = serpentine(side: side)
        backbite(&path, side: side, mask: Array(repeating: true, count: side * side),
                 times: 6 * path.count, rng: &rng)
        return path
    }

    // MARK: - The outline

    static func mask(side: Int, shape: Int, ground: Ground, rng: inout SplitMix64) -> [Bool] {
        var m = Array(repeating: true, count: side * side)
        func cut(_ r: Int, _ c: Int) {
            guard r >= 0, c >= 0, r < side, c < side else { return }
            m[r * side + c] = false
        }
        switch shape {
        case 2:
            // A medallion: the corners clipped.
            let k = side < 10 ? 2 : 3
            for r in 0..<side {
                for c in 0..<side where r + c < k {
                    cut(r, c); cut(r, side - 1 - c); cut(side - 1 - r, c); cut(side - 1 - r, side - 1 - c)
                }
            }
        case 3:
            // One window, where the ground puts it, never touching the border.
            let w = side < 10 ? 2 : 3
            let (r0, c0) = windowOrigin(side: side, size: w, ground: ground, rng: &rng)
            for r in r0..<(r0 + w) { for c in c0..<(c0 + w) { cut(r, c) } }
        case 4:
            // A ground of windows.
            switch ground {
            case .valenciennes:
                // A ring of small square windows just inside a two-pin border. Single-pin
                // windows there pinch the edge into corridors the thread can rarely take.
                let near = 2, far = side - 4
                var spots: [Int] = []
                var i = 4
                while i + 1 < side - 4 { spots.append(i); i += 4 }
                for s in spots {
                    for d in 0..<2 {
                        for e in 0..<2 {
                            cut(near + d, s + e); cut(far + d, s + e)
                            cut(s + e, near + d); cut(s + e, far + d)
                        }
                    }
                }
            case .honeycomb:
                // A checker of single-pin windows.
                var r = 2
                while r < side - 2 {
                    var c = (r / 3) % 2 == 0 ? 2 : 4
                    while c < side - 2 { cut(r, c); c += 4 }
                    r += 3
                }
            default:
                // A field of small windows at a seeded offset.
                let w = side < 10 ? 1 : 2
                let off = 2 + rng.below(2)
                var r = off
                while r + w < side - 1 {
                    var c = off
                    while c + w < side - 1 {
                        for dr in 0..<w { for dc in 0..<w { cut(r + dr, c + dc) } }
                        c += w + 3
                    }
                    r += w + 3
                }
            }
        default:
            break
        }
        balance(&m, side: side)
        if !connected(m, side: side) { return Array(repeating: true, count: side * side) }
        return m
    }

    private static func windowOrigin(side: Int, size w: Int, ground: Ground,
                                     rng: inout SplitMix64) -> (Int, Int) {
        let lo = 1, hi = side - 1 - w
        switch ground {
        case .spider:
            let o = (side - w) / 2
            return (o, o)
        case .fan:
            // The fan opens from a corner; its window sits in the closed one, opposite.
            let corner = fanCorner(side: side)
            return (corner.0 == 0 ? hi : lo, corner.1 == 0 ? hi : lo)
        default:
            return (lo + rng.below(hi - lo + 1), lo + rng.below(hi - lo + 1))
        }
    }

    /// Where the fan ground opens from. Fixed by side so its window and its gimp agree.
    static func fanCorner(side: Int) -> (Int, Int) {
        side % 2 == 0 ? (0, 0) : (0, side - 1)
    }

    /// A thread through every pin needs the two colours of the chessboard to differ by at most
    /// one. Re-pin a cut cell of the scarcer colour (next to the card) until they do, else
    /// snip a border cell of the commoner one.
    private static func balance(_ m: inout [Bool], side: Int) {
        func colour(_ c: Int) -> Int { (c / side + c % side) % 2 }
        for _ in 0..<(side * side) {
            var counts = [0, 0]
            for c in 0..<(side * side) where m[c] { counts[colour(c)] += 1 }
            let diff = counts[0] - counts[1]
            if abs(diff) <= 1 { return }
            let scarce = diff > 0 ? 1 : 0
            let restore = (0..<(side * side)).first { c in
                !m[c] && colour(c) == scarce && neighbours(c, side: side).contains { m[$0] }
            }
            if let restore {
                m[restore] = true
                continue
            }
            let common = 1 - scarce
            let snip = (0..<(side * side)).first { c in
                m[c] && colour(c) == common &&
                    (c / side == 0 || c / side == side - 1 || c % side == 0 || c % side == side - 1)
            }
            if let snip { m[snip] = false } else { return }
        }
    }

    static func neighbours(_ c: Int, side: Int) -> [Int] {
        var out: [Int] = []
        let r = c / side, col = c % side
        if r > 0 { out.append(c - side) }
        if col < side - 1 { out.append(c + 1) }
        if r < side - 1 { out.append(c + side) }
        if col > 0 { out.append(c - 1) }
        return out
    }

    private static func connected(_ m: [Bool], side: Int) -> Bool {
        guard let first = m.firstIndex(of: true) else { return false }
        var seen = Set([first]), stack = [first]
        while let c = stack.popLast() {
            for d in neighbours(c, side: side) where m[d] && !seen.contains(d) {
                seen.insert(d); stack.append(d)
            }
        }
        return seen.count == m.filter { $0 }.count
    }

    // MARK: - The thread

    /// Boustrophedon over the full square: always a Hamiltonian path, for mixing from.
    static func serpentine(side: Int) -> [Int] {
        var out: [Int] = []
        for r in 0..<side {
            for i in 0..<side { out.append(r * side + (r % 2 == 0 ? i : side - 1 - i)) }
        }
        return out
    }

    /// Randomised depth-first search with Warnsdorff ordering, pruning any state whose bare
    /// region falls apart or has more than one dead end. Re-seeds a few times on failure.
    static func hamiltonian(side: Int, mask: [Bool], rng: inout SplitMix64) -> [Int]? {
        if mask.allSatisfy({ $0 }) { return serpentine(side: side) }
        var cells = (0..<(side * side)).filter { mask[$0] }
        // When the two chessboard colours differ by one, both ends are the commoner colour:
        // a thread started on the other can never finish, and would spend the budget proving it.
        let colour = { (c: Int) in (c / side + c % side) % 2 }
        let dark = cells.filter { colour($0) == 0 }.count
        let light = cells.count - dark
        if dark != light {
            let common = dark > light ? 0 : 1
            cells = cells.filter { colour($0) == common }
        }
        var search = PathSearch(side: side, mask: mask)
        // Ends want to be where there is least room: the tightest cells first, then anywhere.
        let starts = cells.sorted { a, b in
            let da = search.gridDegree(a), db = search.gridDegree(b)
            return da != db ? da < db : a < b
        }
        for attempt in 0..<16 {
            search.rng = SplitMix64(seed: rng.next())
            let from = attempt < 4 ? starts[min(attempt, starts.count - 1)] : starts[rng.below(starts.count)]
            if let p = search.run(from: from, budget: 40_000) { return p }
        }
        return nil
    }

    /// Backbite: pick an end, pick one of its grid neighbours already on the path, and reverse
    /// the segment beyond it. Always a Hamiltonian path; after enough of them, a well-mixed one.
    static func backbite(_ path: inout [Int], side: Int, mask: [Bool], times: Int, rng: inout SplitMix64) {
        guard path.count > 2 else { return }
        var index = Array(repeating: -1, count: side * side)
        for (i, c) in path.enumerated() { index[c] = i }
        for _ in 0..<times {
            let fromStart = rng.below(2) == 0
            let end = fromStart ? path[0] : path[path.count - 1]
            let options = neighbours(end, side: side).filter { mask[$0] }
            guard !options.isEmpty else { continue }
            let pick = options[rng.below(options.count)]
            let j = index[pick]
            if fromStart {
                guard j > 1 else { continue }
                // path[0..j-1] reversed: the old start now joins `pick`.
                path[0..<j].reverse()
                for i in 0..<j { index[path[i]] = i }
            } else {
                guard j < path.count - 2 else { continue }
                path[(j + 1)...].reverse()
                for i in (j + 1)..<path.count { index[path[i]] = i }
            }
        }
    }

    // MARK: - The ground

    /// The candidate walls in the order the ground removes them.
    static func order(_ edges: [Edge], ground: Ground, side: Int, path: [Int],
                      rng: inout SplitMix64) -> [Edge] {
        let s = Double(side - 1)
        func mid(_ e: Edge) -> (Double, Double) {
            let a = Int(e.a), b = Int(e.b)
            return (Double(a / side + b / side) / 2, Double(a % side + b % side) / 2)
        }
        // Where the answer runs straight through a pin, for the bar ground.
        var straight = Set<Int>()
        if ground == .bar {
            for i in 1..<(path.count - 1) where path[i] - path[i - 1] == path[i + 1] - path[i] {
                straight.insert(path[i])
            }
        }
        var blockRank: [Int: Int] = [:]
        if ground == .rose {
            let blocks = (side / 2) * (side / 2)
            var ranks = Array(0..<max(blocks, 1))
            ranks.shuffle(using: &rng)
            for (i, r) in ranks.enumerated() { blockRank[i] = r }
        }
        let fan = fanCorner(side: side)
        let keyed: [(Edge, Double, UInt64)] = edges.map { e in
            let (r, c) = mid(e)
            let key: Double
            switch ground {
            case .tulle:
                key = 0
            case .bar:
                key = straight.contains(Int(e.a)) || straight.contains(Int(e.b)) ? 1 : 0
            case .rose:
                let a = Int(e.a), b = Int(e.b)
                let ba = (a / side / 2) * (side / 2) + (a % side / 2)
                let bb = (b / side / 2) * (side / 2) + (b % side / 2)
                let inside = ba == bb && a / side / 2 < side / 2 && a % side / 2 < side / 2
                key = inside ? Double(blockRank[ba] ?? 0) : 1_000
            case .torchon:
                key = min(abs(r - c), abs(r + c - s))
            case .spider:
                key = hypot(r - s / 2, c - s / 2)
            case .fan:
                key = hypot(r - Double(fan.0), c - Double(fan.1))
            case .honeycomb:
                let a = Int(e.a)
                key = (a / side + a % side) % 2 == 0 ? 0 : 1
            case .valenciennes:
                key = min(min(r, c), min(s - r, s - c))
            }
            return (e, key, rng.next())
        }
        return keyed.sorted { $0.1 != $1.1 ? $0.1 < $1.1 : $0.2 < $1.2 }.map(\.0)
    }
}

/// The depth-first search behind `Generator.hamiltonian`.
private struct PathSearch {
    let side: Int
    let mask: [Bool]
    var rng = SplitMix64(seed: 1)
    /// n*4 grid neighbours on the card, -1 for none.
    private let nbr: [Int]
    private var visited: [Bool]
    private var free: [Int]
    private var seen: [Int]
    private var stack: [Int]
    private var stamp = 0
    private var path: [Int] = []
    private let total: Int
    private var nodes = 0

    init(side: Int, mask: [Bool]) {
        self.side = side
        self.mask = mask
        let n = side * side
        var nbr = Array(repeating: -1, count: n * 4)
        for c in 0..<n where mask[c] {
            for (k, d) in Generator.neighbours(c, side: side).enumerated() where mask[d] {
                nbr[c * 4 + k] = d
            }
        }
        self.nbr = nbr
        visited = Array(repeating: false, count: n)
        free = (0..<n).map { c in (0..<4).filter { nbr[c * 4 + $0] >= 0 }.count }
        seen = Array(repeating: 0, count: n)
        stack = Array(repeating: 0, count: n)
        total = mask.filter { $0 }.count
    }

    func gridDegree(_ c: Int) -> Int { (0..<4).filter { nbr[c * 4 + $0] >= 0 }.count }

    mutating func run(from s: Int, budget: Int) -> [Int]? {
        let n = side * side
        visited = Array(repeating: false, count: n)
        free = (0..<n).map(gridDegree)
        path = []
        nodes = 0
        take(s)
        return dfs(budget: budget) ? path : nil
    }

    private mutating func take(_ c: Int) {
        visited[c] = true
        path.append(c)
        for k in 0..<4 { let d = nbr[c * 4 + k]; if d >= 0 { free[d] -= 1 } }
    }

    private mutating func drop(_ c: Int) {
        visited[c] = false
        path.removeLast()
        for k in 0..<4 { let d = nbr[c * 4 + k]; if d >= 0 { free[d] += 1 } }
    }

    private mutating func dfs(budget: Int) -> Bool {
        if path.count == total { return true }
        nodes += 1
        if nodes > budget { return false }
        let head = path[path.count - 1]
        guard ok(head) else { return false }
        var kids: [(Int, Int, UInt64)] = []
        for k in 0..<4 {
            let d = nbr[head * 4 + k]
            if d >= 0, !visited[d] { kids.append((d, free[d], rng.next())) }
        }
        kids.sort { $0.1 != $1.1 ? $0.1 < $1.1 : $0.2 < $1.2 }
        for (k, _, _) in kids {
            take(k)
            if dfs(budget: budget) { return true }
            drop(k)
            if nodes > budget { return false }
        }
        return false
    }

    private mutating func ok(_ head: Int) -> Bool {
        var ends = 0
        var seed = -1
        var remaining = 0
        for c in 0..<(side * side) where mask[c] && !visited[c] {
            remaining += 1
            var eff = free[c]
            for k in 0..<4 where nbr[c * 4 + k] == head { eff += 1; seed = c }
            if eff == 0 { return false }
            if eff == 1 { ends += 1; if ends > 1 { return false } }
        }
        if remaining == 0 { return true }
        guard seed >= 0 else { return false }
        stamp += 1
        var top = 0, reached = 1
        stack[0] = seed; top = 1
        seen[seed] = stamp
        while top > 0 {
            top -= 1
            let c = stack[top]
            for k in 0..<4 {
                let d = nbr[c * 4 + k]
                if d >= 0, !visited[d], seen[d] != stamp {
                    seen[d] = stamp; stack[top] = d; top += 1; reached += 1
                }
            }
        }
        return reached == remaining
    }
}
