//
//  QRAnalyticsSummary.swift
//  ShowThat
//
//  Created by Giuseppe De Masi on 24/06/2025.
//

import Foundation
import FirebaseFirestore

struct QRAnalyticsSummary: Codable {
    @DocumentID var id: String?
    let qrCodeId: String
    var totalScans: Int = 0
    var uniqueScans: Int = 0
    var scansByDay: [String: Int] = [:] // ISO date string: count
    var scansByCountry: [String: Int] = [:]
    var scansByDevice: [String: Int] = [:]
    var scansByBrowser: [String: Int] = [:]
    @ServerTimestamp var lastUpdated: Date?
}
