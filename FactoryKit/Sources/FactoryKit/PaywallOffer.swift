import StoreKit

/// Display model for a paywall row. Real offers come from StoreKit products; the factory's
/// screenshot tooling injects fake ones through `Store.debugOffers`.
public struct PaywallOffer: Identifiable, Hashable, Sendable {
    public let id: String
    public let title: String
    public let priceText: String
    public let periodText: String?
    public let trialText: String?

    public init(id: String, title: String, priceText: String, periodText: String?, trialText: String?) {
        self.id = id
        self.title = title
        self.priceText = priceText
        self.periodText = periodText
        self.trialText = trialText
    }

    /// A subscription renews; a one-time unlock does not. Drives the auto-renewal disclosure
    /// App Review guideline 3.1.2 requires on the paywall itself.
    public var isSubscription: Bool { periodText != nil }

    public init(product: Product) {
        self.init(id: product.id, title: product.displayName, priceText: product.displayPrice, periodText: product.periodDescription, trialText: product.trialDescription)
    }
}
