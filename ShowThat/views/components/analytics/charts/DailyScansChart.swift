//
//  DailyScansChart.swift
//  ShowThat
//
//  Created by Giuseppe De Masi on 02/10/2025.
//

import SwiftUI
import Charts

@available(iOS 16.0, *)
struct DailyScansChart: View {
    let data: [String: Int]
    
    private var chartData: [ChartDataPoint] {
        data.sorted { $0.key < $1.key }.map { ChartDataPoint(date: $0.key, value: $0.value) }
    }
    
    var body: some View {
        Chart(chartData) { point in
            LineMark(
                x: .value("Date", point.date),
                y: .value("Scans", point.value)
            )
            .foregroundStyle(DesignTokens.Colors.primary)
            .lineStyle(StrokeStyle(lineWidth: 3))
            
            AreaMark(
                x: .value("Date", point.date),
                y: .value("Scans", point.value)
            )
            .foregroundStyle(
                LinearGradient(
                    colors: [DesignTokens.Colors.primary.opacity(0.3), DesignTokens.Colors.primary.opacity(0.1)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
        }
        .chartXAxis {
            AxisMarks(values: .stride(by: .day)) { value in
                AxisGridLine()
                AxisValueLabel(format: .dateTime.month().day())
            }
        }
        .chartYAxis {
            AxisMarks { value in
                AxisGridLine()
                AxisValueLabel()
            }
        }
    }
}

#Preview {
    if #available(iOS 16.0, *) {
        DailyScansChart(data: ["test" : 20])
    } else {
        // Fallback on earlier versions
    }
}
