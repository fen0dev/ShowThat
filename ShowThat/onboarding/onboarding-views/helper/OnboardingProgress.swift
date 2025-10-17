//
//  OnboardingProgress.swift
//  ShowThat
//
//  Created by Giuseppe De Masi on 16/10/2025.
//

import SwiftUI

struct OnboardingProgress: View {
    let currentStep: Int
    let totalSteps: Int
    var body: some View {
        HStack(spacing: 8) {
            ForEach(0..<totalSteps, id: \.self) { idx in
                Circle()
                    .fill(idx <= currentStep ? DesignTokens.Colors.primary : DesignTokens.Colors.surface.opacity(0.3))
                    .frame(width: 8, height: 8)
                    .scaleEffect(idx == currentStep ? 1.3 : 1.0)
                    .animation(.spring(response: 0.3), value: currentStep)
            }
        }
        .padding(.horizontal)
    }
}

#Preview {
    OnboardingProgress(
        currentStep: 2,
        totalSteps: 3
    )
}
