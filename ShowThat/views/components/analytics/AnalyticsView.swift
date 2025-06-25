//
//  AnalyticsView.swift
//  ShowThat
//
//  Created by Giuseppe De Masi on 25/06/2025.
//

import SwiftUI

struct AnalyticsView: View {
    let analytics: QRAnalyticsSummary
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Analytics")
                .font(.headline)
            
            HStack(spacing: 15) {
                StatsCard(
                    title: "Total Scans",
                    value: "\(analytics.totalScans)",
                    icon: "eye.fill",
                    color: .blue
                )
                
                StatsCard(
                    title: "Unique Scans",
                    value: "\(analytics.uniqueScans)",
                    icon: "person.fill",
                    color: .green
                )
            }
        }
        .padding()
        .background {
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.05), radius: 10, y: 5)
        }
    }
}

#Preview {
    AnalyticsView(analytics: QRAnalyticsSummary(qrCodeId: UUID().uuidString))
}
