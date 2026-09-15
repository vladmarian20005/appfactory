import Foundation

/// Launch arguments the factory's screenshot and QA tooling passes in. Nothing here changes
/// behaviour in a normal launch from the Home screen.
enum LaunchOptions {
    private static let args = ProcessInfo.processInfo.arguments

    static var onboarded: Bool { args.contains("-onboarded") }
    static var sampleData: Bool { args.contains("-sampleData") }
    static var forcePro: Bool { args.contains("-pro") }
    static var fakeProducts: Bool { args.contains("-fakeProducts") }
    static var resetData: Bool { args.contains("-reset") }
    /// `-won`: land straight on the pull, with the plate already inked.
    static var won: Bool { args.contains("-won") || screen == "win" }

    /// `-screen bed|line|run|settings|paywall|win`
    static var screen: String? { value(for: "-screen") }

    /// `-bed daily|run`: which plate the bench opens on, so a capture can choose between
    /// today's shared plate and the next plate in the run.
    static var bed: String? { value(for: "-bed") }

    /// `-fresh`: leave the plate uncut, so a capture can show the first minute — the floating
    /// burin, the ghost crosshatch and the thread to the clue that forces it.
    static var fresh: Bool { args.contains("-fresh") }

    /// `-demo cut|pull`. Nothing on a runner can touch the screen, so the app cuts its own
    /// plate and pulls its own print shortly after launch, and the critic films it.
    static var demo: String? { value(for: "-demo") }

    /// `-rung 5|51|500`: where on the run to seed the bench. This is what lets the ladder
    /// strip photograph a first session next to one months in.
    static var rung: Int? { value(for: "-rung").flatMap(Int.init) }

    /// `-level` is the factory's own spelling of the same idea; both reach deep state.
    static var level: Int? { rung ?? value(for: "-level").flatMap(Int.init) }

    private static func value(for flag: String) -> String? {
        guard let i = args.firstIndex(of: flag), args.index(after: i) < args.endIndex else { return nil }
        let next = args[args.index(after: i)]
        return next.hasPrefix("-") ? nil : next
    }
}
