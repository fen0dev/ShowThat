//
//  DynamicQRToggle.swift
//  ShowThat
//
//  Created by Giuseppe De Masi on 25/06/2025.
//

import SwiftUI

struct DynamicQRToggle: View {
    @Binding var isDynamic: Bool
    let canCreate: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                VStack(alignment: .leading, spacing: 5) {
                    HStack {
                        Image(systemName: "arrow.triangle.2.circlepath.circle.fill")
                            .foregroundColor(.green)
                        
                        Text("Dynamic QR Code")
                            .font(.headline)
                        
                        Text("PRO")
                            .font(.caption2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(
                                Capsule()
                                    .fill(Color.green)
                            )
                    }
                    
                    Text("Edit destination after creation")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Toggle("", isOn: $isDynamic)
                    .disabled(!canCreate)
            }
            
            if !canCreate && isDynamic {
                Label("Upgrade to create more dynamic QR codes", systemImage: "info.circle")
                    .font(.caption)
                    .foregroundColor(.orange)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(Color.green.opacity(0.1))
        )
    }
}

#Preview {
    DynamicQRToggle(isDynamic: .constant(false), canCreate: false)
}
