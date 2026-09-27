import FactoryKit
import SwiftUI

struct RootView: View {
    @EnvironmentObject private var store: Store
    @EnvironmentObject private var bench: Bench
    @Environment(\.scenePhase) private var scenePhase
    @State private var tab: Tab = .today
    @State private var showPaywall = false
    /// The paywall over the pillow when the book or the archive is open over Today: a sheet
    /// has to come from whatever is on top.
    @State private var showPaywallOver = false

    enum Tab: String { case today, sampler, book, workbox }

    var body: some View {
        TabView(selection: $tab) {
            PillowView(tab: $tab)
                .tabItem { Label("Today", systemImage: "calendar") }
                .tag(Tab.today)
            SamplerView(tab: $tab)
                .tabItem { Label("Sampler", systemImage: "square.grid.2x2") }
                .tag(Tab.sampler)
            BookView(tab: $tab, showPaywall: $showPaywall)
                .tabItem { Label("Patterns", systemImage: "book.closed") }
                .tag(Tab.book)
            WorkboxView(showPaywall: $showPaywall)
                .tabItem { Label("Settings", systemImage: "gearshape") }
                .tag(Tab.workbox)
        }
        .sheet(isPresented: $showPaywall) { paywall { showPaywall = false } }
        // The book, loose work and the archive are worked over Today and close back to it,
        // so the Today tab only ever holds today's lace — the one everybody has.
        .fullScreenCover(isPresented: Binding(get: { bench.awayFromToday },
                                              set: { if !$0 { bench.backToToday() } })) {
            PillowView(tab: $tab, over: true)
                .sheet(isPresented: $showPaywallOver) { paywall { showPaywallOver = false } }
        }
        .onAppear(perform: start)
        .onChange(of: store.isPro) { _, isPro in bench.isPro = isPro || LaunchOptions.forcePro }
        .onChange(of: bench.wantsPaywall) { _, wants in
            if wants {
                if bench.awayFromToday { showPaywallOver = true } else { showPaywall = true }
                bench.wantsPaywall = false
            }
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { bench.rollDay(); bench.ensurePillow() }
            if phase != .active { bench.saveNow() }
        }
    }

    private func paywall(onDone: @escaping () -> Void) -> some View {
        PaywallView(store: store,
                    config: AppInfo.config,
                    headline: AppInfo.paywallHeadline,
                    bullets: AppInfo.paywallBullets,
                    bulletStyle: .ruled(mark: "●"),
                    promise: AppInfo.paywallPromise,
                    subhead: AppInfo.paywallSubhead,
                    cta: AppInfo.paywallCTA,
                    hero: {
                        Image("Book")
                            .resizable()
                            .scaledToFit()
                            .frame(maxHeight: 190)
                            .ambientFloat(distance: 3, period: 4.4)
                            .accessibilityHidden(true)
                    },
                    onDone: onDone)
    }

    private func start() {
        Tones.shared.warmUp()
        bench.isPro = store.isPro || LaunchOptions.forcePro
        if LaunchOptions.fakeProducts {
            // A scheme's StoreKit configuration is never honoured by a `simctl launch`, so
            // without this the paywall has no product and its button sits disabled.
            store.debugOffers = [
                PaywallOffer(id: AppInfo.unlockID, title: "The Pattern Book",
                             priceText: "$4.99", periodText: nil, trialText: nil),
            ]
        }
        switch LaunchOptions.screen {
        case "sampler": tab = .sampler
        case "book": tab = .book
        case "workbox", "settings": tab = .workbox
        case "paywall": showPaywall = true
        default: tab = .today
        }
        if let demo = LaunchOptions.demo {
            tab = .today
            bench.demo(demo)
        }
    }
}
