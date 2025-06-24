//
//  CustomTextField.swift
//  ShowThat
//
//  Created by Giuseppe De Masi on 24/06/2025.
//

import SwiftUI

struct CustomTextField: View {
    let placeholder: String
    @Binding var text: String
    let icon: String
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundStyle(.white.opacity(0.7))
                .frame(width: 20)
            
            TextField(placeholder, text: $text)
                .foregroundStyle(.white)
                .placeholder(when: text.isEmpty) {
                    Text(placeholder)
                        .foregroundStyle(.white.opacity(0.5))
                }
        }
        .padding()
        .background {
            RoundedRectangle(cornerRadius: 12)
                .fill(.white.opacity(0.1))
                .overlay {
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(.white.opacity(0.2), lineWidth: 1)
                }
        }
    }
}

#Preview {
    CustomTextField(placeholder: "Email", text: .constant("email@example.com"), icon: "at")
}
