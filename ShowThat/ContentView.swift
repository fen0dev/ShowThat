//
//  ContentView.swift
//  ShowThat
//
//  Created by Giuseppe De Masi on 19/06/2025.
//

import SwiftUI

@available(iOS 17.0, *)
struct ContentView: View {
    @EnvironmentObject var authState: AuthState
    var body: some View {
        RootView()
            .environmentObject(authState)
    }
}

#Preview {
    if #available(iOS 17.0, *) {
        ContentView()
            .environmentObject(AuthState())
    } else {
        // Fallback on earlier versions
    }
}
