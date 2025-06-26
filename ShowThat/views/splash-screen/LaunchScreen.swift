//
//  LaunchScreen.swift
//  ShowThat
//
//  Created by Giuseppe De Masi on 26/06/2025.
//

import SwiftUI

struct LaunchScreen: View {
    var body: some View {
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
            
            Image(systemName: "qrcode.viewfinder")
                .font(.system(size: 130, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
        }
    }
}

#Preview {
    LaunchScreen()
}
