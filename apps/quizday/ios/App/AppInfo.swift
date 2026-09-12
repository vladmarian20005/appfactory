import FactoryKit
import Foundation
import SwiftUI

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

    /// Three pages, each one a piece of the same world — the press, the stamp, the desk. No
    /// page states the promise; the paywall is the only place in the product that does.
    static let onboarding: [OnboardingPage] = [
        OnboardingPage(
            title: "One edition a day",
            subtitle: "Ten questions, dated and set fresh each morning.",
            artHeight: 400
        ) {
            // The masthead rides with the art: the first second of the app says newspaper
            // before it says anything else.
            VStack(spacing: 14) {
                Masthead(title: "Quizday", strapline: "A new edition every morning", size: 26)
                HandPress(width: 300)
            }
        },
        OnboardingPage(
            title: "Stamp your answer",
            subtitle: "Press one and the ink lands — with the reason it's right underneath.",
            artHeight: 340
        ) {
            Image("Stamp")
                .resizable()
                .scaledToFit()
                .frame(width: 300)
        },
        OnboardingPage(
            title: "Then the day is yours",
            subtitle: "Every edition is dated and kept. The desk reads them, and sets tomorrow's from what got past you.",
            artHeight: 340
        ) {
            Image("Desk")
                .resizable()
                .scaledToFit()
                .frame(width: 330)
        },
    ]

    static let paywallHeadline = "The composing room"
    static let paywallBullets = [
        "Set your own rounds — any section, any night, as many as you like",
        "See which sections you own and which keep catching you",
        "Choose the difficulty: easy, medium or hard",
    ]
    static let paywallPromise = "The daily edition stays free and always will — no ads, nothing to run out of. Pro buys you more type, not the paper."
}
