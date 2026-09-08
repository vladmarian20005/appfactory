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
        guard let offer = subscription?.introductoryOffer, offer.paymentMode == .freeTrial else { return nil }
        let p = offer.period
        let unit: String
        switch p.unit {
        case .day: unit = p.value == 1 ? "day" : "days"
        case .week: unit = p.value == 1 ? "week" : "weeks"
        case .month: unit = p.value == 1 ? "month" : "months"
        case .year: unit = p.value == 1 ? "year" : "years"
        @unknown default: unit = "days"
        }
        return "\(p.value)-\(unit) free trial"
    }

    /// "per week", "per year", nil for one-time products.
    var periodDescription: String? {
        guard let sub = subscription else { return nil }
        switch sub.subscriptionPeriod.unit {
        case .day: return "per day"
        case .week: return "per week"
        case .month: return sub.subscriptionPeriod.value == 1 ? "per month" : "per \(sub.subscriptionPeriod.value) months"
        case .year: return "per year"
        @unknown default: return nil
        }
    }
}
