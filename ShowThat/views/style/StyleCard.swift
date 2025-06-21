//
//  StyleCard.swift
//  ShowThat
//
//  Created by Giuseppe De Masi on 19/06/2025.
//

import SwiftUI

struct StyleCard: View {
    let style: ContentView.QRStyle
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 10) {
                ZStack {
                    RoundedRectangle(cornerRadius: 15)
                        .fill(isSelected ?
                            LinearGradient(
                                colors: [.purple, .blue],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ) :
                            LinearGradient(
                                colors: [Color.white.opacity(0.8)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 80, height: 80)
                        .shadow(
                            color: isSelected ? .purple.opacity(0.3) : .gray.opacity(0.2),
                            radius: 10,
                            y: 5
                        )
                    
                    Image(systemName: style.icon)
                        .font(.title)
                        .foregroundColor(isSelected ? .white : .primary)
                }
                
                Text(style.rawValue)
                    .font(.caption)
                    .fontWeight(isSelected ? .semibold : .regular)
                    .foregroundColor(.primary)
            }
        }
        .buttonStyle(.plain)
        .scaleEffect(isSelected ? 1.05 : 1.0)
    }
}


#Preview {
    StyleCard(style: .branded, isSelected: true, action: {})
}
