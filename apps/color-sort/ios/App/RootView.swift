import FactoryKit
import SwiftData
import SwiftUI

struct RootView: View {
    @EnvironmentObject private var store: Store
    @StateObject private var game = GameModel()
    @State private var showPaywall = false
    @State private var tab: Tab = .play

    @AppStorage("tidepour.currentLevel") private var currentLevel = 1

    enum Tab: String { case play, progress, packs, settings }

    var body: some View {
        TabView(selection: $tab) {
            NavigationStack {
                PlayView(showPaywall: $showPaywall)
            }
            .tabItem { Label("Play", systemImage: "drop.fill") }
            .tag(Tab.play)

            NavigationStack {
                StreakView(onPlayDaily: playDaily)
            }
            .tabItem { Label("Progress", systemImage: "calendar") }
            .tag(Tab.progress)

            NavigationStack {
                PacksView(showPaywall: $showPaywall, onOpenLevel: open(level:))
            }
            .tabItem { Label("Packs", systemImage: "square.grid.2x2.fill") }
            .tag(Tab.packs)

            NavigationStack {
                SettingsView(store: store, config: AppInfo.config, onUpgrade: { showPaywall = true }) {
                    TidepourSettings()
                }
            }
            .tabItem { Label("Settings", systemImage: "gearshape.fill") }
            .tag(Tab.settings)
        }
        .environmentObject(game)
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

    private func playDaily() {
        game.open(.daily(DayKey.key()))
        tab = .play
    }

    private func open(level: Int) {
        if level > AppInfo.freeLevelCount && !store.isUnlocked {
            showPaywall = true
            return
        }
        currentLevel = level
        game.open(.numbered(level))
        tab = .play
    }

    private func applyLaunchOptions() {
        switch LaunchOptions.screen {
        case "play": tab = .play
        case "progress": tab = .progress
        case "packs": tab = .packs
        case "settings": tab = .settings
        case "paywall": showPaywall = true
        default: break
        }
        if LaunchOptions.fakeProducts {
            // A scheme's StoreKit configuration is not honoured by `simctl launch`, so the
            // real product is unavailable and the paywall's button would sit disabled.
            store.debugOffers = [
                PaywallOffer(id: AppInfo.unlockID,
                             title: "Tidepour Unlock",
                             priceText: "$4.99",
                             periodText: nil,
                             trialText: nil)
            ]
        }
    }
}

/// The Tidepour rows inside the kit's Settings screen.
struct TidepourSettings: View {
    @Environment(\.modelContext) private var context
    @Query private var results: [LevelResult]
    @AppStorage("tidepour.currentLevel") private var currentLevel = 1
    @AppStorage("tidepour.highestCleared") private var highestCleared = 0
    @State private var confirmingReset = false

    var body: some View {
        Section {
            LabeledContent("Levels cleared", value: "\(results.filter { !$0.isDaily }.count)")
            LabeledContent("Daily puzzles cleared", value: "\(results.filter(\.isDaily).count)")
            LabeledContent("Free levels", value: "\(AppInfo.freeLevelCount)")
        } header: {
            Text("Your play")
        } footer: {
            Text("Tidepour has no advertising, no in-app currency and no lives. Every board is solved before it is served, and everything you play stays on this device.")
        }

        Section {
            Button(role: .destructive) { confirmingReset = true } label: {
                Label("Erase my progress", systemImage: "trash")
            }
            .confirmationDialog("Erase every cleared level, streak and saved board on this device?",
                                isPresented: $confirmingReset, titleVisibility: .visible) {
                Button("Erase everything", role: .destructive, action: erase)
                Button("Cancel", role: .cancel) {}
            }
        } footer: {
            Text("Nothing leaves the device, so there is nothing to erase anywhere else.")
        }
    }

    private func erase() {
        for result in results { context.delete(result) }
        try? context.save()
        GameModel.eraseSavedBoards()
        currentLevel = 1
        highestCleared = 0
    }
}
