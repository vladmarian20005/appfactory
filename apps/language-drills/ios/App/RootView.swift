import FactoryKit
import SwiftUI

struct RootView: View {
    @EnvironmentObject private var store: Store
    @EnvironmentObject private var library: Library

    @State private var tab: Tab = .bench
    @State private var showPaywall = false
    @State private var showSettings = false

    enum Tab: String { case bench, wall, progress }

    /// One payment opens the whole thousand. `-pro` stands in for it on a runner, where no
    /// purchase can complete.
    private var isOpen: Bool { store.isPro || LaunchOptions.forcePro }

    var body: some View {
        TabView(selection: $tab) {
            NavigationStack {
                BenchView(showSettings: $showSettings, onSeeTheWall: { tab = .wall })
            }
            .tabItem { Label("Bench", systemImage: "square.stack.3d.up") }
            .tag(Tab.bench)

            NavigationStack {
                WallView(showPaywall: $showPaywall)
            }
            .tabItem { Label("Wall", systemImage: "square.grid.3x3.fill") }
            .tag(Tab.wall)

            NavigationStack {
                ProgressWallView()
            }
            .tabItem { Label("Progress", systemImage: "chart.bar.xaxis") }
            .tag(Tab.progress)
        }
        .sheet(isPresented: $showSettings) {
            NavigationStack {
                SettingsView(store: store,
                             config: AppInfo.config,
                             onUpgrade: { showSettings = false; showPaywall = true },
                             upgradeTitle: "Open the whole wall",
                             activeTitle: "The whole wall is open") {
                    ThousandSettings()
                }
                .brandBackground()
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Done") { showSettings = false }
                    }
                }
            }
            .brand(AppBrand.brand)
        }
        .sheet(isPresented: $showPaywall) {
            PaywallView(store: store,
                        config: AppInfo.config,
                        headline: AppInfo.paywallHeadline,
                        bullets: AppInfo.paywallBullets,
                        promise: AppInfo.paywallPromise,
                        hero: {
                            Image("KeptWall")
                                .resizable()
                                .scaledToFit()
                                .ambientFloat(distance: 4, period: 5)
                        }) {
                showPaywall = false
            }
            .brand(AppBrand.brand)
        }
        .onAppear(perform: applyLaunchOptions)
    }

    private func applyLaunchOptions() {
        switch LaunchOptions.screen {
        case "bench": tab = .bench
        case "wall": tab = .wall
        case "progress": tab = .progress
        case "settings": showSettings = true
        case "paywall": showPaywall = true
        default: break
        }
        if LaunchOptions.fakeProducts {
            // A scheme's StoreKit configuration is not honoured by `simctl launch`, so the
            // real product is unavailable and the paywall's button would sit disabled.
            store.debugOffers = [
                PaywallOffer(id: AppInfo.unlockID,
                             title: "The Whole Wall",
                             priceText: "$9.99",
                             periodText: nil,
                             trialText: nil)
            ]
        }
    }
}

/// Thousand's own rows inside the kit's Settings screen. System chrome, brand tint, nothing
/// drawn: the workshop is on the other three screens.
struct ThousandSettings: View {
    @EnvironmentObject private var library: Library
    @AppStorage(Reminder.enabledKey) private var remind = false
    @AppStorage(Reminder.hourKey) private var remindHour = 20
    @State private var confirmingReset = false

    var body: some View {
        Section {
            SayItOnTurnToggle()
            SoundsToggle()
        } header: {
            Text("At the bench")
        }

        Section {
            Toggle(isOn: $remind) {
                Label("Daily reminder", systemImage: "bell")
            }
            .onChange(of: remind) { _, on in
                Reminder.set(on: on, hour: remindHour, ready: library.dryingCount)
            }
            if remind {
                Picker(selection: $remindHour) {
                    ForEach(6..<23) { hour in
                        Text(Reminder.label(hour)).tag(hour)
                    }
                } label: {
                    Label("At", systemImage: "clock")
                }
                .onChange(of: remindHour) { _, hour in
                    Reminder.set(on: remind, hour: hour, ready: library.dryingCount)
                }
            }
        } header: {
            Text("The reminder")
        } footer: {
            Text("It names the tiles waiting at the bench. It never counts the days you were away.")
        }

        Section {
            LabeledContent("In the wall", value: "\(library.setCount)")
            LabeledContent("Drying", value: "\(library.dryingCount)")
            LabeledContent("The whole deck", value: "\(Deck.total)")
        } header: {
            Text("The wall")
        }

        Section {
            Button(role: .destructive) { confirmingReset = true } label: {
                Label("Take the wall down", systemImage: "trash")
            }
            .confirmationDialog("Take down every tile on this device and start from bare plaster?",
                                isPresented: $confirmingReset, titleVisibility: .visible) {
                Button("Take it down", role: .destructive) { library.eraseEverything() }
                Button("Cancel", role: .cancel) {}
            }
        } footer: {
            Text("The wall is only ever on this phone, so there is nothing to take down anywhere else.")
        }
    }
}
