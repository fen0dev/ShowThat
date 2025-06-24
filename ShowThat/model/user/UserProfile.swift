//
//  UserProfile.swift
//  ShowThat
//
//  Created by Giuseppe De Masi on 24/06/2025.
//

import Foundation
import FirebaseFirestore

struct UserProfile: Codable {
    @DocumentID var id: String?
    let email: String
    var displayName: String?
    var subscription: UserSubscription
    @ServerTimestamp var createdAt: Date?
    var qrCodesCreated: Int = 0
    var dynamicQRsCreated: Int = 0
    var totalScans: Int = 0
    var isActive: Bool = true
}
