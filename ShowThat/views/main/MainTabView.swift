//
//  MainTabView.swift
//  ShowThat
//
//  Created by Giuseppe De Masi on 25/06/2025.
//

import SwiftUI

@available(iOS 17.0, *)
struct MainTabView: View {
    enum Tab: Int { case dashboard, scan, analytics, profile }
    @EnvironmentObject var qrManager: QRCodeManager
    @EnvironmentObject var authState: AuthState
    @State private var selectedTab: Tab = .dashboard
    var body: some View {
        TabView(selection: $selectedTab) {
            DashboardView()
                .tabItem {
                    Label("Dashboard", systemImage: "house")
                }
                .tag(Tab.dashboard)
            
            QRScanScreen()
                .environmentObject(qrManager)
                .tabItem {
                    Label("Scan", systemImage: "camera.viewfinder")
                }
                .tag(Tab.scan)
            
            AnalyticsView()
                .tabItem {
                    Label("Analytics", systemImage: "chart.line.uptrend.xyaxis")
                }
                .tag(Tab.analytics)
            
            ProfileSettingsView()
                .tabItem {
                    Label("Profile", systemImage: "person.circle.fill")
                }
                .tag(Tab.profile)
        }
        .tint(DesignTokens.Colors.primary)
    }
}

#Preview {
    if #available(iOS 17.0, *) {
        MainTabView()
            .environmentObject(QRCodeManager())
            .environmentObject(AuthState())
    } else {
        // Fallback on earlier versions
    }
}
