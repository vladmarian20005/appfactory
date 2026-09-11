import FactoryKit
import SwiftUI

struct RootView: View {
    @EnvironmentObject private var store: Store
    @State private var showPaywall = false

    var body: some View {
        TabView {
            NavigationStack {
                HomeView(showPaywall: $showPaywall)
            }
            .tabItem { Label("Home", systemImage: "house.fill") }

            NavigationStack {
                SettingsView(store: store, config: AppInfo.config, onUpgrade: { showPaywall = true })
            }
            .tabItem { Label("Settings", systemImage: "gearshape.fill") }
        }
        .sheet(isPresented: $showPaywall) {
            PaywallView(store: store, config: AppInfo.config, headline: AppInfo.paywallHeadline, bullets: AppInfo.paywallBullets) {
                showPaywall = false
            }
        }
    }
}

/// Screen 1 of 3. Replace the body with the feature from SPEC.md, in the look DESIGN.md
/// describes; keep the Pro gate pattern. The brand calls below are the pattern to keep:
/// canvas, surfaces, display type and the prominent action all come from `AppBrand`.
struct HomeView: View {
    @EnvironmentObject private var store: Store
    @Environment(\.brand) private var brand
    @Binding var showPaywall: Bool
    @State private var items: [String] = ["First thing", "Second thing", "Third thing"]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Today")
                        .brandFont(.largeTitle)
                        .foregroundStyle(brand.palette.ink)
                    Text(store.isPro ? "Pro is active." : "Free plan. Three items, then Pro.")
                        .foregroundStyle(brand.palette.inkSoft)
                }
                ForEach(Array(items.enumerated()), id: \.element) { i, item in
                    NavigationLink(value: item) {
                        HStack {
                            Image(systemName: "circle").foregroundStyle(brand.palette.accent)
                            Text(item).foregroundStyle(brand.palette.ink)
                            Spacer()
                            Image(systemName: "chevron.right").foregroundStyle(brand.palette.inkSoft)
                        }
                        .brandSurface()
                    }
                    .buttonStyle(.pressable)
                    .popIn(delay: 0.05 * Double(i))
                }
                Button {
                    if store.isPro || items.count < 3 {
                        Haptics.tap()
                        withMotion(Motion.bouncy) { items.append("Thing \(items.count + 1)") }
                    } else {
                        showPaywall = true
                    }
                } label: {
                    Label("Add", systemImage: "plus")
                        .frame(maxWidth: .infinity)
                }
                .brandProminent()
            }
            .padding(FactoryTheme.padding)
        }
        .brandBackground()
        .navigationDestination(for: String.self) { DetailView(title: $0) }
    }
}

/// Screen 2 of 3.
struct DetailView: View {
    let title: String
    var body: some View {
        List {
            Section("Detail") {
                Text(title)
                Text("Replace with the detail screen from SPEC.md.").foregroundStyle(.secondary)
            }
        }
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
    }
}
