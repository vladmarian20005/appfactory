import SwiftUI

public struct OnboardingPage: Identifiable, Sendable {
    public let id = UUID()
    public let symbol: String
    public let title: String
    public let subtitle: String
    public init(symbol: String, title: String, subtitle: String) {
        self.symbol = symbol
        self.title = title
        self.subtitle = subtitle
    }
}

/// Paged onboarding. Persist completion with `@AppStorage("factory.onboarded")` in the app.
public struct OnboardingView: View {
    let pages: [OnboardingPage]
    let onFinish: () -> Void
    @State private var index = 0

    public init(pages: [OnboardingPage], onFinish: @escaping () -> Void) {
        self.pages = pages
        self.onFinish = onFinish
    }

    public var body: some View {
        VStack(spacing: 0) {
            TabView(selection: $index) {
                ForEach(Array(pages.enumerated()), id: \.element.id) { i, page in
                    VStack(spacing: 24) {
                        Spacer()
                        Image(systemName: page.symbol)
                            .scaledFont(size: 88, weight: .medium)
                            .foregroundStyle(Color.accentColor)
                            .symbolRenderingMode(.hierarchical)
                        Text(page.title)
                            .font(.largeTitle.bold())
                            .multilineTextAlignment(.center)
                        Text(page.subtitle)
                            .font(.title3)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 28)
                        Spacer()
                        Spacer()
                    }
                    .tag(i)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .always))
            .indexViewStyle(.page(backgroundDisplayMode: .always))

            Button(index == pages.count - 1 ? "Get started" : "Continue") {
                Haptics.tap()
                if index < pages.count - 1 {
                    withAnimation { index += 1 }
                } else {
                    onFinish()
                }
            }
            .buttonStyle(.factoryPrimary)
            .padding(.horizontal, FactoryTheme.padding)
            .padding(.bottom, 24)
        }
        .background(Color(.systemBackground))
    }
}
