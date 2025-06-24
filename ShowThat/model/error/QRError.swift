//
//  QRError.swift
//  ShowThat
//
//  Created by Giuseppe De Masi on 24/06/2025.
//

import Foundation

enum QRError: LocalizedError {
    case notAuthenticated
    case subscriptionLimitReached
    case invalidQRCode
    case networkError
    case imageProcessingFailed
    case bulkImportPartialFailure(errors: [String])
    
    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "Please sign in to continue."
        case .subscriptionLimitReached:
            return "You've reached your plan limit. Upgrade to create more QR codes."
        case .invalidQRCode:
            return "Invalid QR code data."
        case .networkError:
            return "Network error. Please check your connection."
        case .imageProcessingFailed:
            return "Failed to process image."
        case .bulkImportPartialFailure(let errors):
            return "Bulk import completed with \(errors.count) errors."
        }
    }
}
