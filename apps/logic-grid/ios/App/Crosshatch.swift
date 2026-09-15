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
                                   finishTitle: AppInfo.onboardingFinish,
                                   // The page you are on is a cut lozenge; every page you are
                                   // not is an empty ruled cell.
                                   indexMark: "◆") { onboarded = true }
                }
            }
            .brand(AppBrand.brand)
        }
    }
}
