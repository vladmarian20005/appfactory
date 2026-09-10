import FactoryKit
import Foundation

/// One place for everything the scaffolder and the spec fill in.
enum AppInfo {
    static let config = AppConfig(
        name: "Tallies",
        supportURL: URL(string: "https://starhiveconcept.com/tallies-privacy-policy-terms/#support")!,
        privacyURL: URL(string: "https://starhiveconcept.com/tallies-privacy-policy-terms/")!,
        termsURL: URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!,
        productIDs: ["com.starhiveconcept.tallies.pro.weekly", "com.starhiveconcept.tallies.pro.yearly"],
        appStoreID: nil
    )

    static let onboarding: [OnboardingPage] = [
        OnboardingPage(symbol: "plus.circle.fill",
                       title: "Count anything",
                       subtitle: "Tap to add, tap to take away. Keep as many counters as you need, side by side."),
        OnboardingPage(symbol: "chart.bar.fill",
                       title: "See the week",
                       subtitle: "Every tap is kept with its date, so a counter is a history you can read, not just a number."),
        OnboardingPage(symbol: "lock.shield.fill",
                       title: "Nothing to log into",
                       subtitle: "No account, no sync, no ads. Your counts stay on this phone."),
    ]

    static let paywallHeadline = "Tallies Pro"
    static let paywallBullets = [
        "Unlimited counters, not just three",
        "History across every counter, by day",
        "The full 14-day chart on each counter",
        "No ads, no account, ever",
    ]
    static let paywallPromise = "Three counters and a week of history stay free. Pro adds room, not access."

    /// Free-tier limits from the spec.
    static let freeCounterLimit = 3
    static let freeHistoryDays = 7
    static let proHistoryDays = 14
}
