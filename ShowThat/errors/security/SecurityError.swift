//
//  SecurityError.swift
//  ShowThat
//
//  Created by Giuseppe De Masi on 11/10/2025.
//

import Foundation

enum SecurityError: LocalizedError, Equatable {
    case encryptionFailed(String)
    case decryptionFailed(String)
    case keyNotFound
    case invalidKeyFormat
    case accessDenied
    
    var errorDescription: String? {
        switch self {
        case .encryptionFailed(let details):
            return "Encryption failed: \(details)"
        case .decryptionFailed(let details):
            return "Decryption failed: \(details)"
        case .keyNotFound:
            return "Encryption key not found. Please restart the app."
        case .invalidKeyFormat:
            return "Invalid encryption key format"
        case .accessDenied:
            return "Access denied to secure storage"
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .encryptionFailed:
            return "Try again or restart the app if the problem persists"
        case .decryptionFailed:
            return "The encrypted data may be corrupted. Please recreate the QR code."
        case .keyNotFound:
            return "Restart the app to regenerate the encryption key"
        case .invalidKeyFormat:
            return "Contact support if this error persists"
        case .accessDenied:
            return "Check device settings and try again"
        }
    }
}
