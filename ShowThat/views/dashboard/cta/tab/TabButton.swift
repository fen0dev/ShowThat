//
//  TabButton.swift
//  ShowThat
//
//  Created by Giuseppe De Masi on 25/06/2025.
//

import SwiftUI

struct TabButton: View {
    let title: String
    let count: Int
    let isSelected: Bool
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            HStack {
                Text(title)
                    .fontWeight(isSelected ? .semibold : .regular)
                
                if count > 0 {
                    Text("\(count)")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(isSelected ? .white : .gray)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(isSelected ? .blue : .gray.opacity(0.2), in: Capsule())
                }
            }
            .foregroundStyle(isSelected ? .primary : .secondary)
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
            .background(isSelected ? .blue.opacity(0.1) : .clear, in: RoundedRectangle(cornerRadius: 20))
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    TabButton(title: "Test", count: 6, isSelected: true, action: {})
}
