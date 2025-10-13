//
//  SimpleAnalyticsView.swift
//  ShowThat
//
//  Created by Giuseppe De Masi on 07/10/2025.
//

import SwiftUI

@available(iOS 17.0, *)
struct SimpleAnalyticsView: View {
    let qrCode: QRCodeModel
    @State private var analyticsData: QRAnalyticsData?
    @State private var realTime = RealTimeStats()
    @State private var isLoading = false
    var body: some View {
        VStack(spacing: 16) {
            ModernCard(style: .elevated) {
                HStack {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(qrCode.name)
                            .font(DesignTokens.Typography.headline)
                        Text(qrCode.type.rawValue)
                            .font(DesignTokens.Typography.caption2)
                            .foregroundStyle(DesignTokens.Colors.textSecondary)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .foregroundStyle(DesignTokens.Colors.primary)
                }
            }
            
            ModernCard(style: .elevated) {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Real-Time Stats")
                        .font(DesignTokens.Typography.subheadline)
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                        StatsCard(title: "Last 24h", value: "\(realTime.scansLast24h)", subtitle: "Scans", color: .mint)
                        StatsCard(title: "Users", value: "\(realTime.uniqueScansLast24h)", subtitle: "Last 24h", color: .cyan)
                        StatsCard(title: "Avg/Hour", value: String(format: "%.1f", realTime.averageScansPerHour), subtitle: "Scans", color: .indigo)
                    }
                }
            }

            if let data = analyticsData {
                if !data.scansByCountry.isEmpty || !data.scansByDevice.isEmpty {
                    ModernCard(style: .elevated) {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Top Segments")
                                .font(DesignTokens.Typography.subheadline)
                            if !data.scansByCountry.isEmpty {
                                segmentRow(title: "Countries", values: topN(data.scansByCountry, n: 3))
                            }
                            if !data.scansByDevice.isEmpty {
                                segmentRow(title: "Devices", values: topN(data.scansByDevice, n: 3))
                            }
                        }
                    }
                }
            }
        }
        .task { await load() }
    }
    
    private func load() async {
        guard let id = qrCode.id else { isLoading = false; return }
        do {
            let insights = try await AnalyticsManager.shared.getAnalyticsInsights(for: id)
            let rt = await AnalyticsManager.shared.getRealTimeStats(for: id)
            await MainActor.run {
                self.analyticsData = insights
                self.realTime = rt
                self.isLoading = false
            }
        } catch {
            await MainActor.run { self.isLoading = false }
        }
    }

    private func topN(_ dict: [String: Int], n: Int) -> [String] {
        Array(dict.sorted { $0.value > $1.value }.prefix(n).map { $0.key })
    }
    
    @ViewBuilder
    private func segmentRow(title: String, values: [String]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title).font(DesignTokens.Typography.caption)
            HStack(spacing: 8) {
                ForEach(values, id: \.self) { item in
                    Text(item)
                        .font(DesignTokens.Typography.caption2)
                        .padding(.horizontal, 8).padding(.vertical, 6)
                        .background(DesignTokens.Colors.primary.opacity(0.08))
                        .cornerRadius(8)
                }
            }
        }
    }
}

#Preview {
    if #available(iOS 17.0, *) {
        SimpleAnalyticsView(qrCode: QRCodeModel(userId: UUID().uuidString, name: "Giuseppe", type: .url, content: .url("https://wicte.dk"), style: QRStyle(design: .branded, foregroundColor: .init(color: Color(.systemBlue)), backgroundColor: .init(color: Color(.systemGray)), logoURL: "", cornerRadius: 20), isDynamic: true))
    } else { }
}
