import SwiftUI

public enum FactoryTheme {
    public static let cornerRadius: CGFloat = 20
    public static let padding: CGFloat = 20
}

/// A specific point size that still honours Dynamic Type.
///
/// `.font(.system(size: 44))` is frozen: it looks the same to someone who has set the
/// largest accessibility text size as it does at the default, which fails the accessibility
/// bar Apple reviews against. A text style (`.largeTitle`) scales but cannot express "44pt".
/// This does both — the size below is the size at the default setting, and it scales from
/// there in step with `relativeTo`.
///
/// Reach for a plain text style first. Use this only where the design genuinely needs a
/// display size the styles do not cover, such as a hero number or a large glyph.
public struct ScaledFont: ViewModifier {
    @ScaledMetric private var size: CGFloat
    private let weight: Font.Weight
    private let design: Font.Design

    public init(size: CGFloat, weight: Font.Weight = .regular, design: Font.Design = .default, relativeTo style: Font.TextStyle = .largeTitle) {
        _size = ScaledMetric(wrappedValue: size, relativeTo: style)
        self.weight = weight
        self.design = design
    }

    public func body(content: Content) -> some View {
        content.font(.system(size: size, weight: weight, design: design))
    }
}

public extension View {
    /// See ``ScaledFont``. Prefer a semantic text style where one fits.
    func scaledFont(size: CGFloat, weight: Font.Weight = .regular, design: Font.Design = .default, relativeTo style: Font.TextStyle = .largeTitle) -> some View {
        modifier(ScaledFont(size: size, weight: weight, design: design, relativeTo: style))
    }
}

public struct FactoryCard: ViewModifier {
    public func body(content: Content) -> some View {
        content
            .padding(FactoryTheme.padding)
            .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: FactoryTheme.cornerRadius, style: .continuous))
    }
}

public extension View {
    /// Grouped-background card with the kit's radius and padding.
    func factoryCard() -> some View { modifier(FactoryCard()) }
}

public struct PrimaryButtonStyle: ButtonStyle {
    public init() {}
    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(Color.accentColor, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .foregroundStyle(.white)
            .opacity(configuration.isPressed ? 0.85 : 1)
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

public extension ButtonStyle where Self == PrimaryButtonStyle {
    static var factoryPrimary: PrimaryButtonStyle { PrimaryButtonStyle() }
}
