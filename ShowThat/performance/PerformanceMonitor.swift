//
//  PerformanceMonitor.swift
//  ShowThat
//
//  Created by Giuseppe De Masi on 30/09/2025.
//

import Foundation
import SwiftUI
import UIKit
import os.signpost

/// Monitora performance dell'app per identificare bottleneck
final class PerformanceMonitor {
    static let shared = PerformanceMonitor()
    
    // MARK: - Properties
    private let logger = Logger.shared
    private var startTimes: [String: Date] = [:]
    private var memoryBaseline: UInt64 = 0
    private let memoryWarningThreshold: UInt64 = 100 * 1024 * 1024 // 100MB
    
    // MARK: - Signpost Logging
    private let signpostLog = OSLog(subsystem: "com.ShowThat.ShowThat", category: "Performance")
    
    private init() {
        setupMemoryMonitoring()
    }
    
    // MARK: - Public Methods
    
    func startTiming(_ operation: String) {
        startTimes[operation] = Date()
        os_signpost(.begin, log: signpostLog, name: "Operation", "%{public}s", operation)
    }
    
    func endTiming(_ operation: String) {
        guard let startTime = startTimes[operation] else { return }
        
        let duration = Date().timeIntervalSince(startTime)
        startTimes.removeValue(forKey: operation)
        
        os_signpost(.end, log: signpostLog, name: "Operation", "%{public}s", operation)
        
        logger.logInfo("Performance: \(operation) took \(String(format: "%.3f", duration))s")
        
        // Log slow operations
        if duration > 1.0 {
            logger.logWarning("Slow operation detected: \(operation) - \(String(format: "%.3f", duration))s")
        }
    }
    
    func measureMemoryUsage() -> UInt64 {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size)/4
        
        let kerr: kern_return_t = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_,
                         task_flavor_t(MACH_TASK_BASIC_INFO),
                         $0,
                         &count)
            }
        }
        
        if kerr == KERN_SUCCESS {
            return info.resident_size
        } else {
            return 0
        }
    }
    
    func logMemoryUsage(context: String = "") {
        let memoryUsage = measureMemoryUsage()
        let memoryMB = Double(memoryUsage) / 1024.0 / 1024.0
        
        logger.logInfo("Memory usage\(context.isEmpty ? "" : " (\(context))"): \(String(format: "%.1f", memoryMB))MB")
        
        // Check for memory warnings
        if memoryUsage > memoryWarningThreshold {
            logger.logWarning("High memory usage detected: \(String(format: "%.1f", memoryMB))MB")
        }
    }
    
    func measureQRGeneration(_ content: String, style: QRStyle) async -> UIImage? {
        startTiming("QR Generation")
        logMemoryUsage(context: "Before QR Generation")
        
        defer {
            endTiming("QR Generation")
            logMemoryUsage(context: "After QR Generation")
        }
        
        return try? await AsyncQRGenerator.shared.generateQR(from: content, style: style)
    }
    
    func measureImageDownload(_ url: URL) async -> UIImage? {
        startTiming("Image Download")
        logMemoryUsage(context: "Before Image Download")
        
        defer {
            endTiming("Image Download")
            logMemoryUsage(context: "After Image Download")
        }
        
        return await ImageCache.shared.image(for: url)
    }
    
    // MARK: - Private Methods
    
    private func setupMemoryMonitoring() {
        // Monitor memory warnings
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleMemoryWarning),
            name: UIApplication.didReceiveMemoryWarningNotification,
            object: nil
        )
        
        // Monitor app lifecycle
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleAppDidBecomeActive),
            name: UIApplication.didBecomeActiveNotification,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleAppWillResignActive),
            name: UIApplication.willResignActiveNotification,
            object: nil
        )
    }
    
    @objc private func handleMemoryWarning() {
        logger.logWarning("Memory warning received")
        logMemoryUsage(context: "Memory Warning")
        
        // Clear caches
        ImageCache.shared.clearCache()
    }
    
    @objc private func handleAppDidBecomeActive() {
        logMemoryUsage(context: "App Became Active")
    }
    
    @objc private func handleAppWillResignActive() {
        logMemoryUsage(context: "App Will Resign Active")
    }
}

// MARK: - Performance Measurement Wrapper

struct PerformanceMeasurer {
    let operation: String
    
    init(_ operation: String) {
        self.operation = operation
        PerformanceMonitor.shared.startTiming(operation)
    }
    
    func finish() {
        PerformanceMonitor.shared.endTiming(operation)
    }
}

// MARK: - View Modifier for Performance

struct PerformanceTrackingModifier: ViewModifier {
    let viewName: String
    
    func body(content: Content) -> some View {
        content
            .onAppear {
                PerformanceMonitor.shared.startTiming("View Appear: \(viewName)")
            }
            .onDisappear {
                PerformanceMonitor.shared.endTiming("View Appear: \(viewName)")
            }
    }
}

extension View {
    func trackPerformance(_ viewName: String) -> some View {
        modifier(PerformanceTrackingModifier(viewName: viewName))
    }
}
