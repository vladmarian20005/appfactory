import FactoryKit
import SwiftUI

struct RootView: View {
    @EnvironmentObject private var store: Store
    @State private var showPaywall = DebugFlags.screen == "paywall"
    @State private var tab: Tab = DebugFlags.screen == "trends" ? .trends : (DebugFlags.screen == "settings" ? .settings : .today)

    enum Tab { case today, trends, settings }

    var body: some View {
        TabView(selection: $tab) {
            NavigationStack { TodayView() }
                .tabItem { Label("Today", systemImage: "circle.circle.fill") }
                .tag(Tab.today)
            NavigationStack { TrendsView(showPaywall: $showPaywall) }
                .tabItem { Label("Trends", systemImage: "chart.bar.fill") }
                .tag(Tab.trends)
            NavigationStack {
                SettingsView(store: store, config: AppInfo.config, onUpgrade: { showPaywall = true }) {
                    Section("Tracking") {
                        NavigationLink { GoalsView() } label: { Label("Daily goals", systemImage: "target") }
                    }
                }
            }
            .tabItem { Label("Settings", systemImage: "gearshape.fill") }
            .tag(Tab.settings)
        }
        .sheet(isPresented: $showPaywall) {
            PaywallView(store: store, config: AppInfo.config, headline: AppInfo.paywallHeadline, bullets: AppInfo.paywallBullets, promise: AppInfo.paywallPromise) {
                showPaywall = false
            }
        }
    }
}
