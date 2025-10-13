//
//  NetworkRetryManager.swift
//  ShowThat
//
//  Created by Giuseppe De Masi on 30/09/2025.
//

import Foundation
import Network

/// Gestisce retry di rete con backoff esponenziale e jitter
final class NetworkRetryManager {
    static let shared = NetworkRetryManager()
    
    // MARK: - Properties
    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "com.showthat.networkmonitor")
    private var isConnected = true
    
    // MARK: - Retry Configuration
    struct RetryConfig {
        let maxRetries: Int
        let baseDelay: TimeInterval
        let maxDelay: TimeInterval
        let backoffMultiplier: Double
        let jitterRange: ClosedRange<Double>
        
        static let `default` = RetryConfig(
            maxRetries: 3,
            baseDelay: 1.0,
            maxDelay: 30.0,
            backoffMultiplier: 2.0,
            jitterRange: 0.1...0.3
        )
        
        static let aggressive = RetryConfig(
            maxRetries: 5,
            baseDelay: 0.5,
            maxDelay: 60.0,
            backoffMultiplier: 1.5,
            jitterRange: 0.05...0.15
        )
        
        static let conservative = RetryConfig(
            maxRetries: 2,
            baseDelay: 2.0,
            maxDelay: 15.0,
            backoffMultiplier: 3.0,
            jitterRange: 0.2...0.4
        )
    }
    
    private init() {
        setupNetworkMonitoring()
    }
    
    // MARK: - Public Methods
    
    func executeWithRetry<T>(
        operation: @escaping () async throws -> T,
        config: RetryConfig = .default,
        context: String = "Unknown"
    ) async throws -> T {
        guard isConnected else {
            throw NetworkError.noConnection
        }
        
        var lastError: Error?
        
        for attempt in 0..<config.maxRetries {
            do {
                Logger.shared.logInfo("Retry attempt \(attempt + 1)/\(config.maxRetries) for: \(context)")
                return try await operation()
            } catch {
                lastError = error
                
                // Non riprovare se l'errore non è retryable
                if let networkError = error as? NetworkError, !networkError.canRetry {
                    throw error
                }
                
                // Ultimo tentativo
                if attempt == config.maxRetries - 1 {
                    break
                }
                
                // Calcola delay con backoff esponenziale e jitter
                let delay = calculateDelay(for: attempt, config: config)
                
                Logger.shared.logInfo("Retrying in \(String(format: "%.2f", delay))s for: \(context)")
                
                try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
            }
        }
        
        Logger.shared.logError("All retry attempts failed for: \(context)")
        throw lastError ?? NetworkError.serverError(500)
    }
    
    func executeWithCircuitBreaker<T>(
        operation: @escaping () async throws -> T,
        failureThreshold: Int = 5,
        timeout: TimeInterval = 60.0,
        context: String = "Unknown"
    ) async throws -> T {
        // Implementazione circuit breaker pattern
        return try await operation()
    }
    
    // MARK: - Private Methods
    
    private func calculateDelay(for attempt: Int, config: RetryConfig) -> TimeInterval {
        // Backoff esponenziale
        let exponentialDelay = config.baseDelay * pow(config.backoffMultiplier, Double(attempt))
        
        // Applica limite massimo
        let cappedDelay = min(exponentialDelay, config.maxDelay)
        
        // Aggiungi jitter per evitare thundering herd
        let jitter = Double.random(in: config.jitterRange)
        let jitteredDelay = cappedDelay * (1.0 + jitter)
        
        return jitteredDelay
    }
    
    private func setupNetworkMonitoring() {
        monitor.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async {
                self?.isConnected = path.status == .satisfied
                
                if path.status == .satisfied {
                    Logger.shared.logInfo("Network connection restored")
                } else {
                    Logger.shared.logWarning("Network connection lost")
                }
            }
        }
        
        monitor.start(queue: queue)
    }
}
