import SwiftUI

public struct OnboardingPage: Identifiable, @unchecked Sendable {
    public let id = UUID()
    public let symbol: String
    public let title: String
    public let subtitle: String
    let art: (() -> AnyView)?

    /// A page led by an SF Symbol. Thin for a first impression; prefer `init(title:subtitle:art:)`
    /// with something drawn for this app.
    public init(symbol: String, title: String, subtitle: String) {
        self.symbol = symbol
        self.title = title
        self.subtitle = subtitle
        self.art = nil
    }

    /// A page led by the app's own art — shapes, gradients, a Canvas, a piece of the idea.
    /// It gets about 280 points of height and floats gently while the page is showing.
    public init<Art: View>(title: String, subtitle: String, @ViewBuilder art: @escaping () -> Art) {
        self.symbol = ""
        self.title = title
        self.subtitle = subtitle
        self.art = { AnyView(art()) }
    }
}

/// Paged onboarding on the brand's canvas. Persist completion with
/// `@AppStorage("factory.onboarded")` in the app.
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
                    OnboardingPageView(page: page, isCurrent: i == index)
                        .tag(i)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .always))
            .indexViewStyle(.page(backgroundDisplayMode: .always))

            Button {
                if index < pages.count - 1 {
                    Haptics.tap()
                    withMotion(Motion.gentle) { index += 1 }
                } else {
                    Haptics.success()
                    onFinish()
                }
            } label: {
                Text(index == pages.count - 1 ? "Get started" : "Continue")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 4)
            }
            .brandProminent()
            .padding(.horizontal, FactoryTheme.padding)
            .padding(.bottom, 24)
        }
        .brandBackground(drift: true)
    }
}

private struct OnboardingPageView: View {
    let page: OnboardingPage
    let isCurrent: Bool
    @Environment(\.brand) private var brand

    private var shown: Bool { isCurrent || Motion.isStill }

    var body: some View {
        VStack(spacing: 28) {
            Spacer(minLength: 12)
            hero
                .frame(maxWidth: .infinity, maxHeight: 280)
                .dynamicTypeSize(...DynamicTypeSize.accessibility1)
                .scaleEffect(shown ? 1 : 0.9)
                .layoutPriority(-1)
            VStack(spacing: 12) {
                Text(page.title)
                    .brandFont(.largeTitle)
                    .foregroundStyle(brand.palette.ink)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                Text(page.subtitle)
                    .font(.title3)
                    .foregroundStyle(brand.palette.inkSoft)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal, 28)
            .opacity(shown ? 1 : 0)
            .offset(y: shown ? 0 : 18)
            Spacer(minLength: 12)
            Spacer(minLength: 12)
        }
        .animation(Motion.resolved(Motion.gentle), value: isCurrent)
    }

    @ViewBuilder
    private var hero: some View {
        if let art = page.art {
            art().ambientFloat(amplitude: 5, period: 4)
        } else {
            Image(systemName: page.symbol)
                .scaledFont(size: 96, weight: .semibold)
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(brand.palette.accent)
                .symbolEffect(.bounce, value: isCurrent)
                .ambientFloat(amplitude: 5, period: 4)
        }
    }
}
