//
//  MainTabView.swift
//  ShowThat
//
//  Created by Giuseppe De Masi on 25/06/2025.
//

import SwiftUI

struct MainTabView: View {
    @EnvironmentObject var qrManager: QRCodeManager
    @EnvironmentObject var authState: AuthState
    @State private var selectedTab = 0
    var body: some View {
        TabView(selection: $selectedTab) {
            DashboardView()
                .tabItem {
                    Label("Dashboard", systemImage: "house")
                }
                .tag(0)
            
            AnalyticsView()
                .tabItem {
                    Label("Analytics", systemImage: "chart.line.uptrend.xyaxis")
                }
                .tag(1)
            
            ProfileSettingsView()
                .tabItem {
                    Label("Profile", systemImage: "person.circle.fill")
                }
                .tag(2)
        }
    }
}

#Preview {
    MainTabView()
        .environmentObject(QRCodeManager())
        .environmentObject(AuthState())
}
