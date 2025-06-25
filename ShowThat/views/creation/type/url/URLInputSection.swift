//
//  URLInputSection.swift
//  ShowThat
//
//  Created by Giuseppe De Masi on 25/06/2025.
//

import SwiftUI

struct URLInputSection: View {
    @Binding var urlString: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Website URL", systemImage: "globe")
                .font(.headline)
            
            TextField("https://example.com", text: $urlString)
                .textFieldStyle(ModernTextFieldStyle())
                .textInputAutocapitalization(.never)
                .keyboardType(.URL)
                .autocorrectionDisabled()
        }
    }
}

#Preview {
    URLInputSection(urlString: .constant("https://www.google.com"))
}
