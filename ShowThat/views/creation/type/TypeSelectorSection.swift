//
//  TypeSelectorSection.swift
//  ShowThat
//
//  Created by Giuseppe De Masi on 25/06/2025.
//

import SwiftUI

struct TypeSelectorSection: View {
    @Binding var selectedType: QRCodeType
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            Label("QR Code Type", systemImage: "qrcode")
                .font(.headline)
                .padding(.horizontal)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(QRCodeType.allCases, id: \.self) { type in
                        TypeCard(
                            type: type,
                            isSelected: selectedType == type,
                            action: { selectedType = type }
                        )
                    }
                }
                .padding(.horizontal)
            }
        }
    }
}

#Preview {
    TypeSelectorSection(selectedType: .constant(.email))
}
