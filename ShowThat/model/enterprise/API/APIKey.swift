//
//  APIKey.swift
//  ShowThat
//
//  Created by Giuseppe De Masi on 24/06/2025.
//

import Foundation
import FirebaseFirestore

struct APIKey: Codable {
    @DocumentID var id: String?
    let userId: String
    let teamId: String?
    var name: String
    var key: String
    var permissions: [String]
    @ServerTimestamp var createdAt: Date?
    var lastUsed: Date?
    var isActive: Bool = true
}
