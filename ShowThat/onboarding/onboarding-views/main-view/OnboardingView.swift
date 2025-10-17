//
//  OnboardingView.swift
//  ShowThat
//
//  Created by Giuseppe De Masi on 16/10/2025.
//

import SwiftUI

@available(iOS 17.0, *)
struct OnboardingView: View {
    @EnvironmentObject var manager: OnboardingManager
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        ZStack {
            OnboardingBackground()
            
            VStack {
                OnboardingProgress(
                    currentStep: manager.currentStep,
                    totalSteps: OnboardingStep.allSteps.count
                )
                .padding(.top, 50)
                
                TabView(selection: $manager.currentStep) {
                    ForEach(Array(OnboardingStep.allSteps.enumerated()), id: \.element.id) { idx, step in
                        OnboardingStepView(
                            step: step,    
                            stepNumber: idx + 1,
                            totalSteps: OnboardingStep.allSteps.count
                        )
                        .tag(idx)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .disabled(manager.isCompleted)
                .onChange(of: manager.currentStep) { _, _ in
                    HapticManager.shared.lightImpact()
                }
                
                // bottom controls
                OnboardingControlsView(manager: manager)
                    .padding(.bottom, 45)
            }
        }
        .onChange(of: manager.currentStep) { _, newStep in
            if newStep >= OnboardingStep.allSteps.count - 1 {
                // last step - complete onboarding after delay
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    manager.completeOnboarding()
                    HapticManager.shared.mediumImpact()
                    dismiss()
                }
            }
        }
    }
}

#Preview {
    if #available(iOS 17.0, *) {
        OnboardingView()
            .environmentObject(OnboardingManager())
    } else {
        
    }
}
