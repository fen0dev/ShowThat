//
//  RootView.swift
//  ShowThat
//
//  Created by Giuseppe De Masi on 24/06/2025.
//

import SwiftUI

struct RootView: View {
    @EnvironmentObject var authState: AuthState
    var body: some View {
        Group {
            if authState.isAuthenticated {
                ContentView()
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
    }
}

#Preview {
    RootView()
        .environmentObject(AuthState())
}
