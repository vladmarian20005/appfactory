import SwiftUI

/// The thread's geometry, drawn one way everywhere: centre to centre through the pins, round
/// caps and joins, a ring of thread round every pin it turns on, and a lighter dashed strand
/// along every plaited run. `design/lace.js` is the reference drawing; this reproduces it.
enum ThreadGeometry {
    /// Straight runs of four or more pins that end in a turn — the plaits.
    static func plaits(in path: [Int], taken: Int, min: Int = 4, includeLast: Bool = false) -> [Range<Int>] {
        var out: [Range<Int>] = []
        guard taken >= 2 else { return out }
        var runStart = 0
        for i in 1..<taken {
            let turned = i + 1 < taken ? (path[i + 1] - path[i]) != (path[i] - path[i - 1]) : includeLast
            if turned {
                if i - runStart + 1 >= min { out.append(runStart..<(i + 1)) }
                runStart = i
            }
        }
        return out
    }

    /// Every straight run, plaited or not, in order: the margin's run marks.
    static func runs(in path: [Int]) -> [Range<Int>] {
        guard path.count >= 2 else { return [] }
        var out: [Range<Int>] = []
        var runStart = 0
        for i in 1..<path.count {
            let last = i == path.count - 1
            if last || (path[i + 1] - path[i]) != (path[i] - path[i - 1]) {
                out.append(runStart..<(i + 1))
                runStart = i
            }
        }
        return out
    }

    /// Indices of the pins the thread turns on.
    static func turns(in path: [Int]) -> [Int] {
        guard path.count >= 3 else { return [] }
        return (1..<(path.count - 1)).filter { (path[$0 + 1] - path[$0]) != (path[$0] - path[$0 - 1]) }
    }
}

/// Where a pattern's cells sit on a square card of a given size.
struct CardLayout: Equatable {
    let side: Int
    let size: CGFloat

    /// The pins keep a margin of a little more than half a pitch from the card's edge.
    var pitch: CGFloat { size / (CGFloat(side) + 0.8) }
    var inset: CGFloat { (size - pitch * CGFloat(side)) / 2 }

    func centre(_ cell: Int) -> CGPoint {
        CGPoint(x: inset + (CGFloat(cell % side) + 0.5) * pitch,
                y: inset + (CGFloat(cell / side) + 0.5) * pitch)
    }

    /// The cell under a point, or nil when outside the pins.
    func cell(at p: CGPoint) -> Int? {
        let c = Int(floor((p.x - inset) / pitch)), r = Int(floor((p.y - inset) / pitch))
        guard r >= 0, c >= 0, r < side, c < side else { return nil }
        return r * side + c
    }

    /// The cell whose inner 64 % contains the point — the hysteresis that keeps a slow finger
    /// on a boundary from jittering between two pins.
    func innerCell(at p: CGPoint) -> Int? {
        guard let cell = cell(at: p) else { return nil }
        let c = centre(cell)
        let reach = pitch * 0.32
        return abs(p.x - c.x) <= reach && abs(p.y - c.y) <= reach ? cell : nil
    }

    /// Stroke widths at this pitch: the card's 3.4 pt thread, scaled down for small laces.
    var threadWidth: CGFloat { min(3.4, pitch * 0.14) }
    var ringRadius: CGFloat { min(pitch, 40) * 0.17 }
    var ringWidth: CGFloat { min(2, pitch * 0.08) }
    var twistWidth: CGFloat { min(1.1, pitch * 0.05) }
    var gimpWidth: CGFloat { min(2.5, pitch * 0.1) }
}

struct ThreadStyle {
    var color: Color
    var twist: Color
    var width: CGFloat? = nil
    /// Every run gets its twist, plaited or not: the whole piece is lace.
    var twistAll = false
}

extension GraphicsContext {
    /// The thread, through `path` (cell indices) on `layout`, with its rings and plaits.
    func drawThread(_ path: [Int], plaits: [Range<Int>], layout: CardLayout, style: ThreadStyle,
                    ringsUpTo: Int? = nil) {
        guard !path.isEmpty else { return }
        let pts = path.map(layout.centre)
        var line = Path()
        line.move(to: pts[0])
        for p in pts.dropFirst() { line.addLine(to: p) }
        let w = style.width ?? layout.threadWidth
        stroke(line, with: .color(style.color),
               style: StrokeStyle(lineWidth: w, lineCap: .round, lineJoin: .round))
        // The wrap: a ring of thread round every pin the thread turns on.
        let r = layout.ringRadius
        for i in ThreadGeometry.turns(in: path) where i < (ringsUpTo ?? .max) {
            let c = pts[i]
            stroke(Path(ellipseIn: CGRect(x: c.x - r, y: c.y - r, width: 2 * r, height: 2 * r)),
                   with: .color(style.color), lineWidth: layout.ringWidth)
        }
        if path.count == 1 {
            let c = pts[0]
            fill(Path(ellipseIn: CGRect(x: c.x - w * 0.7, y: c.y - w * 0.7, width: w * 1.4, height: w * 1.4)),
                 with: .color(style.color))
        }
        // Plaits: the lighter strand, dashed 3/3, along the run.
        let twisted = style.twistAll ? ThreadGeometry.runs(in: path).filter { $0.count >= 2 } : plaits
        for run in twisted where run.upperBound <= path.count {
            var s = Path()
            s.move(to: pts[run.lowerBound])
            s.addLine(to: pts[run.upperBound - 1])
            let dash = max(1.5, min(3, layout.pitch * 0.12))
            stroke(s, with: .color(style.twist),
                   style: StrokeStyle(lineWidth: layout.twistWidth, lineCap: .round, dash: [dash, dash]))
        }
    }

    /// The gimp: the pattern's walls, drawn between cells, never through a pin.
    func drawGimp(_ gimp: Set<Edge>, layout: CardLayout, color: Color) {
        var walls = Path()
        let half = layout.pitch * 0.42
        for e in gimp {
            let a = layout.centre(Int(e.a)), b = layout.centre(Int(e.b))
            let m = CGPoint(x: (a.x + b.x) / 2, y: (a.y + b.y) / 2)
            if Int(e.b) == Int(e.a) + 1 {
                walls.move(to: CGPoint(x: m.x, y: m.y - half)); walls.addLine(to: CGPoint(x: m.x, y: m.y + half))
            } else {
                walls.move(to: CGPoint(x: m.x - half, y: m.y)); walls.addLine(to: CGPoint(x: m.x + half, y: m.y))
            }
        }
        stroke(walls, with: .color(color),
               style: StrokeStyle(lineWidth: layout.gimpWidth, lineCap: .round))
    }

    /// A pin: a round steel head with a highlight at its upper left and a shadow below right.
    func drawPin(at c: CGPoint, head: CGFloat, color: Color, sunk: Bool = false) {
        let d = sunk ? head * 0.86 : head
        if !sunk {
            fill(Path(ellipseIn: CGRect(x: c.x - d / 2 + d * 0.16, y: c.y - d / 2 + d * 0.2, width: d, height: d)),
                 with: .color(.black.opacity(0.2)))
        }
        fill(Path(ellipseIn: CGRect(x: c.x - d / 2, y: c.y - d / 2, width: d, height: d)), with: .color(color))
        let h = d * 0.3
        fill(Path(ellipseIn: CGRect(x: c.x - d * 0.28, y: c.y - d * 0.3, width: h, height: h)),
             with: .color(.white.opacity(sunk ? 0.35 : 0.7)))
    }

    /// A prick: the hole a pin leaves in the card.
    func drawPrick(at c: CGPoint, size: CGFloat, ink: Color) {
        fill(Path(ellipseIn: CGRect(x: c.x - size / 2, y: c.y - size / 2, width: size, height: size)),
             with: .color(ink.opacity(0.28)))
    }

    /// The picot edge: a scalloped hairline round the piece.
    func drawPicot(layout: CardLayout, color: Color, scallops: Int = 40) {
        let lo = layout.inset - layout.pitch * 0.1, hi = layout.size - lo
        let perSide = max(4, scallops / 4)
        let sw = (hi - lo) / CGFloat(perSide)
        var p = Path()
        func scallop(from a: CGPoint, to b: CGPoint, out: CGVector) {
            let mid = CGPoint(x: (a.x + b.x) / 2 + out.dx * sw * 0.5, y: (a.y + b.y) / 2 + out.dy * sw * 0.5)
            p.addQuadCurve(to: b, control: mid)
        }
        p.move(to: CGPoint(x: lo, y: lo))
        for k in 0..<perSide {
            scallop(from: CGPoint(x: lo + CGFloat(k) * sw, y: lo), to: CGPoint(x: lo + CGFloat(k + 1) * sw, y: lo), out: CGVector(dx: 0, dy: -1))
        }
        for k in 0..<perSide {
            scallop(from: CGPoint(x: hi, y: lo + CGFloat(k) * sw), to: CGPoint(x: hi, y: lo + CGFloat(k + 1) * sw), out: CGVector(dx: 1, dy: 0))
        }
        for k in 0..<perSide {
            scallop(from: CGPoint(x: hi - CGFloat(k) * sw, y: hi), to: CGPoint(x: hi - CGFloat(k + 1) * sw, y: hi), out: CGVector(dx: 0, dy: 1))
        }
        for k in 0..<perSide {
            scallop(from: CGPoint(x: lo, y: hi - CGFloat(k) * sw), to: CGPoint(x: lo, y: hi - CGFloat(k + 1) * sw), out: CGVector(dx: -1, dy: 0))
        }
        stroke(p, with: .color(color), lineWidth: max(0.6, min(1.4, layout.pitch * 0.05)))
    }
}

/// A small lace: a piece's thread figure on nothing, at any size. The sampler's pieces, the
/// book's chapters, the swatch.
struct SmallLace: View {
    let piece: Piece
    var size: CGFloat = 56

    var body: some View {
        Canvas { gc, sz in
            let layout = CardLayout(side: piece.side, size: sz.width)
            let path = piece.path.map(Int.init)
            gc.drawThread(path, plaits: piece.plaits, layout: layout,
                          style: ThreadStyle(color: piece.thread.color, twist: piece.thread.twist))
            if piece.picot {
                gc.drawPicot(layout: layout, color: AppBrand.Workbox.gold, scallops: 24)
            }
        }
        .frame(width: size, height: size)
        .accessibilityHidden(true)
    }
}
