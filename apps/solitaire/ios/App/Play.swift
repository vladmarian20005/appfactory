import FactoryKit
import Foundation

/// The only thing that reads the ladder. Every deal the app lays is chosen here, from what the
/// record says — never `%` over a list, never uniform random.
enum Play {
    /// `grade` is which ninth of the proved pack the deal comes from; `draw` turns to three at
    /// rung 40; `tight` pulls the mark toward the dealer's line until rung 169, and past it
    /// the ledger is the hardest ninth at draw three, chosen against her record by `Mastery`.
    static let ladder = Ladder([
        .init("grade", from: 1, by: 1, every: 14, opensAt: 1, ceiling: 9),
        .init("draw",  from: 1, by: 2, every: 39, opensAt: 1, ceiling: 3),
        .init("tight", from: 0, by: 5, every: 24, opensAt: 1, ceiling: 35),
    ])

    /// Today's deal runs a published week, like a crossword: Monday's is rung 4, Sunday's 150.
    static let dailyWeek = [4, 18, 32, 46, 74, 102, 150]

    /// Monday 19 October 2026 is day 0.
    static let epoch: Date = Calendar(identifier: .gregorian).date(from: DateComponents(year: 2026, month: 10, day: 19))!

    static func dayNumber(_ date: Date = .now) -> Int {
        let cal = Calendar.current
        return cal.dateComponents([.day], from: cal.startOfDay(for: epoch), to: cal.startOfDay(for: date)).day ?? 0
    }

    static func date(ofDay day: Int) -> Date {
        Calendar.current.date(byAdding: .day, value: day, to: Calendar.current.startOfDay(for: epoch)) ?? epoch
    }

    /// Monday = 0.
    static func weekday(_ day: Int) -> Int { ((day % 7) + 7) % 7 }

    static func dailyRung(day: Int) -> Int { dailyWeek[weekday(day)] }

    static func dials(at rung: Int) -> (grade: Int, draw: Int, tight: Int) {
        let d = ladder.dials(at: rung)
        return (d["grade"] ?? 1, d["draw"] ?? 1, d["tight"] ?? 0)
    }

    static func mark(line: Int, tight: Int) -> Int {
        Int((Double(line) * Double(140 - tight) / 100).rounded())
    }

    // MARK: - Choosing

    /// The next deal in the ledger for `rung`: the shape her record says she is weakest at,
    /// at the ladder's draw and grade, never one already played. Same record → same deal.
    static func ledgerDeal(rung: Int, record: Record, pack: Pack) -> PackDeal? {
        let d = dials(at: rung)
        return choose(draw: d.draw, grade: d.grade, record: record, pack: pack, salt: UInt64(rung))
    }

    /// A loose deal: the current rung's grade at the draw she asked for, by the same rule.
    static func looseDeal(draw: Int, record: Record, pack: Pack) -> PackDeal? {
        let d = dials(at: record.rung)
        return choose(draw: draw, grade: d.grade, record: record, pack: pack,
                      salt: UInt64(record.looseLaid) &+ 0x100000)
    }

    /// The order shapes are tried in: the one `Mastery` picks first, then weakest first.
    static func shapeOrder(_ record: Record) -> [Shape] {
        let first = record.mastery.next(from: Shape.allCases, count: 1, unseenShare: 0.3,
                                        avoiding: Set(record.recentShapes)).first ?? .even
        let rest = Shape.allCases
            .filter { $0 != first }
            .sorted { record.mastery.strength(of: $0) < record.mastery.strength(of: $1) }
        return [first] + rest
    }

    private static func choose(draw: Int, grade: Int, record: Record, pack: Pack, salt: UInt64) -> PackDeal? {
        let unplayed = pack.pool.filter { !record.played.contains($0.id) }
        // The chosen shape at this draw and grade, then the next shape in Mastery's order.
        for s in shapeOrder(record) {
            if let d = unplayed.first(where: { $0.draw == draw && $0.grade == grade && $0.shape == s }) { return d }
        }
        // The grade is exhausted: the nearest grade at this draw, harder first on a tie.
        let sameDraw = unplayed.filter { $0.draw == draw }
        if let d = sameDraw.min(by: { (abs($0.grade - grade), -$0.grade) < (abs($1.grade - grade), -$1.grade) }) {
            return d
        }
        if let d = unplayed.min(by: { abs($0.grade - grade) < abs($1.grade - grade) }) { return d }
        // The second pass: the whole pack has been played once. Walk it again in an order
        // seeded from the rung, so it does not come round in the order it went.
        return secondPass(draw: draw, grade: grade, pack: pack, salt: salt)
    }

    static func secondPass(draw: Int, grade: Int, pack: Pack, salt: UInt64) -> PackDeal? {
        let fit = pack.pool.filter { $0.draw == draw && $0.grade == grade }
        let from = fit.isEmpty ? pack.pool : fit
        return from.min { ($0.seed ^ salt) &* 0x9E37_79B9_7F4A_7C15 < ($1.seed ^ salt) &* 0x9E37_79B9_7F4A_7C15 }
    }

    /// Today's: the pack's daily for the day. Outside the packed days — before the epoch, or
    /// after fourteen months without an update — the first pool deal at the weekday's draw and
    /// grade whose seed, under a fixed multiplier and the day, ranks lowest. Deterministic and
    /// the same on every phone.
    static func todayDeal(day: Int, pack: Pack) -> PackDeal? {
        if let d = pack.dailies[String(day)] { return d }
        let d = dials(at: dailyRung(day: day))
        let key = UInt64(bitPattern: Int64(day)) &* 0x9E37_79B9_7F4A_7C15
        let fit = pack.pool.filter { $0.draw == d.draw && $0.grade == d.grade }
        let from = fit.isEmpty ? pack.pool.filter { $0.draw == d.draw } : fit
        return (from.isEmpty ? pack.pool : from).min { ($0.seed ^ key) &* 0xBF58_476D_1CE4_E5B9 < ($1.seed ^ key) &* 0xBF58_476D_1CE4_E5B9 }
    }

    // MARK: - Earned

    /// On entries: deals that came out, of every kind. None of these is for sale.
    static let earned = Earned([
        .init(id: "diary", title: "The diary", blurb: "Your first entry. The diary keeps it.", at: 1),
        .init(id: "claret", title: "The claret cloth",
              blurb: "Ten came out. There is a claret cloth folded in the desk now, if you want a change.", at: 10),
        .init(id: "lattice", title: "The brass lattice",
              blurb: "Twenty-five. A second back for the cards — the brass lattice. It is in Settings.", at: 25),
        .init(id: "gilt", title: "Gilt edges", blurb: "Fifty. The cards are gilt-edged from here on.", at: 50),
        .init(id: "seal", title: "The seal",
              blurb: "A hundred entries. The clerk has had a seal cut. It goes on everything from here.", at: 100),
        .init(id: "volume", title: "Volume two",
              blurb: "A year of entries. Volume one is shelved; volume two is open.", at: 365),
    ])

    /// The shortened horizon for the ending: "The brass lattice comes at twenty-five."
    static func horizon(_ m: Earned.Milestone) -> String {
        switch m.id {
        case "diary": return "The diary opens at the first."
        case "claret": return "The claret cloth comes at ten."
        case "lattice": return "The brass lattice comes at twenty-five."
        case "gilt": return "Gilt edges come at fifty."
        case "seal": return "The seal comes at a hundred."
        default: return "Volume two opens at three hundred and sixty-five."
        }
    }
}
