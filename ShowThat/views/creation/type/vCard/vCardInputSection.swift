//
//  vCardInputSection.swift
//  ShowThat
//
//  Created by Giuseppe De Masi on 25/06/2025.
//

import SwiftUI

struct vCardInputSection: View {
    @Binding var vCardData: VCardData
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            Label("Contact Information", systemImage: "person.crop.rectangle")
                .font(.headline)
            
            Group {
                TextField("Full Name *", text: $vCardData.fullName)
                    .textFieldStyle(ModernTextFieldStyle())
                
                TextField("Company", text: .init(
                    get: { vCardData.organization ?? "" },
                    set: { vCardData.organization = $0.isEmpty ? nil : $0 }
                ))
                .textFieldStyle(ModernTextFieldStyle())
                
                TextField("Job Title", text: .init(
                    get: { vCardData.title ?? "" },
                    set: { vCardData.title = $0.isEmpty ? nil : $0 }
                ))
                .textFieldStyle(ModernTextFieldStyle())
                
                TextField("Phone", text: .init(
                    get: { vCardData.phone ?? "" },
                    set: { vCardData.phone = $0.isEmpty ? nil : $0 }
                ))
                .textFieldStyle(ModernTextFieldStyle())
                .keyboardType(.phonePad)
                
                TextField("Email", text: .init(
                    get: { vCardData.email ?? "" },
                    set: { vCardData.email = $0.isEmpty ? nil : $0 }
                ))
                .textFieldStyle(ModernTextFieldStyle())
                .keyboardType(.emailAddress)
                .textInputAutocapitalization(.never)
                
                TextField("Website", text: .init(
                    get: { vCardData.website ?? "" },
                    set: { vCardData.website = $0.isEmpty ? nil : $0 }
                ))
                .textFieldStyle(ModernTextFieldStyle())
                .keyboardType(.URL)
                .textInputAutocapitalization(.never)
            }
        }
    }
}

#Preview {
    vCardInputSection(vCardData: .constant(VCardData(fullName: "TechnoForged Digital")))
}
