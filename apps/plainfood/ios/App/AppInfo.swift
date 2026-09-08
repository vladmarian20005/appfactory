import FactoryKit
import Foundation

enum AppInfo {
    static let config = AppConfig(
        name: "Plainfood",
        supportURL: URL(string: "https://vladmarian20005.github.io/appmonkey/plainfood/support")!,
        privacyURL: URL(string: "https://vladmarian20005.github.io/appmonkey/plainfood/privacy")!,
        termsURL: URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!,
        productIDs: ["com.factory.plainfood.pro.weekly", "com.factory.plainfood.pro.yearly"],
        appStoreID: nil
    )

    static let onboarding: [OnboardingPage] = [
        OnboardingPage(symbol: "fork.knife.circle.fill", title: "Log food in seconds", subtitle: "Search, scan a barcode, or type it in. Calories and macros update as you go."),
        OnboardingPage(symbol: "lock.open.fill", title: "Macros stay free. Forever.", subtitle: "Protein, carbs and fat on your home screen. No paywall on the basics, nothing taken away later."),
        OnboardingPage(symbol: "iphone", title: "Yours, on your phone", subtitle: "No account. No ads. No feed. Your log lives on your device."),
    ]

    static let paywallHeadline = "Plainfood Pro"
    static let paywallBullets = [
        "Trends: 7 and 30 day calories and macros",
        "Weekly averages against your goal",
        "Streaks, and CSV export soon",
    ]
    static let paywallPromise = "Logging, barcode and macros stay free. Pro is analysis, not access."
}
