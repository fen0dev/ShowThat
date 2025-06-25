//
//  CustomAlertSheet.swift
//  ShowThat
//
//  Created by Giuseppe De Masi on 25/06/2025.
//

import SwiftUI

struct CustomAlertSheet: View {
    let config: AlertConfig
    @Binding var isPresented: Bool
    @State private var animateIcon = false
    
    var body: some View {
        ZStack {
            // Background
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .onTapGesture {
                    withAnimation(.spring()) {
                        isPresented = false
                    }
                }
            
            // Alert Content
            VStack(spacing: 0) {
                // Icon Section
                ZStack {
                    Circle()
                        .fill(config.type.gradient)
                        .frame(width: 100, height: 100)
                        .shadow(color: config.type.color.opacity(0.5), radius: 20, y: 10)
                    
                    Image(systemName: config.icon)
                        .font(.system(size: 50))
                        .foregroundColor(.white)
                        .scaleEffect(animateIcon ? 1.1 : 0.9)
                }
                .padding(.top, 30)
                .onAppear {
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
                        animateIcon = true
                    }
                }
                
                // Title
                Text(config.title)
                    .font(.title2)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                    .padding(.top, 20)
                
                // Message
                Text(config.message)
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 30)
                    .padding(.top, 10)
                
                // Actions
                VStack(spacing: 12) {
                    // Primary Action
                    Button(action: {
                        withAnimation(.spring()) {
                            isPresented = false
                        }
                        config.primaryAction.action?()
                    }) {
                        Text(config.primaryAction.title)
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(config.type.gradient)
                            .cornerRadius(15)
                    }
                    
                    // Secondary Action
                    if let secondaryAction = config.secondaryAction {
                        Button(action: {
                            withAnimation(.spring()) {
                                isPresented = false
                            }
                            secondaryAction.action?()
                        }) {
                            Text(secondaryAction.title)
                                .font(.headline)
                                .foregroundColor(.primary)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(
                                    RoundedRectangle(cornerRadius: 15)
                                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                                )
                        }
                    }
                }
                .padding(.horizontal, 30)
                .padding(.vertical, 30)
            }
            .background(
                RoundedRectangle(cornerRadius: 30)
                    .fill(.regularMaterial)
            )
            .shadow(color: .black.opacity(0.2), radius: 20, y: 10)
            .padding(.horizontal, 40)
            .scaleEffect(animateIcon ? 1 : 0.8)
            .opacity(animateIcon ? 1 : 0)
        }
    }
}

#Preview {
    CustomAlertSheet(config: AlertConfig(type: .success, title: "Success", message: "QR Code generated successfully", icon: "checkmark.fill", primaryAction: AlertAction(title: "Test")), isPresented: .constant(true))
}
