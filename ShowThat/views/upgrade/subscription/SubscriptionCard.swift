//
//  SubscriptionCard.swift
//  ShowThat
//
//  Created by Giuseppe De Masi on 25/06/2025.
//

import SwiftUI

struct SubscriptionCard: View {
    let tier: UserSubscription.Tier
    let isSelected: Bool
    let isCurrent: Bool
    let action: () -> Void
    
    var popularBadge: Bool {
        tier == .pro
    }
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 20) {
                header
                
                // Key Features
                VStack(alignment: .leading, spacing: 12) {
                    ForEach(tier.features.prefix(4), id: \.self) { feature in
                        HStack(spacing: 10) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.caption)
                                .foregroundColor(.green)
                            
                            Text(feature)
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.9))
                            
                            Spacer()
                        }
                    }
                }
            }
            .padding(25)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(
                        LinearGradient(
                            colors: isSelected ?
                                [Color.purple.opacity(0.3), Color.blue.opacity(0.3)] :
                                [Color.white.opacity(0.1), Color.white.opacity(0.05)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(
                                isSelected ? Color.purple : Color.white.opacity(0.2),
                                lineWidth: isSelected ? 2 : 1
                            )
                    )
            )
            .scaleEffect(isSelected ? 1.02 : 1.0)
        }
        .buttonStyle(.plain)
    }
    
    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 5) {
                HStack {
                    Text(tier.rawValue)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    if popularBadge {
                        Text("POPULAR")
                            .font(.caption2)
                            .fontWeight(.bold)
                            .foregroundColor(.black)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(
                                Capsule()
                                    .fill(Color.yellow)
                            )
                    }
                    
                    if isCurrent {
                        Text("CURRENT")
                            .font(.caption2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(
                                Capsule()
                                    .fill(Color.green)
                            )
                    }
                }
                
                HStack(alignment: .bottom, spacing: 4) {
                    Text("$\(tier.price, specifier: "%.0f")")
                        .font(.system(size: 36, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text("/month")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.7))
                        .padding(.bottom, 5)
                }
            }
            
            Spacer()
            
            Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                .font(.title)
                .foregroundColor(isSelected ? .green : .white.opacity(0.3))
        }
    }
}

#Preview {
    SubscriptionCard(tier: .enterprise, isSelected: true, isCurrent: true, action: {})
}
