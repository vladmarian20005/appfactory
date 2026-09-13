import Foundation
import StoreKit

/// StoreKit 2 wrapper: products, purchase, restore, live entitlements.
/// Works against a local .storekit configuration on the simulator and against App Store Connect in production.
@MainActor
public final class Store: ObservableObject {
    @Published public private(set) var products: [Product] = []
    @Published public private(set) var purchasedIDs: Set<String> = []
    @Published public private(set) var isLoading = false
    @Published public private(set) var lastError: String?
    /// When set, the paywall shows these instead of real products. Screenshot tooling only.
    @Published public var debugOffers: [PaywallOffer]?

    public var offers: [PaywallOffer] { debugOffers ?? products.map(PaywallOffer.init(product:)) }

    public func product(for offer: PaywallOffer) -> Product? { products.first { $0.id == offer.id } }

    public var isPro: Bool { !purchasedIDs.isEmpty }

    private let ids: [String]
    private var updates: Task<Void, Never>?

    public init(productIDs: [String]) {
        ids = productIDs
        updates = listenForTransactions()
        Task { await load() }
    }

    deinit { updates?.cancel() }

    public func load() async {
        isLoading = true
        defer { isLoading = false }
        do {
            products = try await Product.products(for: ids).sorted { $0.price < $1.price }
            lastError = nil
        } catch {
            products = []
            lastError = error.localizedDescription
        }
        await refreshEntitlements()
    }

    /// Returns true when the purchase completed.
    @discardableResult
    public func purchase(_ product: Product) async throws -> Bool {
        let result = try await product.purchase()
        switch result {
        case .success(let verification):
            let transaction = try checked(verification)
            await transaction.finish()
            await refreshEntitlements()
            return true
        case .userCancelled, .pending:
            return false
        @unknown default:
            return false
        }
    }

    public func restore() async {
        try? await AppStore.sync()
        await refreshEntitlements()
    }

    public func refreshEntitlements() async {
        var ids = Set<String>()
        for await result in Transaction.currentEntitlements {
            if case .verified(let t) = result, t.revocationDate == nil {
                ids.insert(t.productID)
            }
        }
        purchasedIDs = ids
    }

    private func checked<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .verified(let value): return value
        case .unverified(_, let error): throw error
        }
    }

    private func listenForTransactions() -> Task<Void, Never> {
        Task.detached { [weak self] in
            for await result in Transaction.updates {
                if case .verified(let t) = result {
                    await t.finish()
                    await self?.refreshEntitlements()
                }
            }
        }
    }
}

public extension Product {
    /// "3-day free trial" when the product carries a free introductory offer.
    var trialDescription: String? {
        guard let offer = subscription?.introductoryOffer, offer.paymentMode == .freeTrial,
              let length = PeriodLength(offer.period) else { return nil }
        return "\(length.adjective) free trial"
    }

    /// "per week", "per year", nil for one-time products.
    var periodDescription: String? {
        guard let sub = subscription, let length = PeriodLength(sub.subscriptionPeriod) else { return nil }
        return length.perPeriod
    }
}

/// How long a subscription period or trial lasts, in the unit a person would name it.
///
/// The App Store reports a weekly subscription as seven days, not one week. A local
/// `.storekit` file reports one week, so the simulator and every screenshot read "per week"
/// while Quizday's first TestFlight build read "$2.99 per day", on the paywall and in the
/// renewal terms under it. Whole weeks of days fold back into weeks here, and every unit
/// carries its count, so no period can print as a single day, week, month or year it is not.
struct PeriodLength: Equatable {
    enum Unit: String { case day, week, month, year }

    let count: Int
    let unit: Unit

    init(count: Int, unit: Unit) {
        if unit == .day, count >= 7, count % 7 == 0 {
            self.count = count / 7
            self.unit = .week
        } else {
            self.count = count
            self.unit = unit
        }
    }

    init?(_ period: Product.SubscriptionPeriod) {
        switch period.unit {
        case .day: self.init(count: period.value, unit: .day)
        case .week: self.init(count: period.value, unit: .week)
        case .month: self.init(count: period.value, unit: .month)
        case .year: self.init(count: period.value, unit: .year)
        @unknown default: return nil
        }
    }

    /// "per week", "per 2 months".
    var perPeriod: String { count == 1 ? "per \(unit.rawValue)" : "per \(count) \(unit.rawValue)s" }

    /// "3-day", "1-week". A compound adjective takes the singular, so never "3-days free trial".
    var adjective: String { "\(count)-\(unit.rawValue)" }
}
