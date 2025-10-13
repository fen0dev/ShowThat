//
//  SubscriptionStatusView.swift
//  ShowThat
//
//  Created by Giuseppe De Masi on 25/06/2025.
//

import SwiftUI
import StoreKit

@available(iOS 16.0, *)
struct SubscriptionStatusView: View {
    @EnvironmentObject var qrManager: QRCodeManager
    @StateObject private var paymentManager = PaymentManager.shared
    @State private var showingUpgradeSheet = false
    @State private var expirationDate: Date?
    
    var currentTier: UserSubscription.Tier {
        paymentManager.currentSubscription ?? qrManager.currentSubscription?.tier ?? .free
    }
    
    var isExpiringSoon: Bool {
        guard let expiration = expirationDate else { return false }
        let daysUntilExpiration = Calendar.current.dateComponents([.day], from: Date(), to: expiration).day ?? 0
        return daysUntilExpiration <= 5 && daysUntilExpiration >= 0
    }
    
    var body: some View {
        Group {
            if currentTier != .free {
                subscriptionActiveView
            } else {
                freeTierTrialView
            }
        }
        .sheet(isPresented: $showingUpgradeSheet) {
            UpgradeView(qrManager: qrManager)
        }
        .task {
            await checkSubscriptionStatus()
        }
    }
    
    private var subscriptionActiveView: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "crown.fill")
                    .foregroundColor(.yellow)
                    .font(.title3)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(currentTier.rawValue) Subscription")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    if let expiration = expirationDate {
                        Text("Renews \(expiration, style: .date)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                if paymentManager.subscriptionGroupStatus == .expired {
                    Button("Renew") {
                        showingUpgradeSheet = true
                    }
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.red)
                    .cornerRadius(20)
                }
            }
            
            if isExpiringSoon {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                    
                    Text("Your subscription expires soon")
                        .font(.caption)
                        .foregroundColor(.orange)
                    
                    Spacer()
                }
                .padding(.top, 4)
            }
            
            // Usage bars
            VStack(spacing: 8) {
                UsageBar(
                    title: "QR Codes",
                    current: qrManager.qrCodes.filter { !$0.isDynamic }.count,
                    limit: currentTier.qrLimit
                )
                
                if currentTier.dynamicQRLimit > 0 {
                    UsageBar(
                        title: "Dynamic QRs",
                        current: qrManager.qrCodes.filter { $0.isDynamic }.count,
                        limit: currentTier.dynamicQRLimit
                    )
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(.white)
                .shadow(color: .black.opacity(0.08), radius: 5, y: 2)
        )
    }
    
    private var freeTierTrialView: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Free Plan")
                        .font(.headline.bold())
                    
                    Text("Upgrade to create more unique QR codes")
                        .font(.caption)
                        .foregroundStyle(.gray)
                }
                
                Spacer()
                
                Button(action: {
                    withAnimation(.spring()) {
                        showingUpgradeSheet = true
                    }
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "sparkles")
                        Text("Upgrade")
                    }
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background {
                        LinearGradient(
                            colors: [.purple, .blue],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    }
                    .cornerRadius(20)
                }
            }
            
            // usage bar for free tier
            UsageBar(
                title: "QR Codes",
                current: qrManager.qrCodes.count,
                limit: UserSubscription.Tier.free.qrLimit
            )
        }
        .padding()
        .background(Color.white, in: RoundedRectangle(cornerRadius: 15))
        .shadow(color: .black.opacity(0.08), radius: 5, y: 2)
    }
    
    private func checkSubscriptionStatus() async {
        // Get subscription expiration date from StoreKit
        guard let product = paymentManager.purchasedSubscriptions.first,
              let subscription = product.subscription else { return }
        
        do {
            let statuses = try await subscription.status
            if let status = statuses.first(where: { $0.state != .expired && $0.state != .revoked }) {
                do {
                    let verifiedTransaction = try paymentManager.checkVerifier(status.transaction)
                    await MainActor.run {
                        self.expirationDate = verifiedTransaction.expirationDate
                    }
                } catch {
                    print("[-] Failed to verify transaction: \(error)")
                }
            }
        } catch {
            print("[-] Failed to check subscription status: \(error)")
        }
    }
}

#Preview {
    VStack {
        if #available(iOS 16.0, *) {
            SubscriptionStatusView()
                .environmentObject(QRCodeManager())
        } else {
            // Fallback on earlier versions
        }
        
        Spacer()
    }
    .padding()
}
