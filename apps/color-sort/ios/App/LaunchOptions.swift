import Foundation

/// Launch arguments the factory's screenshot and QA tooling passes in.
/// None of these change behaviour in a normal launch from the Home screen.
enum LaunchOptions {
    private static let args = ProcessInfo.processInfo.arguments

    static var onboarded: Bool { args.contains("-onboarded") }
    static var sampleData: Bool { args.contains("-sampleData") }
    static var forcePro: Bool { args.contains("-pro") }
    static var resetData: Bool { args.contains("-reset") }

    /// A scheme's StoreKit configuration is never honoured by a `simctl launch`, so without
    /// this the paywall has no products to show and its button sits disabled.
    static var fakeProducts: Bool { args.contains("-fakeProducts") }

    /// `-screen play|progress|packs|settings|paywall`
    static var screen: String? { value(for: "-screen") }

    /// `-level 12` opens that level instead of the one the player was last on.
    static var level: Int? { value(for: "-level").flatMap(Int.init) }

    /// `-daily` opens today's shared puzzle.
    static var daily: Bool { args.contains("-daily") }

    /// `-moves 9` plays the first nine moves of the verified solution, so a capture shows a
    /// board part-way through instead of an untouched deal.
    static var autoMoves: Int? { value(for: "-moves").flatMap(Int.init) }

    /// `-hint` arms the hint, which is the wedge made visible: the app knows the next move
    /// because it solved the board before serving it.
    static var hint: Bool { args.contains("-hint") }

    /// `-calm` and `-accessible` turn on the two unlock settings, so a capture can show what
    /// the unlock buys. Both still need `-pro` to take effect, exactly as a purchase would.
    static var calm: Bool { args.contains("-calm") }
    static var accessiblePalette: Bool { args.contains("-accessible") }

    private static func value(for flag: String) -> String? {
        guard let i = args.firstIndex(of: flag), args.index(after: i) < args.endIndex else { return nil }
        let next = args[args.index(after: i)]
        return next.hasPrefix("-") ? nil : next
    }
}
