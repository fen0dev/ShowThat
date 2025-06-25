//
//  UsageIndicator.swift
//  ShowThat
//
//  Created by Giuseppe De Masi on 25/06/2025.
//

import SwiftUI

struct UsageIndicator: View {
    let current: Int
    let limit: Int
    let label: String
    
    var percentage: Double {
        limit > 0 ? Double(current) / Double(limit) : 0
    }
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("\(current)/\(limit)")
                .font(.caption)
                .fontWeight(.semibold)
            
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
            
            ProgressView(value: percentage)
                .tint(percentage > 0.8 ? .orange : .cyan)
                .scaleEffect(y: 0.5)
        }
    }
}

#Preview {
    UsageIndicator(current: 2, limit: 5, label: "Test")
}
