//
//  HapticManager.swift
//  ShowThat
//
//  Created by Giuseppe De Masi on 30/09/2025.
//

import UIKit

/// Gestisce feedback aptico per migliorare l'esperienza utente
final class HapticManager {
    static let shared = HapticManager()
    
    private let lightImpactGenerator = UIImpactFeedbackGenerator(style: .light)
    private let mediumImpactGenerator = UIImpactFeedbackGenerator(style: .medium)
    private let heavyImpactGenerator = UIImpactFeedbackGenerator(style: .heavy)
    private let selectionFeedback = UISelectionFeedbackGenerator()
    private let notificationFeedback = UINotificationFeedbackGenerator()
    
    private init() {
        // Prepara i generatori per ridurre la latenza
        lightImpactGenerator.prepare()
        mediumImpactGenerator.prepare()
        heavyImpactGenerator.prepare()
        selectionFeedback.prepare()
        notificationFeedback.prepare()
    }
    
    // MARK: - Impact Feedback
    
    func lightImpact() {
        lightImpactGenerator.impactOccurred()
    }
    
    func mediumImpact() {
        mediumImpactGenerator.impactOccurred()
    }
    
    func heavyImpact() {
        heavyImpactGenerator.impactOccurred()
    }
    
    // MARK: - Selection Feedback
    
    func selectionChanged() {
        selectionFeedback.selectionChanged()
    }
    
    // MARK: - Notification Feedback
    
    func success() {
        notificationFeedback.notificationOccurred(.success)
    }
    
    func warning() {
        notificationFeedback.notificationOccurred(.warning)
    }
    
    func error() {
        notificationFeedback.notificationOccurred(.error)
    }
    
    // MARK: - Custom Patterns
    
    func qrCodeGenerated() {
        // Pattern personalizzato per generazione QR
        mediumImpact()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.lightImpact()
        }
    }
    
    func qrCodeScanned() {
        // Pattern personalizzato per scansione QR
        success()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            self.lightImpact()
        }
    }
    
    func buttonTapped() {
        lightImpact()
    }
    
    func cardSelected() {
        selectionChanged()
    }
    
    func errorOccurred() {
        error()
    }
    
    func successAction() {
        success()
    }
    
    func warningAction() {
        warning()
    }
}
