//
//  UserSubscription.swift
//  ShowThat
//
//  Created by Giuseppe De Masi on 24/06/2025.
//

import Foundation
import FirebaseFirestore

struct UserSubscription: Codable {
    enum Tier: String, CaseIterable, Codable {
        case free = "Free"
        case pro = "Pro"
        case business = "Business"
        case enterprise = "Enterprise"
        
        var qrLimit: Int {
            switch self {
            case .free: return 3
            case .pro: return 50
            case .business: return 500
            case .enterprise: return 999999
            }
        }
        
        var dynamicQRLimit: Int {
            switch self {
            case .free: return 0
            case .pro: return 10
            case .business: return 100
            case .enterprise: return 999999
            }
        }
        
        var analyticsRetention: Int { // days
            switch self {
            case .free: return 7
            case .pro: return 90
            case .business: return 365
            case .enterprise: return -1 // unlimited
            }
        }
        
        var teamMemberLimit: Int {
            switch self {
            case .free: return 1
            case .pro: return 1
            case .business: return 5
            case .enterprise: return 999999
            }
        }
        
        var price: Double {
            switch self {
            case .free: return 0
            case .pro: return 9.99
            case .business: return 29.99
            case .enterprise: return 99.99
            }
        }
        
        var features: [String] {
            switch self {
            case .free:
                return ["3 Static QR Codes", "Basic Styles", "7-Day Analytics"]
            case .pro:
                return ["50 QR Codes", "10 Dynamic QRs", "90-Day Analytics", "Custom Branding", "Priority Support"]
            case .business:
                return ["500 QR Codes", "100 Dynamic QRs", "1-Year Analytics", "Team Collaboration", "API Access", "Bulk Operations"]
            case .enterprise:
                return ["Unlimited QRs", "Unlimited Dynamic QRs", "Forever Analytics", "White Label", "Dedicated Support", "Custom Features"]
            }
        }
    }
    
    var tier: Tier
    @ServerTimestamp var startDate: Date?
    var endDate: Date?
    var isActive: Bool
    var subscriptionId: String? // App Store subscription ID
    var customerId: String? // Stripe customer ID if using web payments
}

// MARK: - Tier feature Gates
extension UserSubscription.Tier {
    var isProOrAbove: Bool { self == .pro || self == .business || self == .enterprise }
    var isBusinessOrAbove: Bool { self == .business || self == .enterprise }
    var isEnterprise: Bool { self == .enterprise }
    
    var allowedDesigns: [QRStyle.QRDesignStyle] {
        switch self {
        case .free:
            return [.minimal]
        case .pro:
            return [.minimal, .gradient, .rounded]
        case .business:
            return [.minimal, .branded, .gradient, .rounded]
        case .enterprise:
            return QRStyle.QRDesignStyle.allCases
        }
    }
    
    var canUploadLogo: Bool { isProOrAbove }
    var canViewAdvancedAnalytics: Bool { isProOrAbove }
    var canUseBulkOperation: Bool { isBusinessOrAbove }
    var canManageTeam: Bool { isBusinessOrAbove }
    var canUseAPI: Bool { isBusinessOrAbove }
    var canUseWebhooks: Bool { isBusinessOrAbove }
    var whiteLabel: Bool { isEnterprise }
    var canDownloadHiRes: Bool { isProOrAbove }
    var canExportVector: Bool { isEnterprise }
}

extension UserSubscription.Tier {
    var allowedTypes: [QRCodeType] {
        switch self {
        case .free:
            return [.url, .wifi, .sms]
        case .pro:
            return [.url, .wifi, .email, .sms]
        case .business:
            return [.url, .vCard, .wifi, .email, .sms, .whatsapp, .linkedIn]
        case .enterprise:
            return QRCodeType.allCases
        }
    }
}
