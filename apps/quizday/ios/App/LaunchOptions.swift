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
    /// Opens the Today round already in progress, for screenshots and QA.
    static var autoPlay: Bool { args.contains("-play") }

    /// `-screen today|scorecard|practice|paywall|settings`
    static var screen: String? { value(for: "-screen") }

    /// `-playStep 2` advances the auto-played round that many questions in.
    static var playStep: Int? { value(for: "-playStep").flatMap(Int.init) }

    /// `-practiceStart` loads a practice round straight away, to exercise the network path.
    static var practiceStart: Bool { args.contains("-practiceStart") }

    /// `-reveal` answers the current auto-played question wrongly, to show the explanation.
    static var reveal: Bool { args.contains("-reveal") }

    /// `-answered 7` pre-fills today's round as already played with that score.
    static var answered: Int? { value(for: "-answered").flatMap(Int.init) }

    private static func value(for flag: String) -> String? {
        guard let i = args.firstIndex(of: flag), args.index(after: i) < args.endIndex else { return nil }
        let next = args[args.index(after: i)]
        return next.hasPrefix("-") ? nil : next
    }
}
