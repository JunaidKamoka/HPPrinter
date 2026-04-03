import StoreKit
import Foundation

@MainActor
final class SubscriptionService: ObservableObject {

    static let shared = SubscriptionService()

    // MARK: - Product IDs
    static let weeklyID  = "hp.smart.printer.app.ac.weekly"
    static let monthlyID = "hp.smart.printer.app.ac.monthly"
    private let allIDs: [String] = [weeklyID, monthlyID]

    // MARK: - Published State
    @Published var products: [Product] = []
    @Published var purchasedIDs: Set<String> = []
    @Published var isLoading = false
    @Published var purchaseError: String? = nil
    @Published var didRestoreSuccessfully = false

    // MARK: - Computed
    var isPremium: Bool { !purchasedIDs.isEmpty }

    var weeklyProduct:  Product? { products.first { $0.id == Self.weeklyID  } }
    var monthlyProduct: Product? { products.first { $0.id == Self.monthlyID } }

    private var transactionListenerTask: Task<Void, Error>?

    // MARK: - Init
    private init() {
        transactionListenerTask = listenForTransactions()
    }

    deinit { transactionListenerTask?.cancel() }

    // MARK: - Load products from App Store

    func loadProducts() async {
        NSLog("[Sub] ── loadProducts() ──")
        NSLog("[Sub]   requested IDs: %@", allIDs.joined(separator: ", "))
        guard products.isEmpty else {
            NSLog("[Sub]   products already loaded (%d), refreshing entitlements...", products.count)
            await refreshEntitlements(); return
        }
        isLoading = true
        defer { isLoading = false }
        do {
            let fetched = try await Product.products(for: allIDs)
            NSLog("[Sub]   fetched %d products from App Store", fetched.count)
            for p in fetched {
                NSLog("[Sub]     → %@ | %@ | trial=%@", p.id, p.displayPrice,
                      hasFreeTrial(for: p) ? "\(trialDays(for: p) ?? 0)d" : "none")
            }
            // preserve declared order
            products = allIDs.compactMap { id in fetched.first { $0.id == id } }
            NSLog("[Sub]   ordered products: %d", products.count)
            await refreshEntitlements()
        } catch {
            NSLog("[Sub]   ❌ loadProducts error: %@", error.localizedDescription)
        }
    }

    // MARK: - Purchase

    func purchase(_ product: Product) async -> Bool {
        NSLog("[Sub] ── purchase() ──")
        NSLog("[Sub]   product: %@", product.id)
        NSLog("[Sub]   price: %@", product.displayPrice)
        isLoading = true
        purchaseError = nil
        defer { isLoading = false }
        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                NSLog("[Sub]   ✅ Purchase SUCCESS")
                let tx = try verified(verification)
                await tx.finish()
                await refreshEntitlements()
                NSLog("[Sub]   isPremium after purchase: %@", isPremium ? "YES" : "NO")
                return true
            case .userCancelled:
                NSLog("[Sub]   ❌ User CANCELLED purchase")
                return false
            case .pending:
                NSLog("[Sub]   ⏳ Purchase PENDING (ask to buy / payment processing)")
                return false
            @unknown default:
                NSLog("[Sub]   ⚠️ Unknown purchase result")
                return false
            }
        } catch {
            NSLog("[Sub]   ❌ Purchase ERROR: %@", error.localizedDescription)
            purchaseError = error.localizedDescription
            return false
        }
    }

    // MARK: - Restore

    func restorePurchases() async {
        NSLog("[Sub] ── restorePurchases() ──")
        isLoading = true
        purchaseError = nil
        didRestoreSuccessfully = false
        defer { isLoading = false }
        do {
            try await AppStore.sync()
            await refreshEntitlements()
            didRestoreSuccessfully = isPremium
            NSLog("[Sub]   restore result — isPremium: %@", isPremium ? "YES" : "NO")
        } catch {
            NSLog("[Sub]   ❌ Restore ERROR: %@", error.localizedDescription)
            purchaseError = error.localizedDescription
        }
    }

    // MARK: - Refresh Entitlements

    func refreshEntitlements() async {
        var active = Set<String>()
        for await result in Transaction.currentEntitlements {
            guard let tx = try? verified(result),
                  tx.revocationDate == nil else { continue }
            active.insert(tx.productID)
        }
        purchasedIDs = active
        NSLog("[Sub] refreshEntitlements — purchasedIDs: %@", active.isEmpty ? "NONE (free user)" : active.joined(separator: ", "))
        NSLog("[Sub]   isPremium: %@", isPremium ? "YES" : "NO")
    }

    // MARK: - Transaction Listener

    private func listenForTransactions() -> Task<Void, Error> {
        Task.detached { [weak self] in
            for await result in Transaction.updates {
                await MainActor.run { [weak self] in
                    guard let self else { return }
                    Task {
                        if let tx = try? self.verified(result) {
                            await tx.finish()
                            await self.refreshEntitlements()
                        }
                    }
                }
            }
        }
    }

    // MARK: - Verify

    private func verified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified(_, let e): throw e
        case .verified(let v):      return v
        }
    }

    // MARK: - Trial Helpers (reads data from the product returned by App Store)

    func trialDays(for product: Product) -> Int? {
        guard let offer = product.subscription?.introductoryOffer,
              offer.paymentMode == .freeTrial else { return nil }
        let p = offer.period
        switch p.unit {
        case .day:   return p.value
        case .week:  return p.value * 7
        case .month: return p.value * 30
        case .year:  return p.value * 365
        @unknown default: return nil
        }
    }

    func hasFreeTrial(for product: Product) -> Bool {
        trialDays(for: product) != nil
    }

    /// CTA label driven entirely by server data
    func ctaLabel(selectedProduct: Product?) -> String {
        guard let p = selectedProduct else { return "Start Free Trial" }
        if let days = trialDays(for: p) {
            return "Start \(days)-Day Free Trial"
        }
        return "Subscribe – \(p.displayPrice)"
    }

    /// Sub-label under button (trial → "then X/period", else empty)
    func subLabel(for product: Product) -> String? {
        guard let days = trialDays(for: product) else { return nil }
        return "Free for \(days) days, then \(product.displayPrice)"
    }

    /// Per-period price string, e.g. "$3.99/wk" or "$19.99/yr"
    func periodLabel(for product: Product) -> String {
        guard let sub = product.subscription else { return product.displayPrice }
        let unit: String
        switch sub.subscriptionPeriod.unit {
        case .day:   unit = "day"
        case .week:  unit = "wk"
        case .month: unit = "mo"
        case .year:  unit = "yr"
        @unknown default: unit = "period"
        }
        return "\(product.displayPrice)/\(unit)"
    }
}
