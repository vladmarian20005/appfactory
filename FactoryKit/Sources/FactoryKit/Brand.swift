import SwiftUI
import UIKit

/// An app's visual identity — palette, type, shape and canvas — set once at the root with
/// `.brand(_:)` and read by everything below it, FactoryKit's own views included.
///
/// The kit's first theme was a corner radius over the system's grouped grays, and the first
/// two apps built on it looked like the Settings app with a feature bolted on. This is the
/// opposite default: the app states what it looks like, once, from DESIGN.md's tokens, and
/// the kit follows. System controls keep their own look — and their Liquid Glass — by taking
/// the brand's tint rather than being redrawn.
public struct Brand: @unchecked Sendable {
    public var palette: BrandPalette
    public var type: BrandType
    /// Radius of the brand's surfaces. Corners are continuous throughout.
    public var corner: CGFloat
    public var canvas: BrandCanvas

    public init(palette: BrandPalette,
                type: BrandType = BrandType(),
                corner: CGFloat = 22,
                canvas: BrandCanvas = .solid) {
        self.palette = palette
        self.type = type
        self.corner = corner
        self.canvas = canvas
    }

    /// The system look the kit started with: grouped gray, white cards, the asset catalog's
    /// accent. It is what an app has before it has a brand, so existing apps look exactly as
    /// they did — and `tools/design/tells.mjs` fails any app that ships with it.
    public static let factoryDefault = Brand(
        palette: BrandPalette(
            canvas: Color(.systemGroupedBackground),
            surface: Color(.secondarySystemGroupedBackground),
            ink: .primary,
            inkSoft: .secondary,
            accent: .accentColor,
            onAccent: .white,
            highlight: .orange,
            success: .green,
            miss: .red
        ),
        corner: FactoryTheme.cornerRadius
    )
}

/// Named colors with jobs. Give each one a light and a dark value (`Color(light:dark:)`):
/// dark mode is designed, not inverted.
public struct BrandPalette: @unchecked Sendable {
    /// Behind everything. Never the system's grouped gray.
    public var canvas: Color
    /// Content sitting on the canvas: cards, tiles, boards.
    public var surface: Color
    /// Primary text and glyphs.
    public var ink: Color
    /// Secondary text.
    public var inkSoft: Color
    /// The signature color: primary actions, selection, progress.
    public var accent: Color
    /// Text and glyphs on top of `accent`.
    public var onAccent: Color
    /// The second voice: streaks, rewards, the thing that should feel special.
    public var highlight: Color
    public var success: Color
    /// A wrong answer or a failed move. Forgiving, not an alarm.
    public var miss: Color
    /// Whatever else the content needs: game pieces, categories, chart series.
    public var extras: [Color]

    public init(canvas: Color, surface: Color, ink: Color, inkSoft: Color,
                accent: Color, onAccent: Color, highlight: Color,
                success: Color, miss: Color, extras: [Color] = []) {
        self.canvas = canvas
        self.surface = surface
        self.ink = ink
        self.inkSoft = inkSoft
        self.accent = accent
        self.onAccent = onAccent
        self.highlight = highlight
        self.success = success
        self.miss = miss
        self.extras = extras
    }
}

/// The display face is where an app's type gets its character: SF Rounded, SF Expanded,
/// New York (`.serif`), SF Mono for numbers. Body text stays readable.
public struct BrandType: @unchecked Sendable {
    public var display: Font.Design
    public var displayWidth: Font.Width
    public var displayWeight: Font.Weight
    public var body: Font.Design

    public init(display: Font.Design = .default,
                displayWidth: Font.Width = .standard,
                displayWeight: Font.Weight = .bold,
                body: Font.Design = .default) {
        self.display = display
        self.displayWidth = displayWidth
        self.displayWeight = displayWeight
        self.body = body
    }
}

/// What sits behind the content, edge to edge.
public enum BrandCanvas: @unchecked Sendable {
    /// The palette's canvas color, flat.
    case solid
    /// Top to bottom between two colors.
    case wash(Color, Color)
    /// The canvas color with a soft glow of `color` around `at`.
    case glow(Color, at: UnitPoint)
    /// A 3×3 mesh of nine colors on iOS 18 and later; a diagonal wash of the first and last
    /// before that.
    case mesh([Color])
}

private struct BrandKey: EnvironmentKey {
    static let defaultValue = Brand.factoryDefault
}

public extension EnvironmentValues {
    var brand: Brand {
        get { self[BrandKey.self] }
        set { self[BrandKey.self] = newValue }
    }
}

public extension View {
    /// Sets the app's brand for everything below: the kit's views, `brand*` modifiers, and the
    /// tint every system control takes. Apply once, at the root, to onboarding and the main UI.
    func brand(_ brand: Brand) -> some View {
        environment(\.brand, brand)
            .tint(brand.palette.accent)
            .fontDesign(brand.type.body)
    }
}

// MARK: - Color

public extension Color {
    /// `Color(hex: 0x1B2A4A)`. Transparency through `.opacity(_:)`.
    init(hex: UInt32) {
        self.init(.sRGB,
                  red: Double((hex >> 16) & 0xFF) / 255,
                  green: Double((hex >> 8) & 0xFF) / 255,
                  blue: Double(hex & 0xFF) / 255,
                  opacity: 1)
    }

    /// One value in light mode and another in dark, as hex.
    init(light: UInt32, dark: UInt32) {
        self.init(uiColor: UIColor { traits in
            UIColor(Color(hex: traits.userInterfaceStyle == .dark ? dark : light))
        })
    }

    /// One color in light mode and another in dark.
    init(light: Color, dark: Color) {
        self.init(uiColor: UIColor { traits in
            UIColor(traits.userInterfaceStyle == .dark ? dark : light)
        })
    }
}

// MARK: - Canvas

/// The brand's canvas as a view. Most screens want `.brandBackground()` instead.
public struct BrandBackground: View {
    @Environment(\.brand) private var brand
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    private let drift: Bool

    /// - Parameter drift: let a mesh canvas move, very slowly. Stands still for Reduce Motion
    ///   and for the capture tooling.
    public init(drift: Bool = false) {
        self.drift = drift
    }

    public var body: some View {
        Group {
            switch brand.canvas {
            case .solid:
                brand.palette.canvas
            case let .wash(top, bottom):
                LinearGradient(colors: [top, bottom], startPoint: .top, endPoint: .bottom)
            case let .glow(color, at):
                GeometryReader { geo in
                    brand.palette.canvas
                        .overlay {
                            RadialGradient(colors: [color, color.opacity(0)],
                                           center: at,
                                           startRadius: 0,
                                           endRadius: max(geo.size.width, geo.size.height) * 0.75)
                        }
                }
            case let .mesh(colors):
                MeshCanvas(colors: colors, drift: drift && !reduceMotion)
            }
        }
        .ignoresSafeArea()
        .accessibilityHidden(true)
    }
}

private struct MeshCanvas: View {
    let colors: [Color]
    let drift: Bool

    var body: some View {
        if #available(iOS 18.0, *), colors.count >= 9 {
            TimelineView(.animation(minimumInterval: 1.0 / 30, paused: !drift || Motion.isStill)) { context in
                let t = drift && !Motion.isStill ? context.date.timeIntervalSinceReferenceDate : 0
                MeshGradient(width: 3, height: 3, points: points(at: t), colors: Array(colors.prefix(9)))
            }
        } else {
            LinearGradient(colors: [colors.first ?? .clear, colors.last ?? .clear],
                           startPoint: .topLeading, endPoint: .bottomTrailing)
        }
    }

    /// Only the inner points move, and only a little: a canvas that visibly swims is a
    /// distraction, one that breathes is alive.
    private func points(at t: Double) -> [SIMD2<Float>] {
        let a = Float(sin(t * 0.31)) * 0.07
        let b = Float(cos(t * 0.23)) * 0.07
        return [
            [0, 0], [0.5, 0], [1, 0],
            [0, 0.5 + a], [0.5 + b, 0.5 - a], [1, 0.5 - b],
            [0, 1], [0.5, 1], [1, 1],
        ]
    }
}

public extension View {
    /// The brand's canvas behind the view, edge to edge and under the bars. Also hides the
    /// system gray of any `List` or `Form` inside, which would otherwise cover it. Use this
    /// wherever the first apps used `Color(.systemGroupedBackground)`.
    func brandBackground(drift: Bool = false) -> some View {
        scrollContentBackground(.hidden)
            .background { BrandBackground(drift: drift) }
    }

    /// A content surface in the brand's color and radius: cards, tiles, panels.
    func brandSurface(padding: CGFloat = FactoryTheme.padding) -> some View {
        modifier(BrandSurface(padding: padding))
    }

    /// A text style in the brand's display face. Scales with Dynamic Type like any text style.
    func brandFont(_ style: Font.TextStyle, weight: Font.Weight? = nil) -> some View {
        modifier(BrandFont(style: style, weight: weight))
    }

    /// The brand's display face at a size no text style reaches — hero numbers, big headlines —
    /// that still scales with Dynamic Type. `size` is the size at the default text setting.
    func brandDisplay(size: CGFloat, relativeTo style: Font.TextStyle = .largeTitle) -> some View {
        modifier(BrandDisplay(size: size, style: style))
    }

    /// The brand's primary action: the system's prominent button in the brand's accent, as a
    /// capsule. A system style, not a drawn one, so the iOS 26 SDK gives it Liquid Glass. Put
    /// `.frame(maxWidth: .infinity)` on the label for a full-width button.
    func brandProminent() -> some View {
        modifier(BrandProminent())
    }
}

private struct BrandSurface: ViewModifier {
    @Environment(\.brand) private var brand
    @Environment(\.colorScheme) private var scheme
    let padding: CGFloat

    func body(content: Content) -> some View {
        let shape = RoundedRectangle(cornerRadius: brand.corner, style: .continuous)
        content
            .padding(padding)
            .background {
                shape
                    .fill(brand.palette.surface)
                    .shadow(color: .black.opacity(scheme == .dark ? 0 : 0.07), radius: 14, x: 0, y: 6)
            }
            .overlay {
                // A shadow disappears on a dark canvas; a hairline keeps the edge.
                if scheme == .dark {
                    shape.strokeBorder(.white.opacity(0.08), lineWidth: 1)
                }
            }
    }
}

private struct BrandFont: ViewModifier {
    @Environment(\.brand) private var brand
    let style: Font.TextStyle
    let weight: Font.Weight?

    func body(content: Content) -> some View {
        content.font(.system(style, design: brand.type.display, weight: weight ?? brand.type.displayWeight)
            .width(brand.type.displayWidth))
    }
}

private struct BrandDisplay: ViewModifier {
    @Environment(\.brand) private var brand
    @ScaledMetric private var size: CGFloat

    init(size: CGFloat, style: Font.TextStyle) {
        _size = ScaledMetric(wrappedValue: size, relativeTo: style)
    }

    func body(content: Content) -> some View {
        content.font(.system(size: size, weight: brand.type.displayWeight, design: brand.type.display)
            .width(brand.type.displayWidth))
    }
}

private struct BrandProminent: ViewModifier {
    @Environment(\.brand) private var brand

    @ViewBuilder
    func body(content: Content) -> some View {
        #if compiler(>=6.2)
        if #available(iOS 26.0, *) {
            content
                .buttonStyle(.glassProminent)
                .buttonBorderShape(.capsule)
                .controlSize(.large)
                .tint(brand.palette.accent)
                .foregroundStyle(brand.palette.onAccent)
        } else {
            prominent(content)
        }
        #else
        prominent(content)
        #endif
    }

    private func prominent(_ content: Content) -> some View {
        content
            .buttonStyle(.borderedProminent)
            .buttonBorderShape(.capsule)
            .controlSize(.large)
            .tint(brand.palette.accent)
            .foregroundStyle(brand.palette.onAccent)
    }
}
