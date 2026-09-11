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
            extra
            Section {
                Button { requestReview() } label: { Label("Rate \(config.name)", systemImage: "star") }
                if let url = config.appStoreURL {
                    ShareLink(item: url) { Label("Share \(config.name)", systemImage: "square.and.arrow.up") }
                }
                Link(destination: config.supportURL) { Label("Support", systemImage: "questionmark.circle") }
            }
            Section {
                Link("Privacy policy", destination: config.privacyURL)
                Link("Terms of use", destination: config.termsURL)
            } footer: {
                Text("\(config.name) \(config.version)")
            }
        }
        .navigationTitle("Settings")
    }
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
