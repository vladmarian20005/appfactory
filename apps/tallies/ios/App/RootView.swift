import FactoryKit
import SwiftData
import SwiftUI

struct RootView: View {
    @EnvironmentObject private var store: Store
    @State private var showPaywall = false
    @State private var tab: Tab = .counters

    enum Tab: String { case counters, history, settings }

    var body: some View {
        TabView(selection: $tab) {
            CountersView(showPaywall: $showPaywall)
                .tabItem { Label("Counters", systemImage: "list.bullet") }
                .tag(Tab.counters)

            NavigationStack {
                HistoryView(showPaywall: $showPaywall)
            }
            .tabItem { Label("History", systemImage: "clock.arrow.circlepath") }
            .tag(Tab.history)

            NavigationStack {
                SettingsView(store: store, config: AppInfo.config, onUpgrade: { showPaywall = true }) {
                    TalliesSettings()
                }
            }
            .tabItem { Label("Settings", systemImage: "gearshape.fill") }
            .tag(Tab.settings)
        }
        .sheet(isPresented: $showPaywall) {
            PaywallView(store: store,
                        config: AppInfo.config,
                        headline: AppInfo.paywallHeadline,
                        bullets: AppInfo.paywallBullets,
                        promise: AppInfo.paywallPromise) {
                showPaywall = false
            }
        }
        .onAppear(perform: applyLaunchOptions)
    }

    private func applyLaunchOptions() {
        switch LaunchOptions.screen {
        case "counters", "detail", "add": tab = .counters
        case "history": tab = .history
        case "settings": tab = .settings
        case "paywall": showPaywall = true
        default: break
        }
        if LaunchOptions.fakeProducts {
            // A scheme's StoreKit configuration is never honoured by a `simctl launch`, so
            // without this the paywall has no products and its button sits disabled.
            store.debugOffers = [
                PaywallOffer(id: AppInfo.config.productIDs[0], title: "Weekly",
                             priceText: "$2.99", periodText: "per week", trialText: "3-day free trial"),
                PaywallOffer(id: AppInfo.config.productIDs[1], title: "Yearly",
                             priceText: "$19.99", periodText: "per year", trialText: "3-day free trial"),
            ]
        }
    }
}

/// The Tallies rows that sit inside the kit's Settings screen.
struct TalliesSettings: View {
    @Environment(\.modelContext) private var context
    @EnvironmentObject private var store: Store
    @Query private var counters: [Counter]
    @State private var confirmingErase = false

    private var totalTaps: Int {
        counters.reduce(0) { $0 + $1.entries.count }
    }

    var body: some View {
        Section {
            LabeledContent("Counters", value: "\(counters.count)")
            LabeledContent("Taps recorded", value: "\(totalTaps)")
        } header: {
            Text("On this device")
        } footer: {
            Text(store.isProUnlocked
                 ? "Tallies has no ads and no account. Everything you count stays on this phone."
                 : "Free keeps \(AppInfo.freeCounterLimit) counters and the last \(AppInfo.freeHistoryDays) days. Nothing you have already counted is ever taken away.")
        }

        Section {
            Button(role: .destructive) { confirmingErase = true } label: {
                Label("Erase everything", systemImage: "trash")
            }
            .confirmationDialog("Delete every counter and every tap on this device?",
                                isPresented: $confirmingErase, titleVisibility: .visible) {
                Button("Erase everything", role: .destructive, action: erase)
                Button("Cancel", role: .cancel) {}
            }
        } footer: {
            Text("This cannot be undone. Tallies keeps no copy anywhere else.")
        }
    }

    private func erase() {
        for counter in counters { context.delete(counter) }
        try? context.save()
    }
}
