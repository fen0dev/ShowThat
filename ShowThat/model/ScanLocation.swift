//
//  ScanLocation.swift
//  ShowThat
//
//  Created by Giuseppe De Masi on 24/06/2025.
//

import Foundation

struct ScanLocation: Codable {
    let country: String
    let city: String?
    let region: String?
    let latitude: Double?
    let longitude: Double?
}
