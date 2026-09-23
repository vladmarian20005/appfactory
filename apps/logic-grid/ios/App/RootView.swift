import FactoryKit
import SwiftUI

struct RootView: View {
    @EnvironmentObject private var store: Store
    @StateObject private var bench = Bench()
    @State private var tab: Tab = .bed
    @State private var showPaywall = false

    enum Tab: String { case bed, line, run, shop }

    var body: some View {
        TabView(selection: $tab) {
            BedView(bench: bench, showPaywall: $showPaywall)
                .tabItem { Label("Bed", systemImage: "square.grid.3x3.square") }
                .tag(Tab.bed)

            LineView(bench: bench, showPaywall: $showPaywall, tab: $tab)
                .tabItem { Label("Line", systemImage: "rectangle.portrait.on.rectangle.portrait") }
                .tag(Tab.line)

            RunView(bench: bench, showPaywall: $showPaywall, tab: $tab)
                .tabItem { Label("Run", systemImage: "square.stack.3d.up") }
                .tag(Tab.run)

            NavigationStack {
                SettingsView(store: store,
                             config: AppInfo.config,
                             onUpgrade: { showPaywall = true },
                             upgradeTitle: "Unlock every plate",
                             activeTitle: "The whole run is yours") {
                    ShopRows(bench: bench)
                }
                .shopBackground()
            }
            .tabItem { Label("Shop", systemImage: "lamp.desk") }
            .tag(Tab.shop)
        }
        .sheet(isPresented: $showPaywall) {
            PaywallView(store: store,
                        config: AppInfo.config,
                        headline: AppInfo.paywallHeadline,
                        bullets: AppInfo.paywallBullets,
                        bulletStyle: .ruled(mark: "◆"),
                        promise: AppInfo.paywallPromise,
                        subhead: AppInfo.paywallSubhead,
                        cta: AppInfo.paywallCTA,
                        hero: {
                            Image("Rack")
                                .resizable()
                                .scaledToFit()
                                .frame(maxHeight: 200)
                                .ambientFloat(distance: 3, period: 4.4)
                        },
                        onDone: { showPaywall = false })
        }
        .environment(\.aquatint, bench.record.hasEarned("aquatint"))
        .onAppear(perform: start)
        .onChange(of: store.isPro) { _, isPro in bench.note(pro: isPro) }
    }

    private func start() {
        Tones.shared.warmUp()
        bench.note(pro: store.isPro)
        // Today's plate is what the bench opens on, unless it is already on the line — then
        // the next plate in her own run is ruled and waiting.
        if let which = LaunchOptions.bed {
            bench.openBed(daily: which == "daily")
        } else {
            bench.openBed(daily: bench.todaysPull == nil)
        }

        switch LaunchOptions.screen {
        case "line": tab = .line
        case "run": tab = .run
        case "settings", "shop": tab = .shop
        case "paywall": showPaywall = true
        default: tab = .bed
        }
        if LaunchOptions.fakeProducts {
            // A scheme's StoreKit configuration is never honoured by a `simctl launch`, so
            // without this the paywall has no product and its button sits disabled.
            store.debugOffers = [
                PaywallOffer(id: AppInfo.config.productIDs[0], title: "Crosshatch Unlock",
                             priceText: "$4.99", periodText: "one time", trialText: nil),
            ]
        }
        if let demo = LaunchOptions.demo {
            tab = .bed
            bench.startDemo(demo)
        }
    }
}

/// The Crosshatch rows inside the kit's Settings: what is in the shop, the sounds, the two
/// unlocked switches, and the one destructive act behind its confirmation.
struct ShopRows: View {
    @ObservedObject var bench: Bench
    @Environment(\.brand) private var brand
    @State private var confirmScrap = false

    var body: some View {
        Group {
            Section("In the shop") {
                row("Plates pulled", "\(bench.record.platesPulled)")
                row("Points cut", "\(bench.record.pointsCut)")
                row("Longest line", "\(bench.record.bestLine)")
                row("Days running", "\(bench.record.daysRunning)")
            }
            Section {
                SoundsToggle()
                if bench.isPro {
                    Toggle("Muted ink", isOn: Binding(get: { bench.record.calmInk }, set: bench.setCalm))
                    Toggle("Let the plate cross out for you", isOn: Binding(get: { bench.record.assist }, set: bench.setAssist))
                }
            } footer: {
                Text("Everything you have cut is on this phone and nowhere else.")
            }
            Section {
                Button("Scrap the plates", role: .destructive) { confirmScrap = true }
            }
            .alert("Scrap the plates?", isPresented: $confirmScrap) {
                Button("Scrap them", role: .destructive) { bench.scrapThePlates() }
                Button("Keep them", role: .cancel) { }
            } message: {
                Text("Every print and every mark on this phone?")
            }
        }
    }

    private func row(_ name: String, _ value: String) -> some View {
        HStack {
            Text(name)
                .foregroundStyle(brand.palette.ink)
            Spacer()
            Text(value)
                .plateCaps(size: 11)
                .foregroundStyle(brand.palette.highlight)
        }
    }
}
