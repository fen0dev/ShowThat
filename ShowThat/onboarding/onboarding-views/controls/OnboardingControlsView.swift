//
//  OnboardingControlsView.swift
//  ShowThat
//
//  Created by Giuseppe De Masi on 16/10/2025.
//

import SwiftUI

struct OnboardingControlsView: View {
    @ObservedObject var manager: OnboardingManager
    var body: some View {
        HStack {
            if manager.currentStep > 0 {
                Button("Back") {
                    withAnimation(.smooth) {
                        manager.currentStep -= 1
                        HapticManager.shared.lightImpact()
                    }
                }
                .buttonStyle(.plain)
                .foregroundStyle(.white.opacity(0.65))
            }
            
            Spacer()
            
            HStack(spacing: 25) {
                if manager.currentStep < OnboardingStep.allSteps.count - 1 {
                    if manager.currentStep == 0 {
                        Button("Skip") {
                            manager.skipOnboarding()
                            HapticManager.shared.mediumImpact()
                        }
                        .buttonStyle(.plain)
                        .foregroundStyle(.white.opacity(0.65))
                    }
                    
                    Button("Next") {
                        withAnimation(.smooth) {
                            manager.currentStep += 1
                            HapticManager.shared.mediumImpact()
                        }
                    }
                    .buttonStyle(PrimaryButtonStylePlain())
                    
                } else {
                    Button("Got it!") {
                        manager.completeOnboarding()
                        HapticManager.shared.successAction()
                    }
                    .buttonStyle(PrimaryButtonStylePlain())
                }
            }
        }
        .padding(.horizontal, 30)
    }
}

#Preview {
    OnboardingControlsView(manager: OnboardingManager.init())
}
