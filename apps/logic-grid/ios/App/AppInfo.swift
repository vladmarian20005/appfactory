import FactoryKit
import SwiftUI

/// Everything the app says, in the master engraver's voice: old, dry, exact, entirely
/// uninterested in how fast you did it and extremely interested in whether you could name a
/// reason for every mark on the plate.
enum AppInfo {
    static let config = AppConfig(
        name: "Crosshatch",
        supportURL: URL(string: "https://starhiveconcept.com/logic-grid-privacy-policy-terms/#support")!,
        privacyURL: URL(string: "https://starhiveconcept.com/logic-grid-privacy-policy-terms/")!,
        termsURL: URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!,
        productIDs: ["com.starhiveconcept.logicgrid.unlock"],
        appStoreID: nil
    )

    // MARK: - Onboarding

    static let onboarding: [OnboardingPage] = [
        OnboardingPage(title: "A plate a day",
                       subtitle: "Copper, ruled into a grid, with a handful of clues under it. One goes on the bed every morning and it is the same plate for everyone.",
                       artHeight: 300) { OnboardingArt(name: "Plate") },
        OnboardingPage(title: "Cut what the clues force",
                       subtitle: "Two strokes across a pairing rules it out. One deep point fixes it — and the plate does the rest of the crossing out itself.",
                       artHeight: 300) { OnboardingArt(name: "Burin") },
        OnboardingPage(title: "A finished plate gets pulled",
                       subtitle: "Inked, wiped and printed on damp paper, and it goes up on the line to dry. Every plate here was proved to have exactly one answer, reachable by reasoning alone, before it was ever ruled.",
                       artHeight: 300) { OnboardingArt(name: "Press") },
    ]

    static let onboardingNext = "Go on"
    static let onboardingFinish = "Take the burin"

    // MARK: - Paywall

    static let paywallHeadline = "The whole run"
    static let paywallSubhead = "Forty plates are ruled and proved for you before the run asks anything."
    static let paywallBullets = [
        "Every plate the generator has proved, past the first forty — up to five categories and six to a side.",
        "Muted ink: the plate in proof grey, and nothing in the margin but the date.",
        "The crossing-out assist, on or off, plate by plate.",
    ]
    static let paywallPromise = "One proved plate every day stays free, and every print you have pulled stays on the line."
    static let paywallCTA = "Unlock every plate"

    // MARK: - The pools

    /// A plate pulled. Twelve of them, so the tenth print does not read like the first.
    static let praise = [
        "Pulled. The line held the whole way through.",
        "Clean off the plate. Nothing on it you could not give a reason for.",
        "That is a print. The margin is honest.",
        "Inked, wiped, printed. Hang it up.",
        "Good bite on that one. It came off whole.",
        "Every point on it was forced, and the plate knows it.",
        "Off the bed and onto the line.",
        "That plate gave up everything it had.",
        "Nothing guessed, nothing smudged.",
        "The press hardly had to work for that.",
        "Cut, and cut properly. The book is a page longer.",
        "There it is, in one pull.",
    ]

    /// A slip: the burin skidding. He talks about the plate, never about you.
    static let nearMiss = [
        "The burin skidded. The clues had not said that yet.",
        "That may well be true. It is not yet proved.",
        "A scratch in the margin. It will print, and that is all.",
        "Not forced — not by anything legible on this plate.",
        "You got there ahead of the evidence.",
        "Right, and early. Copper remembers early.",
        "A guess. A good one, and the plate still shows where.",
        "Off the line. Something on the list says so; it is not four.",
        "Ahead of yourself. Carry on — the plate still pulls.",
    ]

    static let categoryClosed = [
        "That one is settled.",
        "Four figures in the margin now.",
        "Whole. Nothing left in that block.",
        "Closed, and it closed itself.",
        "The block is finished. It bites deeper.",
    ]

    static let sealedOpened = [
        "The acid is through. Six is legible.",
        "Seven has come up. You had run out of forced moves without it.",
        "That one has bitten open. Read it.",
    ]

    /// A line from a pool, chosen by a number the caller already has, so no two consecutive
    /// plates draw the same one and a capture of the same plate draws the same line twice.
    static func line(from pool: [String], seed: Int) -> String {
        pool[abs(seed) % pool.count]
    }
}

/// The masthead the mocks put over every onboarding page: the app's name in the plate caps
/// between two rules and a lozenge, with the drawing under it.
struct OnboardingArt: View {
    let name: String
    @Environment(\.brand) private var brand

    var body: some View {
        VStack(spacing: 18) {
            VStack(spacing: 8) {
                Text("Crosshatch")
                    .plateCaps(size: 12)
                    .foregroundStyle(brand.palette.inkSoft)
                HStack(spacing: 10) {
                    rule
                    Lozenge()
                        .fill(brand.palette.highlight)
                        .frame(width: 15, height: 9)
                    rule
                }
                .frame(width: 150)
            }
            Image(name)
                .resizable()
                .scaledToFit()
        }
    }

    private var rule: some View {
        Rectangle()
            .fill(brand.palette.inkSoft.opacity(0.5))
            .frame(height: 1)
    }
}
