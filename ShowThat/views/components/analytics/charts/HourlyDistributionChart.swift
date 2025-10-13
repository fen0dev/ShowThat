//
//  HourlyDistributionChart.swift
//  ShowThat
//
//  Created by Giuseppe De Masi on 02/10/2025.
//

import SwiftUI
import Charts

@available(iOS 16.0, *)
struct HourlyDistributionChart: View {
    let data: [Int: Int]
    
    private var chartData: [HourDataPoint] {
        (0..<24).map { hour in
            HourDataPoint(hour: hour, scans: data[hour] ?? 0)
        }
    }
    
    var body: some View {
        Chart(chartData) { point in
            BarMark(
                x: .value("Hour", point.hour),
                y: .value("Scans", point.scans)
            )
            .foregroundStyle(
                LinearGradient(
                    colors: [DesignTokens.Colors.primary, DesignTokens.Colors.secondary],
                    startPoint: .bottom,
                    endPoint: .top
                )
            )
        }
        .chartXAxis {
            AxisMarks(values: .stride(by: 4)) { value in
                AxisValueLabel {
                    if let hour = value.as(Int.self) {
                        Text("\(hour):00")
                    }
                }
            }
        }
    }
}

#Preview {
    if #available(iOS 16.0, *) {
        HourlyDistributionChart(data: [10 : 10])
    } else {
        // Fallback on earlier versions
    }
}
