//
//  AnalyticsView.swift
//  ShowThat
//
//  Created by Giuseppe De Masi on 25/06/2025.
//

import SwiftUI
import Charts

@available(iOS 17.0, *)
struct AnalyticsView: View {
    @EnvironmentObject var qrManager: QRCodeManager
    @StateObject private var analyticsManager = AnalyticsManager.shared
    @State private var selectedQRCode: QRCodeModel?
    @State private var selectedTimeRange: TimeRange = .last7Days
    @State private var analyticsData: QRAnalyticsData?
    @State private var realTimeStats: RealTimeStats = RealTimeStats()
    @State private var predictions: [String: Int] = [:]
    @State private var isLoading = true
    @State private var showQRCodeSelector = false
    
    var totalScans: Int {
        qrManager.qrCodes.reduce(0) { $0 + $1.scanCount }
    }
    
    var activeQRCodes: Int {
        qrManager.qrCodes.filter { $0.isActive }.count
    }
    
    enum TimeRange: String, CaseIterable {
        case last24Hours = "24h"
        case last7Days = "7d"
        case last30Days = "30d"
        case last90Days = "90d"
        
        var days: Int {
            switch self {
            case .last24Hours: return 1
            case .last7Days: return 7
            case .last30Days: return 30
            case .last90Days: return 90
            }
        }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // background gradient
                LinearGradient(
                    gradient: Gradient(colors: [
                        DesignTokens.Colors.backgroundPrimary,
                        DesignTokens.Colors.backgroundSecondary
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // QR code selector
                    if qrManager.qrCodes.count > 1 {
                        qrCodeSelectorView
                            .padding(.horizontal)
                    }
                    
                    if isLoading {
                        LoadingView(message: "Loading Analytics")
                    } else if let qrCode = selectedQRCode, let data = analyticsData {
                        ScrollView {
                            VStack(spacing: 20) {
                                headerView(qrCode: qrCode)
                                realTimeStatsView
                                performanceInsightsView(data.performanceInsights)
                                chartsSection(data)
                                geographicDistributionView(data)
                                deviceAnalyticsView(data)
                                conversionEventsView(data.conversionEvents)
                                
                                if !predictions.isEmpty {
                                    predictionsView
                                }
                            }
                            .padding()
                        }
                    } else {
                        emptyStateView
                    }
                }
            }
            .navigationBarHidden(true)
            .onAppear {
                loadAllAnalytics()
            }
            .refreshable {
                await refreshAnalytics()
            }
        }
    }
    
    
    private func headerView(qrCode: QRCodeModel) -> some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack {
                VStack(alignment: .leading) {
                    Text(qrCode.name)
                        .font(DesignTokens.Typography.title)
                        .foregroundColor(DesignTokens.Colors.textPrimary)
                    
                    Text(qrCode.type.rawValue)
                        .font(DesignTokens.Typography.subheadline)
                        .foregroundColor(DesignTokens.Colors.textSecondary)
                }
                
                Spacer()
                
                // QR Code Type Icon
                Image(systemName: qrCode.type.icon)
                    .font(.title)
                    .foregroundColor(DesignTokens.Colors.primary)
                    .frame(width: 50, height: 50)
                    .background(Circle().fill(DesignTokens.Colors.primary.opacity(0.1)))
            }
            
            // Time Range Selector
            Picker("Time Range", selection: $selectedTimeRange) {
                ForEach(TimeRange.allCases, id: \.self) { range in
                    Text(range.rawValue).tag(range)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
            .onChange(of: selectedTimeRange) { _, _ in
                loadAllAnalytics()
            }
        }
        .padding()
        .background(DesignTokens.Colors.surface)
        .cornerRadius(DesignTokens.CornerRadius.lg)
        .shadow(color: DesignTokens.Shadow.md, radius: 10, y: 5)
    }
    
    private var qrCodeSelectorView: some View {
        ModernCard(style: .elevated) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(qrManager.qrCodes.prefix(5)) { qrCode in
                        Button {
                            selectedQRCode = qrCode
                            loadAllAnalytics()
                        } label: {
                            HStack {
                                Image(systemName: qrCode.type.icon)
                                    .font(.caption)
                                    .foregroundColor(selectedQRCode?.id == qrCode.id ? DesignTokens.Colors.primary : DesignTokens.Colors.textSecondary)
                                
                                Text(qrCode.name)
                                    .font(DesignTokens.Typography.caption)
                                    .foregroundColor(selectedQRCode?.id == qrCode.id ? DesignTokens.Colors.primary : DesignTokens.Colors.textPrimary)
                                    .lineLimit(1)
                                
                                Text("\(qrCode.scanCount)")
                                    .font(DesignTokens.Typography.caption2)
                                    .foregroundColor(DesignTokens.Colors.textSecondary)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(DesignTokens.Colors.primary.opacity(0.1))
                                    .cornerRadius(10)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(
                                RoundedRectangle(cornerRadius: 20)
                                    .fill(selectedQRCode?.id == qrCode.id ? DesignTokens.Colors.primary.opacity(0.1) : DesignTokens.Colors.surface)
                            )
                        }
                    }
                }
                .padding(.vertical, 8)
            }
        }
    }
    
    private func conversionEventsView(_ events: [ConversionEvent]) -> some View {
        ModernCard(style: .elevated) {
            VStack(alignment: .leading, spacing: 15) {
                HStack {
                    Text("Conversion Events")
                        .font(DesignTokens.Typography.headline)
                    
                    Spacer()
                    
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(DesignTokens.Colors.success)
                }
                
                if events.isEmpty {
                    Text("No conversion events recorded yet")
                        .font(DesignTokens.Typography.body)
                        .foregroundColor(DesignTokens.Colors.textSecondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding()
                } else {
                    LazyVStack(spacing: 10) {
                        ForEach(events.prefix(5), id: \.eventType) { event in
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(event.eventType)
                                        .font(DesignTokens.Typography.subheadline)
                                        .fontWeight(.semibold)
                                    
                                    Text(event.timestamp, style: .date)
                                        .font(DesignTokens.Typography.caption)
                                        .foregroundColor(DesignTokens.Colors.textSecondary)
                                }
                                
                                Spacer()
                                
                                if let value = event.value {
                                    Text("+\(String(format: "%.2f", value))")
                                        .font(DesignTokens.Typography.caption)
                                        .foregroundColor(DesignTokens.Colors.success)
                                        .fontWeight(.semibold)
                                }
                            }
                            .padding(.vertical, 8)
                            .padding(.horizontal, 12)
                            .background(DesignTokens.Colors.success.opacity(0.1))
                            .cornerRadius(8)
                        }
                    }
                }
            }
        }
    }
    
    private var realTimeStatsView: some View {
        ModernCard(style: .elevated) {
            VStack(alignment: .leading, spacing: 15) {
                HStack {
                    Text("Real-Time Stats")
                        .font(DesignTokens.Typography.headline)
                    
                    Spacer()
                    
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .foregroundColor(DesignTokens.Colors.primary)
                }
                
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 15) {
                    StatsCard(
                        title: "Last 24h",
                        value: "\(realTimeStats.scansLast24h)",
                        subtitle: "scansioni",
                        color: .blue
                    )
                    
                    StatsCard(
                        title: "Unique Users",
                        value: "\(realTimeStats.uniqueScansLast24h)",
                        subtitle: "ultime 24h",
                        color: .green
                    )
                    
                    StatsCard(
                        title: "Average/Hour",
                        value: String(format: "%.1f", realTimeStats.averageScansPerHour),
                        subtitle: "scansioni",
                        color: .orange
                    )
                }
            }
        }
    }
    
    private func performanceInsightsView(_ insights: PerformanceInsights) -> some View {
        ModernCard(style: .elevated) {
            VStack(alignment: .leading, spacing: 15) {
                HStack {
                    Text("Performance Insights")
                        .font(DesignTokens.Typography.headline)
                    
                    Spacer()
                    
                    Image(systemName: "lightbulb.fill")
                        .foregroundColor(DesignTokens.Colors.warning)
                }
                
                // Growth Rate
                HStack {
                    VStack(alignment: .leading) {
                        Text("Growth Rate")
                            .font(DesignTokens.Typography.subheadline)
                            .foregroundColor(DesignTokens.Colors.textSecondary)
                        
                        Text("\(String(format: "%.1f", insights.growthRate))%")
                            .font(DesignTokens.Typography.headline)
                            .foregroundColor(insights.growthRate >= 0 ? DesignTokens.Colors.success : DesignTokens.Colors.error)
                    }
                    
                    Spacer()
                    
                    Image(systemName: insights.growthRate >= 0 ? "arrow.up.right" : "arrow.down.right")
                        .foregroundColor(insights.growthRate >= 0 ? DesignTokens.Colors.success : DesignTokens.Colors.error)
                }
                
                // Recommendations
                if !insights.recommendations.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Suggestions")
                            .font(DesignTokens.Typography.subheadline)
                            .foregroundColor(DesignTokens.Colors.textSecondary)
                        
                        ForEach(insights.recommendations.prefix(3), id: \.self) { recommendation in
                            HStack(alignment: .top, spacing: 8) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(DesignTokens.Colors.primary)
                                    .font(.caption)
                                
                                Text(recommendation)
                                    .font(DesignTokens.Typography.caption)
                                    .foregroundColor(DesignTokens.Colors.textPrimary)
                                
                                Spacer()
                            }
                        }
                    }
                }
            }
        }
    }
    
    private func chartsSection(_ data: QRAnalyticsData) -> some View {
        VStack(spacing: 20) {
            // Daily Scans Chart
            if !data.scansByDay.isEmpty {
                ModernCard(style: .elevated) {
                    VStack(alignment: .leading, spacing: 15) {
                        Text("Daily Scans")
                            .font(DesignTokens.Typography.headline)
                        
                        DailyScansChart(data: data.scansByDay)
                            .frame(height: 200)
                    }
                }
            }
            
            // Hourly Distribution Chart
            if !data.scansByHour.isEmpty {
                ModernCard(style: .elevated) {
                    VStack(alignment: .leading, spacing: 15) {
                        Text("Hourly Distributed")
                            .font(DesignTokens.Typography.headline)
                        
                        HourlyDistributionChart(data: data.scansByHour)
                            .frame(height: 150)
                    }
                }
            }
        }
    }
    
    private func geographicDistributionView(_ data: QRAnalyticsData) -> some View {
        ModernCard(style: .elevated) {
            VStack(alignment: .leading, spacing: 15) {
                Text("GRographic Distributed")
                    .font(DesignTokens.Typography.headline)
                
                if data.scansByCountry.isEmpty {
                    Text("No geographic data available")
                        .font(DesignTokens.Typography.body)
                        .foregroundColor(DesignTokens.Colors.textSecondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding()
                } else {
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 10) {
                        ForEach(Array(data.scansByCountry.sorted { $0.value > $1.value }.prefix(6)), id: \.key) { country, count in
                            HStack {
                                Text(country)
                                    .font(DesignTokens.Typography.caption)
                                
                                Spacer()
                                
                                Text("\(count)")
                                    .font(DesignTokens.Typography.caption)
                                    .fontWeight(.semibold)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(DesignTokens.Colors.primary.opacity(0.1))
                            .cornerRadius(8)
                        }
                    }
                }
            }
        }
    }
    
    private func deviceAnalyticsView(_ data: QRAnalyticsData) -> some View {
        ModernCard(style: .elevated) {
            VStack(alignment: .leading, spacing: 15) {
                Text("Device Analytics")
                    .font(DesignTokens.Typography.headline)
                
                if data.scansByDevice.isEmpty {
                    Text("No device data available")
                        .font(DesignTokens.Typography.body)
                        .foregroundStyle(DesignTokens.Colors.textSecondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding()
                } else {
                    DeviceAnalyticsChart(data: data.scansByDevice)
                        .frame(height: 200)
                }
            }
        }
    }
    
    private var predictionsView: some View {
        ModernCard(style: .elevated) {
            VStack(alignment: .leading, spacing: 15) {
                HStack {
                    Text("Predictions")
                        .font(DesignTokens.Typography.headline)
                    
                    Spacer()
                    
                    Image(systemName: "crystal.ball.fill")
                        .foregroundStyle(DesignTokens.Colors.primary)
                }
                
                PredictionChart(predictions: predictions)
                    .frame(height: 150)
            }
        }
    }
    
    private var emptyStateView: some View {
        EmptyStateView(
            icon: "chart.line.uptrend.xyaxis",
            title: "Analytics Unavailable",
            message: "Select a QR Code to view analytics"
        )
    }
    
    private func loadAllAnalytics() {
        guard let qrCode = selectedQRCode ?? qrManager.qrCodes.first else {
            isLoading = false
            return
        }
        
        selectedQRCode = qrCode
        isLoading = true
        
        Task {
            do {
                let data = try await analyticsManager.getAnalyticsInsights(for: qrCode.id ?? "")
                let stats = await analyticsManager.getRealTimeStats(for: qrCode.id ?? "")
                let pred = await analyticsManager.predictFutureScans(for: qrCode.id ?? "")
                
                await MainActor.run {
                    self.analyticsData = data
                    self.realTimeStats = stats
                    self.predictions = pred
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.isLoading = false
                }
                Logger.shared.logError("Failed to load analytics: \(error)")
            }
        }
    }
    
    private func refreshAnalytics() async {
        await MainActor.run {
            self.isLoading = true
        }
        loadAllAnalytics()
    }
}

struct QRCodeAnalyticsRow: View {
    let qrCode: QRCodeModel
    let analytics: QRAnalyticsSummary?
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Image(systemName: qrCode.type.icon)
                    .font(.title3)
                    .foregroundStyle(.blue)
                    .frame(width: 40, height: 40)
                    .background(Circle().fill(Color.blue.opacity(0.1)))
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(qrCode.name)
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Text(qrCode.type.rawValue)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("\(qrCode.scanCount)")
                        .font(.headline)
                        .foregroundStyle(.primary)
                    
                    Text("Total Scans")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            .padding()
            
            if let analytics = analytics, analytics.totalScans > 0 {
                Divider()
                
                HStack(spacing: 20) {
                    AnalyticsMetric(
                        label: "Unique",
                        value: "\(analytics.uniqueScans)"
                    )
                    
                    AnalyticsMetric(
                        label: "Countries",
                        value: "\(analytics.scansByCountry.count)"
                    )
                    
                    AnalyticsMetric(
                        label: "Devices",
                        value: "\(analytics.scansByDevice.count)"
                    )
                }
                .padding()
                .background(Color.gray.opacity(0.05))
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.05), radius: 5, y: 2)
        )
    }
}

struct AnalyticsMetric: View {
    let label: String
    let value: String
    
    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.subheadline)
                .fontWeight(.semibold)
            
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    if #available(iOS 17.0, *) {
        AnalyticsView()
            .environmentObject(QRCodeManager())
    } else {
        // Fallback on earlier versions
    }
}
