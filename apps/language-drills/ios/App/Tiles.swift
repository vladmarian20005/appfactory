import FactoryKit
import SwiftUI

extension Color {
    /// The same colour, fired darker. Resolves per trait collection, so a glaze shades
    /// correctly in both the workshop at eleven and the workshop at night.
    func shaded(_ amount: Double) -> Color {
        Color(uiColor: UIColor { traits in
            let base = UIColor(self).resolvedColor(with: traits)
            var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
            base.getRed(&r, green: &g, blue: &b, alpha: &a)
            let k = 1 - CGFloat(amount)
            return UIColor(red: r * k, green: g * k, blue: b * k, alpha: a)
        })
    }
}

/// The light a window leaves on a glaze, at about 102° across the face. `travel` runs -1 to 1
/// and is what the turn animates: a tile catching a window rather than a card animating.
struct TileSheen: View {
    var travel: Double = -0.3
    var strength: Double = 0.3

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            Rectangle()
                .fill(LinearGradient(colors: [.white.opacity(0), .white.opacity(strength), .white.opacity(0)],
                                     startPoint: .top, endPoint: .bottom))
                .frame(width: max(w, h) * 2.4, height: max(w, h) * 0.34)
                .rotationEffect(.degrees(-12))
                .position(x: w / 2, y: h / 2 + travel * h)
        }
        .allowsHitTesting(false)
    }
}

/// The pressed bevel every tile in this app carries: an inner light on the top and left edges,
/// an inner shadow on the bottom and right, scaled to the tile.
struct TileBevel: View {
    let radius: CGFloat
    var width: CGFloat = 3
    var strength: Double = 1

    var body: some View {
        RoundedRectangle(cornerRadius: radius, style: .continuous)
            .strokeBorder(
                LinearGradient(
                    colors: [.white.opacity(0.42 * strength),
                             .white.opacity(0.06 * strength),
                             .black.opacity(0.10 * strength),
                             .black.opacity(0.30 * strength)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing),
                lineWidth: width)
            .allowsHitTesting(false)
    }
}

/// A fired tile: the theme's glaze as a vertical gradient, the bevel, and the light on it.
struct GlazedTile: View {
    let glaze: Color
    var radius: CGFloat = 12
    var bevel: CGFloat = 3
    var sheen: Bool = true
    var travel: Double = -0.3

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: radius, style: .continuous)
        shape
            .fill(LinearGradient(colors: [glaze, glaze.shaded(0.14)], startPoint: .top, endPoint: .bottom))
            .overlay { if sheen { TileSheen(travel: travel).clipShape(shape) } }
            .overlay { TileBevel(radius: radius, width: bevel) }
    }
}

/// Unfired clay: matte, no light on it, because nothing has been glazed yet.
struct BisqueTile: View {
    @Environment(\.brand) private var brand
    var radius: CGFloat = 12

    var body: some View {
        RoundedRectangle(cornerRadius: radius, style: .continuous)
            .fill(brand.palette.surface)
            .overlay {
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .strokeBorder(AppBrand.clayEdge.opacity(0.45), lineWidth: 1)
            }
    }
}

/// On the bench: the glaze went on but the tile has not had its third firing, so the clay
/// still shows through one corner.
struct DryingTile: View {
    @Environment(\.brand) private var brand
    let glaze: Color
    var radius: CGFloat = 6
    var bevel: CGFloat = 2

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: radius, style: .continuous)
        shape
            .fill(brand.palette.surface)
            .overlay {
                shape.fill(glaze.opacity(0.45))
            }
            .overlay {
                // The diagonal of raw clay a half-glazed tile shows along its lower corner.
                GeometryReader { geo in
                    Path { p in
                        p.move(to: CGPoint(x: geo.size.width, y: geo.size.height * 0.42))
                        p.addLine(to: CGPoint(x: geo.size.width, y: geo.size.height))
                        p.addLine(to: CGPoint(x: geo.size.width * 0.42, y: geo.size.height))
                        p.closeSubpath()
                    }
                    .fill(AppBrand.clayEdge.opacity(0.55))
                }
                .clipShape(shape)
            }
            .overlay { TileBevel(radius: radius, width: bevel, strength: 0.6) }
    }
}

/// An empty slot in a course: a recessed grout gap in canvas colour, waiting for its tile.
struct GroutGap: View {
    @Environment(\.brand) private var brand
    var radius: CGFloat = 2

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: radius, style: .continuous)
        shape
            .fill(brand.palette.canvas.shaded(0.06))
            .overlay {
                shape.strokeBorder(
                    LinearGradient(colors: [.black.opacity(0.16), .white.opacity(0.10)],
                                   startPoint: .topLeading, endPoint: .bottomTrailing),
                    lineWidth: 1)
            }
    }
}

/// One tile of the wall, drawn at whatever size the wall is being read at.
struct WallTile: View {
    @Environment(\.brand) private var brand
    let firing: Firing
    let glaze: Color
    var radius: CGFloat = 2
    var freshMortar: Bool = false
    var bevel: CGFloat = 1

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: radius, style: .continuous)
        Group {
            switch firing {
            case .set:
                shape
                    .fill(LinearGradient(colors: [glaze, glaze.shaded(0.16)], startPoint: .top, endPoint: .bottom))
                    .overlay { TileBevel(radius: radius, width: bevel, strength: 0.8) }
            case .drying:
                shape
                    .fill(brand.palette.surface)
                    .overlay { shape.fill(glaze.opacity(0.42)) }
            case .bare:
                shape.fill(brand.palette.surface.opacity(0.55))
            }
        }
        .overlay {
            // A tile that went in today keeps a ring of fresh mortar until midnight, so the
            // day's work can be found inside the thousand.
            if freshMortar {
                shape.strokeBorder(brand.palette.highlight, lineWidth: 1.5)
            }
        }
    }
}

extension View {
    /// The workshop wall behind a screen: the plaster mesh, drifting, with the trowel grain
    /// worked into it. `brandBackground` alone puts the mesh behind everything, so the grain
    /// has to go on top of it and still under the content — which is what this is for.
    func workshopBackground() -> some View {
        scrollContentBackground(.hidden)
            .background {
                BrandBackground(drift: true)
                    .overlay { TrowelGrain() }
                    .ignoresSafeArea()
            }
    }
}

/// Troweled plaster: the mottle a flat fill cannot give. Seeded once and it never moves, so a
/// capture of the bench is the same picture every run.
struct TrowelGrain: View {
    @Environment(\.brand) private var brand
    var strokes = 900

    var body: some View {
        Canvas { context, size in
            var seed: UInt64 = 0x5EED_1CE
            func next() -> Double {
                seed = seed &* 6_364_136_223_846_793_005 &+ 1_442_695_040_888_963_407
                return Double(seed >> 11) / Double(1 << 53)
            }
            for _ in 0..<strokes {
                let x = next() * size.width
                let y = next() * size.height
                let length = 5 + next() * 13
                let lean = (next() - 0.5) * 0.5
                var path = Path()
                path.move(to: CGPoint(x: x, y: y))
                path.addLine(to: CGPoint(x: x + length, y: y + length * lean))
                context.stroke(path, with: .color(brand.palette.ink.opacity(0.03)), lineWidth: 1)
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}
