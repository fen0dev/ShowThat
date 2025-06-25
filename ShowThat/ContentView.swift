//
//  ContentView.swift
//  ShowThat
//
//  Created by Giuseppe De Masi on 19/06/2025.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var authState: AuthState
    var body: some View {
        RootView()
            .environmentObject(authState)
    }
}

#Preview {
    ContentView()
        .environmentObject(AuthState())
}
