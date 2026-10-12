import FactoryKit
import SwiftUI

/// One place for everything the scaffolder and the spec fill in.
enum AppInfo {
    static let unlockID = "com.starhiveconcept.solitaire.unlock"

    static let config = AppConfig(
        name: "Baize",
        supportURL: URL(string: "https://starhiveconcept.com/solitaire-privacy-policy-terms/#support")!,
        privacyURL: URL(string: "https://starhiveconcept.com/solitaire-privacy-policy-terms/")!,
        termsURL: URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!,
        productIDs: [unlockID],
        appStoreID: nil
    )

    static let onboardingNext = "Turn over"
    static let onboardingFinish = "Lay the table"

    static let onboarding: [OnboardingPage] = [
        OnboardingPage(title: "One deal a day",
                       subtitle: "Laid on the baize every morning — the same cards for everyone who sits down to it.",
                       artHeight: 380) { OnboardingArt(image: "Desk") },
        OnboardingPage(title: "Every deal comes out",
                       subtitle: "Each one was played through before it was dealt, and its number is on the table so you can see which it was.",
                       artHeight: 380) { OnboardingArt(image: "Fans") },
        OnboardingPage(title: "The diary keeps it",
                       subtitle: "A day that comes out is written in as the card you had to dig for. Clean, under the mark, or just out — it all goes down.",
                       artHeight: 380) { OnboardingArt(image: "Diary") },
    ]

    static let paywallHeadline = "The drawer"
    static let paywallSubhead = "One payment. The desk is yours."
    static let paywallBullets = [
        "Six card backs and four cloths drawn for this table — blue, claret, moss and slate. Green is in there, since you asked.",
        "The left-handed table: stock and waste on the left, foundations on the right.",
        "Every past day's deal, to lay again, and the whole count — by draw, by grade, and by what each deal asked of you.",
    ]
    static let paywallPromise = "Today's deal stays free, every day, and every entry you have written stays in the diary."
    static let paywallCTA = "Open the drawer"
}

/// Onboarding's art under the masthead: `BAIZE` in the caps between two hairlines and a
/// small card, then the drawing.
struct OnboardingArt: View {
    let image: String
    @Environment(\.brand) private var brand

    var body: some View {
        VStack(spacing: 28) {
            HStack(spacing: 12) {
                Rectangle().fill(brand.palette.ink.opacity(0.25)).frame(height: 0.75)
                Text("Baize").font(.caption.weight(.medium)).textCase(.uppercase).tracking(3)
                    .foregroundStyle(brand.palette.inkSoft)
                RoundedRectangle(cornerRadius: 1.5).fill(brand.palette.ink).frame(width: 9, height: 13)
                Rectangle().fill(brand.palette.ink.opacity(0.25)).frame(height: 0.75)
            }
            .padding(.horizontal, 36)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Baize")
            Image(image)
                .resizable()
                .scaledToFit()
                .padding(.horizontal, 16)
                .accessibilityHidden(true)
        }
    }
}
