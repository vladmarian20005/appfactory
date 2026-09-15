import FactoryKit
import SwiftUI

@main
struct Crosshatch: App {
    @StateObject private var store = Store(productIDs: AppInfo.config.productIDs)
    @AppStorage("factory.onboarded") private var onboarded = false

    var body: some Scene {
        WindowGroup {
            Group {
                if onboarded || LaunchOptions.onboarded {
                    RootView()
                        .environmentObject(store)
                        .factoryReviewPrompt(afterSessions: 3)
                } else {
                    OnboardingView(pages: AppInfo.onboarding,
                                   nextTitle: AppInfo.onboardingNext,
                                   finishTitle: AppInfo.onboardingFinish) { onboarded = true }
                }
            }
            .brand(AppBrand.brand)
        }
    }
}
