import FactoryKit
import SwiftUI

/// The fifty-two cards on the cloth. Each is a `TurningCard` at its `TableLayout` spot; the run
/// in the hand draws at the finger's offset, each card trailing the one above on its own
/// spring, until it is dropped and snaps to its state position.
struct CardsView: View {
    @EnvironmentObject private var desk: Desk
    let table: Table
    let layout: TableLayout

    @State private var drag: DragRun?
    @State private var shrugging: UInt8?
    @State private var flashing: UInt8?
    @State private var settled = true
    @State private var lastUp: [Int] = []

    struct DragRun {
        var cards: [UInt8]
        var source: TableLayout.Place
        var translation: CGSize = .zero
        var target: Target?
    }

    enum Target: Equatable { case column(Int), foundation }

    private static let all: [Card] = (0..<52).map { Card(code: UInt8($0)) }

    var body: some View {
        let spots = layout.spots(table)
        ZStack(alignment: .topLeading) {
            slots
            ForEach(Self.all) { card in
                if let spot = spots[card.code] {
                    cardView(card, spot)
                }
            }
            if let drag, let target = drag.target { ghost(target, count: drag.cards.count) }
            if desk.teaching { GhostHand(table: table, layout: layout) }
        }
        .frame(width: layout.size.width, height: layout.size.height, alignment: .topLeading)
        .coordinateSpace(name: "cloth")
        .onChange(of: desk.dealt) { _, _ in deal() }
        .onAppear {
            lastUp = table.foundations.map(\.count)
            if !LaunchOptions.seeds { deal() }
        }
        .onChange(of: table.foundations.map(\.count)) { _, counts in
            // The card that just went up shows a brass hairline for 300 ms.
            if let s = (0..<4).first(where: { counts[$0] > (lastUp.indices.contains($0) ? lastUp[$0] : 0) }),
               let top = table.foundations[s].last, !Motion.isStill {
                flashing = top.code
                Task { @MainActor in
                    try? await Task.sleep(nanoseconds: 300_000_000)
                    if flashing == top.code { flashing = nil }
                }
            }
            lastUp = counts
        }
    }

    // MARK: - The empty places

    private var slots: some View {
        ZStack(alignment: .topLeading) {
            // The stock: a faint ring once it is empty; a tap gathers the waste back.
            Group {
                if table.stock.isEmpty {
                    Button { desk.play(.turn) } label: {
                        ZStack {
                            CardSlot(width: layout.cardW)
                            Image(systemName: "arrow.counterclockwise")
                                .font(.title3)
                                .foregroundStyle(desk.brand.palette.inkSoft.opacity(0.5))
                        }
                    }
                    .buttonStyle(.pressable)
                    .disabled(table.waste.isEmpty)
                    .accessibilityLabel("Stock, empty")
                    .accessibilityHint(table.waste.isEmpty ? "" : "Double tap to gather the waste back.")
                } else {
                    CardSlot(width: layout.cardW)
                }
            }
            .position(layout.stockCenter)
            ForEach(0..<4, id: \.self) { s in
                CardSlot(suit: Suit(rawValue: s), width: layout.cardW)
                    .position(layout.foundationCenter(s))
                    .accessibilityHidden(true)
            }
            ForEach(0..<7, id: \.self) { c in
                if table.columns[c].isEmpty {
                    CardSlot(width: layout.cardW)
                        .opacity(0.6)
                        .position(layout.columnTop(c))
                        .accessibilityLabel("Column \(c + 1), empty")
                }
            }
        }
    }

    // MARK: - A card

    @ViewBuilder
    private func cardView(_ card: Card, _ spot: TableLayout.Spot) -> some View {
        let liftIndex = drag?.cards.firstIndex(of: card.code) ?? held.firstIndex(of: card.code)
        let lifted = liftIndex != nil
        let offset = drag.flatMap { $0.cards.contains(card.code) ? $0.translation : nil } ?? .zero
        let nudge: CGFloat = isNudged(card, spot) ? 3 : 0
        let pos = settled || spot.place.isStockLike ? spot.center : layout.stockCenter
        let movable = spot.faceUp && isMovable(spot.place)
        let teachingSource = desk.teaching && GhostHand.firstMove(table)?.from == card.code

        let faceUp = spot.faceUp && (settled || spot.place.isStockLike)
        let z: Double = lifted ? 1000 + Double(liftIndex ?? 0) : spot.z
        let shrug = shrugging == card.code
        let point = CGPoint(x: pos.x + offset.width, y: pos.y + offset.height + nudge)
        let trailing: Animation? = trail(liftIndex).flatMap { Motion.resolved($0) }
        let dealing: Animation? = Motion.resolved(Motion.snappy.delay(dealDelay(spot)))

        LiftedCard(card: card, faceUp: faceUp, width: layout.cardW, flash: flashing == card.code,
                   lifted: lifted, shrug: shrug, breathe: teachingSource)
            .position(point)
            .animation(trailing, value: offset)
            .animation(Motion.resolved(Motion.pop), value: nudge)
            .animation(dealing, value: settled)
            .animation(Motion.resolved(Motion.snappy), value: spot.center)
            .zIndex(z)
            .onTapGesture { tap(card, spot) }
            .gesture(dragGesture(card, spot), including: movable ? .all : .subviews)
            .accessibilityElement()
            .accessibilityLabel(label(card, spot))
            .accessibilityHint(movable ? "Double tap to play it up, or drag it to a column." : "")
            .accessibilityAddTraits(movable || spot.place.isStockLike ? .isButton : [])
            .accessibilityHidden(isHiddenForVoiceOver(spot))
    }

    /// The i-th card of a run trails the one above: the top card follows the finger with no
    /// lag, so a run of five bends like a hand of cards and straightens when it stops.
    private func trail(_ i: Int?) -> Animation? {
        guard let i else { return Motion.bouncy }
        guard drag != nil else { return Motion.snappy }
        if i == 0 { return nil }
        return .spring(response: 0.14 + 0.02 * Double(i), dampingFraction: 0.85)
    }

    private var held: [UInt8] {
        guard let m = desk.holding else { return [] }
        switch m {
        case .run(let f, let i, _): return table.columns[f][i...].map(\.code)
        case .up(let c): return table.columns[c].last.map { [$0.code] } ?? []
        case .wasteUp, .wasteDown: return table.waste.last.map { [$0.code] } ?? []
        case .down(let s, _): return table.foundations[s].last.map { [$0.code] } ?? []
        default: return []
        }
    }

    private func dealDelay(_ spot: TableLayout.Spot) -> Double {
        guard case .column(let c, let i) = spot.place else { return 0 }
        // Row by row, as a deal goes: row i takes columns i…6.
        let before = (0..<i).reduce(0) { $0 + (7 - $1) }
        return Double(before + (c - i)) * 0.03
    }

    private func isMovable(_ p: TableLayout.Place) -> Bool {
        switch p {
        case .column: return true
        case .waste(let i): return i == table.waste.count - 1
        case .foundation(let s, let i): return i == table.foundations[s].count - 1
        case .stock: return false
        }
    }

    private func isHiddenForVoiceOver(_ spot: TableLayout.Spot) -> Bool {
        switch spot.place {
        case .stock(let i): return i != table.stock.count - 1
        case .waste(let i): return i != table.waste.count - 1
        case .foundation(let s, let i): return i != table.foundations[s].count - 1
        case .column: return false
        }
    }

    private func label(_ card: Card, _ spot: TableLayout.Spot) -> String {
        switch spot.place {
        case .stock: return "Stock, \(Words.number(table.stock.count)) cards"
        case .waste: return "\(card.spoken), on the waste"
        case .foundation: return "\(card.spoken), on its foundation"
        case .column(let c, _):
            return spot.faceUp ? "\(card.spoken), face up, column \(c + 1)" : "Face down"
        }
    }

    private func isNudged(_ card: Card, _ spot: TableLayout.Spot) -> Bool {
        guard let target = drag?.target else { return false }
        switch (target, spot.place) {
        case (.column(let c), .column(let col, let i)): return c == col && i == table.columns[c].count - 1
        default: return false
        }
    }

    // MARK: - Touch

    private func tap(_ card: Card, _ spot: TableLayout.Spot) {
        var moved = true
        switch spot.place {
        case .stock: desk.play(.turn)
        case .waste: moved = desk.tapWaste()
        case .foundation(let s, _): moved = desk.tapFoundation(s)
        case .column(let c, let i):
            guard spot.faceUp else { return }
            moved = desk.tapColumn(c, index: i)
        }
        if !moved { shrug(card) }
    }

    /// A card with nowhere to go rocks 2° and back. No sound, no red.
    private func shrug(_ card: Card) {
        shrugging = card.code
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 130_000_000)
            shrugging = nil
        }
    }

    private func dragGesture(_ card: Card, _ spot: TableLayout.Spot) -> some Gesture {
        DragGesture(minimumDistance: 4, coordinateSpace: .named("cloth"))
            .onChanged { v in
                if drag == nil {
                    guard let cards = run(from: spot.place) else { return }
                    drag = DragRun(cards: cards, source: spot.place)
                    Haptics.soft()
                }
                guard var d = drag else { return }
                d.translation = v.translation
                let centre = CGPoint(x: spot.center.x + v.translation.width, y: spot.center.y + v.translation.height)
                let target = target(at: centre, run: d)
                if target != d.target, target != nil { Haptics.selection() }
                d.target = target
                drag = d
            }
            .onEnded { _ in
                guard let d = drag else { return }
                if let target = d.target, let move = move(d, to: target) {
                    withMotion(Motion.snappy) {
                        drag = nil
                        desk.play(move)
                    }
                } else {
                    Haptics.soft()
                    withMotion(Motion.bouncy) { drag = nil }
                }
            }
    }

    private func run(from place: TableLayout.Place) -> [UInt8]? {
        switch place {
        case .column(let c, let i): return table.columns[c][i...].map(\.code)
        case .waste: return table.waste.last.map { [$0.code] }
        case .foundation(let s, _): return table.foundations[s].last.map { [$0.code] }
        case .stock: return nil
        }
    }

    private func target(at p: CGPoint, run d: DragRun) -> Target? {
        if d.cards.count == 1, layout.foundationRow.contains(p),
           let m = move(d, to: .foundation), table.isLegal(m) { return .foundation }
        for c in 0..<7 where layout.columnFrame(c).contains(p) {
            if let m = move(d, to: .column(c)), table.isLegal(m) { return .column(c) }
        }
        return nil
    }

    private func move(_ d: DragRun, to target: Target) -> Table.Move? {
        switch (d.source, target) {
        case (.column(let f, let i), .column(let t)): return .run(from: f, index: i, to: t)
        case (.column(let f, _), .foundation): return .up(col: f)
        case (.waste, .column(let t)): return .wasteDown(col: t)
        case (.waste, .foundation): return .wasteUp
        case (.foundation(let s, _), .column(let t)): return .down(suit: s, col: t)
        default: return nil
        }
    }

    /// A card-shaped ghost where the run would land.
    @ViewBuilder
    private func ghost(_ target: Target, count: Int) -> some View {
        let p: CGPoint = {
            switch target {
            case .column(let c): return layout.nextSpot(on: c, in: table)
            case .foundation:
                let suit = drag.flatMap { $0.cards.first }.map { Int($0) / 13 } ?? 0
                return layout.foundationCenter(suit)
            }
        }()
        RoundedRectangle(cornerRadius: layout.cardW * 0.08, style: .continuous)
            .fill(AppBrand.CardBox.stock.opacity(0.22))
            .frame(width: layout.cardW, height: layout.cardH)
            .position(p)
            .zIndex(900)
            .allowsHitTesting(false)
            .accessibilityHidden(true)
    }

    // MARK: - Laying the cards

    /// The 28 tableau cards fly from the stock's place to their columns row by row, 30 ms apart.
    private func deal() {
        guard !Motion.isStill, !UIAccessibility.isReduceMotionEnabled else { return }
        var t = Transaction()
        t.disablesAnimations = true
        withTransaction(t) { settled = false }
        DispatchQueue.main.async { settled = true }
    }
}

private extension TableLayout.Place {
    var isStockLike: Bool {
        switch self {
        case .column: return false
        default: return true
        }
    }
}

/// A card as the hand holds it: lifted to 1.04 with its shadow grown, or shrugging 2°.
private struct LiftedCard: View {
    let card: Card
    let faceUp: Bool
    let width: CGFloat
    let flash: Bool
    let lifted: Bool
    let shrug: Bool
    let breathe: Bool

    var body: some View {
        TurningCard(card: card, faceUp: faceUp, width: width, flash: flash)
            .animation(Motion.resolved(.spring(response: 0.22, dampingFraction: 0.9)), value: faceUp)
            .modifier(BreatheIf(on: breathe))
            .scaleEffect(lifted ? 1.04 : 1)
            .rotationEffect(.degrees(shrug ? 2 : 0), anchor: .bottom)
            .shadow(color: AppBrand.CardBox.ink.opacity(lifted ? 0.35 : 0.16),
                    radius: lifted ? 14 : 1.5, x: 0, y: lifted ? 8 : 1)
            .animation(Motion.resolved(.spring(response: 0.18, dampingFraction: 0.8)), value: lifted)
            .animation(Motion.resolved(Motion.pop), value: shrug)
    }
}

private struct BreatheIf: ViewModifier {
    let on: Bool
    func body(content: Content) -> some View {
        if on { content.breathing(amount: 0.06, period: 2.2) } else { content }
    }
}

/// The ghost hand on a first deal: a fingertip's circle comes down on the card that can go
/// first, drags it along a curve with a ghost of the card following, and lifts off. Every 4 s
/// until the first move, and never again.
struct GhostHand: View {
    let table: Table
    let layout: TableLayout

    struct First { let from: UInt8?; let start: CGPoint; let end: CGPoint; let card: Card? }

    static func firstMove(_ t: Table) -> (from: UInt8, to: Table.Move)? {
        let moves = t.legalMoves
        let pick = moves.first { if case .up = $0 { return true }; return false }
            ?? moves.first { if case .run(_, let i, let to) = $0 { return !(i == 0 && t.columns[to].isEmpty) }; return false }
            ?? moves.first { if case .wasteUp = $0 { return true }; if case .wasteDown = $0 { return true }; return false }
        guard let m = pick else { return nil }
        switch m {
        case .up(let c): return t.columns[c].last.map { ($0.code, m) }
        case .run(let f, let i, _): return (t.columns[f][i].code, m)
        case .wasteUp, .wasteDown: return t.waste.last.map { ($0.code, m) }
        default: return nil
        }
    }

    private var path: First {
        guard let (code, m) = Self.firstMove(table) else {
            // Nothing on the tableau can move: the hand taps the stock.
            return First(from: nil, start: layout.stockCenter, end: layout.stockCenter, card: nil)
        }
        let spots = layout.spots(table)
        let start = spots[code]?.center ?? layout.stockCenter
        let end: CGPoint
        switch m {
        case .up: end = layout.foundationCenter(Int(code) / 13)
        case .wasteUp: end = layout.foundationCenter(Int(code) / 13)
        case .run(_, _, let to): end = layout.nextSpot(on: to, in: table)
        case .wasteDown(let to): end = layout.nextSpot(on: to, in: table)
        default: end = start
        }
        return First(from: code, start: start, end: end, card: Card(code: code))
    }

    var body: some View {
        let p = path
        TimelineView(.animation(minimumInterval: 1.0 / 60, paused: Motion.isStill)) { ctx in
            // A still capture freezes the drag at its middle, where the curve and the card show.
            let t = Motion.isStill ? 1.6 : ctx.date.timeIntervalSinceReferenceDate.truncatingRemainder(dividingBy: 4) + 0.9
            let travel = min(1, max(0, (t - 0.9 - 0.3) / 0.8))
            let eased = travel * travel * (3 - 2 * travel)
            let mid = CGPoint(x: (p.start.x + p.end.x) / 2, y: min(p.start.y, p.end.y) - layout.cardH * 0.6)
            let pos = quad(p.start, mid, p.end, eased)
            let alpha: Double = {
                let k = t - 0.9
                if k < 0 || k > 1.5 { return 0 }
                if k < 0.25 { return k / 0.25 }
                if k > 1.15 { return max(0, (1.5 - k) / 0.35) }
                return 1
            }()
            ZStack {
                if let card = p.card {
                    CardFace(card: card, width: layout.cardW)
                        .opacity(0.3)
                        .position(pos)
                }
                Circle()
                    .fill(AppBrand.CardBox.stock.opacity(0.18))
                    .overlay(Circle().strokeBorder(AppBrand.CardBox.stock.opacity(0.35), lineWidth: 1))
                    .frame(width: 44, height: 44)
                    .scaleEffect(p.card == nil ? 1 - 0.15 * sin(eased * .pi) : 1)
                    .position(x: pos.x, y: pos.y + layout.cardH * 0.12)
            }
            .opacity(alpha)
        }
        .allowsHitTesting(false)
        .zIndex(950)
        .accessibilityHidden(true)
    }

    private func quad(_ a: CGPoint, _ c: CGPoint, _ b: CGPoint, _ t: Double) -> CGPoint {
        let u = 1 - t
        return CGPoint(x: u * u * a.x + 2 * u * t * c.x + t * t * b.x,
                       y: u * u * a.y + 2 * u * t * c.y + t * t * b.y)
    }
}
