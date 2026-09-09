import StoreKit
import SwiftUI

/// Subscription paywall driven by `Store`. Present as a sheet; call `onDone` when the user
/// buys or closes.
public struct PaywallView: View {
    @ObservedObject var store: Store
    let config: AppConfig
    let headline: String
    let bullets: [String]
    let promise: String?
    let onDone: () -> Void

    @State private var selected: PaywallOffer?
    @State private var busy = false
    @State private var message: String?

    public init(store: Store, config: AppConfig, headline: String, bullets: [String], promise: String? = nil, onDone: @escaping () -> Void) {
        self.store = store
        self.config = config
        self.headline = headline
        self.bullets = bullets
        self.promise = promise
        self.onDone = onDone
    }

    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(headline)
                            .font(.largeTitle.bold())
                        Text("Unlock everything in \(config.name).")
                            .foregroundStyle(.secondary)
                    }
                    VStack(alignment: .leading, spacing: 12) {
                        ForEach(bullets, id: \.self) { b in
                            Label(b, systemImage: "checkmark.circle.fill")
                                .symbolRenderingMode(.hierarchical)
                                .foregroundStyle(.primary)
                        }
                    }
                    .factoryCard()

                    if let promise {
                        Label(promise, systemImage: "hand.raised.fill")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }

                    if store.isLoading && store.offers.isEmpty {
                        ProgressView().frame(maxWidth: .infinity)
                    } else if store.offers.isEmpty {
                        Text(store.lastError ?? "Products are not available right now.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    } else {
                        VStack(spacing: 10) {
                            ForEach(store.offers) { o in
                                offerRow(o)
                            }
                        }
                    }

                    Button {
                        Task { await buy() }
                    } label: {
                        if busy { ProgressView().tint(.white) } else { Text(ctaTitle) }
                    }
                    .buttonStyle(.factoryPrimary)
                    .disabled(busy || selected == nil)

                    if let message {
                        Text(message).font(.footnote).foregroundStyle(.secondary)
                    }

                    // App Review guideline 3.1.2 wants the renewal terms on the paywall
                    // itself, not only in the App Store description. Missing this is one of
                    // the most common subscription rejections.
                    if let renewalDisclosure {
                        Text(renewalDisclosure)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                            .accessibilityLabel("Subscription terms. \(renewalDisclosure)")
                    }

                    // A plain VStack rather than one HStack: at accessibility text sizes four
                    // items in a row overlap, and these links have to stay reachable.
                    VStack(alignment: .leading, spacing: 10) {
                        Button("Restore purchases") { Task { await store.restore(); if store.isPro { onDone() } } }
                        HStack(spacing: 16) {
                            Link("Terms of use", destination: config.termsURL)
                            Link("Privacy policy", destination: config.privacyURL)
                            Spacer(minLength: 0)
                        }
                        if store.isPro {
                            Link("Manage subscription", destination: Self.manageSubscriptionsURL)
                        }
                    }
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                }
                .padding(FactoryTheme.padding)
            }
            .background(Color(.systemGroupedBackground))
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button { onDone() } label: { Image(systemName: "xmark") }
                        .accessibilityLabel("Close")
                }
            }
            .onAppear { if selected == nil { selected = store.offers.last } }
            .onChange(of: store.offers) { _, new in if selected == nil { selected = new.last } }
        }
    }

    private var ctaTitle: String {
        if let selected, let trial = selected.trialText { return "Start \(trial)" }
        return "Continue"
    }

    /// Where iOS sends a customer to cancel. Opens the App Store's subscription settings.
    static let manageSubscriptionsURL = URL(string: "https://apps.apple.com/account/subscriptions")!

    /// The renewal terms App Review expects to see before the customer buys. Nil for a
    /// one-time unlock, which does not renew and must not claim to.
    private var renewalDisclosure: String? {
        guard let selected, selected.isSubscription else { return nil }
        var parts: [String] = []
        if let period = selected.periodText {
            parts.append("\(selected.title) is \(selected.priceText) \(period) and renews automatically.")
        } else {
            parts.append("\(selected.title) renews automatically.")
        }
        if selected.trialText != nil {
            parts.append("Any unused part of a free trial is forfeited when you buy a subscription.")
        }
        parts.append(
            "Payment is charged to your Apple Account at confirmation of purchase. "
            + "Your account is charged for renewal within 24 hours before the current period ends, "
            + "unless you cancel at least 24 hours before then. "
            + "Manage and cancel subscriptions in your Apple Account settings."
        )
        return parts.joined(separator: " ")
    }

    @ViewBuilder
    private func offerRow(_ o: PaywallOffer) -> some View {
        let isSelected = selected?.id == o.id
        Button {
            Haptics.tap()
            selected = o
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(o.title).font(.headline)
                    if let trial = o.trialText {
                        Text("\(trial), then \(o.priceText) \(o.periodText ?? "")")
                            .font(.footnote).foregroundStyle(.secondary)
                    } else {
                        Text("\(o.priceText) \(o.periodText ?? "one time")")
                            .font(.footnote).foregroundStyle(.secondary)
                    }
                }
                Spacer()
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(isSelected ? Color.accentColor : Color.secondary)
                    .font(.title3)
            }
            .padding(16)
            .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(isSelected ? Color.accentColor : .clear, lineWidth: 2))
        }
        .buttonStyle(.plain)
    }

    private func buy() async {
        guard let selected else { return }
        guard let product = store.product(for: selected) else {
            message = "Purchases are only available in the App Store build."
            return
        }
        busy = true
        defer { busy = false }
        do {
            if try await store.purchase(product) {
                Haptics.success()
                onDone()
            }
        } catch {
            message = error.localizedDescription
            Haptics.warning()
        }
    }
}
