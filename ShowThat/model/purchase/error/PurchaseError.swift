//
//  PurchaseError.swift
//  ShowThat
//
//  Created by Giuseppe De Masi on 25/06/2025.
//

import Foundation

enum PurchaseError: LocalizedError {
    case userCancelled
    case pending
    case productNotFound
    case purchaseFailed(Error)
    case verificationFailed
    case noPurchasesToRestore
    case unknown
    
    var errorDescription: String? {
        switch self {
        case .userCancelled:
            return "Purchase was cancelled"
        case .pending:
            return "Purchase is pending approval"
        case .productNotFound:
            return "Product not found"
        case .purchaseFailed(let error):
            return "Purchase failed: \(error.localizedDescription)"
        case .verificationFailed:
            return "Purchase verification failed"
        case .noPurchasesToRestore:
            return "No purchases to restore"
        case .unknown:
            return "An unknown error occurred"
        }
    }
}
