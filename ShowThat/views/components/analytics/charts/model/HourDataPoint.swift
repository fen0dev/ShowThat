//
//  HourDataPoint.swift
//  ShowThat
//
//  Created by Giuseppe De Masi on 02/10/2025.
//

import Foundation

struct HourDataPoint: Identifiable {
    let id = UUID()
    let hour: Int
    let scans: Int
}
