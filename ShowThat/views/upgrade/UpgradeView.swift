//
//  UpgradeView.swift
//  ShowThat
//
//  Created by Giuseppe De Masi on 25/06/2025.
//

import SwiftUI
import StoreKit

struct UpgradeView: View {
    let qrManager: QRCodeManager
    
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var paymentManager: PaymentManager
    @State private var selectedProduct: Product?
    @State private var isPurchasing = false
    @State private var showingRestoreAlert = false
    
    var currentTier: UserSubscription.Tier {
        qrManager.currentSubscription?.tier ?? .free
    }
    
    var sortedProducts: [Product] {
        paymentManager.products.sorted { first, second in
            // Sort by price ascending
            first.price < second.price
        }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // Gradient Background
                LinearGradient(
                    gradient: Gradient(stops: [
                        .init(color: Color(red: 0.1, green: 0.1, blue: 0.3), location: 0),
                        .init(color: Color(red: 0.2, green: 0.1, blue: 0.4), location: 0.5),
                        .init(color: Color(red: 0.3, green: 0.1, blue: 0.5), location: 1)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                if paymentManager.isLoading && paymentManager.products.isEmpty {
                    // Loading State
                    VStack(spacing: 20) {
                        ProgressView()
                            .scaleEffect(1.5)
                            .tint(.white)
                        
                        Text("Loading subscription options...")
                            .foregroundColor(.white.opacity(0.8))
                    }
                } else if paymentManager.products.isEmpty {
                    // Error State
                    VStack(spacing: 20) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 50))
                            .foregroundColor(.yellow)
                        
                        Text("Unable to load subscriptions")
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        Text("Please check your internet connection")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.8))
                        
                        Button("Try Again") {
                            Task {
                                await paymentManager.loadProducts(force: true)
                            }
                        }
                        .buttonStyle(PrimaryButtonStyle())
                    }
                } else {
                    // Main Content
                    ScrollView {
                        VStack(spacing: 30) {
                            // Header
                            headerView
                            
                            // Subscription Cards
                            VStack(spacing: 20) {
                                ForEach(sortedProducts, id: \.id) { product in
                                    if let tier = tierForProduct(product) {
                                        SubscriptionCard(
                                            product: product,
                                            tier: tier,
                                            isSelected: selectedProduct?.id == product.id,
                                            isCurrent: currentTier == tier,
                                            isPurchased: paymentManager.isSubscribed(to: tier),
                                            action: {
                                                withAnimation(.spring()) {
                                                    selectedProduct = product
                                                }
                                            }
                                        )
                                    }
                                }
                            }
                            .padding(.horizontal)
                            
                            // Subscribe Button
                            subscribeButton
                            
                            // Footer Actions
                            footerActions
                        }
                    }
                }
            }
            .navigationBarHidden(true)
            .overlay(alignment: .topTrailing) {
                closeButton
            }
            .alert("Restore Purchases", isPresented: $showingRestoreAlert) {
                Button("OK") { }
            } message: {
                Text(paymentManager.purchasedSubscriptions.isEmpty ?
                     "No active subscriptions found" :
                     "Your purchases have been restored successfully")
            }
        }
        .task {
            // Load products if not already loaded
            if paymentManager.products.isEmpty {
                await paymentManager.loadProducts(force: true)
            }
            
            // Pre-select current tier or Pro
            if let currentProduct = paymentManager.product(for: currentTier) {
                selectedProduct = currentProduct
            } else if let proProduct = paymentManager.product(for: .pro) {
                selectedProduct = proProduct
            }
        }
    }
    
    // MARK: - View Components
    
    private var headerView: some View {
        VStack(spacing: 15) {
            Image(systemName: "crown.fill")
                .font(.system(size: 60))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.yellow, .orange],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .shadow(color: .yellow.opacity(0.5), radius: 20)
            
            Text("Unlock Premium Features")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
            
            Text("Choose the plan that works best for you")
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.8))
        }
        .padding(.top, 40)
    }
    
    private var subscribeButton: some View {
        Group {
            if let product = selectedProduct {
                Button(action: { purchaseProduct(product) }) {
                    HStack {
                        if isPurchasing {
                            ProgressView()
                                .tint(.white)
                                .scaleEffect(0.8)
                        } else {
                            Image(systemName: "sparkles")
                            
                            Text(subscribeButtonText(for: product))
                                .fontWeight(.semibold)
                            
                            Image(systemName: "sparkles")
                        }
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
                    .background(
                        LinearGradient(
                            colors: buttonColors(for: product),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(20)
                    .shadow(
                        color: buttonShadowColor(for: product),
                        radius: 20,
                        y: 10
                    )
                }
                .padding(.horizontal)
                .disabled(isPurchasing || isCurrentTier(product))
            }
        }
    }
    
    private var footerActions: some View {
        VStack(spacing: 15) {
            Button("Restore Purchases") {
                restorePurchases()
            }
            .foregroundColor(.white.opacity(0.7))
            
            // Terms and Privacy
            HStack(spacing: 20) {
                Link("Terms of Service", destination: URL(string: "https://showthat.app/terms")!)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.5))
                
                Link("Privacy Policy", destination: URL(string: "https://showthat.app/privacy")!)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.5))
            }
            
            // Subscription Info
            Text("Subscriptions auto-renew monthly. Cancel anytime.")
                .font(.caption2)
                .foregroundColor(.white.opacity(0.4))
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .padding(.bottom, 40)
    }
    
    private var closeButton: some View {
        Button(action: { dismiss() }) {
            Image(systemName: "xmark.circle.fill")
                .font(.title2)
                .foregroundStyle(.white.opacity(0.6), .white.opacity(0.2))
        }
        .padding()
    }
    
    // MARK: - Helper Methods
    
    private func tierForProduct(_ product: Product) -> UserSubscription.Tier? {
        guard let productID = PaymentManager.ProductID(rawValue: product.id) else { return nil }
        return productID.tier
    }
    
    private func isCurrentTier(_ product: Product) -> Bool {
        guard let tier = tierForProduct(product) else { return false }
        return currentTier == tier
    }
    
    private func subscribeButtonText(for product: Product) -> String {
        if isCurrentTier(product) {
            return "Current Plan"
        } else if paymentManager.isSubscribed(to: tierForProduct(product) ?? .free) {
            return "Already Subscribed"
        } else {
            return "Subscribe for \(product.displayPrice)/month"
        }
    }
    
    private func buttonColors(for product: Product) -> [Color] {
        if isCurrentTier(product) || paymentManager.isSubscribed(to: tierForProduct(product) ?? .free) {
            return [.gray]
        } else {
            return [.purple, .blue]
        }
    }
    
    private func buttonShadowColor(for product: Product) -> Color {
        if isCurrentTier(product) || paymentManager.isSubscribed(to: tierForProduct(product) ?? .free) {
            return .clear
        } else {
            return .purple.opacity(0.5)
        }
    }
    
    // MARK: - Purchase Methods
    
    private func purchaseProduct(_ product: Product) {
        isPurchasing = true
        
        Task {
            do {
                try await paymentManager.purchase(product)
                
                // Success
                await MainActor.run {
                    AlertManager.shared.showSuccess(
                        title: "Welcome to Premium!",
                        message: getUpgradeMessage(for: tierForProduct(product) ?? .pro),
                        icon: "crown.fill"
                    ) {
                        dismiss()
                    }
                }
            } catch PurchaseError.userCancelled {
                // User cancelled - no action needed
            } catch PurchaseError.pending {
                await MainActor.run {
                    AlertManager.shared.showInfo(
                        title: "Purchase Pending",
                        message: "Your purchase is awaiting approval. You'll receive access once it's approved.",
                        icon: "clock.fill"
                    )
                }
            } catch {
                await MainActor.run {
                    AlertManager.shared.showError(
                        title: "Purchase Failed",
                        message: error.localizedDescription
                    ) {
                        // Retry
                        purchaseProduct(product)
                    }
                }
            }
            
            await MainActor.run {
                isPurchasing = false
            }
        }
    }
    
    private func restorePurchases() {
        Task {
            do {
                try await paymentManager.restorePurchases()
                showingRestoreAlert = true
            } catch {
                await MainActor.run {
                    AlertManager.shared.showError(
                        title: "Restore Failed",
                        message: error.localizedDescription
                    )
                }
            }
        }
    }
    
    private func getUpgradeMessage(for tier: UserSubscription.Tier) -> String {
        switch tier {
        case .free:
            return "You're on the free plan."
        case .pro:
            return "You now have access to dynamic QR codes, advanced analytics, and custom branding!"
        case .business:
            return "Welcome to Business! You can now collaborate with your team and access our API."
        case .enterprise:
            return "Welcome to Enterprise! Your dedicated account manager will contact you shortly."
        }
    }
}

#Preview {
    UpgradeView(qrManager: QRCodeManager())
        .environmentObject(PaymentManager.shared)
}


struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundColor(.white)
            .padding(.horizontal, 30)
            .padding(.vertical, 15)
            .background(
                LinearGradient(
                    colors: [.purple, .blue],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(25)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
    }
}
