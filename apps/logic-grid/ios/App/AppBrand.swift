import FactoryKit
import SwiftUI

/// The shop at eleven in the morning under a north light: a zinc slab, cream laid paper, and
/// the copper plate, which is the only warm thing in the room. Straight from DESIGN.md.
enum AppBrand {
    static let brand = Brand(
        palette: BrandPalette(
            canvas: Color(light: 0x96A199, dark: 0x0F1413),
            surface: Color(light: 0xF3EDDC, dark: 0x23231E),
            ink: Color(light: 0x15191A, dark: 0xEFE8D6),
            inkSoft: Color(light: 0x2F3634, dark: 0xA29D8C),
            accent: Color(light: 0x10525C, dark: 0x67CBD6),
            onAccent: Color(light: 0xF3EDDC, dark: 0x04191C),
            highlight: Color(light: 0x9E4E17, dark: 0xF0A257),
            success: Color(light: 0x286554, dark: 0x6FC6A4),
            miss: Color(light: 0x6E6455, dark: 0x9E9483),
            extras: [
                Color(light: 0x9E4E17, dark: 0xF0A257),   // copper
                Color(light: 0x1D4468, dark: 0x89B4E0),   // prussian
                Color(light: 0x286554, dark: 0x6FC6A4),   // verdigris
                Color(light: 0x8E3A33, dark: 0xDE8B80),   // sanguine
                Color(light: 0x6E5416, dark: 0xD7B15C),   // bistre
                Color(light: 0x3B454C, dark: 0xA3AEB6),   // payne's grey
            ]
        ),
        type: BrandType(display: .serif,
                        displayWidth: .standard,
                        displayWeight: .bold,
                        body: .default),
        corner: 3,
        canvas: .glow(Color(light: 0xB0BAB0, dark: 0x1C2422),
                      at: UnitPoint(x: 0.78, y: 0.06))
    )

    /// The plate is drawn from its own ramp, not from a palette role: copper under one lamp
    /// dims, it does not invert. Every value here was checked against the cut in both modes.
    enum Plate {
        static let faceTop    = Color(light: 0xE0A05E, dark: 0xB4793E)
        static let faceBottom = Color(light: 0xBE7A36, dark: 0xA87643)
        static let bevel      = Color(light: 0x7A4415, dark: 0x40240C)
        static let trough     = Color(light: 0x15191A, dark: 0x0B0705)
        static let lip        = Color(light: 0xFBDCB0, dark: 0xE3B87E)
    }

    /// The burin's own two springs. The bite is metal meeting metal and barely moves; the
    /// point overshoots, because the copper gives before it holds.
    enum Cut {
        static let bite  = Animation.spring(response: 0.09, dampingFraction: 0.95)
        static let point = Animation.spring(response: 0.15, dampingFraction: 0.72)
    }

    /// The crosshatch: two passes, crossed at 32°, fine and close. Crossing at a right angle
    /// can only ever make a mesh — the interstices have to come out lozenge-shaped.
    enum Hatch {
        static let firstPass: Double = 40
        static let secondPass: Double = 72
        static let spacing: CGFloat = 4.4
        static let weight: CGFloat = 1.25
    }
}

// MARK: - The plate caps

extension View {
    /// What is punched into a plate's margin: monospaced small caps, widely tracked, never a
    /// sentence. `PLATE 214 · 17 SEPTEMBER · DEPTH 5`.
    func plateCaps(size: CGFloat = 11) -> some View {
        scaledFont(size: size, weight: .medium, design: .monospaced, relativeTo: .caption2)
            .textCase(.uppercase)
            .tracking(2.4)
    }
}

// MARK: - The shop's canvas

/// The ground tooth and the bed rails: the app's own name drawn into its own background, and
/// the press bed the plate lies on. Seeded from a constant, and it never animates — a moving
/// texture is noise.
struct GroundTooth: View {
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        Canvas { context, size in
            let tone = scheme == .dark ? Color.white.opacity(0.036) : Color(hex: 0x15191A).opacity(0.034)
            hatch(&context, size: size, degrees: 62, tone: tone, whole: true)
            hatch(&context, size: size, degrees: -62, tone: tone, whole: false)
        }
        // Rasterised once and composited after, rather than re-stroked under every beat of
        // the pull.
        .drawingGroup()
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    /// One field of parallel strokes. The second pass covers the lower-left quadrant only, so
    /// that corner is literally crosshatched and sits a shade darker.
    private func hatch(_ context: inout GraphicsContext, size: CGSize, degrees: Double, tone: Color, whole: Bool) {
        // From the middle, half the diagonal reaches every corner at any angle.
        let reach = hypot(size.width, size.height) / 2 + 4
        let radians = degrees * .pi / 180
        let dx = CGFloat(cos(radians)), dy = CGFloat(sin(radians))
        var path = Path()
        var offset: CGFloat = -reach
        while offset < reach {
            let origin = CGPoint(x: size.width / 2 - dy * offset, y: size.height / 2 + dx * offset)
            path.move(to: CGPoint(x: origin.x - dx * reach, y: origin.y - dy * reach))
            path.addLine(to: CGPoint(x: origin.x + dx * reach, y: origin.y + dy * reach))
            offset += 3.5
        }
        var layer = context
        if !whole {
            layer.clip(to: Path(CGRect(x: 0, y: size.height * 0.5, width: size.width * 0.5, height: size.height * 0.5)))
        }
        layer.stroke(path, with: .color(tone), lineWidth: 1)
    }
}

/// The two rails of the press bed, which are the app's horizon and are in every screenshot.
struct BedRails: View {
    @Environment(\.brand) private var brand

    var body: some View {
        VStack(spacing: 0) {
            rail
            Spacer(minLength: 0)
            rail
        }
        .padding(.vertical, 22)
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    private var rail: some View {
        ZStack(alignment: .top) {
            Rectangle()
                .fill(brand.palette.ink.opacity(0.12))
                .frame(height: 2)
            Rectangle()
                .fill(brand.palette.highlight.opacity(0.22))
                .frame(height: 1)
        }
        .frame(height: 2)
    }
}

extension View {
    /// The bench: the brand's north light, the ground tooth over it, and the bed rails. Not
    /// `brandBackground()` with the tooth layered on — that puts the texture *behind* an
    /// opaque canvas — so the three are stacked here in the order an engraver would see them.
    func shopBackground() -> some View {
        scrollContentBackground(.hidden)
            .background {
                ZStack {
                    BrandBackground()
                    GroundTooth().ignoresSafeArea()
                    BedRails().ignoresSafeArea(edges: .horizontal)
                }
            }
    }
}
