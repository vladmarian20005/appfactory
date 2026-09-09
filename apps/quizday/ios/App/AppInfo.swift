import FactoryKit
import Foundation

/// One place for everything the scaffolder and the spec fill in.
enum AppInfo {
    static let config = AppConfig(
        name: "Quizday",
        supportURL: URL(string: "https://starhiveconcept.com/quizday-privacy-policy-terms/#support")!,
        privacyURL: URL(string: "https://starhiveconcept.com/quizday-privacy-policy-terms/")!,
        termsURL: URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!,
        productIDs: ["com.starhiveconcept.quizday.pro.weekly", "com.starhiveconcept.quizday.pro.yearly"],
        appStoreID: nil
    )

    static let onboarding: [OnboardingPage] = [
        OnboardingPage(
            symbol: "10.circle.fill",
            title: "Ten questions a day",
            subtitle: "The same ten for everyone, every day. Play them in a couple of minutes, then you're done."
        ),
        OnboardingPage(
            symbol: "hand.raised.fill",
            title: "No ads. Nothing runs out.",
            subtitle: "No ad between questions, no lives to wait for, no coins to buy. That is the whole point."
        ),
        OnboardingPage(
            symbol: "text.book.closed.fill",
            title: "Every answer explained",
            subtitle: "Each question comes with the reason and a source, so you learn something even when you miss."
        ),
    ]

    static let paywallHeadline = "Quizday Pro"
    static let paywallBullets = [
        "Practice any category, as much as you like",
        "See your accuracy category by category",
        "Choose easy, medium or hard",
    ]
    static let paywallPromise = "The daily ten stays free, with no ads and nothing to run out of. Pro adds practice, not access."
}
