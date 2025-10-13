//
//  AnalyticsManager.swift
//  ShowThat
//
//  Created by Giuseppe De Masi on 02/10/2025.
//

import Foundation
import FirebaseFirestore
import FirebaseAnalytics
import CoreLocation
import UIKit

@MainActor
final class AnalyticsManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    static let shared = AnalyticsManager()
    
    // MARK: - Properties
    private let db = Firestore.firestore()
    private let locationManager = CLLocationManager()
    private var analyticsCache: [String: QRAnalyticsData] = [:]
    private let cacheExpiry: TimeInterval = 300
    private var locationContinuation: CheckedContinuation<CLLocation?, Never>?
    
    override init() {
        super.init()
        setupLocationManager()
    }
    
    // MARK: - Core Analytics Methods
    
    func recordScan(
        qrCodeId: String,
        device: DeviceInfo,
        location: ScanLocation? = nil,
        referrer: String? = nil
    ) async {
        let scanEvent = ScanEvent(
            qrCodeId: qrCodeId,
            location: location,
            device: device,
            referrer: referrer
        )
        
        // Real-time processing
        await processScanEvent(scanEvent)
        
        // Batch processing for insights
        await scheduleBatchProcessing(qrCodeId: qrCodeId)
        
        Logger.shared.logInfo("Scan recorded for QR Code: \(qrCodeId)")
    }
    
    // Register scans with authomatic information on device
    func recordScanAutomatically(
        qrCodeId: String,
        referrer: String? = nil,
        completion: ((Error?) -> Void)? = nil
    ) async {
        do {
            let deviceInfo = await getCurrentDeviceInfo()
            let locationInfo = await getCurrentLocation()
            
            await recordScan(
                qrCodeId: qrCodeId,
                device: deviceInfo,
                location: locationInfo,
                referrer: referrer
            )
            
            // Log Firebase Analytics event
            Analytics.logEvent("qr_code_scanned", parameters: [
                "qr_code_id": qrCodeId,
                "device_platform": deviceInfo.platform,
                "device_type": deviceInfo.deviceType ?? "unknown"
            ])
            
            completion?(nil)
        }
    }
    
    private func getCurrentDeviceInfo() async -> DeviceInfo {
        let device = UIDevice.current
        let systemVersion = device.systemVersion
        
        // determine device type
        let deviceType = await determineDeviceType()
        
        // generate unique ID for the device based on vendor ID
        let deviceId = await getDeviceIdentifier()
        
        return DeviceInfo(
            platform: "iOS",
            browser: "ShowThat App",
            osVersion: systemVersion,
            deviceType: deviceType,
            os: "iOS",
            id: deviceId
        )
    }
    
    // determine device type (phone, tablet, etc..)
    private func determineDeviceType() async -> String {
        let screenSize = UIScreen.main.bounds.size
        let diagonal = sqrt(pow(screenSize.width, 2) + pow(screenSize.height, 2))
        
        // based on screen dimension
        if diagonal < 700 {
            return "phone"
        } else if diagonal < 1000 {
            return "phone_large"
        } else if diagonal < 1200 {
            return "tablet"
        } else {
            return "tablet_large"
        }
    }
    
    // obtain unique ID for device
    private func getDeviceIdentifier() async -> String {
        // use IdentifierForVendor if available, otherwise generate unique persistent ID
        if let vendorId = UIDevice.current.identifierForVendor?.uuidString {
            return vendorId
        } else {
            // fallback : generate unqiue UUID based on other device characteristics
            let device = UIDevice.current
            let deviceName = device.name
            let systemVersion = device.systemVersion
            let combined = deviceName + systemVersion
            //hash
            let data = Data(combined.utf8)
            
            return String(data.hashValue)
        }
    }
    
    // obtains current location of user who scans (if authorized)
    private func getCurrentLocation() async -> ScanLocation? {
        guard CLLocationManager.locationServicesEnabled() else {
            return nil
        }
        
        // Check authorization status
        let status = locationManager.authorizationStatus
        guard status == .authorizedWhenInUse || status == .authorizedAlways else {
            locationManager.requestWhenInUseAuthorization()
            return nil // Return nil if not authorized yet
        }
        
        let clLocation: CLLocation? = await withCheckedContinuation { continuation in
            self.locationContinuation = continuation
            self.locationManager.delegate = self
            self.locationManager.requestLocation()
        }
        
        guard let location = clLocation else { return nil }
        
        do {
            let geocoder = CLGeocoder()
            let placemarks = try await geocoder.reverseGeocodeLocation(location)
            let placemark = placemarks.first
            
            return ScanLocation(
                country: placemark?.country ?? "Unknown",
                city: placemark?.locality,
                region: placemark?.administrativeArea,
                latitude: location.coordinate.latitude,
                longitude: location.coordinate.longitude
            )
        } catch {
            Logger.shared.logError("Failed to reverse geocode location: \(error)")
            return nil
        }
    }
    
    private func processScanEvent(_ event: ScanEvent) async {
        let dateKey = ISO8601DateFormatter().string(from: Date()).prefix(10).description
        let hour = Calendar.current.component(.hour, from: Date())
        
        var updates: [String: Any] = [
            "qrCodeId": event.qrCodeId,
            "totalScans": FieldValue.increment(Int64(1)),
            "scansByDay.\(dateKey)": FieldValue.increment(Int64(1)),
            "scansByHour.\(hour)": FieldValue.increment(Int64(1)),
            "scansByDevice.\(event.device.platform)": FieldValue.increment(Int64(1)),
            "lastUpdated": FieldValue.serverTimestamp()
        ]
        
        if let country = event.location?.country {
            updates["scansByCountry.\(country)"] = FieldValue.increment(Int64(1))
        }
        
        if let city = event.location?.city {
            updates["scansByLocation.\(city)"] = FieldValue.increment(Int64(1))
        }
        
        if let browser = event.device.browser {
            updates["scansByBrowser.\(browser)"] = FieldValue.increment(Int64(1))
        }
        
        if let os = event.device.os {
            updates["scansByOS.\(os)"] = FieldValue.increment(Int64(1))
        }
        
        do {
            try await db.collection("analytics").document(event.qrCodeId).setData(updates, merge: true)
        } catch {
            Logger.shared.logError("Failed to update analytics: \(error)")
        }
    }
    
    // MARK: - Advanced Analytics Methods
    
    func getAnalyticsInsights(for qrCodeId: String) async throws -> QRAnalyticsData {
        // Check cache first
        if let cached = analyticsCache[qrCodeId],
           let lastUpdated = cached.lastUpdated,
           Date().timeIntervalSince(lastUpdated) < cacheExpiry {
            return cached
        }
        
        // Fetch from Firestore
        let document = try await db.collection("analytics").document(qrCodeId).getDocument()
        guard document.exists else {
            return QRAnalyticsData(qrCodeId: qrCodeId)
        }
        
        let analyticsData = (try? document.data(as: QRAnalyticsData.self)) ?? QRAnalyticsData(qrCodeId: qrCodeId)
        
        // Generate insights
        let insights = await generateInsights(for: analyticsData)
        var updatedData = analyticsData
        updatedData.performanceInsights = insights
        
        // Cache the result
        analyticsCache[qrCodeId] = updatedData
        return updatedData
    }
    
    private func generateInsights(for data: QRAnalyticsData) async -> PerformanceInsights {
        var insights = PerformanceInsights()
        
        // Calculate growth rate
        insights.growthRate = calculateGrowthRate(scansByDay: data.scansByDay)
        
        // Find peak performance day
        insights.peakPerformanceDay = findPeakDay(scansByDay: data.scansByDay)
        
        // Identify underperforming hours
        insights.underperformingHours = findUnderperformingHours(scansByHour: data.scansByHour)
        
        // Find geographic hotspots
        insights.geographicHotspots = findGeographicHotspots(scansByLocation: data.scansByLocation)
        
        // Analyze device trends
        insights.deviceTrends = analyzeDeviceTrends(scansByDevice: data.scansByDevice)
        
        // Generate recommendations
        insights.recommendations = generateRecommendations(for: data, insights: insights)
        
        return insights
    }
    
    // MARK: - Machine Learning Algorithms
    
    private func calculateGrowthRate(scansByDay: [String: Int]) -> Double {
        let sortedDays = scansByDay.keys.sorted()
        guard sortedDays.count >= 7 else { return 0 }
        
        let recentWeek = sortedDays.suffix(7)
        let previousWeek = sortedDays.suffix(14).prefix(7)
        
        let recentAverage = recentWeek.compactMap { scansByDay[$0] }.reduce(0, +) / 7
        let previousAverage = previousWeek.compactMap { scansByDay[$0] }.reduce(0, +) / 7
        
        guard previousAverage > 0 else { return 0 }
        
        return ((Double(recentAverage) - Double(previousAverage)) / Double(previousAverage)) * 100
    }
    
    private func findPeakDay(scansByDay: [String: Int]) -> String? {
        return scansByDay.max(by: { $0.value < $1.value })?.key
    }
    
    private func findUnderperformingHours(scansByHour: [Int: Int]) -> [Int] {
        let totalScans = scansByHour.values.reduce(0, +)
        let averagePerHour = Double(totalScans) / 24.0
        
        return scansByHour.compactMap { hour, scans in
            Double(scans) < averagePerHour * 0.5 ? hour : nil
        }
    }
    
    private func findGeographicHotspots(scansByLocation: [String: Int]) -> [String] {
        let totalScans = scansByLocation.values.reduce(0, +)
        let threshold = Double(totalScans) * 0.1 // Top 10%
        
        return scansByLocation.compactMap { location, scans in
            Double(scans) > threshold ? location : nil
        }.sorted { scansByLocation[$0]! > scansByLocation[$1]! }
    }
    
    private func analyzeDeviceTrends(scansByDevice: [String: Int]) -> [String: Double] {
        let totalScans = scansByDevice.values.reduce(0, +)
        guard totalScans > 0 else { return [:] }
        
        return scansByDevice.mapValues { Double($0) / Double(totalScans) * 100 }
    }
    
    private func generateRecommendations(for data: QRAnalyticsData, insights: PerformanceInsights) -> [String] {
        var recommendations: [String] = []
        
        // Growth recommendations
        if insights.growthRate < 0 {
            recommendations.append("Considera campagne marketing per aumentare le scansioni")
        }
        
        // Time-based recommendations
        if !insights.underperformingHours.isEmpty {
            recommendations.append("Ottimizza per le ore di picco: \(insights.underperformingHours.map(String.init).joined(separator: ", "))")
        }
        
        // Geographic recommendations
        if !insights.geographicHotspots.isEmpty {
            recommendations.append("Concentrati sui mercati: \(insights.geographicHotspots.prefix(3).joined(separator: ", "))")
        }
        
        // Device recommendations
        if let topDevice = insights.deviceTrends.max(by: { $0.value < $1.value }) {
            recommendations.append("Ottimizza per \(topDevice.key) (dominante al \(String(format: "%.1f", topDevice.value))%)")
        }
        
        return recommendations
    }
    
    // MARK: - REal-time Stats
    
    func getRealTimeStats(for qrCodeId: String) async -> RealTimeStats {
        let last24Hours = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
        
        let query = db.collection("scans")
            .whereField("qrCodeId", isEqualTo: qrCodeId)
            .whereField("timestamp", isGreaterThan: last24Hours)
            .limit(to: 1000)
        
        do {
            let snapshot = try await query.getDocuments()
            let scans = snapshot.documents.compactMap { try? $0.data(as: ScanEvent.self) }
            
            return RealTimeStats(
                scansLast24h: scans.count,
                uniqueScansLast24h: Set(scans.map { $0.device.id }).count,
                averageScansPerHour: Double(scans.count) / 24.0,
                topCountries: getTopCountries(from: scans),
                topDevices: getTopDevices(from: scans)
            )
        } catch {
            Logger.shared.logError("Failed to get real-time stats: \(error)")
            return RealTimeStats()
        }
    }
    
    private func getTopCountries(from scans: [ScanEvent]) -> [String] {
        let countryCounts = Dictionary(grouping: scans.compactMap { $0.location?.country }) { $0 }
            .mapValues { $0.count }
        
        return countryCounts.sorted { $0.value > $1.value }.prefix(5).map { $0.key }
    }
    
    private func getTopDevices(from scans: [ScanEvent]) -> [String] {
        let deviceCounts = Dictionary(grouping: scans.map { $0.device.platform }) { $0 }
            .mapValues { $0.count }
        
        return deviceCounts.sorted { $0.value > $1.value }.prefix(3).map { $0.key }
    }
    
    // MARK: - Predictive analysis
    
    func predictFutureScans(for qrCodeId: String, days: Int = 7) async -> [String: Int]  {
        let analyticsData = try? await getAnalyticsInsights(for: qrCodeId)
        guard let data = analyticsData else { return [:] }
        
        let predictions = predictLinearTrend(scansByDay: data.scansByDay, days: days)
        return predictions
    }
    
    private func predictLinearTrend(scansByDay: [String: Int], days: Int) -> [String: Int] {
        let sortedDays = scansByDay.keys.sorted()
        guard sortedDays.count >= 7 else { return [:] }
        
        let recentDays = sortedDays.suffix(7)
        let values = recentDays.compactMap { scansByDay[$0] }
        
        let trend = self.calculateTrend(values: values)
        
        var predictions: [String: Int] = [:]
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        
        for i in 1...days {
            if let lastDate = dateFormatter.date(from: sortedDays.last!),
               let futureDate = Calendar.current.date(byAdding: .day, value: i, to: lastDate) {
                let futureDateString = dateFormatter.string(from: futureDate)
                let predictedValues = max(0, Int(Double(values.last ?? 0) + Double(i) * trend))
                predictions[futureDateString] = predictedValues
            }
        }
        
        return predictions
    }
    
    private func calculateTrend(values: [Int]) -> Double {
        guard values.count >= 2 else { return 0 }
        
        let n = Double(values.count)
        let sumX = (0..<values.count).reduce(0) { $0 + $1 }
        let sumY = values.reduce(0) { $0 + $1 }
        let sumXY = zip(0..<values.count, values).map { Double($0) * Double($1) }.reduce(0) { $0 + $1 }
        let sumXX = (0..<values.count).map { Double($0 * $0) }.reduce(0) { $0 + $1 }
        
        let slope = (n * sumXY - Double(sumX) * Double(sumY)) / (n * sumXX - Double(sumX * sumX))
        return slope
    }
    
    // MARK: - Helper methods
    
    func setupLocationManager() {
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = 100
        locationManager.requestWhenInUseAuthorization()
    }
    
    // MARK: - CLLocationManager Delegate
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.first else {
            Task { @MainActor in
                self.locationContinuation?.resume(returning: nil)
                self.locationContinuation = nil
            }
            return
        }
        
        // Resume the continuation with the location
        locationContinuation?.resume(returning: location)
        locationContinuation = nil
        
        // Process the location to get scan location data
        Task {
            await processLocationForAnalytics(location)
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        Task { @MainActor in
            Logger.shared.logError("Location manager failed with error: \(error)")
            self.locationContinuation?.resume(returning: nil)
            self.locationContinuation = nil
        }
    }
    
    private func processLocationForAnalytics(_ location: CLLocation) async {
        do {
            let geocoder = CLGeocoder()
            let placemarks = try await geocoder.reverseGeocodeLocation(location)
            
            guard let placemark = placemarks.first else {
                return
            }
            
            let scanLocation = ScanLocation(
                country: placemark.country ?? "Unknown",
                city: placemark.locality,
                region: placemark.administrativeArea,
                latitude: location.coordinate.latitude,
                longitude: location.coordinate.longitude
            )
            
            // Here you could store the location or use it for analytics
            Logger.shared.logInfo("Location processed: \(scanLocation.city ?? "Unknown"), \(scanLocation.country)")
            
        } catch {
            Logger.shared.logError("Failed to reverse geocode location: \(error)")
        }
    }
    
    private func scheduleBatchProcessing(qrCodeId: String) async {
        Task.detached(priority: .background) {
            if let analyticsData = try? await self.getAnalyticsInsights(for: qrCodeId) {
                _ = await self.generateInsights(for: analyticsData)
            }
        }
    }
}
