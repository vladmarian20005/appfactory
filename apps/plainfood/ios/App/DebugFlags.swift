import Foundation

/// Launch arguments used by the factory's screenshot and QA tooling. Harmless in production:
/// end users cannot pass launch arguments.
enum DebugFlags {
    private static let args = ProcessInfo.processInfo.arguments
    static let onboarded = args.contains("-onboarded")
    static let sampleData = args.contains("-sampleData")
    static let forcePro = args.contains("-pro")
    static let fakeProducts = args.contains("-fakeProducts")
    static var query: String? {
        guard let i = args.firstIndex(of: "-query"), i + 1 < args.count else { return nil }
        return args[i + 1]
    }
    static var screen: String? {
        guard let i = args.firstIndex(of: "-screen"), i + 1 < args.count else { return nil }
        return args[i + 1]
    }
}
