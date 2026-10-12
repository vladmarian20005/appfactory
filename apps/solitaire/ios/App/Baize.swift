import FactoryKit
import SwiftUI

@main
struct Baize: App {
    @StateObject private var store = Store(productIDs: AppInfo.config.productIDs)
    @StateObject private var desk = Desk()
    @AppStorage("factory.onboarded") private var onboarded = false

    init() {
        if LaunchOptions.resetData {
            UserDefaults.standard.removeObject(forKey: "factory.onboarded")
        }
        Self.letterTitles()
    }

    /// Diary, Drawer, Settings: titles in New York Semibold, in cream, like everything else on
    /// the cloth. Scaled with Dynamic Type through the text style's metrics.
    private static func letterTitles() {
        func serif(_ style: UIFont.TextStyle) -> UIFont {
            let base = UIFont.preferredFont(forTextStyle: style)
            let semibold = base.fontDescriptor.addingAttributes([
                .traits: [UIFontDescriptor.TraitKey.weight: UIFont.Weight.semibold],
            ])
            let descriptor = semibold.withDesign(.serif) ?? semibold
            return UIFont(descriptor: descriptor, size: 0)
        }
        let ink = UIColor(AppBrand.brand.palette.ink)
        let bar = UINavigationBar.appearance()
        bar.largeTitleTextAttributes = [.font: serif(.largeTitle), .foregroundColor: ink]
        bar.titleTextAttributes = [.font: serif(.headline), .foregroundColor: ink]
    }

    var body: some Scene {
        WindowGroup {
            Group {
                if onboarded || LaunchOptions.onboarded {
                    RootView()
                        .environmentObject(store)
                        .environmentObject(desk)
                        .factoryReviewPrompt(afterSessions: 3)
                } else {
                    OnboardingView(pages: AppInfo.onboarding,
                                   nextTitle: AppInfo.onboardingNext,
                                   finishTitle: AppInfo.onboardingFinish,
                                   // The page you are on is a small card; every page you are
                                   // not is an empty slot.
                                   indexMark: "▮") { onboarded = true }
                        .background { Nap() }
                }
            }
            .brand(desk.brand)
            .environment(\.cardStyle, CardStyle(back: desk.back, gilt: desk.record.gilt,
                                                fourColour: desk.record.fourColour,
                                                largePips: desk.record.largePips))
        }
    }
}
