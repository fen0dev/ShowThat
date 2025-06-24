//
//  AnimatedGradientBackground.swift
//  ShowThat
//
//  Created by Giuseppe De Masi on 24/06/2025.
//

import SwiftUI

struct AnimatedGradientBackground: View {
    @State private var animatedBackground = false
    var body: some View {
        LinearGradient(
            colors: [
                Color(red: 0.1, green: 0.2, blue: 0.45),
                Color(red: 0.2, green: 0.1, blue: 0.5),
                Color(red: 0.3, green: 0.2, blue: 0.6)
            ],
            startPoint: animatedBackground ? .topLeading : .bottomLeading,
            endPoint: animatedBackground ? .bottomTrailing : .topTrailing
        )
        .ignoresSafeArea()
        .onAppear {
            withAnimation(.linear(duration: 5).repeatForever(autoreverses: true)) {
                animatedBackground.toggle()
            }
        }
    }
}

#Preview {
    AnimatedGradientBackground()
}
