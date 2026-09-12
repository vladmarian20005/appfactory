import Foundation

/// The setter. An alicatador who has laid tile for thirty years, works standing up, and talks
/// about clay, glaze, the kiln and the wall — never about apps, levels or days.
///
/// Nine words or fewer, concrete nouns from the workshop, and a forgotten word is a tile that
/// needs another firing rather than a mistake. Nothing he says can be read as a scold.
enum Voice {
    /// How the session went, which is what decides how loud the wall is.
    enum Tier {
        /// Finished, and some tiles went back to the bench.
        case set
        /// Nothing went back.
        case clean
        /// The session crossed 100, 200 … 1000 words known.
        case hundred(Int)
    }

    static let praise = [
        "The wall grew today.",
        "Straight courses, no gaps.",
        "That glaze took well.",
        "Clean work. The kiln did its part.",
        "You set those without looking twice.",
        "Every one of them held.",
        "The bench is clear.",
        "Good hands today.",
        "That course is true.",
        "Mortar's dry. It stays.",
    ]

    static let nearMiss = [
        "A few went back to the bench.",
        "Clay before glaze. That is the order.",
        "Some want a second firing.",
        "The wall does not mind waiting.",
        "Two courses forward, one relaid.",
        "They will come good.",
        "Nothing lost. Set aside.",
        "That is how a wall gets straight.",
    ]

    static func headline(_ tier: Tier) -> String {
        switch tier {
        case .set: return "The bench is clear."
        case .clean: return "Not one back to the bench."
        case let .hundred(n): return "\(spelled(n).capitalizedFirst) in the wall."
        }
    }

    /// A line from a pool, never the one that came out last time. The tenth win must not read
    /// like the first.
    static func line(from pool: [String], memory key: String) -> String {
        guard !pool.isEmpty else { return "" }
        guard pool.count > 1 else { return pool[0] }
        let defaults = UserDefaults.standard
        let last = defaults.object(forKey: key) as? Int
        var pick = Int.random(in: 0..<pool.count)
        if pick == last { pick = (pick + 1 + Int.random(in: 0..<(pool.count - 1))) % pool.count }
        defaults.set(pick, forKey: key)
        return pool[pick]
    }

    /// The quiet line of fact under the praise: what is standing and what is still plaster.
    static func standing(panels: Int, of total: Int) -> String {
        let bare = max(0, total - panels)
        if panels == 0 { return "The first course goes in today." }
        if bare == 0 { return "Every panel standing, none left bare." }
        let panelWord = panels == 1 ? "panel" : "panels"
        return "\(spelled(panels).capitalizedFirst) \(panelWord) standing, \(spelled(bare)) still bare plaster."
    }

    /// What the swept bench says under "The bench is swept."
    static func sweptBench(drying: Int, tomorrow: Int) -> String {
        let dryingPart = drying == 1
            ? "One tile is drying."
            : "\(spelled(drying).capitalizedFirst) tiles are drying."
        let tomorrowPart = tomorrow == 1
            ? "One is ready tomorrow."
            : "\(spelled(tomorrow).capitalizedFirst) are ready tomorrow."
        return "\(dryingPart) \(tomorrowPart)"
    }

    /// The daily reminder. It names work at the bench, never absence.
    static func reminder(ready: Int) -> String {
        ready == 1
            ? "One tile is ready at the bench."
            : "\(spelled(ready).capitalizedFirst) tiles are ready at the bench."
    }

    private static let speller: NumberFormatter = {
        let f = NumberFormatter()
        f.numberStyle = .spellOut
        f.locale = Locale(identifier: "en_US")
        return f
    }()

    /// "twenty-two", "three hundred". A wall is counted out loud, not printed as a digit.
    static func spelled(_ n: Int) -> String {
        speller.string(from: NSNumber(value: n)) ?? "\(n)"
    }
}

extension String {
    var capitalizedFirst: String {
        guard let first else { return self }
        return first.uppercased() + dropFirst()
    }
}
