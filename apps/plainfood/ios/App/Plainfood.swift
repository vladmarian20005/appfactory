import FactoryKit
import SwiftData
import SwiftUI

@main
struct Plainfood: App {
    @StateObject private var store: Store
    @AppStorage("factory.onboarded") private var onboarded = false
    private let container: ModelContainer

    init() {
        let s = Store(productIDs: AppInfo.config.productIDs)
        if DebugFlags.fakeProducts {
            s.debugOffers = [
                PaywallOffer(id: "com.factory.plainfood.pro.weekly", title: "Pro Weekly", priceText: "$4.99", periodText: "per week", trialText: "3-day free trial"),
                PaywallOffer(id: "com.factory.plainfood.pro.yearly", title: "Pro Yearly", priceText: "$29.99", periodText: "per year", trialText: "3-day free trial"),
            ]
        }
        _store = StateObject(wrappedValue: s)
        do {
            container = try ModelContainer(for: FoodEntry.self)
        } catch {
            fatalError("Could not open the food log: \(error)")
        }
        if DebugFlags.onboarded { UserDefaults.standard.set(true, forKey: "factory.onboarded") }
        if DebugFlags.sampleData {
            let context = container.mainContext
            let count = (try? context.fetchCount(FetchDescriptor<FoodEntry>())) ?? 0
            if count == 0 { SampleData.seed(into: context) }
        }
    }

    var body: some Scene {
        WindowGroup {
            Group {
                if onboarded {
                    RootView()
                        .environmentObject(store)
                        .factoryReviewPrompt(afterSessions: DebugFlags.sampleData ? .max : 3)
                } else {
                    OnboardingView(pages: AppInfo.onboarding) { onboarded = true }
                }
            }
            .modelContainer(container)
        }
    }
}
