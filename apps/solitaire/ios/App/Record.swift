import FactoryKit
import Foundation

/// Everything the desk remembers, in one file, written atomically after every change.
struct Record: Codable, Equatable {
    var schema = 1                            // bump on any breaking change; migrate in init(from:)
    var rung = 1                              // position in the ledger. +1 per ledger deal out. Never down.
    var looseLaid = 0                         // loose deals laid, for their seed order
    var entries: [Entry] = []                 // every deal that came out, oldest first
    var bestMargin: Int? = nil                // widest margin under the mark, as a percent — the `best` tier's bar
    var mastery = Mastery<Shape>()            // written on every deal out or gathered, read to pick the next shape
    var recentShapes: [Shape] = []            // the last two ledger shapes, for `avoiding:`
    var played: Set<String> = []              // deal ids ever laid as ledger or loose, so nothing comes round
    var cloth: Cloth = .blue
    var back: Back = .lattice
    var leftHanded = false                    // drawer
    var fourColour = false                    // free
    var largePips = false                     // free
    var showClock = false                     // free; the clock is off unless asked
    var reminderHour: Int? = nil              // nil = not laid; else 0…23
    var table: SavedTable?                    // the ledger, loose or again deal in progress, if any
    var todayTable: SavedTable?               // today's (or yesterday's, still laid), if any
    var taught = false                        // the first move has been made; the ghost hand never returns

    init() {}

    // A missing field takes its default, so an update never loses a diary.
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        schema = try c.decodeIfPresent(Int.self, forKey: .schema) ?? 1
        rung = try c.decodeIfPresent(Int.self, forKey: .rung) ?? 1
        looseLaid = try c.decodeIfPresent(Int.self, forKey: .looseLaid) ?? 0
        entries = try c.decodeIfPresent([Entry].self, forKey: .entries) ?? []
        bestMargin = try c.decodeIfPresent(Int.self, forKey: .bestMargin)
        mastery = try c.decodeIfPresent(Mastery<Shape>.self, forKey: .mastery) ?? Mastery()
        recentShapes = try c.decodeIfPresent([Shape].self, forKey: .recentShapes) ?? []
        played = try c.decodeIfPresent(Set<String>.self, forKey: .played) ?? []
        cloth = try c.decodeIfPresent(Cloth.self, forKey: .cloth) ?? .blue
        back = try c.decodeIfPresent(Back.self, forKey: .back) ?? .lattice
        leftHanded = try c.decodeIfPresent(Bool.self, forKey: .leftHanded) ?? false
        fourColour = try c.decodeIfPresent(Bool.self, forKey: .fourColour) ?? false
        largePips = try c.decodeIfPresent(Bool.self, forKey: .largePips) ?? false
        showClock = try c.decodeIfPresent(Bool.self, forKey: .showClock) ?? false
        reminderHour = try c.decodeIfPresent(Int.self, forKey: .reminderHour)
        table = try c.decodeIfPresent(SavedTable.self, forKey: .table)
        todayTable = try c.decodeIfPresent(SavedTable.self, forKey: .todayTable)
        taught = try c.decodeIfPresent(Bool.self, forKey: .taught) ?? !entries.isEmpty
    }

    // MARK: - Derived, never stored

    func hasEarned(_ id: String) -> Bool { Play.earned.isUnlocked(id, at: entries.count) }

    /// Consecutive days with today's deal out, counting back from today or yesterday.
    func daysRunning(today: Int = Play.dayNumber()) -> Int {
        let days = Set(entries.filter { $0.kind == .today }.map(\.day))
        var d = days.contains(today) ? today : today - 1
        var n = 0
        while days.contains(d) { n += 1; d -= 1 }
        return n
    }

    var clean: Int { entries.filter(\.isClean).count }

    func todayEntry(day: Int = Play.dayNumber()) -> Entry? {
        entries.last { $0.kind == .today && $0.day == day }
    }

    /// The entry a calendar day shows: today's deal of that day, else the first that came out.
    func entry(forDay day: Int) -> Entry? {
        entries.last { $0.kind == .today && $0.day == day } ?? entries.last { $0.day == day }
    }

    /// The cloth on the table, as earned or bought.
    func clothInUse(pro: Bool) -> Cloth {
        switch cloth {
        case .blue: return .blue
        case .claret: return hasEarned("claret") || pro ? .claret : .blue
        case .moss, .slate: return pro ? cloth : .blue
        }
    }

    func backInUse(pro: Bool) -> Back {
        switch back {
        case .lattice: return .lattice
        case .brassLattice: return hasEarned("lattice") || pro ? .brassLattice : .lattice
        default: return pro ? back : .lattice
        }
    }

    var gilt: Bool { hasEarned("gilt") }
    var sealed: Bool { hasEarned("seal") }

    // MARK: - The file

    static var url: URL {
        let dir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir.appendingPathComponent("record.json")
    }

    /// A record that fails to decode is set aside as `record.broken.json` and a fresh one
    /// started — never a crash on launch, never a silent wipe.
    static func load() -> Record {
        guard let data = try? Data(contentsOf: url) else { return Record() }
        do {
            return try JSONDecoder().decode(Record.self, from: data)
        } catch {
            let broken = url.deletingLastPathComponent().appendingPathComponent("record.broken.json")
            try? FileManager.default.removeItem(at: broken)
            try? FileManager.default.moveItem(at: url, to: broken)
            return Record()
        }
    }

    func save() {
        guard let data = try? JSONEncoder().encode(self) else { return }
        try? data.write(to: Self.url, options: .atomic)
    }

    static func erase() {
        try? FileManager.default.removeItem(at: url)
    }
}

enum Kind: Codable, Equatable, Hashable {
    case today, ledger(Int), loose, again(day: Int)
}

/// A deal that came out.
struct Entry: Codable, Equatable, Identifiable, Hashable {
    var id: Int                               // 1-based, the order it came out
    var day: Int                              // Play.dayNumber of the day it came out (today's: the daily's day)
    var date: Date
    var kind: Kind
    var dealID: String
    var draw: Int
    var grade: Int
    var shape: Shape
    var moves: Int                            // her count, the sweep included
    var line: Int                             // the dealer's line
    var mark: Int
    var takenBack: Int
    var longestChain: Int
    var tier: Int                             // Run.Tier.rawValue
    var seconds: Int
    var buried: Card
    var gathered: Bool = false

    var isClean: Bool { takenBack == 0 && !gathered }
    var underMark: Bool { moves <= mark }
    var margin: Int { Int((Double(mark - moves) / Double(max(1, mark)) * 100).rounded(.down)) }
    var runTier: Run.Tier { Run.Tier(rawValue: tier) ?? .finished }

    var ledgerNumber: Int? {
        if case .ledger(let n) = kind { return n }
        return nil
    }
}

/// A deal on the cloth. The state is the deal replayed through `moves`.
struct SavedTable: Codable, Equatable {
    var dealID: String
    var seed: UInt64
    var kind: Kind
    var day: Int                              // the day it was laid (today's: the daily's day)
    var draw: Int
    var grade: Int
    var tight: Int
    var line: Int
    var shape: Shape
    var buried: Card
    var moves: [Table.Move] = []
    var run = Run()
    var started: Date = .now
    var seconds: Int = 0
    var gathered = false
    var takenBack = 0
    var heard: Set<String> = []               // the clerk's once-a-deal asides already said

    var mark: Int { Play.mark(line: line, tight: tight) }
    var deal: Table { Deal.table(seed: seed, draw: draw) }
    var printed: String { "\(dealID.prefix(4))-\(dealID.suffix(4))" }

    init(deal: PackDeal, kind: Kind, day: Int, tight: Int) {
        dealID = deal.id
        seed = deal.seed
        self.kind = kind
        self.day = day
        draw = deal.draw
        grade = deal.grade
        self.tight = tight
        line = deal.lineCount
        shape = deal.shape
        buried = deal.buried
    }
}
