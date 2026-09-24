import FactoryKit
import Foundation

/// The book: how a pattern's shape grows with the rung, what today's shared pattern is, which
/// ground comes next, and what winding — rather than paying — opens.
enum Play {
    /// `flattensAt` is 221 — `loose` reaches 2 there — and `climbs(through: 150)` is true.
    /// Past 221 the shape is fixed at its hardest and what still changes is the ground,
    /// chosen from the player's own record, and where its windows fall.
    static let ladder = Ladder([
        .init("side",  from: 5,  by: 1, every: 12, opensAt: 1,  ceiling: 14),
        .init("open",  from: 40, by: 5, every: 7,  opensAt: 1,  ceiling: 100),
        .init("shape", from: 1,  by: 1, every: 45, opensAt: 30, ceiling: 4),
        .init("loose", from: 0,  by: 1, every: 90, opensAt: 41, ceiling: 2),
    ])

    struct Dials: Equatable {
        var side: Int
        var open: Int
        var shape: Int
        var loose: Int
    }

    static func dials(at rung: Int) -> Dials {
        let d = ladder.dials(at: max(1, rung))
        return Dials(side: d["side"] ?? 5, open: d["open"] ?? 40,
                     shape: d["shape"] ?? 1, loose: d["loose"] ?? 0)
    }

    /// The published week, the same for everybody, Monday first.
    static let dailyWeek = [6, 14, 26, 40, 58, 82, 131]
    static let freePatterns = 60

    static let groundOpens: [Ground: Int] = [.tulle: 1, .bar: 1, .rose: 10, .torchon: 22,
                                             .spider: 36, .fan: 52, .honeycomb: 70, .valenciennes: 90]

    static func groundsOpen(at rung: Int) -> [Ground] {
        Ground.allCases.filter { (groundOpens[$0] ?? 1) <= rung }
    }

    // MARK: - Days

    static func dayNumber(_ date: Date = .now) -> Int {
        let c = Calendar.current.dateComponents([.year, .month, .day], from: date)
        var utc = Calendar(identifier: .gregorian)
        utc.timeZone = TimeZone(identifier: "UTC")!
        let midnight = utc.date(from: c) ?? date
        return Int(midnight.timeIntervalSince1970 / 86_400)
    }

    static func date(ofDay day: Int) -> Date {
        var utc = Calendar(identifier: .gregorian)
        utc.timeZone = TimeZone(identifier: "UTC")!
        let d = Date(timeIntervalSince1970: TimeInterval(day) * 86_400)
        let c = utc.dateComponents([.year, .month, .day], from: d)
        return Calendar.current.date(from: c) ?? d
    }

    /// 1970-01-01 was a Thursday, so day 4 is the first Monday.
    static func dailyRung(day: Int) -> Int {
        dailyWeek[((day - 4) % 7 + 7) % 7]
    }

    /// Today's ground: a seeded draw over the grounds open at that weekday's rung, never the
    /// same as any of the three days before it. Shared, because nothing personal is in it.
    static func todayGround(day: Int) -> Ground {
        let recent = Set((1...3).map { rawGround(day: day - $0) })
        let pool = shuffled(groundsOpen(at: dailyRung(day: day)), seed: daySeed(day))
        return pool.first { !recent.contains($0) } ?? pool[0]
    }

    private static func rawGround(day: Int) -> Ground {
        shuffled(groundsOpen(at: dailyRung(day: day)), seed: daySeed(day))[0]
    }

    private static func shuffled(_ grounds: [Ground], seed: UInt64) -> [Ground] {
        var rng = SplitMix64(seed: seed)
        var g = grounds
        g.shuffle(using: &rng)
        return g
    }

    static func daySeed(_ day: Int) -> UInt64 { UInt64(day) &* 0x9E37_79B9_7F4A_7C15 }

    static func todayPricking(day: Int) -> Pricking {
        let rung = dailyRung(day: day)
        let d = dials(at: rung)
        return Generator.pricking(side: d.side, open: d.open, shape: d.shape, loose: d.loose,
                                  ground: todayGround(day: day), seed: daySeed(day), rung: rung)
    }

    // MARK: - The book

    /// The ground he is weakest at, with a share of ones he has not met, and not one of the
    /// last three. This is where `Mastery` is read.
    static func nextGround(rung: Int, record: Record) -> Ground {
        record.mastery.next(from: groundsOpen(at: rung), count: 1, unseenShare: 0.3,
                            avoiding: Set(record.recentGrounds.suffix(3))).first ?? .tulle
    }

    static func bookPricking(rung: Int, ground: Ground, salt: UInt64) -> Pricking {
        let d = dials(at: rung)
        return Generator.pricking(side: d.side, open: d.open, shape: d.shape, loose: d.loose,
                                  ground: ground, seed: SplitMix64.mix(UInt64(rung), salt), rung: rung)
    }

    /// Loose work: the current rung's dials, seeded by its own counter so it never repeats.
    static func loosePricking(n: Int, rung: Int, ground: Ground, salt: UInt64) -> Pricking {
        let d = dials(at: rung)
        return Generator.pricking(side: d.side, open: d.open, shape: d.shape, loose: d.loose,
                                  ground: ground, seed: SplitMix64.mix(UInt64(n), salt ^ 0x1005E), rung: rung)
    }

    // MARK: - Earned

    /// What playing opens, on pieces worked. Never what paying opens: the book past sixty is
    /// behind the unlock, and that door cannot be the only one.
    static let earned = Earned([
        .init(id: "sampler", title: "The sampler",
              blurb: "Your first piece is in the sampler. It will keep.", at: 1),
        .init(id: "silk", title: "Rose silk",
              blurb: "Six pieces. There is rose silk in the workbox now — wind with whichever you like.", at: 6),
        .init(id: "pin", title: "The marking pin",
              blurb: "Fifteen. Take a marking pin from the cushion — press one in beside any hole you mean to come back to.", at: 15),
        .init(id: "gold", title: "Gold thread",
              blurb: "Forty pieces. Gold thread, and picots on the edge of everything you work from here.", at: 40),
        .init(id: "ticking", title: "Indigo ticking",
              blurb: "A hundred. The pillow gets a new cover — indigo ticking, if you want it.", at: 100),
        .init(id: "initials", title: "Initials",
              blurb: "Two hundred pieces. A lacemaker signs her work. Two letters, in the workbox.", at: 200),
        .init(id: "year", title: "The year cloth",
              blurb: "A year of pieces. That cloth is full — it gets hemmed and hung, and a fresh one goes up.", at: 365),
    ])

    /// The shortened line an ending closes on.
    static func horizon(_ m: Earned.Milestone) -> String {
        switch m.id {
        case "sampler": "The sampler goes up at one."
        case "silk": "Rose silk comes at six."
        case "pin": "The marking pin comes at fifteen."
        case "gold": "Gold thread comes at forty."
        case "ticking": "The ticking comes at a hundred."
        case "initials": "Initials come at two hundred."
        default: "The year cloth is hemmed at three hundred and sixty-five."
        }
    }
}
