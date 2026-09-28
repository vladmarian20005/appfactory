import FactoryKit
import SwiftUI

/// One place for everything the scaffolder and the spec fill in.
enum AppInfo {
    static let unlockID = "com.starhiveconcept.maze.pro"

    static let config = AppConfig(
        name: "Lacework",
        supportURL: URL(string: "https://starhiveconcept.com/maze-privacy-policy-terms/#support")!,
        privacyURL: URL(string: "https://starhiveconcept.com/maze-privacy-policy-terms/")!,
        termsURL: URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!,
        productIDs: [unlockID],
        appStoreID: nil
    )

    static let onboardingNext = "Go on"
    static let onboardingFinish = "Show me how"

    /// One page, and it says the one thing: there is a lace a day, and it is everyone's.
    /// How to wind it is taught on the pillow itself, with the first card, not in words here.
    static let onboarding: [OnboardingPage] = [
        OnboardingPage(title: "One lace a day",
                       subtitle: "A new pattern every morning, the same one for everybody. Lead one thread through every pin, and it lifts off as lace. Thirty seconds to learn.",
                       artHeight: 360) { OnboardingArt(image: "Pillow") },
    ]

    static let paywallHeadline = "The whole pattern book"
    static let paywallSubhead = "One payment, no subscription. Yours to keep, like the pillow."
    static let paywallBullets = [
        "Every pattern in the book, from five by five to fourteen by fourteen — medallions, windows, loose ends — each proved to have exactly one way through.",
        "Chosen for you: the next pattern is pricked in the ground you find hardest.",
        "Loose work: a fresh pattern whenever you want one, never the same twice.",
        "The ledger: your pieces by size and by ground.",
    ]
    static let paywallPromise = "Today's lace stays free for everyone, every day. No ads, ever."
    static let paywallCTA = "Unlock the whole book"
}

/// Onboarding's art under the masthead: `LACEWORK` in the caps between two hairlines and a
/// pin-head, then the drawing.
struct OnboardingArt: View {
    let image: String
    @Environment(\.brand) private var brand

    var body: some View {
        VStack(spacing: 22) {
            HStack(spacing: 12) {
                Rectangle().fill(brand.palette.ink.opacity(0.25)).frame(height: 0.75)
                Text("Lacework").caps(.caption, tracking: 3)
                PinHead(size: 6)
                Rectangle().fill(brand.palette.ink.opacity(0.25)).frame(height: 0.75)
            }
            .padding(.horizontal, 36)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Lacework")
            Image(image)
                .resizable()
                .scaledToFit()
                .padding(.horizontal, 20)
                .accessibilityHidden(true)
        }
    }
}
