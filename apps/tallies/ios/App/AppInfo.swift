import FactoryKit
import Foundation
import SwiftUI

/// One place for everything the scaffolder and the spec fill in — and the carver's voice.
///
/// He made the staves and keeps the bench: quietly interested in what you are counting and
/// completely uninterested in whether you did enough of it. A number, never an adjective. It
/// reports; it never instructs. One sentence, two at most.
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
        OnboardingPage(title: "A stave for each thing",
                       subtitle: "Ash, fifty notches long. One for whatever you are keeping a number on — reps, birds, glasses, cars past the window.",
                       artHeight: 320) {
            Image("Bench").resizable().scaledToFit()
        },
        OnboardingPage(title: "Five to a gate",
                       subtitle: "Four uprights and a stroke across them, the way people have counted since before there were numbers to count in.",
                       artHeight: 320) {
            Image("Gate").resizable().scaledToFit()
        },
        OnboardingPage(title: "Full staves go in the rack",
                       subtitle: "Scored, dated and stood up behind the bench. Nothing you have cut is ever taken back down.",
                       artHeight: 320) {
            Image("Rack").resizable().scaledToFit()
        },
    ]

    static let onboardingNext = "Go on"
    static let onboardingFinish = "Take the blade"

    static let paywallHeadline = "The rack and the ledger"
    static let paywallBullets = [
        "As many staves on the bench as you want, not three.",
        "The ledger: every cut you have made, by the day, with the week and the month beside it.",
        "The strip on each stave reaches back as far as your record goes, not seven days.",
    ]
    static let paywallPromise = "Three staves and a week of strip stay free, and nothing already cut is ever taken back down."
    static let paywallCTA = "Start the 3-day trial"

    /// Free-tier limits from the spec.
    static let freeStaveLimit = 3
    static let freeStripDays = 7

    // MARK: Pools

    /// A stave scored. Ten of them, so the tenth win does not read like the first.
    static let praise = [
        "Scored. Fifty notches, and the date on the end.",
        "That is a stave. It goes in the rack the way it is.",
        "Full. The next one is already on the bench.",
        "Fifty. The rack takes it without comment.",
        "Cut through. Good grain on that one.",
        "Done and dated. Nothing on it to explain.",
        "A stave closed. The bench is clear again.",
        "Fifty notches, all of them yours.",
        "Scored across. That is the whole length of it.",
        "Stood up in the rack. It will be there in a year.",
    ]

    /// A cut waxed. Nobody minds a wax.
    static let nearMiss = [
        "Waxed. The record would rather be right than tidy.",
        "Filled. It still shows, and it should.",
        "Taken back. The wax is paler; you will always know.",
        "One out, one filled. The count is right again.",
        "Waxed over. Nobody minds a wax.",
        "Back to where it was. The mark stays, the number does not.",
        "Filled with wax. An honest stave has a few.",
        "Corrected. The stave keeps the story.",
    ]

    static let goalReached = [
        "The gauge is at the line.",
        "The line is reached.",
        "That is the day's mark.",
        "Level with the line. The rest is extra.",
        "The chalk line is behind you.",
    ]

    /// Never the same line twice running: the pools are long enough that a seeded pick from
    /// the count avoids the one before it.
    static func line(from pool: [String], avoiding previous: String?) -> String {
        let choices = pool.filter { $0 != previous }
        return choices.randomElement() ?? pool[0]
    }

    static func headline(for tier: Run.Tier) -> String {
        switch tier {
        case .best: return "NOT ONE WAX, AND YOUR BEST"
        case .clean: return "FIFTY, AND NOT A WAXED ONE"
        default: return "SCORED. THE WAX SHOWS, AND THAT IS FINE"
        }
    }
}
