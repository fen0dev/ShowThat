//
//  DeviceDataPoint.swift
//  ShowThat
//
//  Created by Giuseppe De Masi on 02/10/2025.
//

import Foundation

struct DeviceDataPoint: Identifiable {
    let id = UUID()
    let device: String
    let scans: Int
}
