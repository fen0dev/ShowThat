//
//  AnalyticsView.swift
//  ShowThat
//
//  Created by Giuseppe De Masi on 25/06/2025.
//

import SwiftUI

struct AnalyticsView: View {
    @EnvironmentObject var qrManager: QRCodeManager
    @State private var selectedQRCode: QRCodeModel?
    @State private var analytics: [String: QRAnalyticsSummary] = [:]
    @State private var isLoading = true
    
    var totalScans: Int {
        qrManager.qrCodes.reduce(0) { $0 + $1.scanCount }
    }
    
    var activeQRCodes: Int {
        qrManager.qrCodes.filter { $0.isActive }.count
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // background gradient
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(red: 0.95, green: 0.95, blue: 1.0),
                        Color(red: 0.92, green: 0.94, blue: 1.0)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    ScrollView {
                        VStack(spacing: 20) {
                            // Overview Cards
                            overviewSection
                            
                            // QR Code Performance
                            if !qrManager.qrCodes.isEmpty {
                                qrCodePerformanceSection
                            } else {
                                emptyStateView
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationBarHidden(true)
            .onAppear {
                loadAllAnalytics()
            }
        }
    }
    
    private var overviewSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Overview")
                .font(.headline)
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 15) {
                StatsCard(
                    title: "Total Scans",
                    value: "\(totalScans)",
                    icon: "eye.fill",
                    color: .blue
                )
                
                StatsCard(
                    title: "Active QR Codes",
                    value: "\(activeQRCodes)",
                    icon: "qrcode",
                    color: .green
                )
                
                StatsCard(
                    title: "Dynamic QRs",
                    value: "\(qrManager.qrCodes.filter { $0.isDynamic }.count)",
                    icon: "arrow.triangle.2.circlepath",
                    color: .purple
                )
                
                StatsCard(
                    title: "Avg. Scans",
                    value: qrManager.qrCodes.isEmpty ? "0" : "\(totalScans / qrManager.qrCodes.count)",
                    icon: "chart.bar.fill",
                    color: .orange
                )
            }
        }
    }
    
    private var qrCodePerformanceSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack {
                Text("QR Code Performance")
                    .font(.headline)
                
                Spacer()
                
                if isLoading {
                    ProgressView()
                        .scaleEffect(0.8)
                }
            }
            
            ForEach(qrManager.qrCodes.sorted { $0.scanCount > $1.scanCount }) { qrCode in
                QRCodeAnalyticsRow(
                    qrCode: qrCode,
                    analytics: analytics[qrCode.id ?? ""]
                )
            }
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "chart.line.uptrend.xyaxis")
                .font(.system(size: 60))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.purple.opacity(0.5), .blue.opacity(0.5)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            
            Text("No Analytics Yet")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Create QR codes to start tracking their performance")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.top, 40)
    }
    
    private func loadAllAnalytics() {
        isLoading = true
        
        Task {
            for qrCode in qrManager.qrCodes {
                if let qrId = qrCode.id,
                   let summary = try? await qrManager.getAnalytics(for: qrCode) {
                    analytics[qrId] = summary
                }
            }
            isLoading = false
        }
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
    AnalyticsView()
        .environmentObject(QRCodeManager())
}
