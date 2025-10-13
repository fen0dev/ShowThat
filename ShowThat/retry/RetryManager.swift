//
//  RetryManager.swift
//  ShowThat
//
//  Created by Giuseppe De Masi on 30/09/2025.
//

import Foundation

/// Gestisce retry automatici con backoff esponenziale
final class RetryManager {
    static let shared = RetryManager()
    
    private let maxRetries: Int
    private let baseDelay: TimeInterval
    private let maxDelay: TimeInterval
    private let backoffMultiplier: Double
    
    private init(
        maxRetries: Int = 3,
        baseDelay: TimeInterval = 1.0,
        maxDelay: TimeInterval = 30.0,
        backoffMultiplier: Double = 2.0
    ) {
        self.maxRetries = maxRetries
        self.baseDelay = baseDelay
        self.maxDelay = maxDelay
        self.backoffMultiplier = backoffMultiplier
    }
    
    // MARK: - Public Methods
    
    func executeWithRetry<T>(
        operation: @escaping () async throws -> T,
        maxRetries: Int? = nil,
        context: ErrorContext = .general
    ) async throws -> T {
        let retries = maxRetries ?? self.maxRetries
        var lastError: Error?
        
        for attempt in 0..<retries {
            do {
                return try await operation()
            } catch {
                lastError = error
                
                // Non riprovare se l'errore non è retryable
                if let appError = error as? AppError, !appError.canRetry {
                    throw error
                }
                
                // Ultimo tentativo
                if attempt == retries - 1 {
                    break
                }
                
                // Calcola delay con backoff esponenziale
                let delay = calculateDelay(for: attempt)
                
                Logger.shared.logInfo("Retry attempt \(attempt + 1)/\(retries) in \(delay)s for context: \(context.rawValue)")
                
                try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
            }
        }
        
        // Log fallimento finale
        Logger.shared.logError("All retry attempts failed for context: \(context.rawValue)")
        
        throw lastError ?? NetworkError.serverError(500)
    }
    
    // MARK: - Private Methods
    
    private func calculateDelay(for attempt: Int) -> TimeInterval {
        let delay = baseDelay * pow(backoffMultiplier, Double(attempt))
        return min(delay, maxDelay)
    }
}
