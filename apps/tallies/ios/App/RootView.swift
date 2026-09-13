import FactoryKit
import SwiftData
import SwiftUI

struct RootView: View {
    @EnvironmentObject private var store: Store
    @State private var showPaywall = false
    @State private var tab: Tab = .bench

    enum Tab: String { case bench, ledger, settings }

    var body: some View {
        TabView(selection: $tab) {
            BenchView(showPaywall: $showPaywall)
                // The app's own mark in the chrome: a five-bar gate, drawn, as a template
                // image, so the tab bar still tints and animates it the way it does its own.
                .tabItem { Label { Text("Bench") } icon: { Image("TallyGlyph") } }
                .tag(Tab.bench)

            NavigationStack {
                LedgerView(showPaywall: $showPaywall)
            }
            .tabItem { Label("Ledger", systemImage: "list.bullet.rectangle.portrait.fill") }
            .tag(Tab.ledger)

            NavigationStack {
                SettingsView(store: store, config: AppInfo.config, onUpgrade: { showPaywall = true }) {
                    TalliesSettings()
                }
                .benchBackground()
            }
            .tabItem { Label("Settings", systemImage: "gearshape.fill") }
            .tag(Tab.settings)
        }
        .sheet(isPresented: $showPaywall) {
            PaywallView(store: store,
                        config: AppInfo.config,
                        headline: AppInfo.paywallHeadline,
                        bullets: AppInfo.paywallBullets,
                        bulletStyle: .ruled(mark: "⌄"),
                        promise: AppInfo.paywallPromise,
                        subhead: AppInfo.paywallSubhead,
                        cta: AppInfo.paywallCTA,
                        hero: {
                            Image("Rack")
                                .resizable()
                                .scaledToFit()
                                .frame(maxHeight: 220)
                                .ambientFloat(distance: 3, period: 4.4)
                        },
                        onDone: { showPaywall = false })
        }
        .onAppear(perform: applyLaunchOptions)
    }

    private func applyLaunchOptions() {
        switch LaunchOptions.screen {
        case "bench", "face", "lay", "win": tab = .bench
        case "ledger": tab = .ledger
        case "settings": tab = .settings
        case "paywall": showPaywall = true
        default: break
        }
        if LaunchOptions.demo != nil { tab = .bench }
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

/// The Tallies rows inside the kit's Settings screen. What is on this bench, the sounds, and
/// the one destructive act, behind its confirmation.
struct TalliesSettings: View {
    @Environment(\.modelContext) private var context
    @EnvironmentObject private var store: Store
    @Query private var counters: [Counter]
    @State private var confirmingClear = false

    private var notches: Int {
        counters.reduce(0) { $0 + $1.entries.reduce(0) { $0 + max(0, $1.delta) } }
    }

    private var daysKept: Int {
        let calendar = Calendar.current
        let days = counters.flatMap { $0.entries }.filter { $0.delta > 0 }
            .map { calendar.startOfDay(for: $0.at) }
        return Set(days).count
    }

    var body: some View {
        Section {
            LabeledContent("Staves", value: "\(counters.count)")
            LabeledContent("Notches cut", value: "\(notches)")
            LabeledContent("Days kept", value: "\(daysKept)")
            SoundsToggle()
        } header: {
            Text("On this bench")
        } footer: {
            Text(store.isProUnlocked
                 ? "Everything you have cut is on this phone and nowhere else."
                 : "Three staves and a week of strip. Nothing already cut is ever taken back down.")
        }

        Section {
            Button(role: .destructive) { confirmingClear = true } label: {
                Label("Clear the bench", systemImage: "trash")
            }
            .confirmationDialog("Clear the bench — every stave and every notch on this phone?",
                                isPresented: $confirmingClear, titleVisibility: .visible) {
                Button("Clear the bench", role: .destructive, action: clear)
                Button("Leave it", role: .cancel) {}
            }
        } footer: {
            Text("This cannot be undone. There is no copy anywhere else.")
        }
    }

    private func clear() {
        for counter in counters { context.delete(counter) }
        try? context.save()
    }
}
