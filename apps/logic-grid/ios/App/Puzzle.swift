import Foundation

/// One member of one category: the thing a cell on the plate pairs with another.
struct Cell: Hashable, Codable {
    var category: Int
    var member: Int
}

/// The seven kinds of clue, in the order the `kinds` dial opens them. The id is what the
/// app's `Mastery` is kept over, so what the generator is asked for next comes from which of
/// these the player has been cutting against and which have been forcing her slips.
enum ClueKind: String, Codable, CaseIterable, Identifiable {
    case direct, negative, either, relational, arithmetic, adjacency, exclusive

    var id: String { rawValue }

    /// The rung at which this kind enters the vocabulary. `kinds` opens them in this order.
    static let opening = [1, 1, 28, 55, 82, 109, 136]

    var order: Int { ClueKind.allCases.firstIndex(of: self) ?? 0 }

    /// What the loupe calls it, in the plate caps.
    var caps: String {
        switch self {
        case .direct: return "direct"
        case .negative: return "negative"
        case .either: return "either or"
        case .relational: return "relational"
        case .arithmetic: return "arithmetic"
        case .adjacency: return "adjacency"
        case .exclusive: return "exclusive"
        }
    }
}

/// A clue, as the solver reads it and as the plate prints it.
struct Clue: Codable, Identifiable, Equatable {
    var id: Int
    var kind: ClueKind
    var a: Cell
    var b: Cell
    var c: Cell?
    var d: Cell?
    /// The gap, for an arithmetic clue.
    var n: Int = 0
    /// The ordered category, for the three clue kinds that compare positions.
    var ordered: Int = 0
    var text: String = ""
    /// Which cast ink the hanging numeral takes: the category the clue leads with.
    var leadCategory: Int = 0
    /// Scratched out when the plate comes up, and it bites open the moment the plate has no
    /// forced move without it.
    var sealed: Bool = false
}

/// The answer, held as one permutation per category. Entity `e` is member `e` of category 0 —
/// the people — which is why the print reads as their rows.
struct Solution: Codable, Equatable {
    /// `assign[category][entity]` is the member of that category belonging to that entity.
    var assign: [[Int]]

    func member(_ category: Int, of entity: Int) -> Int { assign[category][entity] }

    func entity(of cell: Cell) -> Int {
        assign[cell.category].firstIndex(of: cell.member) ?? 0
    }

    func holds(_ x: Cell, _ y: Cell) -> Bool {
        entity(of: x) == entity(of: y)
    }
}

/// What a cell on the plate carries.
enum Mark: Int8, Codable {
    /// Bare copper.
    case blank = 0
    /// A point cut deep: this pairing is fixed.
    case point = 1
    /// Two strokes across it: this pairing is ruled out.
    case ruled = 2
}

/// The plate's state: every pairing of every two categories. Stored both ways round, because
/// nine hundred bytes is nothing and the code that reads it is half the length.
struct Grid: Codable, Equatable {
    let categories: Int
    let members: Int
    private(set) var cells: [Int8]

    init(categories: Int, members: Int) {
        self.categories = categories
        self.members = members
        cells = Array(repeating: 0, count: categories * categories * members * members)
    }

    @inline(__always)
    private func index(_ x: Int, _ i: Int, _ y: Int, _ j: Int) -> Int {
        ((x * categories + y) * members + i) * members + j
    }

    @inline(__always)
    func at(_ x: Int, _ i: Int, _ y: Int, _ j: Int) -> Mark {
        Mark(rawValue: cells[index(x, i, y, j)]) ?? .blank
    }

    func at(_ p: Cell, _ q: Cell) -> Mark { at(p.category, p.member, q.category, q.member) }

    @inline(__always)
    mutating func set(_ x: Int, _ i: Int, _ y: Int, _ j: Int, _ mark: Mark) {
        cells[index(x, i, y, j)] = mark.rawValue
        cells[index(y, j, x, i)] = mark.rawValue
    }

    mutating func set(_ p: Cell, _ q: Cell, _ mark: Mark) {
        set(p.category, p.member, q.category, q.member, mark)
    }

    /// Positions of `cell` that are still possible in the ordered category.
    func possible(_ cell: Cell, in ordered: Int) -> [Int] {
        (0..<members).filter { at(cell.category, cell.member, ordered, $0) != .ruled }
    }

    /// Every pairing of category 0 with another category — the answer rows, and what the
    /// plate's points are counted in.
    func pointsCut() -> Int {
        var total = 0
        for y in 1..<categories {
            for i in 0..<members where (0..<members).contains(where: { at(0, i, y, $0) == .point }) {
                total += 1
            }
        }
        return total
    }

    var isPulled: Bool { pointsCut() == members * (categories - 1) }
}

/// A plate: its shape, its subject, its cast, its clues and the answer they prove.
struct Plate: Codable, Equatable {
    var rung: Int
    var themeID: String
    /// Which of the subject's blocks this plate was cast from. A plate smaller than five
    /// categories drops a cast block and keeps the ordered one, because the ordering is what
    /// three of the seven clue kinds compare.
    var blockIndices: [Int]
    var title: String
    /// `casting[category][member]` is the mark cut for that member, assigned when the plate
    /// was ruled so no two members of a plate ever wear the same figure.
    var casting: [[Glyph]]
    var categories: Int
    var members: Int
    var clues: [Clue]
    var solution: Solution
    /// What the solver measured: how many chained waves the hardest forced step needed.
    var depth: Int
    /// Today's plate, seeded from the date and the same for everybody.
    var isDaily: Bool = false
    /// The number punched in the margin.
    var number: Int

    var theme: Theme { Themes.theme(id: themeID) }

    func block(_ category: Int) -> CastBlock {
        let blocks = theme.blocks
        let index = category < blockIndices.count ? blockIndices[category] : category
        return blocks[min(index, blocks.count - 1)]
    }

    func member(_ cell: Cell) -> CastMember { block(cell.category).members[cell.member] }

    func glyph(_ cell: Cell) -> Glyph { casting[cell.category][cell.member] }

    var totalPoints: Int { members * (categories - 1) }

    /// `FOUR CATEGORIES, FIVE TO A SIDE · DEPTH 5`
    var shapeCaps: String {
        "\(Spelled.out(categories)) categories, \(Spelled.out(members)) to a side · depth \(depth)"
    }
}

// MARK: - The words

extension Clue {
    /// The clue as it is set on the paper, built from the two grammatical forms every member
    /// carries. No phrase table per pair of categories, and every sentence comes out English.
    static func phrase(_ kind: ClueKind, a: Cell, b: Cell, c: Cell?, d: Cell?, n: Int,
                       ordered: Int, plate: PlateDraft) -> String {
        func subject(_ cell: Cell) -> String { plate.member(cell).subject }
        func predicate(_ cell: Cell) -> String { plate.member(cell).predicate }
        func sentence(_ body: String) -> String { body.prefix(1).uppercased() + body.dropFirst() + "." }

        switch kind {
        case .direct:
            let (x, y) = a.category < b.category ? (a, b) : (b, a)
            return sentence("\(subject(x)) is \(predicate(y))")
        case .negative:
            let (x, y) = a.category < b.category ? (a, b) : (b, a)
            return sentence("\(subject(x)) is not \(predicate(y))")
        case .either:
            guard let c else { return "" }
            return sentence("\(subject(a)) is either \(predicate(b)) or \(predicate(c))")
        case .relational:
            let template = plate.ordering(ordered)?.before ?? "%1 goes before %2"
            return sentence(fill(template, subject(a), subject(b), n: n, plate: plate, ordered: ordered))
        case .arithmetic:
            let template = plate.ordering(ordered)?.gap ?? "%1 comes %n after %2"
            return sentence(fill(template, subject(a), subject(b), n: n, plate: plate, ordered: ordered))
        case .adjacency:
            let template = plate.ordering(ordered)?.adjacent ?? "%1 and %2 are one apart"
            return sentence(fill(template, subject(a), subject(b), n: n, plate: plate, ordered: ordered))
        case .exclusive:
            guard let c, let d else { return "" }
            let first = "\(subject(a)) is \(predicate(b))"
            let second = "\(subject(c)) is \(predicate(d))"
            return sentence("either \(first), or \(second) — not both")
        }
    }

    private static func fill(_ template: String, _ one: String, _ two: String, n: Int,
                             plate: PlateDraft, ordered: Int) -> String {
        let order = plate.ordering(ordered)
        return template
            .replacingOccurrences(of: "%1", with: one)
            .replacingOccurrences(of: "%2", with: two)
            .replacingOccurrences(of: "%n", with: Spelled.out(n))
            .replacingOccurrences(of: "%u", with: n == 1 ? (order?.unit ?? "step") : (order?.unitPlural ?? "steps"))
    }
}

/// What the generator works on before a plate exists: the shape, the cast and the answer.
struct PlateDraft {
    let theme: Theme
    let categories: Int
    let members: Int
    let solution: Solution
    let orderedCategory: Int

    func member(_ cell: Cell) -> CastMember {
        theme.blocks[cell.category].members[cell.member]
    }

    func ordering(_ category: Int) -> Ordering? {
        theme.blocks[category].ordering
    }
}
