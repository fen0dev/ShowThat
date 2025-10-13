//
//  AlertManager.swift
//  ShowThat
//
//  Created by Giuseppe De Masi on 25/06/2025.
//

import Foundation

@MainActor
class AlertManager: ObservableObject {
    static let shared = AlertManager()
    
    // Sheet Alerts
    @Published var showingAlert = false
    @Published var alertConfig: AlertConfig?
    
    // Toast Notifications
    @Published var showingToast = false
    @Published var toastConfig: ToastConfig?
    
    private init() {}
    
    // MARK: - Sheet Alerts
    
    func showSuccess(
        title: String,
        message: String,
        icon: String = "checkmark.circle.fill",
        action: (() -> Void)? = nil
    ) {
        alertConfig = AlertConfig(
            type: .success,
            title: title,
            message: message,
            icon: icon,
            primaryAction: AlertAction(title: "Great!", action: action)
        )
        showingAlert = true
    }
    
    func showError(
        title: String = "Oops!",
        message: String,
        icon: String = "exclamationmark.triangle.fill",
        retryAction: (() -> Void)? = nil
    ) {
        alertConfig = AlertConfig(
            type: .error,
            title: title,
            message: message,
            icon: icon,
            primaryAction: AlertAction(
                title: retryAction != nil ? "Try Again" : "OK",
                action: retryAction
            ),
            secondaryAction: retryAction != nil ? AlertAction(title: "Cancel") : nil
        )
        showingAlert = true
    }
    
    func showInfo(
        title: String,
        message: String,
        icon: String,
        action: (() -> Void)? = nil
    ) {
        alertConfig = AlertConfig(
            type: .info,
            title: title,
            message: message,
            icon: icon,
            primaryAction: AlertAction(title: "Got it", action: action)
        )
        showingAlert = true
    }
    
    func showCustom(config: AlertConfig) {
        alertConfig = config
        showingAlert = true
    }
    
    // MARK: - Toast Notifications
    
    func showToast(
        _ message: String,
        type: ToastType = .info,
        duration: Double = 3.0
    ) {
        toastConfig = ToastConfig(
            message: message,
            type: type,
            duration: duration
        )
        showingToast = true
    }
    
    func showSuccessToast(_ message: String) {
        showToast(message, type: .success)
    }
    
    func showErrorToast(_ message: String) {
        showToast(message, type: .error)
    }
}
