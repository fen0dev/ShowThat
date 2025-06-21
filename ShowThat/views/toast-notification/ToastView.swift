//
//  ToastView.swift
//  ShowThat
//
//  Created by Giuseppe De Masi on 21/06/2025.
//

import SwiftUI

struct ToastView: View {
    let message: String
    let type: ContentView.ToastStyle
    @Binding var isShowing: Bool
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: type.icon)
                .font(.title2)
                .foregroundStyle(.white)
            
            Text(message)
                .font(.body)
                .fontWeight(.medium)
                .foregroundStyle(.white)
                .lineLimit(2)
            
            Spacer()
        }
        .padding(.vertical, 16)
        .padding(.horizontal, 20)
        .background {
            Capsule()
                .fill(
                    LinearGradient(
                        colors: [type.color, type.color.opacity(0.8)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .shadow(color: type.color.opacity(0.3), radius: 20, y: 10)
        }
        .padding(.horizontal)
        .transition(.asymmetric(
            insertion: .move(edge: .top).combined(with: .opacity),
            removal: .move(edge: .top).combined(with: .opacity)
        ))
        .onTapGesture {
            withAnimation(.spring()) {
                isShowing = false
            }
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                withAnimation(.spring()) {
                    isShowing = false
                }
            }
        }
    }
}

#Preview {
    ToastView(message: "QR code generated", type: .success, isShowing: .constant(true))
}
