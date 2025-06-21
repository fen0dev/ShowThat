//
//  ActionButton.swift
//  ShowThat
//
//  Created by Giuseppe De Masi on 19/06/2025.
//

import SwiftUI

struct ActionButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                Text(title)
                    .fontWeight(.medium)
            }
            .foregroundColor(.white)
            .padding(.horizontal, 30)
            .padding(.vertical, 15)
            .background(
                LinearGradient(
                    colors: [color, color.opacity(0.8)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .cornerRadius(12)
            .shadow(color: color.opacity(0.3), radius: 8, y: 4)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    ActionButton(title: "test", icon: "globe", color: .pink, action: {})
}
