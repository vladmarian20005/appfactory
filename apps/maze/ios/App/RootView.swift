import FactoryKit
import SwiftUI

struct RootView: View {
    @EnvironmentObject private var store: Store
    @EnvironmentObject private var bench: Bench
    @Environment(\.scenePhase) private var scenePhase
    @State private var tab: Tab = .pillow
    @State private var showPaywall = false

    enum Tab: String { case pillow, sampler, book, workbox }

    var body: some View {
        TabView(selection: $tab) {
            PillowView()
                .tabItem { Label("Pillow", systemImage: "square.grid.3x3.topleft.filled") }
                .tag(Tab.pillow)
            SamplerView(tab: $tab)
                .tabItem { Label("Sampler", systemImage: "square.grid.2x2") }
                .tag(Tab.sampler)
            BookView(tab: $tab, showPaywall: $showPaywall)
                .tabItem { Label("Book", systemImage: "book.closed") }
                .tag(Tab.book)
            WorkboxView(showPaywall: $showPaywall)
                .tabItem { Label("Workbox", systemImage: "shippingbox") }
                .tag(Tab.workbox)
        }
        .sheet(isPresented: $showPaywall) {
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
                        onDone: { showPaywall = false })
        }
        .onAppear(perform: start)
        .onChange(of: store.isPro) { _, isPro in bench.isPro = isPro || LaunchOptions.forcePro }
        .onChange(of: bench.wantsPaywall) { _, wants in
            if wants {
                showPaywall = true
                bench.wantsPaywall = false
            }
        }
        .onChange(of: bench.which) { _, _ in tab = .pillow }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { bench.rollDay(); bench.ensurePillow() }
            if phase != .active { bench.saveNow() }
        }
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
        default: tab = .pillow
        }
        if let demo = LaunchOptions.demo {
            tab = .pillow
            bench.demo(demo)
        }
    }
}
