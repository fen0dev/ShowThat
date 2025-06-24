//
//  DeviceInfo.swift
//  ShowThat
//
//  Created by Giuseppe De Masi on 24/06/2025.
//

import Foundation

struct DeviceInfo: Codable {
    let platform: String // iOS, Android, etc
    let browser: String?
    let osVersion: String?
    let deviceType: String? // phone, tablet, desktop
}
