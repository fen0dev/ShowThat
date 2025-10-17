//
//  OnboardingStep.swift
//  ShowThat
//
//  Created by Giuseppe De Masi on 16/10/2025.
//

import Foundation
import SwiftUI

struct OnboardingStep: Identifiable {
    let id = UUID()
    let title: String
    let subtitle: String
    let description: String
    let icon: String
    let color: Color
    let backgroundGradient: LinearGradient
    let animation: LottieAnimation?
    let interactiveElements: [InteractiveElement]
    
    struct InteractiveElement: Identifiable {
        let id = UUID()
        let type: ElementType
        let title: String
        let action: () -> Void
        
        enum ElementType {
            case button, toggle, textField
        }
    }
    
    struct LottieAnimation {
        let name: String
        let loop: Bool
        let speed: Double
    }
}

// Static data for onboarding steps
extension OnboardingStep {
    static let allSteps: [OnboardingStep] = [
         OnboardingStep(
             title: "Welcome",
             subtitle: "Your creative QR code studio",
             description: "Create professional and beautiful QR codes to share with the world. Track performance and manage everything from a single app.",
             icon: "qrcode.viewfinder",
             color: .purple,
             backgroundGradient: LinearGradient(
                 colors: [.purple.opacity(0.8), .blue.opacity(0.6)],
                 startPoint: .topLeading,
                 endPoint: .bottomTrailing
             ),
             animation: LottieAnimation(name: "welcome-animation", loop: true, speed: 1.0),
             interactiveElements: []
         ),
         OnboardingStep(
             title: "Create your first QR",
             subtitle: "Choose your content type",
             description: "URLs, business cards, WiFi, email and much more. Every QR code can be customized with your unique style.",
             icon: "plus.circle.fill",
             color: .blue,
             backgroundGradient: LinearGradient(
                 colors: [.blue.opacity(0.8), .cyan.opacity(0.6)],
                 startPoint: .topLeading,
                 endPoint: .bottomTrailing
             ),
             animation: LottieAnimation(name: "create-qr-animation", loop: true, speed: 1.2),
             interactiveElements: [
                 InteractiveElement(type: .button, title: "Explore QR types", action: {}),
                 InteractiveElement(type: .button, title: "See examples", action: {})
             ]
         ),
         OnboardingStep(
             title: "Customize the design",
             subtitle: "Make your QR code unique",
             description: "Choose from Minimal, Branded, Gradient or Glass styles. Add your logo and custom colors for a professional result.",
             icon: "paintbrush.fill",
             color: .green,
             backgroundGradient: LinearGradient(
                 colors: [.green.opacity(0.8), .mint.opacity(0.6)],
                 startPoint: .topLeading,
                 endPoint: .bottomTrailing
             ),
             animation: LottieAnimation(name: "design-animation", loop: true, speed: 0.8),
             interactiveElements: [
                 InteractiveElement(type: .toggle, title: "Dark mode", action: {}),
                 InteractiveElement(type: .button, title: "Try styles", action: {})
             ]
         ),
         OnboardingStep(
             title: "Share and analyze",
             subtitle: "Track your performance",
             description: "Share your QR codes and monitor how many times they get scanned. Get detailed insights about your content.",
             icon: "chart.line.uptrend.xyaxis",
             color: .orange,
             backgroundGradient: LinearGradient(
                 colors: [.orange.opacity(0.8), .yellow.opacity(0.6)],
                 startPoint: .topLeading,
                 endPoint: .bottomTrailing
             ),
             animation: LottieAnimation(name: "analytics-animation", loop: true, speed: 1.0),
             interactiveElements: [
                 InteractiveElement(type: .button, title: "View dashboard", action: {}),
                 InteractiveElement(type: .toggle, title: "Analytics notifications", action: {})
             ]
         ),
         OnboardingStep(
             title: "You're all set!",
             subtitle: "Start creating amazing QR codes",
             description: "You've completed the guided tour. Now you can start creating professional QR codes and tracking their performance.",
             icon: "checkmark.circle.fill",
             color: .purple,
             backgroundGradient: LinearGradient(
                 colors: [.purple.opacity(0.8), .pink.opacity(0.6)],
                 startPoint: .topLeading,
                 endPoint: .bottomTrailing
             ),
             animation: LottieAnimation(name: "success-animation", loop: false, speed: 1.0),
             interactiveElements: [
                 InteractiveElement(type: .button, title: "Get started", action: {})
             ]
         )
     ]
}
