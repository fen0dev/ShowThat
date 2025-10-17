//
//  OnboardingManager.swift
//  ShowThat
//
//  Created by Giuseppe De Masi on 16/10/2025.
//

import Foundation
import SwiftUI

final class OnboardingManager: ObservableObject {
    @Published var currentStep: Int = 0
    @Published var isCompleted: Bool = false
    @Published var userPreferences: [String: Any] = [:]
    
    private let userDefaults = UserDefaults.standard
    private let onboardingKey = "onboarding_completed"
    private let preferencesKey = "onboarding_preferences"
    
    init() {
        checkOnboardingStatus()
    }
    
    private func checkOnboardingStatus() {
        isCompleted = userDefaults.bool(forKey: onboardingKey)
    }
    
    func completeOnboarding() {
        isCompleted = true
        userDefaults.set(true, forKey: onboardingKey)
        userDefaults.set(userPreferences, forKey: preferencesKey)
    }
    
    func skipOnboarding() {
        isCompleted = false
        currentStep = 0
        userPreferences.removeAll()
        userDefaults.removeObject(forKey: onboardingKey)
        userDefaults.removeObject(forKey: preferencesKey)
        completeOnboarding()
    }
    
    func savePreference(_ key: String, value: Any) {
        userPreferences[key] = value
    }
}
