import StoreKit
import SwiftUI

/// Counts app sessions and asks for a rating once the threshold is reached, at most once per version.
struct ReviewPromptModifier: ViewModifier {
    let afterSessions: Int
    @AppStorage("factory.sessions") private var sessions = 0
    @AppStorage("factory.reviewedVersion") private var reviewedVersion = ""
    @Environment(\.requestReview) private var requestReview

    func body(content: Content) -> some View {
        content.onAppear {
            sessions += 1
            let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
            guard sessions >= afterSessions, reviewedVersion != version else { return }
            reviewedVersion = version
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) { requestReview() }
        }
    }
}

public extension View {
    /// Ask for an App Store rating after `afterSessions` launches, once per version.
    func factoryReviewPrompt(afterSessions: Int = 3) -> some View {
        modifier(ReviewPromptModifier(afterSessions: afterSessions))
    }
}
