//
//  QRAnalyticsSummary.swift
//  ShowThat
//
//  Created by Giuseppe De Masi on 24/06/2025.
//

import Foundation
import FirebaseFirestore

struct QRAnalyticsSummary: Codable {
    @DocumentID var id: String?
    let qrCodeId: String
    var totalScans: Int = 0
    var uniqueScans: Int = 0
    var scansByDay: [String: Int] = [:] // ISO date string: count
    var scansByCountry: [String: Int] = [:]
    var scansByDevice: [String: Int] = [:]
    var scansByBrowser: [String: Int] = [:]
    @ServerTimestamp var lastUpdated: Date?
}

struct QRAnalyticsData: Codable {
    let qrCodeId: String
    var totalScans: Int = 0
    var uniqueScans: Int = 0
    var scansByDay: [String: Int] = [:]
    var scansByHour: [Int: Int] = [:]
    var scansByCountry: [String: Int] = [:]
    var scansByDevice: [String: Int] = [:]
    var scansByBrowser: [String: Int] = [:]
    var scansByOS: [String: Int] = [:]
    var scansByLocation: [String: Int] = [:] // City level
    var conversionEvents: [ConversionEvent] = []
    var userJourney: [UserJourneyStep] = []
    var engagementMetrics: EngagementMetrics = EngagementMetrics()
    var performanceInsights: PerformanceInsights = PerformanceInsights()
    @ServerTimestamp var lastUpdated: Date?
}

struct ConversionEvent: Codable {
    let eventType: String
    let timestamp: Date
    let value: Double?
    let metadata: [String: String]
}

struct UserJourneyStep: Codable {
    let step: String
    let timestamp: Date
    let duration: TimeInterval?
    let success: Bool
}

struct EngagementMetrics: Codable {
    var averageSessionDuration: TimeInterval = 0
    var bounceRate: Double = 0
    var returnVisitorRate: Double = 0
    var peakUsageHours: [Int] = []
    var seasonalTrends: [String: Double] = [:]
}

struct PerformanceInsights: Codable {
    var growthRate: Double = 0
    var peakPerformanceDay: String?
    var underperformingHours: [Int] = []
    var geographicHotspots: [String] = []
    var deviceTrends: [String: Double] = [:]
    var recommendations: [String] = []
}

struct RealTimeStats {
    let scansLast24h: Int
    let uniqueScansLast24h: Int
    let averageScansPerHour: Double
    let topCountries: [String]
    let topDevices: [String]
    
    init(scansLast24h: Int = 0, uniqueScansLast24h: Int = 0, averageScansPerHour: Double = 0, topCountries: [String] = [], topDevices: [String] = []) {
        self.scansLast24h = scansLast24h
        self.uniqueScansLast24h = uniqueScansLast24h
        self.averageScansPerHour = averageScansPerHour
        self.topCountries = topCountries
        self.topDevices = topDevices
    }
}
