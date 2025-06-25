//
//  UsageBar.swift
//  ShowThat
//
//  Created by Giuseppe De Masi on 25/06/2025.
//

import SwiftUI

struct UsageBar: View {
    let title: String
    let current: Int
    let limit: Int
    
    var percentage: Double {
        guard limit > 0 else { return 0 }
        return min(Double(current) / Double(limit), 1.0)
    }
    
    var isNearLimit: Bool {
        percentage >= 0.8
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text("\(current)/\(limit)")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(isNearLimit ? .orange : .primary)
            }
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.gray.opacity(0.2))
                    
                    // Progress
                    RoundedRectangle(cornerRadius: 4)
                        .fill(
                            LinearGradient(
                                colors: isNearLimit ? [.orange, .red] : [.blue, .purple],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geometry.size.width * percentage)
                        .animation(.spring(), value: percentage)
                }
            }
            .frame(height: 8)
        }
    }
}

#Preview {
    UsageBar(title: "Test", current: 2, limit: 6)
}
