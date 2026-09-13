import FactoryKit
import SwiftData
import SwiftUI

/// A thing the user counts. Its value is not stored: it is the sum of its entries, so the
/// number on the card and the bars on the detail screen can never disagree.
@Model
final class Counter {
    var name: String = ""
    /// A `Pigment` id. A name rather than a colour so the store stays portable.
    var colorID: String = Pigment.default.id
    /// Cuts wanted in a day. Zero means no chalk line on the gauge, which is the default.
    var dailyGoal: Int = 0
    var createdAt: Date = Date.now

    @Relationship(deleteRule: .cascade, inverse: \Tap.counter)
    var entries: [Tap] = []

    init(name: String, colorID: String = Pigment.default.id, dailyGoal: Int = 0, createdAt: Date = .now) {
        self.name = name
        self.colorID = colorID
        self.dailyGoal = dailyGoal
        self.createdAt = createdAt
    }

    var pigment: Pigment { Pigment.named(colorID) }

    var total: Int { entries.reduce(0) { $0 + $1.delta } }

    func total(since date: Date) -> Int {
        entries.reduce(0) { $0 + ($1.at >= date ? $1.delta : 0) }
    }

    var todayTotal: Int { total(since: Calendar.current.startOfDay(for: .now)) }

    /// The whole record, replayed from the rows. Cheap enough to ask for per redraw on the
    /// face; the bench asks only for what it draws.
    var record: Record { Record(taps: entries) }
}

/// One tap. Kept individually rather than as a running number because the history screen and
/// the chart both need to know *when*, not just how many.
///
/// Named `Tap` and not `Entry`: SwiftUI exports an `Entry()` macro, and a model type of that
/// name resolves to the macro instead, with errors that point everywhere but here.
@Model
final class Tap {
    /// +1 for a tap up, -1 for a tap down.
    var delta: Int = 1
    var at: Date = Date.now
    var counter: Counter?

    init(delta: Int, at: Date = .now, counter: Counter? = nil) {
        self.delta = delta
        self.at = at
        self.counter = counter
    }
}

/// The six pots on the bench, which are the spec's "fixed palette of six": the band painted
/// on a stave's end, that stave's bars on the strip, and its mark in the ledger. Pigment 0 is
/// the same keel red as the brand's `highlight` — it is the same pot.
struct Pigment: Identifiable, Hashable {
    let id: String
    let label: String
    let color: Color

    static let all: [Pigment] = [
        Pigment(id: "keel", label: "Keel red", color: Color(light: 0xA2361B, dark: 0xF0885F)),
        Pigment(id: "chalk", label: "Chalk blue", color: Color(light: 0x17506A, dark: 0x6FBADD)),
        Pigment(id: "verdigris", label: "Verdigris", color: Color(light: 0x2C6650, dark: 0x6FC0A0)),
        Pigment(id: "ochre", label: "Ochre", color: Color(light: 0x7E5C12, dark: 0xE0B455)),
        Pigment(id: "logwood", label: "Logwood", color: Color(light: 0x5C3A6B, dark: 0xB491C6)),
        Pigment(id: "graphite", label: "Graphite", color: Color(light: 0x3E4247, dark: 0xA8AEB5)),
    ]

    static var `default`: Pigment { all[0] }

    static func named(_ id: String) -> Pigment {
        all.first { $0.id == id } ?? .default
    }
}

extension Store {
    /// Pro from a real entitlement, or forced by `-pro` so QA and the screenshot pass can
    /// reach the Pro screens without a purchase no runner can make.
    var isProUnlocked: Bool { isPro || LaunchOptions.forcePro }
}
