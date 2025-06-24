//
//  QRCodeModel.swift
//  ShowThat
//
//  Created by Giuseppe De Masi on 24/06/2025.
//

import Foundation
import SwiftUI
import FirebaseFirestore

struct QRCodeModel: Identifiable, Codable {
    @DocumentID var id: String?
    let userId: String
    var name: String
    var type: QRCodeType
    var content: QRContent
    var style: QRStyle
    var isDynamic: Bool
    let shortCode: String?
    @ServerTimestamp var createdAt: Date?
    @ServerTimestamp var updatedAt: Date?
    var scanCount: Int = 0
    var isActive: Bool = true
    var tags: [String] = []
    
    // Computed property for Firestore collection reference
    var dynamicURL: String? {
        guard isDynamic, let shortCode = shortCode else { return nil }
        return "https://showt.hat/\(shortCode)" // Your Firebase hosting domain
    }
    
    // Initialize for new QR codes
    init(userId: String, name: String, type: QRCodeType, content: QRContent, style: QRStyle, isDynamic: Bool = false) {
        self.userId = userId
        self.name = name
        self.type = type
        self.content = content
        self.style = style
        self.isDynamic = isDynamic
        self.shortCode = isDynamic ? QRCodeModel.generateShortCode() : nil
    }
    
    static func generateShortCode() -> String {
        let letters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        return String((0..<8).map{ _ in letters.randomElement()! })
    }
}



