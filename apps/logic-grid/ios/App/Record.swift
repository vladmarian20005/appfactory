import FactoryKit
import Foundation

/// The run: how a plate's shape grows with the rung, what the day's shared plate is, and what
/// cutting — rather than paying — opens.
enum Play {

    /// A plate pulled advances the rung by one; a plate pulled clean advances it by two, so
    /// someone who deduces rather than guesses climbs twice as fast. `flattensAt` is 270, and
    /// that is an honest end stated rather than dodged with a dial that has no ceiling: past
    /// it the shape is fixed and what still changes is which kinds the generator leans on,
    /// taken from the player's own record.
    static let ladder = Ladder([
        .init("members",    from: 4, by: 1, every: 55, opensAt: 1,   ceiling: 6),
        .init("categories", from: 3, by: 1, every: 42, opensAt: 1,   ceiling: 5),
        .init("kinds",      from: 2, by: 1, every: 27, opensAt: 1,   ceiling: 7),
        .init("depth",      from: 2, by: 1, every: 18, opensAt: 12,  ceiling: 14),
        .init("sealed",     from: 1, by: 1, every: 40, opensAt: 150, ceiling: 4),
    ])

    static func shape(at rung: Int) -> Generator.Shape {
        let dials = ladder.dials(at: max(1, rung))
        return Generator.Shape(categories: dials["categories"] ?? 3,
                               members: dials["members"] ?? 4,
                               kinds: dials["kinds"] ?? 2,
                               depth: dials["depth"] ?? 2,
                               sealed: dials["sealed"] ?? 0)
    }

    /// Which clue kinds are legible at a rung, in the order the vocabulary opens.
    static func kindsOpen(at rung: Int) -> [ClueKind] {
        Array(ClueKind.allCases.prefix(max(2, shape(at: rung).kinds)))
    }

    /// The published week, the same for everybody, so a newcomer joining on day 300 is not
    /// handed a rung-300 plate and a veteran is not handed a rung-1 one.
    static let dailyWeek = [14, 28, 46, 68, 96, 140, 205]

    static func dailyRung(for date: Date) -> Int {
        // Monday first, whatever the phone's calendar starts its week on.
        let weekday = Calendar(identifier: .gregorian).component(.weekday, from: date)
        return dailyWeek[(weekday + 5) % 7]
    }

    static func dayNumber(for date: Date) -> Int {
        Int(Calendar.current.startOfDay(for: date).timeIntervalSince1970 / 86_400)
    }

    /// What playing opens. Never what paying opens: the run past forty is behind the unlock,
    /// and that door cannot be the only one.
    static let earned = Earned([
        .init(id: "line", title: "The drying line",
              blurb: "Your first pull is on the line. It will be dry by morning.", at: 1),
        .init(id: "pencil", title: "The pencil",
              blurb: "Four on the line. There is a pencil on the bench if you want to name them.", at: 4),
        .init(id: "burnisher", title: "The burnisher",
              blurb: "Twelve. The burnisher is worth keeping by you now.", at: 12),
        .init(id: "aquatint", title: "The aquatint box",
              blurb: "Thirty pulled. The aquatint box comes down off the shelf.", at: 30),
        .init(id: "chine", title: "Chine-collé",
              blurb: "Seventy-five. There is coloured stock under the bench — every pull takes the colour of its day from here.", at: 75),
        .init(id: "edition", title: "The edition",
              blurb: "A hundred and fifty. They do not fit the line any more. There is a book for them.", at: 150),
    ])

    /// What a session ends on: the next thing waiting, named and shortened to fit a margin.
    static func horizon(_ milestone: Earned.Milestone) -> String {
        switch milestone.id {
        case "line": return "The line goes up at one"
        case "pencil": return "The pencil comes to the bench at four"
        case "burnisher": return "The burnisher comes to the bench at twelve"
        case "aquatint": return "The aquatint box comes down at thirty"
        case "chine": return "The coloured stock comes out at seventy-five"
        default: return "The book for them is bound at a hundred and fifty"
        }
    }

    /// The free run, past which the whole generated ladder is behind the one-time unlock.
    static let freeRungs = 40
}

/// One print on the drying line. Enough of it is kept to draw it again — the cast marks in
/// their solved rows, the date in the margin, the colour of its stock — and nothing that
/// would spoil a plate somebody else has not pulled yet.
struct Pull: Codable, Identifiable, Equatable {
    var id: Int { number }
    var number: Int
    var day: Int
    var date: Date
    var title: String
    var themeID: String
    var points: Int
    var longestLine: Int
    var scars: Int
    var burnished: Bool
    var tier: Int
    /// The answer as it was engraved: one row per entity, its cast marks in order.
    var rows: [[Glyph]]
    var names: [String]
    /// Which cast ink this plate leads with — the colour of its square in the day-book and,
    /// past chine-collé, of its stock.
    var ink: Int

    var isClean: Bool { scars == 0 }
}

/// The plate caps under the day-book, and everything the app remembers about the player. A
/// missed day is a square of bare copper on the page, which is the truth and is not an
/// accusation.
struct Record: Codable, Equatable {
    var rung: Int = 1
    var pointsCut: Int = 0
    var bestLine: Int = 0
    var pulls: [Pull] = []
    /// Which clue kinds she is strong at, written on every cut and read to build the next
    /// plate. Kept by the kind's id.
    var mastery = Mastery<String>()
    /// Which subjects the shop has set lately, so a theme does not come round twice in a week.
    var themes = Mastery<String>()
    var recentThemes: [String] = []
    var recentKinds: [String] = []
    /// The salt that makes this bench's run its own. A plate is seeded from (rung, salt).
    var salt: UInt64 = 0x5E1F_0B12_9A44_7C31
    var calmInk = false
    var assist = true
    /// The plate left on the bed, saved on every mark so a crash never costs a plate.
    var bed: SavedPlate?
    var dailyBed: SavedPlate?
    var lastDailyDay: Int = 0

    var platesPulled: Int { pulls.count }

    var daysInked: Set<Int> { Set(pulls.map(\.day)) }

    /// Days running: consecutive days with a pull, counting back from today or yesterday. It
    /// is shown unasked and it is never used to ask for anything.
    var daysRunning: Int {
        let days = daysInked
        guard !days.isEmpty else { return 0 }
        let today = Play.dayNumber(for: .now)
        var day = days.contains(today) ? today : today - 1
        guard days.contains(day) else { return 0 }
        var count = 0
        while days.contains(day) {
            count += 1
            day -= 1
        }
        return count
    }

    func hasEarned(_ id: String) -> Bool { Play.earned.isUnlocked(id, at: platesPulled) }
}

/// A plate mid-cut, as it is written to disk after every mark.
struct SavedPlate: Codable, Equatable {
    var plate: Plate
    var grid: Grid
    /// What is at risk, and nothing beyond this plate. `Run` carries its own chain and its
    /// longest, and it is `Codable`, so a plate picked up tomorrow is the same run.
    var run: Run
    /// One mark per cut she made, in order: the proof strip on the share card.
    var strip: [Bool]
    /// Where the burin skidded, as a fraction along the margin.
    var scars: [Double]
    var openedSeals: [Int]
    var started: Date
}
