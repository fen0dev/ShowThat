//
//  DesignStyleCard.swift
//  ShowThat
//
//  Created by Giuseppe De Masi on 25/06/2025.
//

import SwiftUI

struct DesignStyleCard: View {
    let design: QRStyle.QRDesignStyle
    let isSelected: Bool
    let action: () -> Void
    
    var icon: String {
        switch design {
        case .minimal: return "square"
        case .branded: return "paintbrush.fill"
        case .gradient: return "wand.and.rays"
        case .glass: return "cube.transparent.fill"
        case .dots: return "circle.grid.3x3.fill"
        case .rounded: return "app.fill"
        }
    }
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(isSelected ? .white : .primary)
                
                Text(design.rawValue)
                    .font(.caption2)
                    .fontWeight(isSelected ? .semibold : .regular)
                    .foregroundColor(isSelected ? .white : .primary)
            }
            .frame(width: 80, height: 70)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ?
                        LinearGradient(
                            colors: [.purple, .blue],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ) :
                        LinearGradient(
                            colors: [Color.gray.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    DesignStyleCard(design: .dots, isSelected: true, action: {})
}
