import FactoryKit
import SwiftUI

struct RootView: View {
    @EnvironmentObject private var store: Store
    @EnvironmentObject private var desk: Desk
    @Environment(\.scenePhase) private var scenePhase
    @State private var showSettings = LaunchOptions.screen == "settings"

    var body: some View {
        TabView(selection: $desk.tab) {
            NavigationStack {
                TableView()
            }
            .tabItem { Label("Table", systemImage: "rectangle.on.rectangle") }
            .tag(Desk.Tab.table)

            NavigationStack {
                DiaryView(showSettings: $showSettings)
                    .navigationDestination(isPresented: $showSettings) { SettingsScreen() }
            }
            .tabItem { Label("Diary", systemImage: "book") }
            .tag(Desk.Tab.diary)

            NavigationStack {
                DrawerView()
            }
            .tabItem { Label("Drawer", systemImage: "archivebox") }
            .tag(Desk.Tab.drawer)
        }
        .sheet(isPresented: $desk.showPaywall) {
            PaywallView(store: store, config: AppInfo.config,
                        headline: AppInfo.paywallHeadline,
                        bullets: AppInfo.paywallBullets,
                        bulletStyle: .ruled(mark: "▮"),
                        promise: AppInfo.paywallPromise,
                        subhead: AppInfo.paywallSubhead,
                        cta: AppInfo.paywallCTA,
                        hero: { Image("Drawer").resizable().scaledToFit() }) {
                desk.showPaywall = false
            }
            .brand(desk.brand)
        }
        .onAppear {
            Tones.shared.warmUp()
            switch LaunchOptions.screen {
            case "diary", "settings": desk.tab = .diary
            case "drawer": desk.tab = .drawer
            case "paywall": desk.showPaywall = true
            default: break
            }
            if LaunchOptions.fakeProducts {
                store.debugOffers = [PaywallOffer(id: AppInfo.unlockID, title: "The Drawer", priceText: "$4.99",
                                                  periodText: nil, trialText: nil)]
            }
            desk.isPro = store.isPro || LaunchOptions.forcePro
            if let demo = LaunchOptions.demo { Task { await desk.demo(demo) } }
        }
        .onChange(of: store.isPro) { _, pro in desk.isPro = pro || LaunchOptions.forcePro }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { desk.resume() } else { desk.pause() }
        }
    }
}
