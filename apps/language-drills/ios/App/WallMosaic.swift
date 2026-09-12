import FactoryKit
import SwiftUI

/// The whole thousand as one object: twelve panels of small tiles, known ones in their glaze,
/// drying ones half glazed, the rest bare clay.
///
/// Drawn in one `Canvas` rather than a thousand views, so it costs the same on the win screen,
/// on Progress and inside the share card. It fits itself to whatever room it is given.
struct WallMosaic: View {
    @Environment(\.brand) private var brand

    /// The finish of every rank in the deck. Anything missing is bare clay.
    let firings: [Int: Firing]
    /// Ranks that went into the wall today: they keep a ring of fresh amber mortar.
    var fresh: Set<Int> = []
    /// The largest a tile may be drawn; it shrinks to fit.
    var maxTile: CGFloat = 9
    var gap: CGFloat = 2
    var panelGap: CGFloat = 11
    var panelsAcross: Int = 4
    /// 0…1 as a lustre sweep crosses the wall; nil when nothing is sweeping.
    var lustre: Double?

    private var panelRows: Int {
        Int(ceil(Double(max(Deck.themes.count, 1)) / Double(panelsAcross)))
    }

    private var longestPanel: Int {
        (0..<Deck.themes.count).map { Deck.panel($0).count }.max() ?? 1
    }

    var body: some View {
        GeometryReader { geo in
            let layout = fit(in: geo.size)
            Canvas { context, _ in
                draw(in: &context, layout: layout)
            }
            .frame(width: geo.size.width, height: geo.size.height)
            .overlay {
                if let lustre {
                    sweep(at: lustre, width: geo.size.width)
                }
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("The wall: \(firings.values.filter { $0 == .set }.count) tiles of \(Deck.total) set.")
    }

    private struct Layout {
        var tile: CGFloat
        var cols: Int
        var rows: Int
        var panelW: CGFloat
        var panelH: CGFloat
        var originX: CGFloat
        var originY: CGFloat
        var panelGapV: CGFloat
    }

    /// Pick the biggest tile that puts the whole wall inside the space, and centre it there.
    private func fit(in size: CGSize) -> Layout {
        var best = Layout(tile: 2, cols: 1, rows: 1, panelW: 0, panelH: 0,
                          originX: 0, originY: 0, panelGapV: panelGap)
        var candidate = maxTile
        while candidate >= 2 {
            let panelW = (size.width - panelGap * CGFloat(panelsAcross - 1)) / CGFloat(panelsAcross)
            let cols = max(1, Int((panelW + gap) / (candidate + gap)))
            let rows = Int(ceil(Double(longestPanel) / Double(cols)))
            let panelH = CGFloat(rows) * (candidate + gap) - gap
            let totalH = CGFloat(panelRows) * panelH + panelGap * CGFloat(panelRows - 1)
            if totalH <= size.height {
                let usedW = CGFloat(cols) * (candidate + gap) - gap
                best = Layout(tile: candidate,
                              cols: cols,
                              rows: rows,
                              panelW: panelW,
                              panelH: panelH,
                              originX: (panelW - usedW) / 2,
                              originY: (size.height - totalH) / 2,
                              panelGapV: panelGap)
                break
            }
            candidate -= 0.5
        }
        return best
    }

    private func draw(in context: inout GraphicsContext, layout: Layout) {
        let radius = max(1, layout.tile * 0.22)
        let bare = brand.palette.surface.opacity(0.5)
        let highlight = brand.palette.highlight

        for theme in 0..<Deck.themes.count {
            let panelCol = theme % panelsAcross
            let panelRow = theme / panelsAcross
            let baseX = CGFloat(panelCol) * (layout.panelW + panelGap) + layout.originX
            let baseY = CGFloat(panelRow) * (layout.panelH + layout.panelGapV) + layout.originY
            let glaze = AppBrand.glaze(theme)
            let words = Deck.panel(theme)

            for (i, word) in words.enumerated() {
                let col = i % layout.cols
                let row = i / layout.cols
                guard row < layout.rows else { break }
                let rect = CGRect(x: baseX + CGFloat(col) * (layout.tile + gap),
                                  y: baseY + CGFloat(row) * (layout.tile + gap),
                                  width: layout.tile,
                                  height: layout.tile)
                let path = Path(roundedRect: rect, cornerRadius: radius)
                switch firings[word.rank] ?? .bare {
                case .set:
                    context.fill(path, with: .color(glaze))
                    // One line of light along the top edge is the whole bevel at this size.
                    var lit = Path()
                    lit.move(to: CGPoint(x: rect.minX + radius, y: rect.minY + 0.5))
                    lit.addLine(to: CGPoint(x: rect.maxX - radius, y: rect.minY + 0.5))
                    context.stroke(lit, with: .color(.white.opacity(0.28)), lineWidth: 1)
                case .drying:
                    context.fill(path, with: .color(brand.palette.surface))
                    context.fill(path, with: .color(glaze.opacity(0.42)))
                case .bare:
                    context.fill(path, with: .color(bare))
                }
                if fresh.contains(word.rank) {
                    context.stroke(path, with: .color(highlight), lineWidth: 1.2)
                }
            }
        }
    }

    /// A new hundred lights the wall course by course, left to right.
    private func sweep(at t: Double, width: CGFloat) -> some View {
        LinearGradient(colors: [.white.opacity(0), .white.opacity(0.55), .white.opacity(0)],
                       startPoint: .leading, endPoint: .trailing)
            .frame(width: width * 0.35)
            .offset(x: -width * 0.5 + t * width * 1.3)
            .blendMode(.plusLighter)
            .allowsHitTesting(false)
    }
}

/// The wall line: how much of the thousand is standing, with a notch at the next hundred.
struct WallLine: View {
    @Environment(\.brand) private var brand
    let known: Int
    var width: CGFloat = 292

    private var nextHundred: Int { min(Deck.total, (known / 100 + 1) * 100) }

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            GeometryReader { geo in
                let w = geo.size.width
                let filled = w * CGFloat(min(1, Double(known) / Double(max(Deck.total, 1))))
                ZStack(alignment: .leading) {
                    Capsule().fill(brand.palette.surface)
                    Capsule().fill(brand.palette.accent).frame(width: filled)
                    Capsule()
                        .fill(brand.palette.highlight)
                        .frame(width: 3, height: 11)
                        .offset(x: w * CGFloat(Double(nextHundred) / Double(max(Deck.total, 1))) - 1.5)
                }
                .frame(height: 3)
                .frame(height: geo.size.height, alignment: .center)
            }
            .frame(height: 11)

            HStack(spacing: 10) {
                Mark("THE WALL").foregroundStyle(brand.palette.inkSoft)
                Spacer(minLength: 0)
                Mark("\(nextHundred) NEXT").foregroundStyle(brand.palette.inkSoft)
            }
            .dynamicTypeSize(...DynamicTypeSize.accessibility1)
        }
        .frame(maxWidth: width)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(known) of \(Deck.total) set. Next hundred at \(nextHundred).")
    }
}
