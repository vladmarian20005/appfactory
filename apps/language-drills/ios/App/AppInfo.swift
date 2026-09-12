import FactoryKit
import Foundation
import SwiftUI

/// One place for everything the scaffolder and the spec fill in.
enum AppInfo {
    /// One non-consumable unlock, not a subscription: SPEC.md's monetisation is a single
    /// $9.99 payment, so there is no weekly/yearly pair here and nothing that renews.
    static let unlockID = "com.starhiveconcept.thousand.unlock"

    static let config = AppConfig(
        name: "Thousand",
        supportURL: URL(string: "https://starhiveconcept.com/language-drills-privacy-policy-terms/#support")!,
        privacyURL: URL(string: "https://starhiveconcept.com/language-drills-privacy-policy-terms/")!,
        termsURL: URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!,
        productIDs: [unlockID],
        appStoreID: nil
    )

    /// Three pages in the setter's voice, each led by a drawing of the workshop. Page 3 is the
    /// one place in the product, other than the paywall, that states the deal.
    static let onboarding: [OnboardingPage] = [
        OnboardingPage(
            title: "A thousand words, one wall.",
            subtitle: "The words you actually meet, in the order you meet them."
        ) {
            Image("WallAtNoon").resizable().scaledToFit()
        },
        OnboardingPage(
            title: "Turn it over. Say how it went.",
            subtitle: "Each tile comes back exactly when it is about to slip."
        ) {
            Image("TheBench").resizable().scaledToFit()
        },
        OnboardingPage(
            title: "Bought once, kept for good.",
            subtitle: "The whole wall lives on this phone. No subscription, nothing to renew."
        ) {
            Image("KeptWall").resizable().scaledToFit()
        },
    ]

    static let paywallHeadline = "The whole wall."
    static let paywallSubhead = "Ten of the twelve panels are still under the dust sheet."
    static let paywallBullets = [
        "All 1,000 words, every one of the twelve panels.",
        "Works in a tunnel, on a plane, with the phone in a bag.",
        "One payment. No subscription, ever.",
    ]
    static let paywallPromise = "One payment opens the whole thousand, on this phone, offline, for good."

    /// Words openable without the unlock: the first 100 by frequency rank, and the two panels
    /// they mostly live in.
    static let freeWordCount = 100
    static let freeThemeCount = 2
}
