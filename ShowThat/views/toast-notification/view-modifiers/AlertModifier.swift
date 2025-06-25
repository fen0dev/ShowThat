//
//  AlertModifier.swift
//  ShowThat
//
//  Created by Giuseppe De Masi on 25/06/2025.
//

import SwiftUI

struct AlertModifier: ViewModifier {
    @ObservedObject var alertManager = AlertManager.shared
    
    func body(content: Content) -> some View {
        content
            .overlay(alignment: .top) {
                if alertManager.showingToast, let config = alertManager.toastConfig {
                    ToastView(
                        config: config,
                        isPresented: $alertManager.showingToast
                    )
                    .padding(.top, 50)
                    .transition(.asymmetric(
                        insertion: .move(edge: .top).combined(with: .opacity),
                        removal: .move(edge: .top).combined(with: .opacity)
                    ))
                    .zIndex(999)
                }
            }
            .overlay {
                if alertManager.showingAlert, let config = alertManager.alertConfig {
                    CustomAlertSheet(
                        config: config,
                        isPresented: $alertManager.showingAlert
                    )
                    .transition(.opacity.combined(with: .scale))
                    .zIndex(1000)
                }
            }
    }
}

extension View {
    func withAlerts() -> some View {
        modifier(AlertModifier())
    }
}
