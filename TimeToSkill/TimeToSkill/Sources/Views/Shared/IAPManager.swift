import Foundation
import StoreKit
import SwiftUI

@MainActor
final class IAPManager: ObservableObject {
    static let shared = IAPManager()

    // Set your real non-consumable product identifier
    private let productId = "com.gregkaps.timetoskill.pro"

    @Published var isPurchased: Bool = false
    @Published var product: Product?

    private init() {
        Task { [weak self] in
            await self?.loadProduct()
            await self?.refreshEntitlements()
            await self?.observeTransactions()
        }
    }

    var displayPrice: String? {
        product?.displayPrice
    }

    func loadProduct() async {
        do {
            let products = try await Product.products(for: [productId])
            self.product = products.first
        } catch {
            // Ignore transient errors; UI can retry via pull-to-refresh or re-open
        }
    }

    func purchase() async {
        guard let product else { return }
        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                if case .verified(let transaction) = verification {
                    await apply(transaction)
                    await transaction.finish()
                }
            case .userCancelled, .pending:
                break
            @unknown default:
                break
            }
        } catch {
            // Surface error in UI if needed
        }
    }

    func restorePurchases() async {
        do {
            try await AppStore.sync()
        } catch {
            // Surface error in UI if needed
        }
    }

    private func observeTransactions() async {
        for await update in StoreKit.Transaction.updates {
            if case .verified(let transaction) = update {
                await apply(transaction)
                await transaction.finish()
            }
        }
    }

    private func refreshEntitlements() async {
        for await entitlement in StoreKit.Transaction.currentEntitlements {
            if case .verified(let transaction) = entitlement {
                await apply(transaction)
            }
        }
    }

    private func apply(_ transaction: StoreKit.Transaction) async {
        if transaction.productID == productId {
            isPurchased = true
        }
    }
}


