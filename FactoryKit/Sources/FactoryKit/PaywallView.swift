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

                    HStack(spacing: 16) {
                        Button("Restore purchases") { Task { await store.restore(); if store.isPro { onDone() } } }
                        Spacer()
                        Link("Terms", destination: config.termsURL)
                        Link("Privacy", destination: config.privacyURL)
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
