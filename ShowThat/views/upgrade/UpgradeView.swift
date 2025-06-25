//
//  UpgradeView.swift
//  ShowThat
//
//  Created by Giuseppe De Masi on 25/06/2025.
//

import SwiftUI

struct UpgradeView: View {
    let qrManager: QRCodeManager
    
    @Environment(\.dismiss) var dismiss
    @State private var selectedTier: UserSubscription.Tier = .pro
    @State private var showingPurchaseAlert = false
    
    var currentTier: UserSubscription.Tier {
        qrManager.currentSubscription?.tier ?? .free
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
                
                ScrollView {
                    VStack(spacing: 30) {
                        // Header
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
                        
                        // Subscription Cards
                        VStack(spacing: 20) {
                            ForEach([UserSubscription.Tier.pro, .business, .enterprise], id: \.self) { tier in
                                SubscriptionCard(
                                    tier: tier,
                                    isSelected: selectedTier == tier,
                                    isCurrent: currentTier == tier,
                                    action: {
                                        withAnimation(.spring()) {
                                            selectedTier = tier
                                        }
                                    }
                                )
                            }
                        }
                        .padding(.horizontal)
                        
                        // Subscribe Button
                        Button(action: subscribe) {
                            HStack {
                                Image(systemName: "sparkles")
                                
                                Text(currentTier == selectedTier ? "Current Plan" : "Upgrade to \(selectedTier.rawValue)")
                                    .fontWeight(.semibold)
                                
                                Image(systemName: "sparkles")
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 20)
                            .background(
                                LinearGradient(
                                    colors: currentTier == selectedTier ? [.gray] : [.purple, .blue],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(20)
                            .shadow(
                                color: currentTier == selectedTier ? .clear : .purple.opacity(0.5),
                                radius: 20,
                                y: 10
                            )
                        }
                        .padding(.horizontal)
                        .disabled(currentTier == selectedTier)
                        
                        // Restore Purchases
                        Button("Restore Purchases") {
                            // Implement restore
                        }
                        .foregroundColor(.white.opacity(0.7))
                        .padding(.bottom, 40)
                    }
                }
            }
            .navigationBarHidden(true)
            .overlay(alignment: .topTrailing) {
                // Close Button
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundStyle(.white.opacity(0.6), .white.opacity(0.2))
                }
                .padding()
            }
            .alert("Upgrade to \(selectedTier.rawValue)", isPresented: $showingPurchaseAlert) {
                Button("Subscribe - $\(selectedTier.price, specifier: "%.2f")/mo") {
                    completeUpgrade()
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("You'll be charged $\(selectedTier.price, specifier: "%.2f") monthly. Cancel anytime.")
            }
        }
    }
    
    private func subscribe() {
        showingPurchaseAlert = true
    }
    
    private func completeUpgrade() {
        Task {
            do {
                try await qrManager.upgradeSubscription(to: selectedTier, subscriptionId: "mock-subscription-id")
                
                AlertManager.shared.showSuccess(
                    title: "Welcome to \(selectedTier.rawValue)!",
                    message: getUpgradeMessage(for: selectedTier),
                    icon: "crown.fill"
                ) {
                    dismiss()
                }
            } catch {
                AlertManager.shared.showError(
                    title: "Upgrade Failed",
                    message: "There was an issue processing your upgrade. Please try again."
                )
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
}
