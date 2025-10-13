//
//  TypeSelectorSection.swift
//  ShowThat
//
//  Created by Giuseppe De Masi on 25/06/2025.
//

import SwiftUI

struct TypeSelectorSection: View {
    @Binding var selectedType: QRCodeType
    @EnvironmentObject var qrManager: QRCodeManager
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            Label("QR Code Type", systemImage: "qrcode")
                .font(.headline)
                .padding(.horizontal)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(QRCodeType.allCases, id: \.self) { type in
                        let allowed = qrManager.currentSubscriptionTier.allowedTypes.contains(type)
                        
                        ZStack {
                            TypeCard(
                                type: type,
                                isSelected: selectedType == type,
                                action: {
                                    if allowed {
                                        selectedType = type
                                    } else {
                                        AlertManager.shared.showInfo(
                                            title: "Upgrade required",
                                            message: "This feature is available from \(getRequiredTier(for: type)) upwards.",
                                            icon: "lock.fill"
                                        )
                                    }
                                }
                            )
                            
                            if !allowed {
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color.black.opacity(0.35))
                                    .overlay(
                                        Image(systemName: "lock.fill")
                                            .foregroundColor(.white)
                                    )
                            }
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
    }
    
    private func getRequiredTier(for type: QRCodeType) -> String {
        switch qrManager.currentSubscriptionTier {
        case .free:
            return type == .vCard || type == .wifi || type == .email || type == .sms || type == .whatsapp ? "Pro" : "Business"
        case .pro:
            return type == .linkedIn ? "Business" : "Pro"
        default:
            return "Free"
        }
    }
}

#Preview {
    TypeSelectorSection(selectedType: .constant(.url))
        .environmentObject(QRCodeManager())
}
