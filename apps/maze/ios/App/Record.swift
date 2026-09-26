import FactoryKit
import Foundation

/// Everything the pillow remembers, in one file, written atomically after every change.
struct Record: Codable, Equatable {
    var schema = 1                          // bump on any breaking change; migrate in load()
    var salt: UInt64                        // random at first launch; the book is seeded from (rung, salt)
    var rung = 1                            // position in the book. +1 per book pattern lifted. Never down.
    var loosePiecesWorked = 0               // the loose-work counter; seeds (loosePiecesWorked, salt)
    var pieces: [Piece] = []                // every lifted piece, oldest first
    var bestThread = 0                      // longest chain ever, any pattern — the `best` tier's bar
    var mastery = Mastery<Ground>()         // written on every lifted piece, read to pick the next ground
    var recentGrounds: [Ground] = []        // the last three book grounds, for `avoiding:`
    var thread: ThreadColour = .indigo      // the workbox choice
    var cover: Cover = .linen
    var initials = ""                       // two letters, from 200 pieces
    var reminderHour: Int? = nil            // nil = not pinned; else 0…23
    var pillow: SavedPillow?                // the book or loose pattern in progress, if any
    var todayPillow: SavedPillow?           // today's pattern in progress, if any
    var todayDay = 0                        // dayNumber the daily pillow belongs to
    var tomorrow: Pricking?                 // tomorrow's pattern, pricked ahead when today's lifts
    var nextBook: Pricking?                 // the next book pattern, pricked ahead on every lift
    var taught = false                      // the first card was worked through, or set aside
    var hints: [String] = []                // the lacemaker's one-time notes already said: start, finish, window

    init(salt: UInt64) { self.salt = salt }

    // A missing field takes its default, so an update never loses a sampler.
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        schema = try c.decodeIfPresent(Int.self, forKey: .schema) ?? 1
        salt = try c.decode(UInt64.self, forKey: .salt)
        rung = try c.decodeIfPresent(Int.self, forKey: .rung) ?? 1
        loosePiecesWorked = try c.decodeIfPresent(Int.self, forKey: .loosePiecesWorked) ?? 0
        pieces = try c.decodeIfPresent([Piece].self, forKey: .pieces) ?? []
        bestThread = try c.decodeIfPresent(Int.self, forKey: .bestThread) ?? 0
        mastery = try c.decodeIfPresent(Mastery<Ground>.self, forKey: .mastery) ?? Mastery()
        recentGrounds = try c.decodeIfPresent([Ground].self, forKey: .recentGrounds) ?? []
        thread = try c.decodeIfPresent(ThreadColour.self, forKey: .thread) ?? .indigo
        cover = try c.decodeIfPresent(Cover.self, forKey: .cover) ?? .linen
        initials = try c.decodeIfPresent(String.self, forKey: .initials) ?? ""
        reminderHour = try c.decodeIfPresent(Int.self, forKey: .reminderHour)
        pillow = try c.decodeIfPresent(SavedPillow.self, forKey: .pillow)
        todayPillow = try c.decodeIfPresent(SavedPillow.self, forKey: .todayPillow)
        todayDay = try c.decodeIfPresent(Int.self, forKey: .todayDay) ?? 0
        tomorrow = try c.decodeIfPresent(Pricking.self, forKey: .tomorrow)
        nextBook = try c.decodeIfPresent(Pricking.self, forKey: .nextBook)
        taught = try c.decodeIfPresent(Bool.self, forKey: .taught) ?? false
        hints = try c.decodeIfPresent([String].self, forKey: .hints) ?? []
    }

    // MARK: - Derived, never stored

    var piecesWorked: Int { pieces.count }

    func hasEarned(_ id: String) -> Bool { Play.earned.isUnlocked(id, at: pieces.count) }

    /// Consecutive days with today's pattern lifted, counting back from today or yesterday.
    func daysRunning(today: Int = Play.dayNumber()) -> Int {
        let days = Set(pieces.filter { $0.kind == .today }.map(\.day))
        var d = days.contains(today) ? today : today - 1
        var n = 0
        while days.contains(d) { n += 1; d -= 1 }
        return n
    }

    var largestSide: Int { pieces.map(\.side).max() ?? 0 }

    func todayPiece(day: Int = Play.dayNumber()) -> Piece? {
        pieces.last { $0.kind == .today && $0.day == day }
    }

    /// The thread a piece is worked in, as earned: gold falls back to indigo if not yet earned.
    var threadInHand: ThreadColour {
        switch thread {
        case .rose where hasEarned("silk"): .rose
        case .gold where hasEarned("gold"): .gold
        default: .indigo
        }
    }

    var ticking: Bool { cover == .ticking && hasEarned("ticking") }

    // MARK: - The file

    static var url: URL {
        let dir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir.appendingPathComponent("record.json")
    }

    static func fresh() -> Record {
        var g = SystemRandomNumberGenerator()
        return Record(salt: g.next())
    }

    /// A record that fails to decode is set aside as `record.broken.json` and a fresh one
    /// started — never a crash on launch, never a silent wipe.
    static func load() -> Record {
        guard let data = try? Data(contentsOf: url) else { return fresh() }
        do {
            return try JSONDecoder().decode(Record.self, from: data)
        } catch {
            let broken = url.deletingLastPathComponent().appendingPathComponent("record.broken.json")
            try? FileManager.default.removeItem(at: broken)
            try? FileManager.default.moveItem(at: url, to: broken)
            return fresh()
        }
    }

    func save() {
        guard let data = try? JSONEncoder().encode(self) else { return }
        try? data.write(to: Self.url, options: .atomic)
    }
}

struct Piece: Codable, Equatable, Identifiable, Hashable {
    enum Kind: Codable, Equatable, Hashable {
        case today
        case book(rung: Int)
        case loose(n: Int)
    }

    var id: Int                             // 1-based, the order it was lifted
    var day: Int                            // Play.dayNumber
    var date: Date
    var kind: Kind
    var side: Int
    var shape: Int
    var ground: Ground
    var pins: Int                           // cells on the pattern
    var path: [UInt8]                       // the thread, as cell indices row-major
    var plaits: [Range<Int>]                // runs that were plaited, as index ranges into `path`
    var unpicks: Int
    var longestThread: Int
    var tier: Int                           // Run.Tier.rawValue
    var thread: ThreadColour
    var picot: Bool = false                 // gold earned when it was lifted
    var initials: String = ""
    var restarted: Bool = false

    var isClean: Bool { unpicks == 0 }
    var runTier: Run.Tier { Run.Tier(rawValue: tier) ?? .finished }

    var isToday: Bool { kind == .today }

    /// "23 SEP" for a day's piece, "BK 51" for the book, "LOOSE 4" for loose work.
    var mark: String {
        switch kind {
        case .today: Play.date(ofDay: day).formatted(.dateTime.day().month(.abbreviated))
        case .book(let rung): "Bk \(rung)"
        case .loose(let n): "Loose \(n)"
        }
    }
}

struct SavedPillow: Codable, Equatable {
    var pricking: Pricking
    var path: [UInt8] = []                  // pins taken so far, in order
    var plaits: [Range<Int>] = []
    var markers: [UInt8] = []               // marking pins (≤ 3), once earned
    var run = Run()                         // what is at risk, for this pattern and nothing beyond it
    var started = Date()
    var restarted = false                   // "Pull the pins" was used: no snips on the lift, mastery miss
    var kind: Piece.Kind = .today

    init(pricking: Pricking, kind: Piece.Kind) {
        self.pricking = pricking
        self.kind = kind
    }

    var isEmpty: Bool { path.isEmpty }
    var head: Int? { path.last.map(Int.init) }
    var isComplete: Bool { path.count == pricking.pins }
}
