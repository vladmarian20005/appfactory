import Foundation

/// What is at risk inside one session — and nothing outside it.
///
/// Every spec in this factory is written as a subtraction: no lives, no coins, no timer, no
/// streak, a missed day costs nothing. That wedge is right and it stays. But lives are stakes
/// bent into a weapon, and the factory removed the weapon without putting stakes back, which
/// is why the first five apps are pleasant and weightless: nothing in a session can be lost,
/// so nothing that happens in it matters.
///
/// A `Run` is the honest version. A chain builds while the player is doing well; a miss costs
/// the chain and the clean sheet and *nothing else* — never a life, never a level already
/// cleared, never tomorrow, never money to continue. The player can always keep going, and
/// they still have something to protect. Decided 12 Sep 2026; see TASTE.md, "Pull, not push".
public struct Run: Sendable, Equatable, Codable {
    /// How a finished run went, for the reward to scale to. TASTE.md asks for tiers: a clean
    /// sweep is louder than a pass, a new best louder still.
    public enum Tier: Int, Sendable, Codable, Comparable {
        case finished, good, clean, best
        public static func < (a: Tier, b: Tier) -> Bool { a.rawValue < b.rawValue }
    }

    /// Successes so far.
    public private(set) var hits = 0
    /// Misses so far. They cost the chain, and are not otherwise punished.
    public private(set) var misses = 0
    /// The run of successes standing right now. This is the thing at risk.
    public private(set) var chain = 0
    /// The longest chain reached in this run, which a miss cannot take away.
    public private(set) var longestChain = 0

    public init() {}

    /// Nothing has gone wrong yet.
    public var isClean: Bool { misses == 0 }
    public var attempts: Int { hits + misses }

    /// A success: the chain grows.
    public mutating func hit() {
        hits += 1
        chain += 1
        longestChain = max(longestChain, chain)
    }

    /// A miss. It breaks the chain and spoils the clean sheet. It takes nothing else: the run
    /// continues, and so does everything the player earned before it.
    public mutating func miss() {
        misses += 1
        chain = 0
    }

    /// How this run should be celebrated, given the best the player has managed before.
    /// Pass the score the run is judged on — its hits, its longest chain, whatever the app
    /// counts — and the record it is measured against.
    public func tier(score: Int, beating best: Int) -> Tier {
        if score > best { return .best }
        if isClean && attempts > 0 { return .clean }
        if attempts > 0 && Double(hits) / Double(attempts) >= 0.8 { return .good }
        return .finished
    }

    /// The shorthand for apps whose score *is* the hit count.
    public func tier(beating best: Int) -> Tier { tier(score: hits, beating: best) }
}
