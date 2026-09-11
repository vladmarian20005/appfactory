import FactoryKit
import Foundation

/// One place for everything the scaffolder and the spec fill in.
enum AppInfo {
    /// One non-consumable unlock, not a subscription: the spec's monetisation is "play free
    /// forever or pay once", so there is no weekly/yearly pair here and no renewal to disclose.
    static let unlockID = "com.starhiveconcept.colorsort.unlock"

    static let config = AppConfig(
        name: "Tidepour",
        supportURL: URL(string: "https://starhiveconcept.com/color-sort-privacy-policy-terms/#support")!,
        privacyURL: URL(string: "https://starhiveconcept.com/color-sort-privacy-policy-terms/")!,
        termsURL: URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!,
        productIDs: [unlockID],
        appStoreID: nil
    )

    static let onboarding: [OnboardingPage] = [
        OnboardingPage(
            symbol: "drop.fill",
            title: "Pour until the colors separate",
            subtitle: "Tap a tube, tap where it should go. One color per tube and the level is done — a five-minute break, not a slot machine."
        ),
        OnboardingPage(
            symbol: "checkmark.seal.fill",
            title: "Every level has a solution",
            subtitle: "Tidepour solves each board before it hands it to you. If it cannot be won it is thrown away, and the hint replays the solution one move at a time."
        ),
        OnboardingPage(
            symbol: "hand.raised.fill",
            title: "No ads. Nothing runs out.",
            subtitle: "No interstitials, no coins, no lives, no timer. Play offline for as long as you like and the app never asks you to wait."
        ),
    ]

    static let paywallHeadline = "Unlock Tidepour"
    static let paywallBullets = [
        "The full generated ladder, past level 60",
        "Calm mode: no move counter, muted colors, slower pours",
        "Color-blind palettes with a shape on every unit",
        "One payment. No subscription, no coins, no ads.",
    ]
    static let paywallPromise = "The daily puzzle, the first 60 levels, your streak, undo, restart and hints stay free forever. This buys more puzzle, never access."

    /// Levels playable without the unlock. The daily puzzle is outside this and always free.
    static let freeLevelCount = 60
}
