import FactoryKit
import Foundation
import SwiftUI

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

    /// Two pages, each led by a drawing of the shore rather than an SF Symbol, and neither of
    /// them the pitch — the paywall's promise line is the one place that states the deal.
    static let onboarding: [OnboardingPage] = [
        OnboardingPage(
            title: "Every light wants its own glass.",
            subtitle: "Decant one glow into another until every vial on the flat holds a single colour."
        ) {
            Image("RackAtDusk").resizable().scaledToFit()
        },
        OnboardingPage(
            title: "The way out is already drawn.",
            subtitle: "Every rack is walked before it is handed to you. Ask, and the charted line lights up on the glass."
        ) {
            Image("ChartedLine").resizable().scaledToFit()
        },
    ]

    static let paywallHeadline = "Unlock Tidepour"
    static let paywallBullets = [
        "The whole shore: the ladder past level 60",
        "Calm mode — no counter, muted light, a slower pour",
        "A color-blind palette, with a shape on every unit",
        "One payment. No subscription, no coins, no ads.",
    ]
    static let paywallPromise = "Today's pool, the first 60 racks, your streak, back, refill and the charted line stay free forever. This buys more shore, never access."

    /// Levels playable without the unlock. The daily puzzle is outside this and always free.
    static let freeLevelCount = 60

    /// What playing opens, as distinct from what the one payment opens.
    ///
    /// Every `unlock` in this app used to be `store.isUnlocked`: the paywall was the only door
    /// in it, and nothing whatever arrived for playing well. These are the three rungs where
    /// `LevelGenerator.ladder` changes the rack itself — a ninth colour, then vials blown
    /// deeper twice — which used to happen silently. Now the shore says so when you reach it,
    /// and the win names the next one, so there is always something on the way in.
    static let earned = Earned([
        Earned.Milestone(id: "thirteenth-light", title: "The thirteenth light",
                         blurb: "A thirteenth colour comes into the flat. The rack is as wide as the pool gets.",
                         at: 81),
        Earned.Milestone(id: "tall-glass", title: "Tall glass",
                         blurb: "The glass is blown deeper — five measures to a vial, and longer lines to walk.",
                         at: 105),
        Earned.Milestone(id: "deep-glass", title: "Deep glass",
                         blurb: "Six measures. The longest pours in the pool, and the last shape the rack takes.",
                         at: 155),
    ])
}
