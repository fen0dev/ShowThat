//
//  ToastView.swift
//  ShowThat
//
//  Created by Giuseppe De Masi on 21/06/2025.
//

import SwiftUI

struct ToastView: View {
    let config: ToastConfig
    @Binding var isPresented: Bool
    @State private var animateIn = false
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: config.type.icon)
                .font(.title2)
                .foregroundStyle(.white)
            
            Text(config.message)
                .font(.body)
                .fontWeight(.medium)
                .foregroundStyle(.white)
                .lineLimit(2)
            
            Spacer()
            
            Button(action: {
                withAnimation(.spring()) {
                    isPresented = false
                }
            }) {
                Image(systemName: "xmark")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.7))
                    .padding(4)
                    .background(Circle().fill(.white.opacity(0.2)))
            }
        }
        .padding(.vertical, 16)
        .padding(.horizontal, 20)
        .background {
            Capsule()
                .fill(
                    LinearGradient(
                        colors: [config.type.color, config.type.color.opacity(0.8)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .shadow(color: config.type.color.opacity(0.3), radius: 20, y: 10)
        }
        .padding(.horizontal)
        .offset(y: animateIn ? 0 : -100)
        .opacity(animateIn ? 1 : 0)
        .onAppear {
            withAnimation(.spring()) {
                animateIn = true
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + config.duration) {
                withAnimation(.spring()) {
                    isPresented = false
                }
            }
        }
        .onTapGesture {
            withAnimation(.spring()) {
                isPresented = false
            }
        }
    }
}

#Preview {
    ToastView(config: ToastConfig(message: "QR Code generated successfully", type: .success, duration: Double(0.5)), isPresented: .constant(true))
}
