//
//  StatsCard.swift
//  ShowThat
//
//  Created by Giuseppe De Masi on 25/06/2025.
//

import SwiftUI

struct StatsCard: View {
    let title: String
    let value: String
    let subtitle: String
    let color: Color
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(DesignTokens.Typography.caption)
                .foregroundStyle(DesignTokens.Colors.secondary)
            
            Text(value)
                .font(DesignTokens.Typography.headline)
                .foregroundStyle(color)
            
            Text(subtitle)
                .font(DesignTokens.Typography.caption2)
                .foregroundStyle(DesignTokens.Colors.textTertiary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(color.opacity(0.1))
        .cornerRadius(DesignTokens.CornerRadius.md)
    }
}

#Preview {
    StatsCard(title: "Test", value: "Test", subtitle: "testing", color: .pink)
}
