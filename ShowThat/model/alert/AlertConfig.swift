//
//  AlertConfig.swift
//  ShowThat
//
//  Created by Giuseppe De Masi on 25/06/2025.
//

import SwiftUI

struct AlertConfig {
    enum AlertType {
        case success
        case error
        case info
        case custom
        
        var color: Color {
            switch self {
            case .success: return .green
            case .error: return .red
            case .info: return .blue
            case .custom: return .purple
            }
        }
        
        var gradient: LinearGradient {
            switch self {
            case .success:
                return LinearGradient(
                    colors: [Color.green.opacity(0.8), Color.green],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            case .error:
                return LinearGradient(
                    colors: [Color.red.opacity(0.8), Color.pink],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            case .info:
                return LinearGradient(
                    colors: [Color.blue.opacity(0.8), Color.blue],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            case .custom:
                return LinearGradient(
                    colors: [Color.purple.opacity(0.8), Color.blue],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            }
        }
    }
    
    let type: AlertType
    let title: String
    let message: String
    let icon: String
    let primaryAction: AlertAction
    let secondaryAction: AlertAction?
    
    init(
        type: AlertType,
        title: String,
        message: String,
        icon: String,
        primaryAction: AlertAction,
        secondaryAction: AlertAction? = nil
    ) {
        self.type = type
        self.title = title
        self.message = message
        self.icon = icon
        self.primaryAction = primaryAction
        self.secondaryAction = secondaryAction
    }
}

