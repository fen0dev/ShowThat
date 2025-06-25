//
//  LinkedInInputSection.swift
//  ShowThat
//
//  Created by Giuseppe De Masi on 25/06/2025.
//

import SwiftUI

struct LinkedInInputSection: View {
    @Binding var content: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("LinkedIn Profile", systemImage: "link")
                .font(.headline)
            
            TextField("linkedin.com/in/yourprofile", text: $content)
                .textFieldStyle(ModernTextFieldStyle())
                .keyboardType(.URL)
                .textInputAutocapitalization(.never)
        }
    }
}

#Preview {
    LinkedInInputSection(content: .constant("www.linkedin.com/in/gius3pp3"))
}
