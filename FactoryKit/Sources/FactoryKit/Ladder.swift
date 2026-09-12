import Foundation

/// A difficulty curve that is not allowed to stop climbing, and the things playing it opens.
///
/// Tidepour shipped the factory's only real ladder and it died: the generator reached seven
/// colours at level 26 and its par bar saturated at level 36, so every board from there to
/// level 10,000 was the same board — the exact complaint its own spec mocked the competition
/// for. Nobody noticed, because nothing downstream of the build can see a flat curve. A
/// screenshot of level 40 and a screenshot of level 400 are the same screenshot.
///
/// So the ladder is a type now, and it knows where it flattens. Describe the curve as dials
/// that open at a rung and grow on a schedule, and `flattensAt` names the rung after which
/// nothing about the game changes again. `tells.mjs` fails a build whose ladder stops inside
/// 150 rungs, because that is where a real player gets to.
///
/// It asks for 150 rather than for infinity on purpose. The first version of this type
/// demanded that some dial have no ceiling at all, and rebuilding Tidepour against it showed
/// why that is the wrong rule: a puzzle whose every board is solver-verified has a hardest
/// board, and an open dial just means demanding solutions longer than any board of that shape
/// contains — which produced a flat, noisy curve that cost six seconds a level to generate. A
/// bounded ladder that is still climbing long after anyone has stopped counting is honest; an
/// unbounded one is usually a fiction. Say where it ends in DESIGN.md, and what happens there.
/// Decided 12 Sep 2026.
///
///     let ladder = Ladder([
///         .init("colours", from: 3, every: 5, opensAt: 1, ceiling: 9),
///         .init("depth", from: 4, every: 75, opensAt: 50, ceiling: 6),
///         .init("par", from: 9, by: 1, every: 3, opensAt: 1, ceiling: 30),
///     ])
///     ladder["colours", at: 30]     // 8
///     ladder.flattensAt             // 200
///     ladder.climbs(through: 150)   // true
public struct Ladder: Sendable, Equatable {
    /// One dimension of difficulty: where it starts, when it opens, how fast it grows and
    /// whether it ever stops. A dial with no `ceiling` climbs for as long as anyone plays.
    public struct Dial: Sendable, Equatable {
        public let name: String
        /// The dial's value on the rung it opens.
        public let start: Int
        /// How much it moves each time it moves.
        public let step: Int
        /// Rungs between moves.
        public let every: Int
        /// The first rung on which this dial exists at all. A dial that opens late is how a
        /// ladder stays interesting after the early ones have run out of room.
        public let opensAt: Int
        /// The value it never passes, or `nil` to climb forever.
        public let ceiling: Int?

        public init(
            _ name: String,
            from start: Int,
            by step: Int = 1,
            every: Int = 1,
            opensAt: Int = 1,
            ceiling: Int? = nil
        ) {
            precondition(step > 0, "a dial that does not move is not a dial: \(name)")
            precondition(every > 0, "every must be at least 1 rung: \(name)")
            precondition(ceiling == nil || ceiling! >= start, "\(name) ceils below its start")
            self.name = name
            self.start = start
            self.step = step
            self.every = every
            self.opensAt = opensAt
            self.ceiling = ceiling
        }

        /// The dial's value on `rung`, or `nil` before it opens.
        public func value(at rung: Int) -> Int? {
            guard rung >= opensAt else { return nil }
            let grown = start + step * ((rung - opensAt) / every)
            guard let ceiling else { return grown }
            return min(grown, ceiling)
        }

        /// The last rung on which this dial changes, or `nil` if it never stops.
        public var lastChange: Int? {
            guard let ceiling else { return nil }
            let moves = Int(ceil(Double(ceiling - start) / Double(step)))
            return opensAt + every * moves
        }
    }

    public let dials: [Dial]

    public init(_ dials: [Dial]) {
        precondition(!dials.isEmpty, "a ladder with no dials is a flat line")
        self.dials = dials
    }

    /// The value of one dial on one rung, or `nil` before that dial opens.
    public func value(_ name: String, at rung: Int) -> Int? {
        dials.first { $0.name == name }?.value(at: rung)
    }

    public subscript(name: String, at rung: Int) -> Int? { value(name, at: rung) }

    /// Every dial that is open on `rung`, for handing to a generator in one go.
    public func dials(at rung: Int) -> [String: Int] {
        dials.reduce(into: [:]) { out, dial in
            if let v = dial.value(at: rung) { out[dial.name] = v }
        }
    }

    /// The rung after which nothing about the game changes again, or `nil` when the ladder
    /// climbs forever. If this returns a number, that number is where players leave.
    public var flattensAt: Int? {
        var last = 0
        for dial in dials {
            guard let change = dial.lastChange else { return nil }
            last = max(last, change)
        }
        return last
    }

    /// The ladder is still changing the game at `rung`. This is the question worth asking —
    /// 150 is roughly five months of a level a day — rather than whether it runs forever.
    public func climbs(through rung: Int) -> Bool {
        guard let flattensAt else { return true }
        return flattensAt >= rung
    }

    /// The ladder never stops. True of a curve with an open dial; rarer, and less often
    /// honest, than it looks — see the note above.
    public var climbsForever: Bool { flattensAt == nil }
}

/// Something the player is given because they played well, not because they paid.
///
/// Across the first five apps the word `unlock` appears fifty-odd times and every single one
/// is a purchase — `store.isUnlocked`, `AppInfo.unlockID`, `showPaywall`. Nothing in any of
/// them arrives for playing. A paywall is a fine door; it cannot be the only door, so every
/// app opens at least one thing this way. `next(after:)` is also what a session should say
/// when it ends: name the thing that is waiting, rather than a score over "Come back tomorrow".
public struct Earned: Sendable, Equatable, Codable {
    public struct Milestone: Sendable, Equatable, Codable, Identifiable {
        public let id: String
        /// What it is called, in the app's voice — this is shown to the player.
        public let title: String
        /// The line that tells them it arrived, in the app's voice.
        public let blurb: String
        /// The progress value that opens it: a rung, a best, a count of anything.
        public let at: Int

        public init(id: String, title: String, blurb: String, at: Int) {
            self.id = id
            self.title = title
            self.blurb = blurb
            self.at = at
        }
    }

    public let milestones: [Milestone]

    public init(_ milestones: [Milestone]) {
        self.milestones = milestones.sorted { $0.at < $1.at }
    }

    public func unlocked(at progress: Int) -> [Milestone] {
        milestones.filter { $0.at <= progress }
    }

    public func isUnlocked(_ id: String, at progress: Int) -> Bool {
        milestones.contains { $0.id == id && $0.at <= progress }
    }

    /// The horizon: the next thing waiting, for the end of a session to name.
    public func next(after progress: Int) -> Milestone? {
        milestones.first { $0.at > progress }
    }

    /// What crossing from `from` to `to` just opened, for the win to celebrate.
    public func justUnlocked(from: Int, to: Int) -> [Milestone] {
        milestones.filter { $0.at > from && $0.at <= to }
    }
}
