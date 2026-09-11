import FactoryKit
import SwiftUI

/// Tidepour's look, straight from DESIGN.md's Tokens block: a tide pool at dusk — deep water,
/// glass, and light. Light mode is dusk in the shallows, dark mode is the same pool three hours
/// later. Two different underwater blues, never one blue and its inverse.
enum AppBrand {
    static let brand = Brand(
        palette: BrandPalette(
            canvas:    Color(light: 0x0F3340, dark: 0x04161F),
            surface:   Color(light: 0x16414F, dark: 0x0A2632),
            ink:       Color(light: 0xE9F6F2, dark: 0xD6EEEA),
            inkSoft:   Color(light: 0x9DBAC0, dark: 0x7F9FA8),
            accent:    Color(light: 0x4FE3D2, dark: 0x5FEBDA),
            onAccent:  Color(light: 0x04262A, dark: 0x021C20),
            highlight: Color(light: 0xFFB661, dark: 0xF3A748),
            success:   Color(light: 0x5FD8A9, dark: 0x4FC79A),
            miss:      Color(light: 0xFF8A57, dark: 0xE87A4C),
            extras: [
                Color(light: 0xFF8A57, dark: 0xF07C4C),   // ember
                Color(light: 0x5CB2F0, dark: 0x4C9EDC),   // tide
                Color(light: 0xFFD265, dark: 0xEFC055),   // lantern
                Color(light: 0x5FD8A9, dark: 0x4FC79A),   // kelp
                Color(light: 0xB69AF5, dark: 0xA286E6),   // dusk
                Color(light: 0xFF93AC, dark: 0xEC819B),   // coral
                Color(light: 0xEADCC0, dark: 0xD6C7A9),   // pearl
                Color(light: 0x6E82E4, dark: 0x6070D4),   // abyss
            ]
        ),
        type: BrandType(display: .serif,
                        displayWidth: .standard,
                        displayWeight: .bold,
                        body: .default),
        corner: 18,
        // Dusk sky along the top, cold water through the middle, a lantern-warm pool glow at
        // the bottom. Nine points, drifting slowly, still for a capture and for Reduce Motion.
        canvas: .mesh([
            Color(light: 0x14394A, dark: 0x061C27),
            Color(light: 0x123745, dark: 0x051923),
            Color(light: 0x16404E, dark: 0x071F2B),
            Color(light: 0x0E3340, dark: 0x04161F),
            Color(light: 0x114150, dark: 0x062330),
            Color(light: 0x0D303D, dark: 0x03131C),
            Color(light: 0x0B2C38, dark: 0x03121A),
            Color(light: 0x1A4A4A, dark: 0x0A2A2E),
            Color(light: 0x0A2A35, dark: 0x021017),
        ])
    )

    /// The chart marks on the flat: small, tracked, uppercase. `POURED`, `THE LINE · 13`.
    static func chartLabel(_ size: CGFloat = 11) -> Font {
        .system(size: size, weight: .semibold)
    }
}

/// A small tracked uppercase label — the chart marks drawn on the flat. Scales with Dynamic
/// Type through `scaledFont`, so it never freezes at 11 points.
struct ChartMark: View {
    let text: String
    var color: Color?

    @Environment(\.brand) private var brand

    var body: some View {
        Text(text.uppercased())
            .scaledFont(size: 11, weight: .semibold, relativeTo: .caption2)
            .tracking(1.6)
            .foregroundStyle(color ?? brand.palette.inkSoft)
            .lineLimit(1)
            .minimumScaleFactor(0.7)
    }
}
