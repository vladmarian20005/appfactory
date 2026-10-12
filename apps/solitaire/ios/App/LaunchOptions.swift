import Foundation

/// Launch arguments the factory's screenshot and QA tooling passes in.
/// None of these change behaviour in a normal launch from the Home screen.
enum LaunchOptions {
    private static let args = ProcessInfo.processInfo.arguments

    static var onboarded: Bool { args.contains("-onboarded") }
    /// Ledger No. 51, twenty-three entries, nine days running to yesterday, the claret cloth
    /// earned, today's deal played twelve moves along its line.
    static var sampleData: Bool { args.contains("-sampleData") }
    static var forcePro: Bool { args.contains("-pro") }
    static var resetData: Bool { args.contains("-reset") }

    /// A scheme's StoreKit configuration is never honoured by a `simctl launch`, so without
    /// this the paywall has no products to show and its button sits disabled.
    static var fakeProducts: Bool { args.contains("-fakeProducts") }

    /// `-screen table|diary|drawer|settings|paywall|win`
    static var screen: String? { value(for: "-screen") }

    /// `-board today|ledger|loose` — which deal the table shows.
    static var board: String? { value(for: "-board") }

    /// `-fresh` leaves the deal unplayed, for the first-deal teaching.
    static var fresh: Bool { args.contains("-fresh") }

    /// `-rung 150` (or `-level 150`) seeds the ledger at that rung, with a diary to match, so
    /// the ladder strip can photograph session 5 and session 500 side by side.
    static var rung: Int? { (value(for: "-rung") ?? value(for: "-level")).flatMap(Int.init) }

    /// `-played 30` plays that many moves of the deal along the dealer's line.
    static var played: Int? { value(for: "-played").flatMap(Int.init) }

    /// `-won` (or `-screen win`) lands on the win, finished.
    static var won: Bool { args.contains("-won") || screen == "win" }

    /// `-done` puts today's in the diary and leaves the table empty: the done state.
    static var done: Bool { args.contains("-done") }

    /// `-cloth claret|moss|slate`
    static var cloth: String? { value(for: "-cloth") }

    /// `-demo move|win` makes the app play its signature interaction, and the win, by
    /// itself: nothing on a runner can touch a screen.
    static var demo: String? { value(for: "-demo") }

    /// A flag that seeds a record for a capture.
    static var seeds: Bool { sampleData || rung != nil || demo != nil || won || done }

    private static func value(for flag: String) -> String? {
        guard let i = args.firstIndex(of: flag), args.index(after: i) < args.endIndex else { return nil }
        let next = args[args.index(after: i)]
        return next.hasPrefix("-") ? nil : next
    }
}
