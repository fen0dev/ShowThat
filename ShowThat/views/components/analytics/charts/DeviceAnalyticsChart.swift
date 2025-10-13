//
//  DeviceAnalyticsChart.swift
//  ShowThat
//
//  Created by Giuseppe De Masi on 02/10/2025.
//

import SwiftUI
import Charts

@available(iOS 16.0, *)
struct DeviceAnalyticsChart: View {
    let data: [String: Int]
    
    private var chartData: [DeviceDataPoint] {
        data.map { DeviceDataPoint(device: $0.key, scans: $0.value) }
            .sorted { $0.scans > $1.scans }
    }
    
    var body: some View {
        Chart(chartData) { point in
            BarMark(
                x: .value("Scans", point.scans),
                y: .value("Device", point.device)
            )
            .foregroundStyle(DesignTokens.Colors.primary)
        }
        .chartXAxis {
            AxisMarks { value in
                AxisValueLabel()
            }
        }
    }
}

#Preview {
    if #available(iOS 16.0, *) {
        DeviceAnalyticsChart(data: ["test": 20])
    } else {
        // Fallback on earlier versions
    }
}
