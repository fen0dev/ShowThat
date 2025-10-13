//
//  EmailInputSection.swift
//  ShowThat
//
//  Created by Giuseppe De Masi on 25/06/2025.
//

import SwiftUI

@available(iOS 16.0, *)
struct EmailInputSection: View {
    @Binding var emailData: EmailData
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            Label("Email Details", systemImage: "envelope")
                .font(.headline)
            
            TextField("Email Address *", text: $emailData.email)
                .textFieldStyle(ModernTextFieldStyle())
                .keyboardType(.emailAddress)
                .textInputAutocapitalization(.never)
            
            TextField("Subject (Optional)", text: .init(
                get: { emailData.subject ?? "" },
                set: { emailData.subject = $0.isEmpty ? nil : $0 }
            ))
            .textFieldStyle(ModernTextFieldStyle())
            
            TextField("Message (Optional)", text: .init(
                get: { emailData.body ?? "" },
                set: { emailData.body = $0.isEmpty ? nil : $0 }
            ), axis: .vertical)
            .textFieldStyle(ModernTextFieldStyle())
            .lineLimit(3...6)
        }
    }
}

#Preview {
    if #available(iOS 16.0, *) {
        EmailInputSection(emailData: .constant(EmailData(email: "this@example.com")))
    } else {
        // Fallback on earlier versions
    }
}
