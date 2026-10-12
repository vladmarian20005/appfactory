import Foundation

/// The deals the build proved, bundled as `deals.json` by `apps/solitaire/tools/pack.mjs`.
/// The phone never searches: it reshuffles from a seed and replays.
struct Pack: Codable {
    let engine: Int
    let epoch: String
    let dailies: [String: PackDeal]
    let pool: [PackDeal]

    static let empty = Pack(engine: 1, epoch: "2026-10-19", dailies: [:], pool: [])

    static func load() -> Pack {
        guard let url = Bundle.main.url(forResource: "deals", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let pack = try? JSONDecoder().decode(Pack.self, from: data),
              pack.engine == 1 else { return .empty }
        return pack
    }

    /// Every deal the pack holds, dailies first, by id.
    func deal(id: String) -> PackDeal? {
        if let d = dailies.values.first(where: { $0.id == id }) { return d }
        return pool.first { $0.id == id }
    }
}

struct PackDeal: Codable, Equatable {
    let id: String              // 8 hex chars of the seed, printed on the table
    let seed: UInt64
    let draw: Int               // the draw it was proved at
    let grade: Int              // 1…9, within its draw's pool
    let shape: Shape
    let lineText: String        // the dealer's line, pruned
    let buried: Card            // the face-down card the line turns last
    let hash: String

    var line: [Table.Move] { Table.Move.parse(line: lineText) }
    var lineCount: Int { lineText.split(separator: " ").count }

    /// `7C3A-19B2`
    var printed: String { "\(id.prefix(4))-\(id.suffix(4))" }

    func table() -> Table { Deal.table(seed: seed, draw: draw) }

    enum CodingKeys: String, CodingKey { case id, seed, draw, grade, shape, line, buried, hash }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(String.self, forKey: .id)
        let hex = try c.decode(String.self, forKey: .seed)
        guard let s = UInt64(hex, radix: 16) else {
            throw DecodingError.dataCorruptedError(forKey: .seed, in: c, debugDescription: "seed")
        }
        seed = s
        draw = try c.decode(Int.self, forKey: .draw)
        grade = try c.decode(Int.self, forKey: .grade)
        shape = try c.decode(Shape.self, forKey: .shape)
        lineText = try c.decode(String.self, forKey: .line)
        buried = Card(code: try c.decode(UInt8.self, forKey: .buried))
        hash = try c.decode(String.self, forKey: .hash)
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id)
        try c.encode(String(format: "%016llx", seed), forKey: .seed)
        try c.encode(draw, forKey: .draw)
        try c.encode(grade, forKey: .grade)
        try c.encode(shape, forKey: .shape)
        try c.encode(lineText, forKey: .line)
        try c.encode(buried.code, forKey: .buried)
        try c.encode(hash, forKey: .hash)
    }
}
