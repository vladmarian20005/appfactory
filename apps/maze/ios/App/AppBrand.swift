import FactoryKit
import SwiftUI

enum AppBrand {
    static let brand = Brand(
        palette: BrandPalette(
            canvas: Color(light: 0xE8E0CF, dark: 0x1A1C24),
            surface: Color(light: 0xF8F3E7, dark: 0x2A2C35),
            ink: Color(light: 0x2A2521, dark: 0xF2ECDF),
            inkSoft: Color(light: 0x655B52, dark: 0xB3AB9C),
            accent: Color(light: 0x31497A, dark: 0x91A9E3),
            onAccent: Color(light: 0xF8F3E7, dark: 0x0E1526),
            highlight: Color(light: 0xA8413A, dark: 0xF0917F),
            success: Color(light: 0x4A7457, dark: 0x8EC59B),
            miss: Color(light: 0x7A6748, dark: 0xBFAE8C),
            extras: [
                Color(light: 0x6F7B88, dark: 0xA2ADBA),   // steel — pins
                Color(light: 0x9C7A2E, dark: 0xE0BB62),   // brass — the start pin, the corner pins
                Color(light: 0xC4586A, dark: 0xEC93A6),   // rose silk — the second thread
                Color(light: 0xA8842E, dark: 0xDCB85A),   // gold thread — the third, and the picots
                Color(light: 0x7A4E2E, dark: 0xB07A52),   // walnut — the bobbin
            ]
        ),
        type: BrandType(display: .serif,
                        displayWidth: .standard,
                        displayWeight: .medium,
                        body: .default),
        corner: 10,
        canvas: .glow(Color(light: 0xF6F0E3, dark: 0x2C2A30),
                      at: UnitPoint(x: 0.22, y: 0.06))
    )

    /// The workbox by name, so no view indexes `extras` by number.
    enum Workbox {
        static let steel  = brand.palette.extras[0]
        static let brass  = brand.palette.extras[1]
        static let rose   = brand.palette.extras[2]
        static let gold   = brand.palette.extras[3]
        static let walnut = brand.palette.extras[4]
    }

    /// The pillow is drawn, not a surface: the linen darkened a shade, with a highlight
    /// along its top edge. Both values were checked against the thread in both modes.
    enum Pillow {
        static let cloth     = Color(light: 0xDDD4C0, dark: 0x22252F)
        static let highlight = Color(light: 0xF4EDDD, dark: 0x343846)
        static let gimp      = Color(light: 0x2A2521, dark: 0xF2ECDF)   // drawn at 0.7 opacity
    }
}

/// The thread reaching a pin, and retracting.
enum Lace {
    static let wind = Animation.spring(response: 0.12, dampingFraction: 0.9)
}

extension ThreadColour {
    var color: Color {
        switch self {
        case .indigo: AppBrand.brand.palette.accent
        case .rose: AppBrand.Workbox.rose
        case .gold: AppBrand.Workbox.gold
        }
    }

    /// The plait's second strand: the thread lightened.
    var twist: Color {
        switch self {
        case .indigo: Color(light: 0x8FA5D6, dark: 0xC8D4F2)
        case .rose: Color(light: 0xE8A3AF, dark: 0xF7C9D2)
        case .gold: Color(light: 0xE0C47E, dark: 0xF0DDA3)
        }
    }

    var name: String {
        switch self {
        case .indigo: "Indigo"
        case .rose: "Rose silk"
        case .gold: "Gold"
        }
    }
}

// MARK: - The caps

extension View {
    /// The third voice: the small letters cross-stitched along the hem of a sampler.
    func caps(_ style: Font.TextStyle = .caption2, tracking: CGFloat = 2) -> some View {
        modifier(Caps(style: style, tracking: tracking))
    }
}

private struct Caps: ViewModifier {
    @Environment(\.brand) private var brand
    let style: Font.TextStyle
    let tracking: CGFloat

    func body(content: Content) -> some View {
        content
            .font(.system(style, weight: .medium))
            .textCase(.uppercase)
            .tracking(tracking)
            .foregroundStyle(brand.palette.inkSoft)
    }
}

// MARK: - The linen

/// The canvas with its weave: two fields of hairlines at 0° and 90° on a 2.6 pt pitch, drawn
/// once and never animated. It is linen. With the ticking cover earned and chosen, 9 pt bands
/// of indigo every 34 pt, vertical.
struct Linen: View {
    var ticking = false
    @Environment(\.colorScheme) private var scheme
    @Environment(\.brand) private var brand

    var body: some View {
        ZStack {
            BrandBackground()
            Canvas { gc, size in
                let line = scheme == .dark ? Color.white.opacity(0.03) : brand.palette.ink.opacity(0.035)
                var weave = Path()
                // A fixed jitter, so it reads as cloth rather than graph paper, and every
                // launch and every screenshot draws the same cloth.
                var state: UInt64 = 0x1ACE_0F11
                func jitter() -> CGFloat {
                    state = state &* 6364136223846793005 &+ 1442695040888963407
                    return CGFloat((state >> 33) % 100) / 100 * 0.6 - 0.3
                }
                var x: CGFloat = 0
                while x < size.width {
                    let dx = x + jitter()
                    weave.move(to: CGPoint(x: dx, y: 0))
                    weave.addLine(to: CGPoint(x: dx, y: size.height))
                    x += 2.6
                }
                var y: CGFloat = 0
                while y < size.height {
                    let dy = y + jitter()
                    weave.move(to: CGPoint(x: 0, y: dy))
                    weave.addLine(to: CGPoint(x: size.width, y: dy))
                    y += 2.6
                }
                gc.stroke(weave, with: .color(line), lineWidth: 0.75)
                if ticking {
                    var bx: CGFloat = 12
                    while bx < size.width {
                        gc.fill(Path(CGRect(x: bx, y: 0, width: 9, height: size.height)),
                                with: .color(brand.palette.accent.opacity(0.10)))
                        bx += 34
                    }
                }
            }
            .ignoresSafeArea()
        }
        .ignoresSafeArea()
        .accessibilityHidden(true)
    }
}

extension View {
    /// The brand's canvas with the linen's weave over it, under the bars.
    func linen(ticking: Bool = false) -> some View {
        scrollContentBackground(.hidden)
            .background { Linen(ticking: ticking) }
    }
}

// MARK: - The pin

/// The one distinctive shape: a round steel head with a highlight at its upper left and a
/// shadow below and to the right. Every cell's marker, the day's mark on the month card, the
/// selection mark and the section divider.
struct PinHead: View {
    var color: Color = AppBrand.Workbox.steel
    var size: CGFloat = 7

    var body: some View {
        ZStack {
            Circle()
                .fill(Color.black.opacity(0.22))
                .offset(x: size * 0.14, y: size * 0.18)
            Circle().fill(color)
            Circle()
                .fill(Color.white.opacity(0.7))
                .frame(width: size * 0.3, height: size * 0.3)
                .offset(x: -size * 0.18, y: -size * 0.18)
        }
        .frame(width: size, height: size)
        .accessibilityHidden(true)
    }
}

/// Three pin-heads in a row, as a section divider.
struct PinRule: View {
    @Environment(\.brand) private var brand
    var body: some View {
        HStack(spacing: 10) {
            Rectangle().fill(brand.palette.ink.opacity(0.18)).frame(height: 0.75)
            PinHead(size: 5)
            PinHead(color: AppBrand.Workbox.brass, size: 6)
            PinHead(size: 5)
            Rectangle().fill(brand.palette.ink.opacity(0.18)).frame(height: 0.75)
        }
        .accessibilityHidden(true)
    }
}
