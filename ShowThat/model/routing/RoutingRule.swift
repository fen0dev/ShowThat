//
//  RoutingRule.swift
//  ShowThat
//
//  Created by Giuseppe De Masi on 24/06/2025.
//

import Foundation
import FirebaseFirestore

struct RoutingRule: Codable {
    @DocumentID var id: String?
    let qrCodeId: String
    var name: String
    var priority: Int
    var conditions: [RoutingCondition]
    var destinationURL: String
    var isActive: Bool = true
}

struct RoutingCondition: Codable {
    enum ConditionType: String, Codable {
        case timeRange = "time_range"
        case deviceType = "device_type"
        case location = "location"
        case scanCount = "scan_count"
    }
    
    var type: ConditionType
    var parameters: [String: String]
}
