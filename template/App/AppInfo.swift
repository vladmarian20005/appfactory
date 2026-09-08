import FactoryKit
import Foundation

/// One place for everything the scaffolder and the spec fill in.
enum AppInfo {
    static let config = AppConfig(
        name: "TemplateApp",
        supportURL: URL(string: "https://vladmarian20005.github.io/appmonkey/templateapp/support")!,
        privacyURL: URL(string: "https://vladmarian20005.github.io/appmonkey/templateapp/privacy")!,
        termsURL: URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!,
        productIDs: ["com.factory.templateapp.pro.weekly", "com.factory.templateapp.pro.yearly"],
        appStoreID: nil
    )

    static let onboarding: [OnboardingPage] = [
        OnboardingPage(symbol: "sparkles", title: "Welcome to TemplateApp", subtitle: "The one-line promise from the spec goes here."),
        OnboardingPage(symbol: "bolt.fill", title: "Fast where it matters", subtitle: "The wedge: the thing the leader gets wrong that this app gets right."),
        OnboardingPage(symbol: "lock.shield.fill", title: "Private by default", subtitle: "Your data stays on your device. No account needed."),
    ]

    static let paywallHeadline = "Go Pro"
    static let paywallBullets = [
        "Everything unlocked, forever",
        "No ads, no upsells",
        "Widgets and iCloud sync",
    ]
}
