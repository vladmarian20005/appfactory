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
    static let onboardingFinish = "Pick up the bobbin"

    static let onboarding: [OnboardingPage] = [
        OnboardingPage(title: "A pattern a day",
                       subtitle: "Pricked into a card and pinned to the pillow every morning — the same one for everyone who opens it.",
                       artHeight: 360) { OnboardingArt(image: "Pillow") },
        OnboardingPage(title: "One thread, every pin",
                       subtitle: "Wind it from pin to pin until none is left bare. It never crosses itself, and it never has to.",
                       artHeight: 360) { OnboardingArt(image: "Bobbins") },
        OnboardingPage(title: "Then the lace comes off",
                       subtitle: "Pull the pins and the piece lifts free, into your sampler. Every pattern here was proved to have exactly one way through before it was pricked.",
                       artHeight: 360) { OnboardingArt(image: "Lace") },
    ]

    static let paywallHeadline = "The whole pattern book"
    static let paywallSubhead = "One payment. It is yours, like the pillow."
    static let paywallBullets = [
        "Every pattern past the sixtieth — up to fourteen pins a side, medallions and windows, each proved to have one way through.",
        "Loose work: a fresh pattern whenever you want one, as hard as the book is now, and never the same one twice.",
        "The ledger: your pieces by size and by ground.",
    ]
    static let paywallPromise = "Today's pattern stays free, every day, and every piece you have worked stays in the sampler."
    static let paywallCTA = "Open the pattern book"
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
