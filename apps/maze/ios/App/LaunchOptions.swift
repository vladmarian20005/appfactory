import Foundation

/// Launch arguments the factory's screenshot and QA tooling passes in.
/// None of these change behaviour in a normal launch from the Home screen.
enum LaunchOptions {
    private static let args = ProcessInfo.processInfo.arguments

    static var onboarded: Bool { args.contains("-onboarded") }
    /// Rung 51, nineteen pieces, twelve days running ending today, the silk and the marking
    /// pin earned, today's pattern half wound.
    static var sampleData: Bool { args.contains("-sampleData") }
    static var forcePro: Bool { args.contains("-pro") }
    static var resetData: Bool { args.contains("-reset") }

    /// A scheme's StoreKit configuration is never honoured by a `simctl launch`, so without
    /// this the paywall has no products to show and its button sits disabled.
    static var fakeProducts: Bool { args.contains("-fakeProducts") }

    /// `-screen pillow|sampler|book|workbox|paywall|win`
    static var screen: String? { value(for: "-screen") }

    /// `-board today|book|loose` — which pattern the pillow shows.
    static var board: String? { value(for: "-board") }

    /// `-rung 150` (or `-level 150`) seeds the book at that rung, with a sampler to match, so
    /// the ladder strip can photograph session 5 and session 500 side by side.
    static var rung: Int? { (value(for: "-rung") ?? value(for: "-level")).flatMap(Int.init) }

    /// `-wound 30` winds that many pins of the pattern along its answer.
    static var wound: Int? { value(for: "-wound").flatMap(Int.init) }

    /// `-fresh` leaves the pattern unwound, for the teaching state.
    static var fresh: Bool { args.contains("-fresh") }

    /// `-thread rose|gold`
    static var thread: String? { value(for: "-thread") }

    /// `-won` (or `-screen win`) lands on the lift, finished.
    static var won: Bool { args.contains("-won") || screen == "win" }

    /// `-lesson [1|2|3]` pins the first card at that practice pattern, whatever the record.
    static var lesson: Int? {
        args.contains("-lesson") ? (value(for: "-lesson").flatMap(Int.init) ?? 1) : nil
    }

    /// A flag that seeds a record or a pattern for a capture. The first card and the
    /// lacemaker's one-time notes stay out of those frames.
    static var isCapture: Bool {
        sampleData || rung != nil || demo != nil || wound != nil || won || board != nil
    }

    /// `-demo wind|lift` makes the app perform the winding, and the lift, by itself: nothing
    /// on a runner can touch a screen.
    static var demo: String? { value(for: "-demo") }

    private static func value(for flag: String) -> String? {
        guard let i = args.firstIndex(of: flag), args.index(after: i) < args.endIndex else { return nil }
        let next = args[args.index(after: i)]
        return next.hasPrefix("-") ? nil : next
    }
}
