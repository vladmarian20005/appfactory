import StoreKit
import SwiftUI

/// Subscription paywall driven by `Store`. Present as a sheet; call `onDone` when the user
/// buys or closes.
public struct PaywallView: View {
    @ObservedObject var store: Store
    let config: AppConfig
    let headline: String
    let bullets: [String]
    let onDone: () -> Void

    @State private var selected: Product?
    @State private var busy = false
    @State private var message: String?

    public init(store: Store, config: AppConfig, headline: String, bullets: [String], onDone: @escaping () -> Void) {
        self.store = store
        self.config = config
        self.headline = headline
        self.bullets = bullets
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

                    if store.isLoading && store.products.isEmpty {
                        ProgressView().frame(maxWidth: .infinity)
                    } else if store.products.isEmpty {
                        Text(store.lastError ?? "Products are not available right now.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    } else {
                        VStack(spacing: 10) {
                            ForEach(store.products, id: \.id) { p in
                                productRow(p)
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
            .onAppear { if selected == nil { selected = store.products.last } }
            .onChange(of: store.products) { _, new in if selected == nil { selected = new.last } }
        }
    }

    private var ctaTitle: String {
        if let selected, let trial = selected.trialDescription { return "Start \(trial)" }
        return "Continue"
    }

    @ViewBuilder
    private func productRow(_ p: Product) -> some View {
        let isSelected = selected?.id == p.id
        Button {
            Haptics.tap()
            selected = p
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(p.displayName).font(.headline)
                    if let trial = p.trialDescription {
                        Text("\(trial), then \(p.displayPrice) \(p.periodDescription ?? "")")
                            .font(.footnote).foregroundStyle(.secondary)
                    } else {
                        Text("\(p.displayPrice) \(p.periodDescription ?? "one time")")
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
        busy = true
        defer { busy = false }
        do {
            if try await store.purchase(selected) {
                Haptics.success()
                onDone()
            }
        } catch {
            message = error.localizedDescription
            Haptics.warning()
        }
    }
}
