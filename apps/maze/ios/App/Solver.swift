import Foundation

/// Counts the ways a single thread can take every pin, honouring the gimp, up to two. A
/// pattern is only ever pricked when this says `unique`: the pillow never asks anyone to
/// guess.
enum Solver {
    enum Verdict: Equatable { case unique, multiple, none, unproved }

    /// From the given start (or every cell when nil) to the given finish (or any). A loose
    /// pattern is counted up to reversal. Stops at `budget` nodes and says so — never guesses.
    static func prove(_ p: Pricking, budget: Int) -> Verdict {
        var graph = Graph(side: p.side, open: p.open, walls: p.gimp)
        return graph.count(start: p.start.map(Int.init), finish: p.finish.map(Int.init), budget: budget)
    }

    /// The same, over a wall bitmap the generator mutates in place — no set, no copy.
    static func prove(_ graph: inout Graph, start: Int?, finish: Int?, budget: Int) -> Verdict {
        graph.count(start: start, finish: finish, budget: budget)
    }
}

/// The pattern as the solver sees it: four neighbour slots per cell, -1 where there is no
/// way through (the edge of the card, a window, or gimp).
struct Graph {
    let side: Int
    let n: Int
    let open: [Bool]
    /// n*4: up, right, down, left. -1 = blocked.
    var nbr: [Int]

    private var visited: [Bool] = []
    private var deg: [Int] = []
    private var stack: [Int] = []
    private var seen: [Int] = []
    private var stamp = 0
    private var nodes = 0
    private var budget = 0
    private var found = 0
    private var remaining = 0
    private var finish = -1
    private var dedupeFrom = -1
    private var firstEnd = -1
    private var colour: [Int] = []
    /// Bare pins of each chessboard colour.
    private var bare = [0, 0]
    private var nearHead: [Int] = []

    init(side: Int, open: [Bool], walls: Set<Edge>) {
        self.side = side
        self.n = side * side
        self.open = open
        nbr = Array(repeating: -1, count: side * side * 4)
        for c in 0..<n where open[c] {
            let r = c / side, col = c % side
            let cand = [r > 0 ? c - side : -1, col < side - 1 ? c + 1 : -1,
                        r < side - 1 ? c + side : -1, col > 0 ? c - 1 : -1]
            for k in 0..<4 {
                let d = cand[k]
                if d >= 0, open[d], !walls.contains(Edge(c, d)) { nbr[c * 4 + k] = d }
            }
        }
    }

    /// Lay or lift the wall between two neighbouring cells.
    mutating func setWall(_ a: Int, _ b: Int, _ wall: Bool) {
        let k = slot(a, b), j = slot(b, a)
        nbr[a * 4 + k] = wall ? -1 : b
        nbr[b * 4 + j] = wall ? -1 : a
    }

    private func slot(_ a: Int, _ b: Int) -> Int {
        if b == a - side { return 0 }
        if b == a + 1 { return 1 }
        if b == a + side { return 2 }
        return 3
    }

    func degree(_ c: Int) -> Int {
        var d = 0
        for k in 0..<4 where nbr[c * 4 + k] >= 0 { d += 1 }
        return d
    }

    mutating func count(start: Int?, finish: Int?, budget: Int) -> Solver.Verdict {
        visited = Array(repeating: false, count: n)
        deg = Array(repeating: 0, count: n)
        stack = Array(repeating: 0, count: n)
        seen = Array(repeating: 0, count: n)
        stamp = 0
        nodes = 0
        self.budget = budget
        found = 0
        self.finish = finish ?? -1
        dedupeFrom = -1
        colour = (0..<n).map { ($0 / side + $0 % side) % 2 }
        nearHead = Array(repeating: 0, count: n)
        bare = [0, 0]
        var total = 0
        for c in 0..<n where open[c] {
            deg[c] = degree(c)
            total += 1
            bare[colour[c]] += 1
        }
        guard total > 0 else { return .none }
        // Any pin the gimp shuts off entirely, or three pins with one way in, is impossible.
        var ones = 0
        for c in 0..<n where open[c] {
            if deg[c] == 0 && total > 1 { return .none }
            if deg[c] == 1 { ones += 1 }
        }
        if ones > 2 { return .none }

        var starts: [Int]
        if let start {
            starts = [start]
        } else {
            // A loose pattern: a pin with only one way in can only be an end. Start there and
            // every path is found exactly once. Otherwise try every pin, and count each
            // undirected path once by requiring its first pin below its last.
            let forced = (0..<n).filter { open[$0] && deg[$0] == 1 && $0 != finish }
            if let f = forced.first {
                starts = [f]
            } else {
                starts = (0..<n).filter { open[$0] }
                if finish == nil { dedupeFrom = 0 }
            }
        }
        for s in starts {
            remaining = total
            firstEnd = s
            visit(s)
            walk(s, root: true)
            unvisit(s)
            if found >= 2 { return .multiple }
            if nodes >= budget { return .unproved }
        }
        return found == 1 ? .unique : .none
    }

    private mutating func visit(_ c: Int) {
        visited[c] = true
        remaining -= 1
        bare[colour[c]] -= 1
        for k in 0..<4 {
            let d = nbr[c * 4 + k]
            if d >= 0 { deg[d] -= 1 }
        }
    }

    private mutating func unvisit(_ c: Int) {
        visited[c] = false
        remaining += 1
        bare[colour[c]] += 1
        for k in 0..<4 {
            let d = nbr[c * 4 + k]
            if d >= 0 { deg[d] += 1 }
        }
    }

    private mutating func walk(_ head: Int, root: Bool = false) {
        nodes += 1
        if nodes >= budget || found >= 2 { return }
        if remaining == 0 {
            if finish >= 0 && head != finish { return }
            if dedupeFrom >= 0 && firstEnd > head { return }
            found += 1
            return
        }
        if head == finish { return }
        // The chessboard: the thread alternates colours, so the bare pins must hold exactly
        // as many of each as the rest of the walk will step on.
        let hc = colour[head]
        if bare[1 - hc] != (remaining + 1) / 2 || bare[hc] != remaining / 2 { return }
        if finish >= 0 && colour[finish] != (remaining % 2 == 1 ? 1 - hc : hc) { return }
        guard feasible(head, fill: root || splits(head)) else { return }

        // Children in Warnsdorff order — the tightest pin first, which finds a second
        // solution sooner when there is one — with a fixed tie-break so the count is
        // deterministic.
        var kids = (-1, -1, -1, -1)
        var count = 0
        for k in 0..<4 {
            let d = nbr[head * 4 + k]
            guard d >= 0, !visited[d] else { continue }
            switch count {
            case 0: kids.0 = d
            case 1: kids.1 = d
            case 2: kids.2 = d
            default: kids.3 = d
            }
            count += 1
        }
        var order = [kids.0, kids.1, kids.2, kids.3].prefix(count).sorted { deg[$0] < deg[$1] }
        // A neighbour whose only way in is from here must be next — and last.
        if let forced = order.first(where: { deg[$0] == 0 }) {
            order = [forced]
        }
        for d in order {
            visit(d)
            walk(d)
            unvisit(d)
            if nodes >= budget || found >= 2 { return }
        }
    }

    /// Whether taking `head` could have cut the bare pins in two. It cannot if every bare pin
    /// the head joins is still joined to the others round the eight cells about it — so the
    /// flood fill only runs when the ring is broken between two of them.
    private func splits(_ head: Int) -> Bool {
        let r = head / side, c = head % side
        let ring = [(-1, -1), (-1, 0), (-1, 1), (0, 1), (1, 1), (1, 0), (1, -1), (0, -1)]
        var cell = [Int](repeating: -1, count: 8)
        for i in 0..<8 {
            let rr = r + ring[i].0, cc = c + ring[i].1
            if rr >= 0, cc >= 0, rr < side, cc < side {
                let d = rr * side + cc
                if open[d] && !visited[d] { cell[i] = d }
            }
        }
        func linked(_ i: Int, _ j: Int) -> Bool {
            let a = cell[i], b = cell[j]
            guard a >= 0, b >= 0 else { return false }
            for k in 0..<4 where nbr[a * 4 + k] == b { return true }
            return false
        }
        var breakAt = -1
        for i in 0..<8 where !linked((i + 7) % 8, i) { breakAt = i; break }
        if breakAt < 0 { return false }
        var arc = 0
        var seenArc = -1
        for s in 0..<8 {
            let i = (breakAt + s) % 8
            if s > 0 && !linked((i + 7) % 8, i) { arc += 1 }
            // An orthogonal cell the head reaches through no gimp.
            if i % 2 == 1, cell[i] >= 0, nbr[head * 4 + i / 2] == cell[i] {
                if seenArc >= 0 && seenArc != arc { return true }
                seenArc = arc
            }
        }
        return false
    }

    /// Everything bare must still be reachable, nothing bare may be shut in, and at most one
    /// bare pin may have only one way in — that one is where the thread must end.
    private mutating func feasible(_ head: Int, fill: Bool) -> Bool {
        var ends = 0
        var seed = -1
        stamp &+= 1
        for k in 0..<4 {
            let d = nbr[head * 4 + k]
            if d >= 0, !visited[d] { nearHead[d] = stamp; seed = d }
        }
        guard seed >= 0 else { return false }
        for c in 0..<n where open[c] && !visited[c] {
            let eff = deg[c] + (nearHead[c] == stamp ? 1 : 0)
            if eff == 0 { return false }
            if eff == 1 {
                if finish >= 0 && c != finish { return false }
                ends += 1
                if ends > 1 { return false }
            }
        }
        guard fill else { return true }
        // One flood fill over the bare pins, from a neighbour of the head.
        stamp &+= 1
        var top = 0
        stack[top] = seed; top += 1
        seen[seed] = stamp
        var reached = 1
        while top > 0 {
            top -= 1
            let c = stack[top]
            for k in 0..<4 {
                let d = nbr[c * 4 + k]
                if d >= 0, !visited[d], seen[d] != stamp {
                    seen[d] = stamp
                    stack[top] = d; top += 1
                    reached += 1
                }
            }
        }
        return reached == remaining
    }
}
