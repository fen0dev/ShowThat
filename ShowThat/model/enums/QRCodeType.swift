//
//  QRCodeType.swift
//  ShowThat
//
//  Created by Giuseppe De Masi on 24/06/2025.
//

import SwiftUI

enum QRCodeType: String, CaseIterable, Codable {
    case url = "URL"
    case vCard = "Business Card"
    case wifi = "WiFi"
    case email = "Email"
    case sms = "SMS"
    case whatsapp = "WhatsApp"
    case linkedIn = "LinkedIn"
    
    var icon: String {
        switch self {
        case .url: return "globe"
        case .vCard: return "person.crop.rectangle"
        case .wifi: return "wifi"
        case .email: return "envelope"
        case .sms: return "message"
        case .whatsapp: return "message.circle.fill"
        case .linkedIn: return "link.circle.fill"
        }
    }
}
