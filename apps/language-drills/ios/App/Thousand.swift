import FactoryKit
import SwiftUI

@main
struct Thousand: App {
    @StateObject private var store = Store(productIDs: AppInfo.config.productIDs)
    @StateObject private var library = Library()
    @AppStorage("factory.onboarded") private var onboarded = false

    var body: some Scene {
        WindowGroup {
            Group {
                if onboarded || LaunchOptions.onboarded {
                    RootView()
                        .environmentObject(store)
                        .environmentObject(library)
                        .factoryReviewPrompt(afterSessions: 3)
                } else {
                    OnboardingView(pages: AppInfo.onboarding) { onboarded = true }
                }
            }
            // The very first frame is already plaster and cobalt.
            .brand(AppBrand.brand)
        }
    }
}
