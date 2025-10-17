//
//  OnboardingStepView.swift
//  ShowThat
//
//  Created by Giuseppe De Masi on 16/10/2025.
//

import SwiftUI

struct OnboardingStepView: View {
    let step: OnboardingStep
    let stepNumber: Int
    let totalSteps: Int
    
    @State private var animateContent = false
    @State private var selectedInteractiveElement: OnboardingStep.InteractiveElement?
    
    var body: some View {
        ZStack {
            VStack(spacing: 30) {
                // icon and title section
                VStack(spacing: 20) {
                    ZStack {
                        Circle()
                            .fill(step.backgroundGradient)
                            .frame(width: 120, height: 120)
                            .blur(radius: 1)
                        
                        Image(systemName: step.icon)
                            .font(.system(size: 50, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                    }
                    .scaleEffect(animateContent ? 1.0 : 0.8)
                    .opacity(animateContent ? 1.0 : 0.0)
                    
                    Text(step.title)
                        .font(.largeTitle.bold())
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)
                        .scaleEffect(animateContent ? 1.1 : 0.9)
                        .opacity(animateContent ? 1.0 : 0.0)
                    
                    Text(step.subtitle)
                        .font(.headline)
                        .foregroundStyle(.white.opacity(0.8))
                        .multilineTextAlignment(.center)
                        .scaleEffect(animateContent ? 1.1 : 0.9)
                        .opacity(animateContent ? 1.0 : 0.0)
                }
                .padding(.top, 50)
                
                // description
                Text(step.description)
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundColor(.white.opacity(0.9))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
                    .lineSpacing(10)
                    .fixedSize(horizontal: false, vertical: true)
                    .scaleEffect(animateContent ? 1.0 : 0.95)
                    .opacity(animateContent ? 1.0 : 0.0)
                
                if !step.interactiveElements.isEmpty {
                    VStack(spacing: 25) {
                        ForEach(step.interactiveElements) { el in
                            InteractiveElementView(element: el)
                                .scaleEffect(animateContent ? 1.0 : 0.9)
                                .opacity(animateContent ? 1.0 : 0.0)
                        }
                    }
                    .padding(.horizontal, 40)
                }
                
                Spacer(minLength: 50)
            }
            .padding(.vertical)
        }
        .frame(alignment: .center)
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                withAnimation(.smooth) {
                    animateContent = true
                }
            }
        }
        .onDisappear {
            animateContent = false
        }
    }
}

#Preview {
    OnboardingStepView(
        step: OnboardingStep(title: "Test", subtitle: "This is a test", description: "Testing this thing", icon: "qrcode", color: .cyan, backgroundGradient: LinearGradient(colors: [.purple, .black, .cyan], startPoint: .topLeading, endPoint: .bottomTrailing), animation: .init(name: "Test animation", loop: true, speed: 0.3), interactiveElements: []),
        stepNumber: 1,
        totalSteps: 3
    )
}
