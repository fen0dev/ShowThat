//
//  OnboardingBackground.swift
//  ShowThat
//
//  Created by Giuseppe De Masi on 17/10/2025.
//

import SwiftUI

struct OnboardingBackground: View {
    var body: some View {
        LinearGradient(
            colors: [
                Color(red: 0.25, green: 0.15, blue: 0.35),     // Dark purple
                Color(red: 0.2, green: 0.25, blue: 0.4),    // Dark blue
                Color(red: 0.02, green: 0.05, blue: 0.56),   // Very dark blue
                Color(red: 0.25, green: 0.2, blue: 0.35)      // Dark purple (back to start)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
        
        ForEach(0..<20) { idx in
            FloatingParticles(delay: Double(idx) * 0.5)
        }
    }
}

#Preview {
    if #available(iOS 17.0, *) {
        OnboardingView()
            .environmentObject(OnboardingManager())
    } else {
        // Fallback on earlier versions
    }
}
