import FactoryKit
import SwiftUI

@main
struct TemplateApp: App {
    @StateObject private var store = Store(productIDs: AppInfo.config.productIDs)
    @AppStorage("factory.onboarded") private var onboarded = false

    var body: some Scene {
        WindowGroup {
            if onboarded {
                RootView()
                    .environmentObject(store)
                    .factoryReviewPrompt(afterSessions: 3)
            } else {
                OnboardingView(pages: AppInfo.onboarding) { onboarded = true }
            }
        }
    }
}
