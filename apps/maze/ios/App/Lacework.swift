import FactoryKit
import SwiftUI

@main
struct Lacework: App {
    @StateObject private var store = Store(productIDs: AppInfo.config.productIDs)
    @StateObject private var bench = Bench()
    @AppStorage("factory.onboarded") private var onboarded = false

    init() {
        if LaunchOptions.resetData {
            UserDefaults.standard.removeObject(forKey: "factory.onboarded")
        }
    }

    var body: some Scene {
        WindowGroup {
            Group {
                if onboarded || LaunchOptions.onboarded {
                    RootView()
                        .environmentObject(store)
                        .environmentObject(bench)
                        .factoryReviewPrompt(afterSessions: 3)
                } else {
                    OnboardingView(pages: AppInfo.onboarding,
                                   nextTitle: AppInfo.onboardingNext,
                                   finishTitle: AppInfo.onboardingFinish,
                                   // The page you are on is a pin-head; every page you are
                                   // not is an empty prick.
                                   indexMark: "●") { onboarded = true }
                        .background { Linen() }
                }
            }
            .brand(AppBrand.brand)
        }
    }
}
