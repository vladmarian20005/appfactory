import Foundation

/// What the player knows, item by item, and what to put in front of them next.
///
/// This is the difference between an app that is paying attention and one that is dealing off
/// the top of a fixed deck. Quizday ships 300 questions, each carrying a `difficulty` field —
/// the word appears 332 times in that app — and picks the day's round with
/// `dayNumber % rounds.count`, so on day 31 it deals day 1's ten questions back in the same
/// order, forever, and no code anywhere reads `difficulty` to decide anything. It also keeps a
/// running per-category accuracy that nothing consults. The machinery to be interesting was
/// there; nothing was wired to it.
///
/// So: hold the player's strength per item here, and let this choose. Selection is
/// deterministic — same state, same pool, same answer — because the capture tooling has to be
/// able to photograph session 5 and session 500 and show that they differ.
/// Decided 12 Sep 2026.
///
///     mastery.record(word, correct: false)
///     let next = mastery.next(from: deck, count: 10, avoiding: justSeen)
public struct Mastery<Item: Hashable & Codable & Sendable>: Sendable, Equatable, Codable {
    /// How well one item is known.
    public struct Record: Sendable, Equatable, Codable {
        /// 0 = new or just missed, 1 = solid. Rises slower than it falls, because forgetting
        /// is real and a single lucky guess is not mastery.
        public var strength: Double = 0
        public var seen: Int = 0
        public var missed: Int = 0
        public var lastSeen: Date?

        public init() {}
    }

    public private(set) var records: [Item: Record] = [:]

    public init() {}

    /// How much a correct answer closes the gap to 1, and how much of the strength a miss
    /// leaves behind. Right three times running gets an item to ~0.78; one miss takes it back
    /// below 0.32.
    private static var gain: Double { 0.4 }
    private static var keep: Double { 0.4 }

    public mutating func record(_ item: Item, correct: Bool, at date: Date = Date()) {
        var record = records[item] ?? Record()
        record.seen += 1
        record.lastSeen = date
        if correct {
            record.strength += (1 - record.strength) * Self.gain
        } else {
            record.missed += 1
            record.strength *= Self.keep
        }
        records[item] = record
    }

    /// 0 for anything never seen.
    public func strength(of item: Item) -> Double { records[item]?.strength ?? 0 }

    public func hasSeen(_ item: Item) -> Bool { records[item] != nil }

    /// The count the player is allowed to be proud of — the number that only goes up.
    public func known(over threshold: Double = 0.7) -> Int {
        records.values.filter { $0.strength >= threshold }.count
    }

    /// What to serve next: the weakest things they have seen, with a share of new material
    /// mixed through so a session is never only revision, and never only strangers.
    ///
    /// - Parameters:
    ///   - pool: everything that could be served, in the order the app considers natural
    ///     (frequency rank, chapter order). Ties break toward the front of this list.
    ///   - unseenShare: how much of the session is new material, 0…1.
    ///   - recent: what was just served and should not come back yet. Honoured unless doing
    ///     so would leave the session short.
    public func next(
        from pool: [Item],
        count: Int,
        unseenShare: Double = 0.3,
        avoiding recent: Set<Item> = []
    ) -> [Item] {
        guard count > 0, !pool.isEmpty else { return [] }
        let rank = Dictionary(pool.enumerated().map { ($1, $0) }, uniquingKeysWith: { first, _ in first })
        let order = { (a: Item, b: Item) in (rank[a] ?? 0) < (rank[b] ?? 0) }

        func pick(from candidates: [Item]) -> [Item] {
            let weakest = candidates.filter(hasSeen).sorted { a, b in
                let sa = strength(of: a), sb = strength(of: b)
                if sa != sb { return sa < sb }
                let la = records[a]?.lastSeen, lb = records[b]?.lastSeen
                if let la, let lb, la != lb { return la < lb }
                return order(a, b)
            }
            let fresh = candidates.filter { !hasSeen($0) }.sorted(by: order)

            let wantFresh = min(fresh.count, Int((Double(count) * max(0, min(1, unseenShare))).rounded()))
            var takeFresh = Array(fresh.prefix(wantFresh))
            var takeWeak = Array(weakest.prefix(count - takeFresh.count))
            // Whichever side came up short, the other one fills the session.
            if takeFresh.count + takeWeak.count < count {
                takeWeak += weakest.dropFirst(takeWeak.count).prefix(count - takeFresh.count - takeWeak.count)
                takeFresh += fresh.dropFirst(takeFresh.count).prefix(count - takeFresh.count - takeWeak.count)
            }

            // Spread the new material through the revision rather than bolting it on the end.
            var out: [Item] = []
            out.reserveCapacity(takeFresh.count + takeWeak.count)
            let total = takeFresh.count + takeWeak.count
            var f = 0, w = 0
            for i in 0..<total {
                let wantFreshHere = takeFresh.count * (i + 1) > total * f
                if wantFreshHere && f < takeFresh.count {
                    out.append(takeFresh[f]); f += 1
                } else if w < takeWeak.count {
                    out.append(takeWeak[w]); w += 1
                } else if f < takeFresh.count {
                    out.append(takeFresh[f]); f += 1
                }
            }
            return out
        }

        let chosen = pick(from: pool.filter { !recent.contains($0) })
        guard chosen.count < count else { return chosen }
        // Everything else was served recently; rather than hand back a short session, allow
        // the least recently seen of them in.
        let rest = pick(from: pool.filter { recent.contains($0) })
        return chosen + rest.prefix(count - chosen.count)
    }
}
