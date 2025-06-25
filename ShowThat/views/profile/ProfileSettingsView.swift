//
//  ProfileSettingsView.swift
//  ShowThat
//
//  Created by Giuseppe De Masi on 25/06/2025.
//

import SwiftUI
import FirebaseAuth

struct ProfileSettingsView: View {
    let qrManager: QRCodeManager
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    HStack {
                        Image(systemName: "person.circle.fill")
                            .font(.largeTitle)
                            .foregroundColor(.gray)
                        
                        VStack(alignment: .leading) {
                            Text(qrManager.userProfile?.displayName ?? "User126h594G")
                                .font(.headline)
                            Text(qrManager.userProfile?.email ?? "no@email.here")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.vertical, 8)
                }
                
                Section("Account") {
                    HStack {
                        Label("Subscription", systemImage: "crown")
                        Spacer()
                        Text(qrManager.currentSubscription?.tier.rawValue ?? "Free")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Label("QR Codes Created", systemImage: "qrcode")
                        Spacer()
                        Text("\(qrManager.qrCodes.count)")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Label("Total Scans", systemImage: "eye")
                        Spacer()
                        Text("\(qrManager.qrCodes.reduce(0) { $0 + $1.scanCount })")
                            .foregroundColor(.secondary)
                    }
                }
                
                Section("Preferences") {
                    Toggle("Push Notifications", isOn: .constant(false))
                    Toggle("Email Updates", isOn: .constant(true))
                }
                
                Section {
                    Button("Sign Out") {
                        dismiss()
                        try? Auth.auth().signOut()
                    }
                    .foregroundColor(.red)
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    ProfileSettingsView(qrManager: QRCodeManager())
}
