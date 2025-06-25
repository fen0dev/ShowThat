//
//  PhoneInputSection.swift
//  ShowThat
//
//  Created by Giuseppe De Masi on 25/06/2025.
//

import SwiftUI

struct PhoneInputSection: View {
    let type: QRCodeType
    @Binding var content: String
    
    var placeholder: String {
        switch type {
        case .sms:
            return "+1234567890"
        case .whatsapp:
            return "+1234567890"
        default:
            return ""
        }
    }
    
    var label: String {
        switch type {
        case .sms:
            return "Phone Number for SMS"
        case .whatsapp:
            return "WhatsApp Number"
        default:
            return "Phone Number"
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label(label, systemImage: "phone")
                .font(.headline)
            
            TextField(placeholder, text: $content)
                .textFieldStyle(ModernTextFieldStyle())
                .keyboardType(.phonePad)
        }
    }
}

#Preview {
    PhoneInputSection(type: .sms, content: .constant("+393883556672"))
}
