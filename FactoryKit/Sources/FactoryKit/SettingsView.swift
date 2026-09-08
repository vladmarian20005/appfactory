import StoreKit
import SwiftUI

/// Standard settings screen: plan status, restore, rate, share, support, legal, version.
public struct SettingsView<Extra: View>: View {
    @ObservedObject var store: Store
    let config: AppConfig
    let onUpgrade: () -> Void
    let extra: Extra

    @Environment(\.requestReview) private var requestReview

    public init(store: Store, config: AppConfig, onUpgrade: @escaping () -> Void, @ViewBuilder extra: () -> Extra) {
        self.store = store
        self.config = config
        self.onUpgrade = onUpgrade
        self.extra = extra()
    }

    public var body: some View {
        List {
            Section {
                if store.isPro {
                    Label("Pro is active", systemImage: "checkmark.seal.fill").foregroundStyle(Color.accentColor)
                } else {
                    Button { onUpgrade() } label: { Label("Upgrade to Pro", systemImage: "sparkles") }
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
    init(store: Store, config: AppConfig, onUpgrade: @escaping () -> Void) {
        self.init(store: store, config: config, onUpgrade: onUpgrade) { EmptyView() }
    }
}
