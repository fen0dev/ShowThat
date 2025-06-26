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
import FirebaseAnalytics

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
    private let db = Firestore.firestore()
    
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
            
            // Log to Firebase Analytics
            Analytics.logEvent("products_loaded", parameters: [
                "product_count": products.count
            ])
        } catch {
            print("Failed to load products: \(error)")
            purchaseError = error
            
            Analytics.logEvent("products_load_failed", parameters: [
                "error": error.localizedDescription
            ])
        }
        
        isLoading = false
    }
    
    @MainActor
    func purchase(_ product: Product) async throws {
        isLoading = true
        defer { isLoading = false }
        
        // Log purchase attempt
        Analytics.logEvent("purchase_initiated", parameters: [
            "product_id": product.id,
            "product_price": product.price
        ])
        
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
            
            // Log successful purchase
            Analytics.logEvent(AnalyticsEventPurchase, parameters: [
                AnalyticsParameterCurrency: "USD",
                AnalyticsParameterValue: product.price,
                AnalyticsParameterItemID: product.id
            ])
            
        case .userCancelled:
            print("User cancelled purchase")
            
            Analytics.logEvent("purchase_cancelled", parameters: [
                "product_id": product.id
            ])
            
            throw PurchaseError.userCancelled
            
        case .pending:
            print("Purchase pending")
            
            Analytics.logEvent("purchase_pending", parameters: [
                "product_id": product.id
            ])
            
            throw PurchaseError.pending
            
        @unknown default:
            throw PurchaseError.unknown
        }
    }
    
    @MainActor
    func restorePurchases() async throws {
        isLoading = true
        defer { isLoading = false }
        
        Analytics.logEvent("restore_initiated", parameters: nil)
        
        try await AppStore.sync()
        
        await updatePurchasedProducts()
        
        if purchasedSubscriptions.isEmpty {
            Analytics.logEvent("restore_failed_no_purchases", parameters: nil)
            throw PurchaseError.noPurchasesToRestore
        } else {
            Analytics.logEvent("restore_successful", parameters: [
                "subscription_count": purchasedSubscriptions.count
            ])
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
            Analytics.logEvent("verification_failed", parameters: [
                "error": error.localizedDescription
            ])
            throw error
        case .verified(let safe):
            return safe
        }
    }
    
    @MainActor
    private func updatePurchasedProducts() async {
        var purchased: [Product] = []
        
        // Check current entitlements
        for await result in Transaction.currentEntitlements {
            do {
                let transaction = try checkVerifier(result)
                
                // Check if transaction is active
                if transaction.revocationDate == nil {
                    if let product = products.first(where: { $0.id == transaction.productID }) {
                        purchased.append(product)
                    }
                }
            } catch {
                print("[PaymentManager] Failed to verify transaction: \(error)")
            }
        }
        
        self.purchasedSubscriptions = purchased
        
        // Update subscription group status
        if let groupID = purchased.first?.subscription?.subscriptionGroupID {
            let statuses = try? await Product.SubscriptionInfo.status(for: groupID)
            self.subscriptionGroupStatus = statuses?.first?.state
        }
    }
    
    private func updateSubscriptionStatus(for transaction: StoreKit.Transaction) async {
        guard let userId = Auth.auth().currentUser?.uid,
              let productId = ProductID(rawValue: transaction.productID) else { return }
        
        let endDate: Date?
        if let expirationDate = transaction.expirationDate {
            endDate = expirationDate
        } else {
            endDate = Calendar.current.date(byAdding: .year, value: 100, to: Date())
        }
        
        let subscription = UserSubscription(
            tier: productId.tier,
            startDate: transaction.purchaseDate,
            endDate: endDate,
            isActive: transaction.revocationDate == nil,
            subscriptionId: String(transaction.id),
            customerId: nil
        )
        
        do {
            // First check if user document exists
            let userDoc = try await db.collection("users").document(userId).getDocument()
            
            if userDoc.exists {
                // Update existing document
                let data: [String: Any] = [
                    "subscription": try Firestore.Encoder().encode(subscription),
                    "updatedAt": FieldValue.serverTimestamp()
                ]
                
                _ = db.collection("users").document(userId).updateData(data)
            } else {
                // Create new user document with subscription
                let newUser = UserProfile(
                    email: Auth.auth().currentUser?.email ?? "",
                    displayName: Auth.auth().currentUser?.displayName,
                    subscription: subscription
                )
                
                _ = db.collection("users").document(userId).setData(from: newUser)
            }
            
            print("[PaymentManager] Updated subscription status for user: \(userId)")
            
            // Update Analytics
            Analytics.setUserProperty(productId.tier.rawValue, forName: "subscription_tier")
            Analytics.logEvent("subscription_updated", parameters: [
                "tier": productId.tier.rawValue,
                "transaction_id": String(transaction.id)
            ])
            
            // Post notification for other parts of the app
            await MainActor.run {
                NotificationCenter.default.post(
                    name: .subscriptionStatusChanged,
                    object: nil,
                    userInfo: ["tier": productId.tier.rawValue]
                )
            }
            
        } catch {
            print("[PaymentManager] Failed to update subscription in Firestore: \(error)")
            
            Analytics.logEvent("firestore_update_failed", parameters: [
                "error": error.localizedDescription,
                "user_id": userId
            ])
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
    
    @MainActor
    func refreshSubscriptionStatus() async {
        await updatePurchasedProducts()
        
        // Notify observers that subscription status may have changed
        NotificationCenter.default.post(
            name: .subscriptionStatusChanged,
            object: nil
        )
    }
}
