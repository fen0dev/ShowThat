//
//  ErrorManager.swift
//  ShowThat
//
//  Created by Giuseppe De Masi on 30/09/2025.
//

import Foundation
import FirebaseAnalytics

// MARK: - Protocols

protocol RetryableError {
    var canRetry: Bool { get }
}

protocol UserVisibleError {
    var shouldShowToUser: Bool { get }
}

/// Gestisce errori in modo centralizzato e robusto
@MainActor
final class ErrorManager: ObservableObject {
    static let shared = ErrorManager()
    
    @Published var currentError: AppError?
    @Published var isShowingError = false
    
    private let logger = Logger.shared
    private let retryManager = RetryManager.shared
    
    private init() {}
    
    // MARK: - Error Handling
    
    func handle(_ error: Error, context: ErrorContext = .general) {
        let appError = AppError.from(error, context: context)
        
        // Log error
        logger.logError(appError)
        
        // Track analytics
        Analytics.logEvent("error_occurred", parameters: [
            "error_type": appError.type.rawValue,
            "context": context.rawValue,
            "is_retryable": appError.canRetry
        ])
        
        // Show to user if needed
        if appError.shouldShowToUser {
            currentError = appError
            isShowingError = true
        }
    }
    
    func handleWithRetry<T>(
        _ operation: @escaping () async throws -> T,
        context: ErrorContext = .general,
        maxRetries: Int = 3
    ) async throws -> T {
        return try await retryManager.executeWithRetry(
            operation: operation,
            maxRetries: maxRetries,
            context: context
        )
    }
    
    func clearError() {
        currentError = nil
        isShowingError = false
    }
}

// MARK: - Error Types

enum AppError: LocalizedError, Equatable, RetryableError, UserVisibleError {
    case network(NetworkError)
    case authentication(AuthError)
    case subscription(SubscriptionError)
    case qrCode(QRCodeError)
    case validation(ValidationError)
    case system(SystemError)
    
    var errorDescription: String? {
        switch self {
        case .network(let error):
            return error.localizedDescription
        case .authentication(let error):
            return error.localizedDescription
        case .subscription(let error):
            return error.localizedDescription
        case .qrCode(let error):
            return error.localizedDescription
        case .validation(let error):
            return error.localizedDescription
        case .system(let error):
            return error.localizedDescription
        }
    }
    
    var type: ErrorType {
        switch self {
        case .network: return .network
        case .authentication: return .authentication
        case .subscription: return .subscription
        case .qrCode: return .qrCode
        case .validation: return .validation
        case .system: return .system
        }
    }
    
    var canRetry: Bool {
        switch self {
        case .network(let error):
            return error.canRetry
        case .authentication, .subscription, .validation:
            return false
        case .qrCode(let error):
            return error.canRetry
        case .system(let error):
            return error.canRetry
        }
    }
    
    var shouldShowToUser: Bool {
        switch self {
        case .network(let error):
            return error.shouldShowToUser
        case .authentication, .subscription, .qrCode, .validation:
            return true
        case .system(let error):
            return error.shouldShowToUser
        }
    }
    
    static func from(_ error: Error, context: ErrorContext) -> AppError {
        if let networkError = error as? NetworkError {
            return .network(networkError)
        } else if let authError = error as? AuthError {
            return .authentication(authError)
        } else if let subscriptionError = error as? SubscriptionError {
            return .subscription(subscriptionError)
        } else if let qrError = error as? QRCodeError {
            return .qrCode(qrError)
        } else if let validationError = error as? ValidationError {
            return .validation(validationError)
        } else {
            return .system(SystemError.unknown(error))
        }
    }
}

enum ErrorType: String, CaseIterable {
    case network = "network"
    case authentication = "authentication"
    case subscription = "subscription"
    case qrCode = "qr_code"
    case validation = "validation"
    case system = "system"
}

enum ErrorContext: String, CaseIterable {
    case general = "general"
    case qrGeneration = "qr_generation"
    case qrScanning = "qr_scanning"
    case authentication = "authentication"
    case subscription = "subscription"
    case analytics = "analytics"
    case storage = "storage"
}

// MARK: - Specific Error Types

enum NetworkError: LocalizedError, Equatable, RetryableError, UserVisibleError {
    case noConnection
    case timeout
    case serverError(Int)
    case invalidResponse
    case rateLimited
    
    var errorDescription: String? {
        switch self {
        case .noConnection:
            return "Check your internet connection and try again"
        case .timeout:
            return "Request expired. Try again soon"
        case .serverError(let code):
            return "Server Error: (\(code)). Try again later."
        case .invalidResponse:
            return "Invalid server response"
        case .rateLimited:
            return "Too many requests. Try less requests"
        }
    }
    
    var canRetry: Bool {
        switch self {
        case .noConnection, .timeout, .serverError, .rateLimited:
            return true
        case .invalidResponse:
            return false
        }
    }
    
    var shouldShowToUser: Bool {
        return true
    }
}

enum AuthError: LocalizedError, Equatable {
    case notAuthenticated
    case invalidCredentials
    case emailAlreadyExists
    case weakPassword
    case userNotFound
    case tooManyRequests
    
    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "Log in before continuing."
        case .invalidCredentials:
            return "Email or password not valid."
        case .emailAlreadyExists:
            return "This email is registered to an existing account"
        case .weakPassword:
            return "Password needs to be at least 6 characters long."
        case .userNotFound:
            return "No account found with this email."
        case .tooManyRequests:
            return "Too many attempts. Try again later."
        }
    }
}

enum SubscriptionError: LocalizedError, Equatable {
    case limitReached
    case paymentFailed
    case subscriptionExpired
    case restoreFailed
    
    var errorDescription: String? {
        switch self {
        case .limitReached:
            return "Limit reached. Update package to create more QR codes."
        case .paymentFailed:
            return "Payment failed. Check your payment method and try again."
        case .subscriptionExpired:
            return "Your subscription expired. Renew it or continue with the free tier."
        case .restoreFailed:
            return "Unable to restore purchases. Try again later."
        }
    }
}

enum QRCodeError: LocalizedError, Equatable, RetryableError {
    case generationFailed
    case invalidContent
    case invalidURL
    case invalidEmail
    case fileTooLarge
    case storageFailed
    
    var errorDescription: String? {
        switch self {
        case .generationFailed:
            return "Unable to generate QR code. Try again."
        case .invalidContent:
            return "Invalid content for QR code."
        case .invalidURL:
            return "Invalid URL. Check format."
        case .invalidEmail:
            return "Invalid email. Check format."
        case .fileTooLarge:
            return "File too large. Upload a smaller file."
        case .storageFailed:
            return "Unable to save file. Try again."
        }
    }
    
    var canRetry: Bool {
        switch self {
        case .generationFailed, .storageFailed:
            return true
        case .invalidContent, .invalidURL, .invalidEmail, .fileTooLarge:
            return false
        }
    }
}

enum ValidationError: LocalizedError, Equatable {
    case emptyField(String)
    case invalidFormat(String)
    case tooLong(String, Int)
    case tooShort(String, Int)
    
    var errorDescription: String? {
        switch self {
        case .emptyField(let field):
            return "Mandatory field: '\(field)'"
        case .invalidFormat(let field):
            return "Invalid format for: '\(field)'."
        case .tooLong(let field, let max):
            return "Field: '\(field)' can't be over \(max) characters."
        case .tooShort(let field, let min):
            return "This field: '\(field)' must be at least \(min) characters long."
        }
    }
}

enum SystemError: LocalizedError, Equatable, RetryableError, UserVisibleError {
    static func == (lhs: SystemError, rhs: SystemError) -> Bool {
        return true
    }
    
    case unknown(Error)
    case memoryWarning
    case diskSpaceLow
    case permissionDenied
    
    var errorDescription: String? {
        switch self {
        case .unknown(let error):
            return "Errore imprevisto: \(error.localizedDescription)"
        case .memoryWarning:
            return "Memoria insufficiente. Chiudi altre app e riprova."
        case .diskSpaceLow:
            return "Spazio di archiviazione insufficiente."
        case .permissionDenied:
            return "Permessi insufficienti per completare l'operazione."
        }
    }
    
    var canRetry: Bool {
        switch self {
        case .unknown, .memoryWarning, .diskSpaceLow:
            return true
        case .permissionDenied:
            return false
        }
    }
    
    var shouldShowToUser: Bool {
        switch self {
        case .unknown:
            return false // Non mostrare errori sconosciuti
        case .memoryWarning, .diskSpaceLow, .permissionDenied:
            return true
        }
    }
}
