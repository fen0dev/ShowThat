//
//  QRCodeContent.swift
//  ShowThat
//
//  Created by Giuseppe De Masi on 24/06/2025.
//

import Foundation

enum QRContent: Codable {
    case url(String) // Store as string for Firestore
    case vCard(VCardData)
    case wifi(WiFiData)
    case email(EmailData)
    case text(String)
    
    var displayText: String {
        switch self {
        case .url(let urlString): return urlString
        case .vCard(let data): return data.fullName
        case .wifi(let data): return data.ssid
        case .email(let data): return data.email
        case .text(let text): return text
        }
    }
    
    var rawValue: String {
        switch self {
        case .url(let urlString):
            return urlString
        case .vCard(let data):
            return data.vCardString
        case .wifi(let data):
            return "WIFI:T:\(data.encryption);S:\(data.ssid);P:\(data.password);;"
        case .email(let data):
            return "mailto:\(data.email)?subject=\(data.subject ?? "")&body=\(data.body ?? "")"
        case .text(let text):
            return text
        }
    }
}
