//
//  SubscriptionExpiredAlert.swift
//  ShowThat
//
//  Created by Giuseppe De Masi on 25/06/2025.
//

import SwiftUI
import StoreKit

struct SubscriptionExpiredAlert: ViewModifier {
    @EnvironmentObject var storeKitManager: PaymentManager
    @EnvironmentObject var qrManager: QRCodeManager
    @State private var showingExpiredAlert = false
    @State private var showingUpgradeSheet = false
    
    func body(content: Content) -> some View {
        content
            .alert("Subscription Expired", isPresented: $showingExpiredAlert) {
                Button("Upgrade Now") {
                    showingUpgradeSheet = true
                }
                Button("Later", role: .cancel) { }
            } message: {
                Text("Your subscription has expired. Upgrade to continue using premium features.")
            }
            .sheet(isPresented: $showingUpgradeSheet) {
                UpgradeView(qrManager: qrManager)
            }
            .onReceive(NotificationCenter.default.publisher(for: .subscriptionStatusChanged)) { _ in
                checkSubscriptionStatus()
            }
    }
    
    private func checkSubscriptionStatus() {
        if storeKitManager.subscriptionGroupStatus == .expired {
            showingExpiredAlert = true
        }
    }
}

extension View {
    func subscriptionExpiredAlert() -> some View {
        modifier(SubscriptionExpiredAlert())
    }
}

extension Notification.Name {
    static let subscriptionStatusChanged = Notification.Name("subscriptionStatusChanged")
}
