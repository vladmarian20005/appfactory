import FactoryKit
import SwiftUI

/// A field of fine parallel troughs. Two passes of it, crossed at 32°, are the app's mark:
/// the ruled-out cell, the sealed clue, the locked plate, the icon. Crossing at a right angle
/// can only ever make a mesh; a shallow crossing makes lozenge-shaped interstices, which is
/// why the technique is called crosshatch and why it reads as tone.
struct HatchField: Shape {
    var degrees: Double
    var spacing: CGFloat

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let reach = rect.width + rect.height
        let radians = degrees * .pi / 180
        let dx = CGFloat(cos(radians)), dy = CGFloat(sin(radians))
        var offset = -reach
        while offset < reach {
            let cx = rect.midX - dy * offset, cy = rect.midY + dx * offset
            path.move(to: CGPoint(x: cx - dx * reach, y: cy - dy * reach))
            path.addLine(to: CGPoint(x: cx + dx * reach, y: cy + dy * reach))
            offset += spacing
        }
        return path
    }
}

/// The cut shading, as a view: a flat wash under two passes of troughs, each with the light
/// catching its upper lip. `progress` cuts the first pass, then the second — which is the two
/// strokes seventy milliseconds apart that make a finger believe it cut something.
struct CutShading: View {
    var progress: CGFloat = 1
    var spacing: CGFloat = AppBrand.Hatch.spacing
    var weight: CGFloat = AppBrand.Hatch.weight
    var tone: CGFloat = 1
    /// The second pass sits a little lighter than the first, which is what makes the two
    /// directions legible as tone rather than closing up into a grille.
    var second: CGFloat = 0.62

    var body: some View {
        let first = min(1, progress * 2)
        let second = max(0, progress * 2 - 1)
        ZStack {
            Rectangle().fill(AppBrand.Plate.trough.opacity(0.10 * Double(tone) * Double(min(1, progress * 3))))
            pass(AppBrand.Hatch.firstPass, trim: first, ink: 0.85)
            pass(AppBrand.Hatch.secondPass, trim: second, ink: 0.85 * Double(self.second))
        }
        .clipped()
        .allowsHitTesting(false)
    }

    @ViewBuilder
    private func pass(_ degrees: Double, trim: CGFloat, ink: Double) -> some View {
        if trim > 0 {
            ZStack {
                HatchField(degrees: degrees, spacing: spacing)
                    .trim(from: 0, to: trim)
                    .stroke(AppBrand.Plate.lip.opacity(0.5 * Double(tone)), lineWidth: weight * 0.4)
                    .offset(x: -0.7, y: -0.7)
                HatchField(degrees: degrees, spacing: spacing)
                    .trim(from: 0, to: trim)
                    .stroke(AppBrand.Plate.trough.opacity(ink * Double(tone)), lineWidth: weight)
            }
        }
    }
}

/// One cell of the plate: bare copper, ruled out with two cut strokes, or fixed with a point.
struct CutCell: View {
    let mark: Mark
    let size: CGFloat
    var ghost = false
    var hinted = false
    var waiting = false

    @State private var stroke: CGFloat = Motion.isStill ? 1 : 0
    @State private var opened = Motion.isStill
    @Environment(\.brand) private var brand

    var body: some View {
        ZStack {
            if ghost && mark == .blank {
                CutShading(progress: 1, tone: 0.14)
                    .breathing(amount: 0.05, period: 2.6)
            }
            if hinted {
                Rectangle().fill(brand.palette.accent.opacity(0.18))
            }
            switch mark {
            case .ruled:
                CutShading(progress: waiting ? 1 : stroke)
            case .point:
                lozenge
            case .blank:
                EmptyView()
            }
        }
        .frame(width: size, height: size)
        .onAppear { settle(to: mark, animated: false) }
        .onChange(of: mark) { _, new in settle(to: new, animated: true) }
    }

    private var lozenge: some View {
        ZStack {
            Lozenge()
                .fill(AppBrand.Plate.lip.opacity(0.65))
                .frame(width: size * 0.62, height: size * 0.37)
                .offset(x: -0.6, y: -0.8)
            Lozenge()
                .fill(AppBrand.Plate.trough)
                .frame(width: size * 0.62, height: size * 0.37)
        }
        .scaleEffect(opened ? 1 : 0.05)
        .animation(Motion.isStill ? nil : AppBrand.Cut.point, value: opened)
    }

    /// The cut: two strokes over 160 ms, or a lozenge opening past its width and settling back.
    private func settle(to mark: Mark, animated: Bool) {
        guard !Motion.isStill else {
            stroke = 1
            opened = mark == .point
            return
        }
        switch mark {
        case .ruled:
            if animated {
                stroke = 0
                withAnimation(.linear(duration: 0.16)) { stroke = 1 }
            } else {
                stroke = 1
            }
            opened = false
        case .point:
            stroke = 1
            if animated {
                opened = false
                DispatchQueue.main.async { opened = true }
            } else {
                opened = true
            }
        case .blank:
            stroke = 0
            opened = false
        }
    }
}

/// Where everything on a plate sits. The staircase matrix: the people down the left of every
/// block, then each remaining category once as a column and once as a row.
struct PlateLayout {
    let categories: Int
    let members: Int
    let cell: CGFloat
    let head: CGFloat
    let gap: CGFloat = 9

    init(categories: Int, members: Int, width: CGFloat) {
        self.categories = categories
        self.members = members
        let blocks = CGFloat(categories - 1)
        let head = min(30, max(20, width * 0.075))
        let usable = width - head - (blocks - 1) * 9 - 10
        self.cell = max(12, min(34, (usable / blocks / CGFloat(members)).rounded(.down)))
        self.head = head
    }

    var columns: [Int] { Array(1..<categories) }
    var rows: [Int] { [0] + Array((2..<categories).reversed()) }

    /// A sub-grid exists where the two categories have not been crossed already: the people
    /// against everything, and every other pair once.
    func exists(row: Int, column: Int) -> Bool { row == 0 || column < row }

    var step: CGFloat { CGFloat(members) * cell + gap }
    var gridWidth: CGFloat { CGFloat(columns.count) * step - gap }
    var gridHeight: CGFloat { CGFloat(rows.count) * step - gap }
    var width: CGFloat { head + gridWidth }
    var height: CGFloat { head + gridHeight }

    func origin(columnIndex: Int, rowIndex: Int) -> CGPoint {
        CGPoint(x: head + CGFloat(columnIndex) * step, y: head + CGFloat(rowIndex) * step)
    }

    /// The triangular void the staircase leaves at the right, which is where the plate stamps
    /// the figures of the blocks that have closed.
    var voidRect: CGRect {
        guard categories >= 4 else { return .zero }
        let x = head + CGFloat(categories - 2) * step
        let y = head + step
        return CGRect(x: x, y: y, width: max(0, head + gridWidth - x), height: max(0, head + gridHeight - y))
    }
}

/// The plate: a copper rectangle lying on the paper, its bevel catching the light on two
/// sides, ruled into the cross-referenced matrix, with its margin punched along the bottom.
/// The copper, the rules and the cut marks are drawn; every cell is a real button over them,
/// with a press state and a VoiceOver label.
struct PlateView: View {
    @ObservedObject var bench: Bench
    let session: Session
    /// The paper the plate is lying on gives it its width; everything else is worked out from
    /// that, so the cells are as big as the plate's shape allows and no bigger.
    let width: CGFloat
    /// The cell the first clue forces, on a plate with no cuts on it. Passed in rather than
    /// asked for per cell: it costs the solver a pass to answer.
    var teaching: Pairing?
    @Environment(\.brand) private var brand

    private var plate: Plate { session.plate }

    var body: some View {
        let layout = PlateLayout(categories: plate.categories, members: plate.members, width: width - 26)
        VStack(spacing: 5) {
            bands(layout)
            HStack(alignment: .top, spacing: 5) {
                rowBands(layout)
                copper(layout)
            }
        }
    }

    private var marginHeight: CGFloat { 62 }

    // MARK: The paper's registration bands, in each category's cast ink

    private func bands(_ layout: PlateLayout) -> some View {
        HStack(spacing: layout.gap) {
            Spacer().frame(width: layout.head + 5)
            ForEach(layout.columns, id: \.self) { category in
                Rectangle()
                    .fill(ink(category))
                    .frame(width: CGFloat(plate.members) * layout.cell, height: 3)
            }
            Spacer(minLength: 0)
        }
        .accessibilityHidden(true)
    }

    private func rowBands(_ layout: PlateLayout) -> some View {
        VStack(spacing: layout.gap) {
            Spacer().frame(height: layout.head + 5)
            ForEach(layout.rows, id: \.self) { category in
                Rectangle()
                    .fill(ink(category))
                    .frame(width: 3, height: CGFloat(plate.members) * layout.cell)
            }
            Spacer(minLength: 0)
        }
        .accessibilityHidden(true)
    }

    private func ink(_ category: Int) -> Color {
        let inks = brand.palette.extras
        guard !inks.isEmpty else { return brand.palette.accent }
        return muted ? brand.palette.inkSoft : inks[category % inks.count]
    }

    private func maxFigures(_ layout: PlateLayout) -> Int {
        max(1, Int((layout.voidRect.height - 26) / 26))
    }

    // MARK: The copper

    private func copper(_ layout: PlateLayout) -> some View {
        ZStack(alignment: .topLeading) {
            face(layout)
            rules(layout)
            heads(layout)
            cells(layout)
            if !layout.voidRect.isEmpty, !session.figures.isEmpty {
                figures(layout)
            }
            margin(layout)
        }
        .frame(width: layout.width + 12, height: layout.height + marginHeight)
        .overlay { registration(layout) }
    }

    private func face(_ layout: PlateLayout) -> some View {
        let shape = RoundedRectangle(cornerRadius: 3, style: .continuous)
        return ZStack {
            shape
                .fill(AppBrand.Plate.bevel)
                .offset(x: 3, y: 3)
            shape
                .fill(LinearGradient(colors: muted ? [Color(light: 0xCFC9BC, dark: 0x4A4A44), Color(light: 0xB6B0A2, dark: 0x3C3C36)]
                                                  : [AppBrand.Plate.faceTop, AppBrand.Plate.faceBottom],
                                     startPoint: .topLeading, endPoint: .bottomTrailing))
                .overlay {
                    // The tooth of the plate itself, very faint: rolled copper is not flat.
                    CutShading(progress: 1, spacing: 3.2, weight: 0.5, tone: 0.16)
                        .opacity(0.5)
                        .clipShape(shape)
                }
        }
        .frame(width: layout.width + 12, height: layout.height + marginHeight)
    }

    /// Muted ink: the plate in proof grey, and nothing in the margin but the date.
    private var muted: Bool { bench.record.calmInk && bench.isPro }

    private func registration(_ layout: PlateLayout) -> some View {
        // The printer's own corner marks, in every screenshot of this app.
        GeometryReader { geo in
            ForEach(0..<4, id: \.self) { corner in
                let x = corner % 2 == 0 ? 10.0 : geo.size.width - 10
                let y = corner < 2 ? 10.0 : geo.size.height - 10
                Path { path in
                    path.move(to: CGPoint(x: x - 5, y: y))
                    path.addLine(to: CGPoint(x: x + 5, y: y))
                    path.move(to: CGPoint(x: x, y: y - 5))
                    path.addLine(to: CGPoint(x: x, y: y + 5))
                    path.addEllipse(in: CGRect(x: x - 2.4, y: y - 2.4, width: 4.8, height: 4.8))
                }
                .stroke(AppBrand.Plate.trough.opacity(0.5), lineWidth: 0.8)
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    /// The rules between cells, and the border of every block — bitten deeper when the block
    /// has closed itself.
    private func rules(_ layout: PlateLayout) -> some View {
        Canvas { context, _ in
            for (rowIndex, row) in layout.rows.enumerated() {
                for (columnIndex, column) in layout.columns.enumerated() where layout.exists(row: row, column: column) {
                    let origin = layout.origin(columnIndex: columnIndex, rowIndex: rowIndex)
                    let side = CGFloat(plate.members) * layout.cell
                    var inner = Path()
                    for step in 1..<plate.members {
                        let offset = CGFloat(step) * layout.cell
                        inner.move(to: CGPoint(x: origin.x + offset, y: origin.y))
                        inner.addLine(to: CGPoint(x: origin.x + offset, y: origin.y + side))
                        inner.move(to: CGPoint(x: origin.x, y: origin.y + offset))
                        inner.addLine(to: CGPoint(x: origin.x + side, y: origin.y + offset))
                    }
                    context.stroke(inner, with: .color(AppBrand.Plate.trough.opacity(0.22)), lineWidth: 0.5)
                    let closed = session.closedPairs.contains(min(row, column) * plate.categories + max(row, column))
                    context.stroke(Path(CGRect(x: origin.x, y: origin.y, width: side, height: side)),
                                   with: .color(AppBrand.Plate.trough.opacity(closed ? 0.62 : 0.4)),
                                   lineWidth: closed ? 2 : 1.5)
                }
            }
        }
        .frame(width: layout.width + 12, height: layout.height + marginHeight)
        .animation(Motion.resolved(Motion.gentle), value: session.closedPairs)
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    /// Column and row heads are cast marks cut into the copper — never rotated text.
    private func heads(_ layout: PlateLayout) -> some View {
        ZStack(alignment: .topLeading) {
            ForEach(layout.columns.indices, id: \.self) { columnIndex in
                let category = layout.columns[columnIndex]
                ForEach(0..<plate.members, id: \.self) { member in
                    let origin = layout.origin(columnIndex: columnIndex, rowIndex: 0)
                    EngravedMark(glyph: plate.casting[category][member],
                                 size: min(22, layout.cell - 2),
                                 color: AppBrand.Plate.trough.opacity(0.85),
                                 lip: AppBrand.Plate.lip.opacity(0.55),
                                 weight: 2)
                        .position(x: origin.x + (CGFloat(member) + 0.5) * layout.cell,
                                  y: layout.head * 0.55)
                }
            }
            ForEach(layout.rows.indices, id: \.self) { rowIndex in
                let category = layout.rows[rowIndex]
                ForEach(0..<plate.members, id: \.self) { member in
                    let origin = layout.origin(columnIndex: 0, rowIndex: rowIndex)
                    EngravedMark(glyph: plate.casting[category][member],
                                 size: min(22, layout.cell - 2),
                                 color: AppBrand.Plate.trough.opacity(0.85),
                                 lip: AppBrand.Plate.lip.opacity(0.55),
                                 weight: 2)
                        .position(x: layout.head * 0.55,
                                  y: origin.y + (CGFloat(member) + 0.5) * layout.cell)
                }
            }
        }
        .frame(width: layout.width + 12, height: layout.height + marginHeight, alignment: .topLeading)
        .allowsHitTesting(false)
    }

    // MARK: The cells

    private func cells(_ layout: PlateLayout) -> some View {
        ZStack(alignment: .topLeading) {
            ForEach(layout.rows.indices, id: \.self) { rowIndex in
                ForEach(layout.columns.indices, id: \.self) { columnIndex in
                    let row = layout.rows[rowIndex], column = layout.columns[columnIndex]
                    if layout.exists(row: row, column: column) {
                        block(layout, rowIndex: rowIndex, columnIndex: columnIndex, row: row, column: column)
                    }
                }
            }
        }
        .frame(width: layout.width + 12, height: layout.height + marginHeight, alignment: .topLeading)
    }

    private func block(_ layout: PlateLayout, rowIndex: Int, columnIndex: Int, row: Int, column: Int) -> some View {
        let origin = layout.origin(columnIndex: columnIndex, rowIndex: rowIndex)
        return ForEach(0..<plate.members, id: \.self) { i in
            ForEach(0..<plate.members, id: \.self) { j in
                let rowCell = Cell(category: row, member: i)
                let columnCell = Cell(category: column, member: j)
                cellButton(rowCell, columnCell, layout: layout)
                    .position(x: origin.x + (CGFloat(j) + 0.5) * layout.cell,
                              y: origin.y + (CGFloat(i) + 0.5) * layout.cell)
            }
        }
    }

    private func cellButton(_ rowCell: Cell, _ columnCell: Cell, layout: PlateLayout) -> some View {
        let pairing = Pairing(rowCell, columnCell)
        let waiting = bench.pending.map { Pairing($0.x, $0.y) == pairing } ?? false
        let mark: Mark = bench.cascading.contains(pairing)
            ? .blank
            : (waiting ? (bench.pending?.mark ?? .blank) : session.grid.at(rowCell, columnCell))
        let ghost = teaching == pairing
        return Button {
            bench.cut(rowCell, columnCell)
        } label: {
            CutCell(mark: mark, size: layout.cell, ghost: ghost,
                    hinted: bench.loupe?.pairing == pairing, waiting: waiting)
        }
        .buttonStyle(.pressable(scale: 0.97, haptic: false))
        .accessibilityLabel(label(rowCell, columnCell, mark: mark))
        .accessibilityHint(hint(rowCell, columnCell, mark: mark))
    }

    private func label(_ x: Cell, _ y: Cell, mark: Mark) -> String {
        let state: String
        switch mark {
        case .blank: state = "bare copper"
        case .ruled: state = "ruled out"
        case .point: state = "fixed"
        }
        return "\(plate.member(x).short) and \(plate.member(y).short), \(state)"
    }

    /// VoiceOver is the one place this app explains itself, and it should.
    private func hint(_ x: Cell, _ y: Cell, mark: Mark) -> String {
        var accessibilityHint: String
        switch mark {
        case .blank: accessibilityHint = "Rules out \(plate.member(x).short) and \(plate.member(y).short). Double tap again to fix it instead."
        case .ruled: accessibilityHint = "Double tap to fix this pairing instead."
        case .point: accessibilityHint = "Double tap twice to take the point back out."
        }
        return accessibilityHint
    }

    // MARK: The figures, and the copper thread

    /// A small engraved figure of the pairing for every block that has closed, stamped into
    /// the void the staircase leaves — so the margin fills with the print as she goes.
    private func figures(_ layout: PlateLayout) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Settled")
                .plateCaps(size: 9)
                .foregroundStyle(AppBrand.Plate.trough.opacity(0.55))
            ForEach(Array(session.figures.prefix(maxFigures(layout)).enumerated()), id: \.offset) { index, pair in
                HStack(spacing: 5) {
                    ForEach(Array(pair.enumerated()), id: \.offset) { _, glyph in
                        EngravedMark(glyph: glyph, size: 20,
                                     color: AppBrand.Plate.trough.opacity(0.9),
                                     lip: AppBrand.Plate.lip.opacity(0.6), weight: 2)
                    }
                }
                .popIn(delay: 0.03 * Double(index))
            }
            Spacer(minLength: 0)
        }
        .frame(width: layout.voidRect.width - 6, height: layout.voidRect.height - 8, alignment: .topLeading)
        .offset(x: layout.voidRect.minX + 4, y: layout.voidRect.minY + 4)
        .allowsHitTesting(false)
    }

    // MARK: The margin

    private func margin(_ layout: PlateLayout) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Rectangle()
                .fill(AppBrand.Plate.trough.opacity(0.35))
                .frame(height: 1)
            HStack(alignment: .bottom, spacing: 10) {
                VStack(alignment: .leading, spacing: 1) {
                    Text(caps)
                        .plateCaps(size: 8.5)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                        .foregroundStyle(AppBrand.Plate.trough.opacity(0.72))
                    HStack(alignment: .firstTextBaseline, spacing: 8) {
                        Text("\(session.pointsCut)")
                            .brandDisplay(size: 34)
                            .foregroundStyle(AppBrand.Plate.trough)
                        Text(muted ? "of \(plate.totalPoints) points"
                                   : "of \(plate.totalPoints) points  ·  line of \(session.run.chain)")
                            .plateCaps(size: 8.5)
                            .lineLimit(2)
                            .minimumScaleFactor(0.8)
                            .foregroundStyle(AppBrand.Plate.trough.opacity(0.72))
                    }
                }
                Spacer(minLength: 0)
                tools
            }
            .padding(.top, 4)
        }
        .padding(.horizontal, 14)
        .frame(width: layout.width + 12, height: marginHeight, alignment: .bottom)
        .position(x: (layout.width + 12) / 2, y: layout.height + marginHeight / 2 - 2)
        .overlay { scars(layout) }
    }

    private var caps: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMMM"
        let date = formatter.string(from: Date())
        if muted { return "plate \(plate.number) · \(date)" }
        return "plate \(plate.number) · \(date) · depth \(plate.depth)"
    }

    /// Every scar, as a hairline scratch running out into the margin. They stay for the life
    /// of the plate and they print on the pull.
    private func scars(_ layout: PlateLayout) -> some View {
        GeometryReader { geo in
            ForEach(Array(session.scars.enumerated()), id: \.offset) { index, at in
                Path { path in
                    let x = 20 + CGFloat(at) * max(40, geo.size.width - 60)
                    let y = geo.size.height - 14 - CGFloat(index % 3) * 9
                    path.move(to: CGPoint(x: x, y: y))
                    path.addLine(to: CGPoint(x: x + 34, y: y - 9))
                }
                .stroke(AppBrand.Plate.trough.opacity(0.45), lineWidth: 0.9)
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    /// The burnisher at the left of the margin, the loupe at its right.
    private var tools: some View {
        HStack(spacing: 14) {
            Button {
                if bench.canBurnish { bench.burnish() } else { bench.takeItBack() }
            } label: {
                BurnisherMark()
                    .stroke(AppBrand.Plate.trough.opacity(bench.canTakeBack || bench.canBurnish ? 0.85 : 0.3),
                            style: StrokeStyle(lineWidth: 2, lineCap: .round))
                    .frame(width: 24, height: 24)
            }
            .buttonStyle(.pressable(scale: 0.9))
            .disabled(!bench.canTakeBack && !bench.canBurnish)
            .accessibilityLabel(bench.canBurnish ? "Burnish it out" : "Take it back")

            Button {
                bench.nameTheClue()
            } label: {
                LoupeMark()
                    .stroke(brand.palette.accent, style: StrokeStyle(lineWidth: 2.2, lineCap: .round))
                    .frame(width: 26, height: 26)
            }
            .buttonStyle(.pressable(scale: 0.9))
            .accessibilityLabel("Name the clue")
        }
    }
}

/// The loupe: a lens on its handle. The hint, free and unlimited, with no badge counting
/// anything down.
struct LoupeMark: Shape {
    func path(in rect: CGRect) -> Path {
        let side = min(rect.width, rect.height)
        var path = Path()
        path.addEllipse(in: CGRect(x: side * 0.06, y: side * 0.06, width: side * 0.62, height: side * 0.62))
        path.move(to: CGPoint(x: side * 0.62, y: side * 0.62))
        path.addLine(to: CGPoint(x: side * 0.95, y: side * 0.95))
        return path
    }
}

/// The burnisher: a smooth steel rod with a swelled tip, for taking a scratch off a print.
struct BurnisherMark: Shape {
    func path(in rect: CGRect) -> Path {
        let side = min(rect.width, rect.height)
        var path = Path()
        path.move(to: CGPoint(x: side * 0.16, y: side * 0.84))
        path.addLine(to: CGPoint(x: side * 0.72, y: side * 0.24))
        path.addEllipse(in: CGRect(x: side * 0.64, y: side * 0.08, width: side * 0.26, height: side * 0.26))
        path.move(to: CGPoint(x: side * 0.1, y: side * 0.9))
        path.addLine(to: CGPoint(x: side * 0.3, y: side * 0.74))
        return path
    }
}
