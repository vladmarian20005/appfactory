import SwiftUI

public enum FactoryTheme {
    public static let cornerRadius: CGFloat = 20
    public static let padding: CGFloat = 20
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
