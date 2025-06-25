//
//  PaymentManager.swift
//  ShowThat
//
//  Created by Giuseppe De Masi on 25/06/2025.
//

import Foundation
import StoreKit
import FirebaseAuth
import FirebaseFirestore

class PaymentManager: NSObject, ObservableObject {
    static let shared = PaymentManager()
    
    // MARK: - Product Identifiers
    enum ProductID: String, CaseIterable {
        case pro = "com.showthat.subscription.pro"
        case business = "com.showthat.subscription.business"
        case enterprise = "com.showthat.subscription.enterprise"
        
        var tier: UserSubscription.Tier {
            switch self {
            case .pro: return .pro
            case .business: return .business
            case .enterprise: return .enterprise
            }
        }
        
        static func from(tier: UserSubscription.Tier) -> ProductID? {
            switch tier {
            case .free: return nil
            case .pro: return .pro
            case .business: return .business
            case .enterprise: return .enterprise
            }
        }
    }
    
    // MARK: - Published Properties
    @Published var products: [Product] = []
    @Published var purchasedSubscriptions: [Product] = []
    @Published var subscriptionGroupStatus: Product.SubscriptionInfo.RenewalState?
    @Published var isLoading = false
    @Published var purchaseError: Error?
    
    private var productsLoaded = false
    private var updates: Task<Void, Never>? = nil
    
    override init() {
        super.init()
        
        updates = observerTransactionUpdates()
        
        Task {
            await loadProducts()
            await updatePurchasedProducts()
        }
    }
    
    deinit {
        updates?.cancel()
    }
    
    // MARK: - Product Loading
    @MainActor
    func loadProducts() async {
        guard !productsLoaded else { return }
        
        isLoading = true
        
        do {
            let productIDs = ProductID.allCases.map { $0.rawValue }
            products = try await Product.products(for: productIDs)
            productsLoaded = true
            
            print("Loaded \(products.count) products")
        } catch {
            print("Failed to load products: \(error)")
            purchaseError = error
        }
        
        isLoading = false
    }
    
    @MainActor
    func purchase(_ product: Product) async throws {
        isLoading = true
        defer { isLoading = false }
        
        let result = try await product.purchase()
        
        switch result {
        case .success(let verification):
            // Verify the transaction
            let transaction = try checkVerifier(verification)
            
            // Update subscription in Firebase
            await updateSubscriptionStatus(for: transaction)
            
            // Always finish transactions
            await transaction.finish()
            
            // Update local state
            await updatePurchasedProducts()
            
        case .userCancelled:
            print("User cancelled purchase")
            throw PurchaseError.userCancelled
            
        case .pending:
            print("Purchase pending")
            throw PurchaseError.pending
            
        @unknown default:
            throw PurchaseError.unknown
        }
    }
    
    @MainActor
    func restorePurchases() async throws {
        isLoading = true
        defer { isLoading = false }
        
        try await AppStore.sync()
        
        await updatePurchasedProducts()
        
        if purchasedSubscriptions.isEmpty {
            throw PurchaseError.noPurchasesToRestore
        }
    }
    
    // MARK: - Transaction Observation
    private func observerTransactionUpdates() -> Task<Void, Never> {
        Task(priority: .background) {
            for await verificationResult in Transaction.updates {
                do {
                    let transaction = try checkVerifier(verificationResult)
                    
                    await updateSubscriptionStatus(for: transaction)
                    
                    await transaction.finish()
                    await updatePurchasedProducts()
                } catch {
                    print("Transaction verification failed: \(error)")
                }
            }
        }
    }
    
    // MARK: - Verification
    func checkVerifier<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified(_, let error):
            throw error
        case .verified(let safe):
            return safe
        }
    }
    
    @MainActor
    private func updatePurchasedProducts() async {
        var purchased: [Product] = []
        
        // check current entitlements
        for await result in Transaction.currentEntitlements {
            do {
                let transaction = try checkVerifier(result)
                
                if let product = products.first(where: { $0.id == transaction.productID }) {
                    purchased.append(product)
                }
            } catch {
                print("[-] Failed to verify transaction: \(error)")
            }
        }
        
        self.purchasedSubscriptions = purchased
        
        // update subscription group status
        let statuses = try? await Product.SubscriptionInfo.status(for: "com.showthat.subscriptions")
        self.subscriptionGroupStatus = statuses?.first?.state
    }
    
    private func updateSubscriptionStatus(for transaction: StoreKit.Transaction) async {
        guard let userId = Auth.auth().currentUser?.uid,
              let productId = ProductID(rawValue: transaction.productID) else { return }
        
        let db = Firestore.firestore()
        // get subscription end date
        let endDate: Date?
        if let expirationDate = transaction.expirationDate {
            endDate = expirationDate
        } else {
            endDate = Calendar.current.date(byAdding: .year, value: 100, to: Date())
        }
        
        // subscription object
        let subscription = UserSubscription(
            tier: productId.tier,
            startDate: transaction.purchaseDate,
            endDate: endDate,
            isActive: transaction.revocationDate == nil,
            subscriptionId: String(transaction.id),
            customerId: nil
        )
        
        // update firestore
        do {
            let data: [String: Any] = [
                "subscription": try Firestore.Encoder().encode(subscription),
                "updatedAt": FieldValue.serverTimestamp()
            ]
            
            _ = db.collection("users").document(userId).updateData(data)
            
            print("[+] Updated subscription status for user: \(userId)")
        } catch {
            print("[-] Failed to update subscription in Firestore: \(error)")
        }
    }
    
    // MARK: - Helper Methods
    func product(for tier: UserSubscription.Tier) -> Product? {
        guard let productID = ProductID.from(tier: tier) else { return nil }
        return products.first { $0.id == productID.rawValue }
    }
    
    func isSubscribed(to tier: UserSubscription.Tier) -> Bool {
        guard let productID = ProductID.from(tier: tier) else { return false }
        return purchasedSubscriptions.contains { $0.id == productID.rawValue }
    }
    
    var currentSubscription: UserSubscription.Tier? {
        if isSubscribed(to: .enterprise) { return .enterprise }
        if isSubscribed(to: .business) { return .business }
        if isSubscribed(to: .pro) { return .pro }
        return nil
    }
    
    var hasActiveSubscription: Bool {
        return !purchasedSubscriptions.isEmpty && subscriptionGroupStatus != .expired && subscriptionGroupStatus != .revoked
    }
    
    var isSubscriptionExpired: Bool {
        return subscriptionGroupStatus == .expired
    }
    
    var isSubscriptionInBillingRetry: Bool {
        return subscriptionGroupStatus == .inBillingRetryPeriod
    }
    
    var isSubscriptionInGracePeriod: Bool {
        return subscriptionGroupStatus == .inGracePeriod
    }
    
    // MARK: - Price formatting
    func formattedPrice(for product: Product) -> String {
        product.displayPrice
    }
}
