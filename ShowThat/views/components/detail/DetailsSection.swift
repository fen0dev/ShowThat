//
//  DetailsSection.swift
//  ShowThat
//
//  Created by Giuseppe De Masi on 25/06/2025.
//

import SwiftUI

struct DetailsSection: View {
    let qrCode: QRCodeModel
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Details")
                .font(.headline)
            
            DetailRow(label: "Type", value: qrCode.type.rawValue)
            DetailRow(label: "Created", value: formatDate(qrCode.createdAt ?? Date()))
            DetailRow(label: "Updated", value: formatDate(qrCode.updatedAt ?? Date()))
            
            if qrCode.isDynamic {
                DetailRow(label: "Short Code", value: qrCode.shortCode ?? "N/A")
            }
            
            DetailRow(label: "Status", value: qrCode.isActive ? "Active" : "Inactive")
        }
        .padding()
        .background {
            RoundedRectangle(cornerRadius: 20)
                .fill(.white)
                .shadow(color: .black.opacity(0.05), radius: 10, y: 5)
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

#Preview {
    DetailsSection(qrCode: QRCodeModel(userId: UUID().uuidString, name: "Giuseppe", type: .vCard, content: .vCard(VCardData(fullName: "TechnoForged Digital")), style: QRStyle()))
}
