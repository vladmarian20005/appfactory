import StoreKit
import SwiftUI

/// Standard settings screen: plan status, restore, rate, share, support, legal, version.
public struct SettingsView<Extra: View>: View {
    @ObservedObject var store: Store
    let config: AppConfig
    let onUpgrade: () -> Void
    /// What the paid tier is called in this app. An app whose purchase is a one-time unlock
    /// must not offer to "Upgrade to Pro" — the row would name something it does not sell.
    let upgradeTitle: String
    let activeTitle: String
    let extra: Extra

    @Environment(\.requestReview) private var requestReview
    @Environment(\.brand) private var brand

    public init(store: Store,
                config: AppConfig,
                onUpgrade: @escaping () -> Void,
                upgradeTitle: String = "Upgrade to Pro",
                activeTitle: String = "Pro is active",
                @ViewBuilder extra: () -> Extra) {
        self.store = store
        self.config = config
        self.onUpgrade = onUpgrade
        self.upgradeTitle = upgradeTitle
        self.activeTitle = activeTitle
        self.extra = extra()
    }

    public var body: some View {
        List {
            Section {
                if store.isPro {
                    Label(activeTitle, systemImage: "checkmark.seal.fill").foregroundStyle(Color.accentColor)
                } else {
                    Button { onUpgrade() } label: { Label(upgradeTitle, systemImage: "sparkles") }
                }
                Button("Restore purchases") { Task { await store.restore() } }
            }
            .listRowBackground(rows)
            extra
                .listRowBackground(rows)
            Section {
                Button { requestReview() } label: { Label("Rate \(config.name)", systemImage: "star") }
                if let url = config.appStoreURL {
                    ShareLink(item: url) { Label("Share \(config.name)", systemImage: "square.and.arrow.up") }
                }
                Link(destination: config.supportURL) { Label("Support", systemImage: "questionmark.circle") }
            }
            .listRowBackground(rows)
            Section {
                Link("Privacy policy", destination: config.privacyURL)
                Link("Terms of use", destination: config.termsURL)
            } footer: {
                Text("\(config.name) \(config.version)")
            }
            .listRowBackground(rows)
        }
        .brandBackground()
        .navigationTitle("Settings")
    }

    /// The List stays the system's — it is chrome, and chrome should be — but its rows take
    /// the brand's surface rather than the system's white. Without this every app's Settings
    /// is white rounded cards on whatever canvas its direction spent itself on, which is the
    /// first slop tell in TASTE.md, shipped by the kit itself. An app that has not set a
    /// brand is unchanged: `factoryDefault`'s surface *is* the system's row colour.
    ///
    /// It has to sit on the sections, not on the `List`: outside the list it sets the
    /// background of the row the list is in, which is nothing, and does so silently.
    private var rows: Color { brand.palette.surface }
}

public extension SettingsView where Extra == EmptyView {
    init(store: Store,
         config: AppConfig,
         onUpgrade: @escaping () -> Void,
         upgradeTitle: String = "Upgrade to Pro",
         activeTitle: String = "Pro is active") {
        self.init(store: store,
                  config: config,
                  onUpgrade: onUpgrade,
                  upgradeTitle: upgradeTitle,
                  activeTitle: activeTitle) { EmptyView() }
    }
}
