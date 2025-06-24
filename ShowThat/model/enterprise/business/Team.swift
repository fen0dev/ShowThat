//
//  Team.swift
//  ShowThat
//
//  Created by Giuseppe De Masi on 24/06/2025.
//

import Foundation
import FirebaseFirestore

struct Team: Codable {
    @DocumentID var id: String?
    var name: String
    var ownerId: String
    var memberIds: [String]
    @ServerTimestamp var createdAt: Date?
    var qrCodeIds: [String] = []
    var settings: TeamSettings
}

struct TeamSettings: Codable {
    var defaultStyle: QRStyle?
    var brandGuidelines: BrandGuidelines?
    var webhookURL: String?
}

struct BrandGuidelines: Codable {
    var primaryColor: CodableColor
    var secondaryColor: CodableColor
    var logoURL: String
    var fontName: String?
}
