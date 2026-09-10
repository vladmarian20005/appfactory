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

/// Screen 1 of 3. Replace the body with the feature from SPEC.md; keep the Pro gate pattern.
struct HomeView: View {
    @EnvironmentObject private var store: Store
    @Binding var showPaywall: Bool
    @State private var items: [String] = ["First thing", "Second thing", "Third thing"]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Today").font(.largeTitle.bold())
                    Text(store.isPro ? "Pro is active." : "Free plan. Three items, then Pro.")
                        .foregroundStyle(.secondary)
                }
                ForEach(items, id: \.self) { item in
                    NavigationLink(value: item) {
                        HStack {
                            Image(systemName: "circle").foregroundStyle(Color.accentColor)
                            Text(item)
                            Spacer()
                            Image(systemName: "chevron.right").foregroundStyle(.tertiary)
                        }
                        .factoryCard()
                    }
                    .buttonStyle(.plain)
                }
                Button {
                    if store.isPro || items.count < 3 {
                        Haptics.tap()
                        items.append("Thing \(items.count + 1)")
                    } else {
                        showPaywall = true
                    }
                } label: {
                    Label("Add", systemImage: "plus")
                }
                .buttonStyle(.factoryPrimary)
            }
            .padding(FactoryTheme.padding)
        }
        .background(Color(.systemGroupedBackground))
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
