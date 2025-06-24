//
//  ScanEvent.swift
//  ShowThat
//
//  Created by Giuseppe De Masi on 24/06/2025.
//

import Foundation
import FirebaseFirestore

struct ScanEvent: Identifiable, Codable {
    @DocumentID var id: String?
    let qrCodeId: String
    @ServerTimestamp var timestamp: Date?
    let location: ScanLocation?
    let device: DeviceInfo
    let referrer: String?
}
