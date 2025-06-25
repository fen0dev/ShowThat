//
//  WiFiInputSection.swift
//  ShowThat
//
//  Created by Giuseppe De Masi on 25/06/2025.
//

import SwiftUI

struct WiFiInputSection: View {
    @Binding var wifiData: WiFiData
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            Label("WiFi Network", systemImage: "wifi")
                .font(.headline)
            
            TextField("Network Name (SSID) *", text: $wifiData.ssid)
                .textFieldStyle(ModernTextFieldStyle())
            
            SecureField("Password", text: $wifiData.password)
                .textFieldStyle(ModernTextFieldStyle())
            
            Picker("Encryption", selection: $wifiData.encryption) {
                Text("WPA/WPA2").tag("WPA")
                Text("WEP").tag("WEP")
                Text("None").tag("nopass")
            }
            .pickerStyle(SegmentedPickerStyle())
            
            Toggle("Hidden Network", isOn: $wifiData.isHidden)
                .tint(.blue)
        }
    }
}

#Preview {
    WiFiInputSection(wifiData: .constant(WiFiData(ssid: UUID().uuidString, password: "ThisIsPassword1234@!<>")))
}
