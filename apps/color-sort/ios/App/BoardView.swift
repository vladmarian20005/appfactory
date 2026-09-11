import FactoryKit
import SwiftUI

/// Where every vial stands on the flat.
///
/// Computed rather than handed to a stack, because the pour has to know where a mouth *is*:
/// the arc is drawn from one vial's tipped mouth to another's, and a stack will not say.
struct RackLayout {
    let width: CGFloat
    let unit: CGFloat
    let spacing: CGFloat
    let rowSpacing: CGFloat
    let rows: [[Int]]
    let size: CGSize

    var tubeHeight: CGFloat { unit * CGFloat(Board.capacity) }

    private var totalHeight: CGFloat {
        tubeHeight * CGFloat(rows.count) + rowSpacing * CGFloat(max(0, rows.count - 1))
    }

    private func place(_ index: Int) -> (row: Int, column: Int, count: Int)? {
        for (r, row) in rows.enumerated() {
            if let c = row.firstIndex(of: index) { return (r, c, row.count) }
        }
        return nil
    }

    func center(of index: Int) -> CGPoint {
        guard let (row, column, count) = place(index) else { return .zero }
        let rowWidth = width * CGFloat(count) + spacing * CGFloat(count - 1)
        let x = (size.width - rowWidth) / 2 + CGFloat(column) * (width + spacing) + width / 2
        let y = (size.height - totalHeight) / 2
            + CGFloat(row) * (tubeHeight + rowSpacing) + tubeHeight / 2
        return CGPoint(x: x, y: y)
    }

    /// The lip of the vial, after it has been lifted by `offset` and tipped by `tilt` degrees
    /// about its own base.
    func mouth(of index: Int, tilt: Double = 0, offset: CGSize = .zero) -> CGPoint {
        let c = center(of: index)
        let base = CGPoint(x: c.x + offset.width, y: c.y + tubeHeight / 2 + offset.height)
        let radians = tilt * .pi / 180
        return CGPoint(x: base.x + tubeHeight * sin(radians),
                       y: base.y - tubeHeight * cos(radians))
    }

    func unitPoint(of index: Int) -> UnitPoint {
        let c = center(of: index)
        guard size.width > 0, size.height > 0 else { return .center }
        return UnitPoint(x: c.x / size.width, y: c.y / size.height)
    }
}

/// The arc of light between two mouths. A quadratic, because liquid poured from a height
/// leaves in a line and arrives in one.
struct PourArc: Shape {
    var from: CGPoint
    var to: CGPoint

    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: from)
        let lift = abs(to.x - from.x) * 0.18 + 22
        let control = CGPoint(x: (from.x + to.x) / 2, y: min(from.y, to.y) - lift)
        path.addQuadCurve(to: to, control: control)
        return path
    }
}

/// The rack: at most two rows, so even the widest board fits a phone in portrait without
/// scrolling, with the pour drawn over it.
struct BoardView: View {
    let board: Board
    let style: BoardStyle
    let selection: Int?
    let hint: Move?
    let flight: PourFlight?
    let stream: Double
    let rise: Double
    let teaching: Move?
    let completions: Int
    let completedTube: Int?
    let refusedTube: Int?
    let refusals: Int
    let onTap: (Int) -> Void

    @Environment(\.brand) private var brand

    private var columns: Int {
        min(5, max(3, Int((Double(board.tubes.count) / 2).rounded(.up))))
    }

    private func layout(in size: CGSize) -> RackLayout {
        let spacing = max(10.0, size.width * 0.035)
        let available = size.width - spacing * CGFloat(columns - 1)
        let width = min(82, available / CGFloat(columns))
        var rows: [[Int]] = []
        var row: [Int] = []
        for index in board.tubes.indices {
            row.append(index)
            if row.count == columns { rows.append(row); row = [] }
        }
        if !row.isEmpty { rows.append(row) }
        // Room under each row for the ring on the flat and the frond, so a finished vial is
        // not sitting on the row below it.
        let rowSpacing = spacing * 1.6 + width * 0.3
        let perRow = (size.height - rowSpacing * CGFloat(max(0, rows.count - 1))) / CGFloat(max(1, rows.count))
        let unit = min(width * 0.95, perRow / CGFloat(Board.capacity))
        return RackLayout(width: width, unit: max(18, unit), spacing: spacing,
                          rowSpacing: rowSpacing, rows: rows, size: size)
    }

    var body: some View {
        GeometryReader { geo in
            let rack = layout(in: geo.size)
            ZStack {
                ForEach(board.tubes.indices, id: \.self) { index in
                    vial(index, in: rack)
                }
                if let flight, flight.stage != .lift {
                    pour(flight, in: rack)
                        .allowsHitTesting(false)
                        .zIndex(3)
                }
            }
            .frame(width: geo.size.width, height: geo.size.height)
            .confetti(trigger: completions,
                      colors: burstColors,
                      from: completedTube.map { rack.unitPoint(of: $0) } ?? .center,
                      count: 26,
                      power: 0.45)
        }
    }

    // MARK: - One vial

    @ViewBuilder
    private func vial(_ index: Int, in rack: RackLayout) -> some View {
        let isSource = flight?.from == index
        let isChosen = selection == index && flight == nil
        TubeView(contents: contents(of: index),
                 style: style,
                 width: rack.width,
                 unitHeight: rack.unit,
                 isSelected: isChosen || isSource,
                 isHintSource: hint?.from == index,
                 isHintTarget: hint?.to == index,
                 rising: rising(in: index),
                 riseProgress: rise,
                 draining: draining(in: index),
                 drainProgress: stream,
                 isComplete: board.isComplete(index),
                 isTeaching: teaching?.from == index)
            .rotationEffect(.degrees(tilt(for: index, in: rack)), anchor: .bottom)
            .offset(lift(for: index, in: rack))
            .shake(trigger: refusedTube == index ? refusals : 0)
            .position(rack.center(of: index))
            .zIndex(isSource ? 2 : (isChosen ? 1 : 0))
            .onTapGesture { onTap(index) }
    }

    /// How many of a vial's top units have only just arrived.
    private func rising(in index: Int) -> Int {
        guard let flight, flight.to == index, flight.stage != .lift else { return 0 }
        return flight.amount
    }

    /// How many are still leaving the tipped mouth. The board has already given them up, so
    /// they are put back here and drained with the arc — otherwise the vial in the air is an
    /// empty glass being waved about.
    private func draining(in index: Int) -> Int {
        guard let flight, flight.from == index, flight.stage == .stream else { return 0 }
        return flight.amount
    }

    private func contents(of index: Int) -> [Int] {
        guard draining(in: index) > 0, let flight else { return board.tubes[index] }
        return board.tubes[index] + Array(repeating: flight.color, count: flight.amount)
    }

    /// Anticipation for the vial that has been picked up; the full tip for the one pouring.
    private func tilt(for index: Int, in rack: RackLayout) -> Double {
        if let flight, flight.from == index {
            let a = rack.center(of: flight.from)
            let b = rack.center(of: flight.to)
            return b.x >= a.x ? 42 : -42
        }
        if selection == index && flight == nil { return -5 }
        return 0
    }

    private func lift(for index: Int, in rack: RackLayout) -> CGSize {
        if let flight, flight.from == index {
            let a = rack.center(of: flight.from)
            let b = rack.center(of: flight.to)
            return CGSize(width: (b.x - a.x) * 0.34,
                          height: (b.y - a.y) * 0.34 - rack.unit * 0.62)
        }
        if selection == index && flight == nil { return CGSize(width: 0, height: -rack.unit * 0.34) }
        return .zero
    }

    private var burstColors: [Color]? {
        guard let completedTube, let color = board.tubes[completedTube].first else { return nil }
        let liquid = style.liquid(color)
        return [liquid.top, liquid.color, brand.palette.highlight]
    }

    // MARK: - The pour itself

    @ViewBuilder
    private func pour(_ flight: PourFlight, in rack: RackLayout) -> some View {
        let start = rack.mouth(of: flight.from,
                               tilt: tilt(for: flight.from, in: rack),
                               offset: lift(for: flight.from, in: rack))
        let end = rack.mouth(of: flight.to)
        let liquid = style.liquid(flight.color)
        ZStack {
            PourArc(from: start, to: end)
                .trim(from: 0, to: stream)
                .stroke(liquid.glow.opacity(0.45),
                        style: StrokeStyle(lineWidth: 14, lineCap: .round))
                .blur(radius: 7)
            PourArc(from: start, to: end)
                .trim(from: 0, to: stream)
                .stroke(LinearGradient(colors: [liquid.top, liquid.color],
                                       startPoint: .top, endPoint: .bottom),
                        style: StrokeStyle(lineWidth: 6, lineCap: .round))
            // Where it lands: a bloom on the surface that opens and goes out with the arc.
            Ellipse()
                .fill(liquid.top)
                .frame(width: rack.width * 0.52, height: rack.width * 0.15)
                .blur(radius: 2)
                .scaleEffect(0.5 + stream * 0.7)
                .opacity(stream * 0.85)
                .position(x: end.x, y: end.y + 3)
        }
        .accessibilityHidden(true)
    }
}
