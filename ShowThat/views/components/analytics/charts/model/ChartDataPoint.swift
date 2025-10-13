//
//  ChartDataPoint.swift
//  ShowThat
//
//  Created by Giuseppe De Masi on 02/10/2025.
//

import Foundation

struct ChartDataPoint: Identifiable {
    let id = UUID()
    let date: String
    let value: Int
}
