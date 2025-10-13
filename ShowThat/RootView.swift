//
//  RootView.swift
//  ShowThat
//
//  Created by Giuseppe De Masi on 24/06/2025.
//

import SwiftUI

@available(iOS 17.0, *)
struct RootView: View {
    @EnvironmentObject var authState: AuthState
    var body: some View {
        Group {
            if authState.isAuthenticated {
                MainTabView()
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing),
                        removal: .move(edge: .leading)
                    ))
            } else {
                AuthenticationView()
                    .transition(.asymmetric(
                        insertion: .move(edge: .leading),
                        removal: .move(edge: .trailing)
                    ))
            }
        }
        .animation(.spring(), value: authState.isAuthenticated)
        .withAlerts()
        .subscriptionExpiredAlert()
    }
}

#Preview {
    if #available(iOS 17.0, *) {
        RootView()
            .environmentObject(AuthState())
    } else {
        // Fallback on earlier versions
    }
}
