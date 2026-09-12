import Foundation

/// Launch arguments the factory's screenshot and QA tooling passes in.
/// None of these change behaviour in a normal launch from the Home screen.
enum LaunchOptions {
    private static let args = ProcessInfo.processInfo.arguments

    static var onboarded: Bool { args.contains("-onboarded") }
    static var forcePro: Bool { args.contains("-pro") }
    static var resetData: Bool { args.contains("-reset") }

    /// `-sampleData` lays a believable wall: 213 words known, a band of them learning, and a
    /// session waiting at the bench. Nothing on a runner can drill for a fortnight.
    static var sampleData: Bool { args.contains("-sampleData") }

    /// A scheme's StoreKit configuration is never honoured by a `simctl launch`, so without
    /// this the paywall has no products to show and its button sits disabled.
    static var fakeProducts: Bool { args.contains("-fakeProducts") }

    /// `-screen bench|wall|progress|settings|paywall|word`
    static var screen: String? { value(for: "-screen") }

    /// `-turned` opens the bench with the tile already over and the grades up, which is the
    /// half of the signature interaction a still capture can show.
    static var turned: Bool { args.contains("-turned") }

    /// `-won` lands straight on the swept bench and the day's tiles in the wall. It is the
    /// best picture the app has.
    static var won: Bool { args.contains("-won") }

    /// `-swept` empties the bench, so the empty state can be photographed as well as reasoned
    /// about.
    static var swept: Bool { args.contains("-swept") }

    /// `-demo turn` and `-demo win` make the app turn a tile, set it, and reach its win by
    /// itself: nothing on a runner can touch a screen, and an interaction nobody can film is
    /// an interaction nobody can judge.
    static var demo: String? { value(for: "-demo") }

    private static func value(for flag: String) -> String? {
        guard let i = args.firstIndex(of: flag), args.index(after: i) < args.endIndex else { return nil }
        let next = args[args.index(after: i)]
        return next.hasPrefix("-") ? nil : next
    }
}
