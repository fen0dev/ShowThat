//
//  AppConfiguration.swift
//  ShowThat
//
//  Created by Giuseppe De Masi on 30/09/2025.
//

import Foundation
import FirebaseCore

final class AppConfiguration {
    static let shared = AppConfiguration()
    
    // MARK: - Config keys
    private enum ConfigKey: String {
        case firebaseAPIKey = "FIREBASE_API_KEY"
        case firebaseProjectID = "FIREBASE_PROJECT_ID"
        case firebaseStorageBucket = "FIREBASE_STORAGE_BUCKET"
        case firebaseAppID = "FIREBASE_APP_ID"
        case firebaseSenderID = "FIREBASE_SENDER_ID"
        case analyticsEnabled = "ANALYTICS_ENABLED"
        case debugMode = "DEBUG_MODE"
    }
    
    // MARK: - Properties
    let firebaseAPIKey: String
    let firebaseProjectID: String
    let firebaseStorageBucket: String
    let firebaseAppID: String
    let firebaseSenderID: String
    let analyticsEnabled: Bool
    let debugMode: Bool
    
    private init() {
        // Carica configurazione da variabili d'ambiente o Info.plist
        self.firebaseAPIKey = Self.getValue(for: .firebaseAPIKey) ?? ""
        self.firebaseProjectID = Self.getValue(for: .firebaseProjectID) ?? ""
        self.firebaseStorageBucket = Self.getValue(for: .firebaseStorageBucket) ?? ""
        self.firebaseAppID = Self.getValue(for: .firebaseAppID) ?? ""
        self.firebaseSenderID = Self.getValue(for: .firebaseSenderID) ?? ""
        self.analyticsEnabled = Self.getValue(for: .analyticsEnabled) == "true"
        self.debugMode = Self.getValue(for: .debugMode) == "true"
        
        validateConfiguration()
    }
    
    // MARK: - Private Methods
    
    private static func getValue(for key: ConfigKey) -> String? {
        if let envValue = ProcessInfo.processInfo.environment[key.rawValue] {
            return envValue
        }
        
        if let plistValue = Bundle.main.object(forInfoDictionaryKey: key.rawValue) as? String {
            return plistValue
        }
        
        return getDevelopmentValue(for: key)
    }
    
    private static func getDevelopmentValue(for key: ConfigKey) -> String? {
        switch key {
        case .firebaseAPIKey:
            return "AIzaSyAyaxIXvLQ90GP-ld3BqKjRONswIDpm67Y"
        case .firebaseProjectID:
            return "showthat-23935"
        case .firebaseStorageBucket:
            return "showthat-23935.firebasestorage.app"
        case .firebaseAppID:
            return "1:753818250132:ios:a516c619cae0d8609dfd81"
        case .firebaseSenderID:
            return "753818250132"
        case .analyticsEnabled:
            return "false"
        case .debugMode:
            return "true"
        }
    }
    
    private func validateConfiguration() {
        let requiredKeys = [
            firebaseAPIKey,
            firebaseProjectID,
            firebaseStorageBucket,
            firebaseAppID,
            firebaseSenderID
        ]
        
        for (index, value) in requiredKeys.enumerated() {
            if value.isEmpty {
                let keyNames = ["API Key", "Project ID", "Storage Bucket", "App ID", "Sender ID"]
                fatalError("Missing required Firebase configuration: \(keyNames[index])")
            }
        }
    }
    
    // MARK: - Public Methods
    
    func configureFirebase() {
        let options = FirebaseOptions(
            googleAppID: firebaseAppID,
            gcmSenderID: firebaseSenderID
        )
        options.apiKey = firebaseAPIKey
        options.projectID = firebaseProjectID
        options.storageBucket = firebaseStorageBucket
        
        FirebaseApp.configure(options: options)
        
        if debugMode {
            print("🔥 Firebase configured successfully")
            print("📊 Analytics enabled: \(analyticsEnabled)")
        }
    }
}
