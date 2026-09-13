import Foundation

/// Launch arguments the factory's screenshot and QA tooling passes in.
/// None of these change behaviour in a normal launch from the Home screen.
enum LaunchOptions {
    private static let args = ProcessInfo.processInfo.arguments

    static var onboarded: Bool { args.contains("-onboarded") }
    static var sampleData: Bool { args.contains("-sampleData") }
    static var forcePro: Bool { args.contains("-pro") }
    static var fakeProducts: Bool { args.contains("-fakeProducts") }
    static var resetData: Bool { args.contains("-reset") }

    /// `-screen bench|face|ledger|settings|paywall|lay|win`
    static var screen: String? { value(for: "-screen") }

    /// `-demo cut|score`. Nothing on a runner can touch the screen, so the app performs its
    /// own signature interaction and its own win shortly after launch and the critic films it.
    static var demo: String? { value(for: "-demo") }

    /// `-days 5|50|500`: how deep a record to seed. This is what lets the ladder strip show
    /// the same screen at a first sitting and at one half a year in.
    static var days: Int? { value(for: "-days").flatMap(Int.init) }

    private static func value(for flag: String) -> String? {
        guard let i = args.firstIndex(of: flag), args.index(after: i) < args.endIndex else { return nil }
        let next = args[args.index(after: i)]
        return next.hasPrefix("-") ? nil : next
    }
}
