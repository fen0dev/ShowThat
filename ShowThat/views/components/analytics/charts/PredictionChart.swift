//
//  PredictionChart.swift
//  ShowThat
//
//  Created by Giuseppe De Masi on 02/10/2025.
//

import SwiftUI
import Charts

@available(iOS 16.0, *)
struct PredictionChart: View {
    let predictions: [String: Int]
    
    private var chartData: [PredictionDataPoint] {
        predictions.sorted { $0.key < $1.key }.map { PredictionDataPoint(date: $0.key, predicted: $0.value) }
    }
    
    var body: some View {
        Chart(chartData) { point in
            LineMark(
                x: .value("Date", point.date),
                y: .value("Predicted", point.predicted)
            )
            .foregroundStyle(DesignTokens.Colors.warning)
            .lineStyle(StrokeStyle(lineWidth: 2, dash: [5, 5]))
            
            AreaMark(
                x: .value("Date", point.date),
                y: .value("Predicted", point.predicted)
            )
            .foregroundStyle(DesignTokens.Colors.warning.opacity(0.2))
        }
        .chartXAxis {
            AxisMarks(values: .stride(by: .day)) { value in
                AxisValueLabel(format: .dateTime.month().day())
            }
        }
    }
}

#Preview {
    if #available(iOS 16.0, *) {
        PredictionChart(predictions: ["test": 20])
    } else {
        // Fallback on earlier versions
    }
}
