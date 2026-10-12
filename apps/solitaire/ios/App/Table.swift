import Foundation

/// Klondike, as a value. The view never holds table state of its own: a table is the deal
/// replayed through its moves, and taking back is dropping the last move and replaying.
struct Table: Codable, Equatable {
    var draw: Int
    var stock: [Card]           // top is last
    var waste: [Card]           // top is last
    var foundations: [[Card]]   // 4, in Suit order; top is last
    var columns: [[Card]]       // 7; the first card is the deepest
    var faceDown: [Int]         // per column: how many at the start of the array are face down
    var passes = 0              // recycles so far

    enum Move: Equatable, Hashable {
        case turn                                   // stock → waste (1 or 3); or gather the waste back
        case wasteUp                                // waste → foundation
        case wasteDown(col: Int)                    // waste → column
        case up(col: Int)                           // column top → foundation
        case run(from: Int, index: Int, to: Int)    // column from its index on → column
        case down(suit: Int, col: Int)              // foundation top → column
        case home(card: UInt8)                      // the sweep: a card from anywhere straight up
    }

    // MARK: - Rules

    var allFaceUp: Bool { faceDown.allSatisfy { $0 == 0 } }
    var isOut: Bool { foundations.allSatisfy { $0.count == 13 } }
    var cardsUp: Int { foundations.reduce(0) { $0 + $1.count } }
    var faceDownCount: Int { faceDown.reduce(0, +) }

    func canGoUp(_ c: Card) -> Bool { foundations[c.suit.rawValue].count == c.rank - 1 }

    func canPlace(_ c: Card, on col: Int) -> Bool {
        guard let top = columns[col].last else { return c.rank == 13 }
        return top.rank == c.rank + 1 && top.isRed != c.isRed
    }

    func isFaceUp(col: Int, index: Int) -> Bool { index >= faceDown[col] }

    func isLegal(_ m: Move) -> Bool {
        switch m {
        case .turn:
            return !stock.isEmpty || !waste.isEmpty
        case .wasteUp:
            guard let c = waste.last else { return false }
            return canGoUp(c)
        case .wasteDown(let col):
            guard let c = waste.last, (0..<7).contains(col) else { return false }
            return canPlace(c, on: col)
        case .up(let col):
            guard (0..<7).contains(col), let c = columns[col].last else { return false }
            return canGoUp(c)
        case .run(let from, let index, let to):
            guard (0..<7).contains(from), (0..<7).contains(to), from != to,
                  index >= faceDown[from], index < columns[from].count else { return false }
            return canPlace(columns[from][index], on: to)
        case .down(let suit, let col):
            guard (0..<4).contains(suit), (0..<7).contains(col), let c = foundations[suit].last else { return false }
            return canPlace(c, on: col)
        case .home(let code):
            let c = Card(code: code)
            guard canGoUp(c) else { return false }
            return columns.contains { $0.last == c } || waste.contains(c) || stock.contains(c)
        }
    }

    var legalMoves: [Move] {
        var out: [Move] = []
        if isLegal(.turn) { out.append(.turn) }
        if isLegal(.wasteUp) { out.append(.wasteUp) }
        for c in 0..<7 where isLegal(.wasteDown(col: c)) { out.append(.wasteDown(col: c)) }
        for c in 0..<7 where isLegal(.up(col: c)) { out.append(.up(col: c)) }
        for f in 0..<7 where !columns[f].isEmpty {
            for i in faceDown[f]..<columns[f].count {
                for t in 0..<7 where isLegal(.run(from: f, index: i, to: t)) {
                    out.append(.run(from: f, index: i, to: t))
                }
            }
        }
        return out
    }

    /// A move that changes the tableau or the foundations — what "Nothing moves" is about.
    var hasTableMove: Bool {
        legalMoves.contains { m in
            switch m {
            case .turn: return false
            case .run(let f, let i, let t):
                // A king run from the bottom of one column to an empty one changes nothing.
                return !(i == 0 && columns[t].isEmpty)
            default: return true
            }
        }
    }

    /// Applies a legal move. If a column's top becomes face down it turns face up in the same
    /// step and `turned` is set, so the view can play the turn just after the landing.
    @discardableResult
    mutating func apply(_ m: Move) -> (turned: Card?, gathered: Bool) {
        var touched: Int?
        var gathered = false
        switch m {
        case .turn:
            if stock.isEmpty {
                stock = waste.reversed()
                waste = []
                passes += 1
                gathered = true
            } else {
                for _ in 0..<min(draw, stock.count) { waste.append(stock.removeLast()) }
            }
        case .wasteUp:
            let c = waste.removeLast()
            foundations[c.suit.rawValue].append(c)
        case .wasteDown(let col):
            columns[col].append(waste.removeLast())
        case .up(let col):
            let c = columns[col].removeLast()
            foundations[c.suit.rawValue].append(c)
            touched = col
        case .run(let from, let index, let to):
            let moving = columns[from][index...]
            columns[to].append(contentsOf: moving)
            columns[from].removeSubrange(index...)
            touched = from
        case .down(let suit, let col):
            columns[col].append(foundations[suit].removeLast())
        case .home(let code):
            let c = Card(code: code)
            if let col = columns.firstIndex(where: { $0.last == c }) {
                columns[col].removeLast()
                touched = col
            } else if let i = waste.firstIndex(of: c) {
                waste.remove(at: i)
            } else if let i = stock.firstIndex(of: c) {
                stock.remove(at: i)
            }
            foundations[c.suit.rawValue].append(c)
        }
        var turned: Card?
        if let col = touched, !columns[col].isEmpty, faceDown[col] == columns[col].count {
            faceDown[col] -= 1
            turned = columns[col].last
        }
        return (turned, gathered)
    }

    /// Every card to its foundation in rank order — all four aces, then the twos — from
    /// wherever it lies. Only meaningful when `allFaceUp`. This is the sweep.
    func sweepMoves() -> [Move] {
        var t = self
        var out: [Move] = []
        while !t.isOut {
            // The lowest card that can go up, spades · hearts · clubs · diamonds within a rank.
            let next = (0..<4)
                .filter { t.foundations[$0].count < 13 }
                .map { Card(suit: Suit(rawValue: $0)!, rank: t.foundations[$0].count + 1) }
                .filter { t.isLegal(.home(card: $0.code)) }
                .min { ($0.rank, $0.suit.rawValue) < ($1.rank, $1.suit.rawValue) }
            guard let next else { break }
            out.append(.home(card: next.code))
            t.apply(.home(card: next.code))
        }
        return out
    }

    static func replay(_ deal: Table, _ moves: [Move]) -> Table {
        var t = deal
        for m in moves where t.isLegal(m) { t.apply(m) }
        return t
    }

    // MARK: - A tapped card

    /// Where a tapped card goes: up if it can, else the legal column with the most cards.
    func bestMove(forColumn col: Int, index: Int) -> Move? {
        guard index >= faceDown[col], index < columns[col].count else { return nil }
        if index == columns[col].count - 1, isLegal(.up(col: col)) { return .up(col: col) }
        let targets = (0..<7).filter { isLegal(.run(from: col, index: index, to: $0)) }
            // A king already at the bottom of a column has nowhere better to be.
            .filter { !(index == 0 && columns[$0].isEmpty) }
        guard let to = targets.max(by: { columns[$0].count < columns[$1].count }) else { return nil }
        return .run(from: col, index: index, to: to)
    }

    func bestMoveForWaste() -> Move? {
        if isLegal(.wasteUp) { return .wasteUp }
        let targets = (0..<7).filter { isLegal(.wasteDown(col: $0)) }
        guard let to = targets.max(by: { columns[$0].count < columns[$1].count }) else { return nil }
        return .wasteDown(col: to)
    }

    func bestMoveForFoundation(_ suit: Int) -> Move? {
        let targets = (0..<7).filter { isLegal(.down(suit: suit, col: $0)) }
        guard let to = targets.max(by: { columns[$0].count < columns[$1].count }) else { return nil }
        return .down(suit: suit, col: to)
    }
}

// MARK: - The move encoding shared with pack.mjs

extension Table.Move: Codable {
    /// "t", "w", "w3", "u3", "r2.4.5", "d1.6", "h12"
    var token: String {
        switch self {
        case .turn: return "t"
        case .wasteUp: return "w"
        case .wasteDown(let c): return "w\(c)"
        case .up(let c): return "u\(c)"
        case .run(let f, let i, let t): return "r\(f).\(i).\(t)"
        case .down(let s, let c): return "d\(s).\(c)"
        case .home(let card): return "h\(card)"
        }
    }

    init?(token: String) {
        guard let head = token.first else { return nil }
        let nums = token.dropFirst().split(separator: ".").compactMap { Int($0) }
        switch (head, nums.count) {
        case ("t", 0): self = .turn
        case ("w", 0): self = .wasteUp
        case ("w", 1): self = .wasteDown(col: nums[0])
        case ("u", 1): self = .up(col: nums[0])
        case ("r", 3): self = .run(from: nums[0], index: nums[1], to: nums[2])
        case ("d", 2): self = .down(suit: nums[0], col: nums[1])
        case ("h", 1): self = .home(card: UInt8(nums[0]))
        default: return nil
        }
    }

    init(from decoder: Decoder) throws {
        let s = try decoder.singleValueContainer().decode(String.self)
        guard let m = Table.Move(token: s) else {
            throw DecodingError.dataCorrupted(.init(codingPath: decoder.codingPath, debugDescription: "bad move \(s)"))
        }
        self = m
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.singleValueContainer()
        try c.encode(token)
    }

    static func parse(line: String) -> [Table.Move] {
        line.split(separator: " ").compactMap { Table.Move(token: String($0)) }
    }
}
