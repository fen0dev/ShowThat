//
//  WiFiData.swift
//  ShowThat
//
//  Created by Giuseppe De Masi on 24/06/2025.
//

import Foundation
import CryptoKit

struct WiFiData: Codable, Equatable {
    var ssid: String
    private var encryptedPasswordData: EncryptedString?
    var encryption: WiFiEncryption = .wpa
    var isHidden: Bool = false
    
    // MARK: - Password Management
    
    /// Password in chiaro (solo per generazione QR)
    var password: String {
        get {
            guard let encryptedData = encryptedPasswordData else { return "" }
            do {
                return try EncryptionService.shared.decryptString(encryptedData)
            } catch {
                print("Failed to decrypt WiFi password: \(error)")
                return ""
            }
        }
        set {
            if newValue.isEmpty {
                encryptedPasswordData = nil
            } else {
                do {
                    encryptedPasswordData = try EncryptionService.shared.encryptString(newValue)
                } catch {
                    print("Failed to encrypt WiFi password: \(error)")
                    encryptedPasswordData = nil
                }
            }
        }
    }
    
    /// Verifica se la password è impostata
    var hasPassword: Bool {
        return encryptedPasswordData != nil && !password.isEmpty
    }
    
    // MARK: - QR Code Generation
    
    /// Genera il contenuto sicuro per il QR code WiFi
    var secureQRContent: String {
        var components: [String] = []
        components.append("WIFI:T:\(encryption.rawValue)")
        components.append("S:\(escapeSSID(ssid))")
        
        if hasPassword {
            components.append("P:\(password)")
        } else {
            components.append("P:")
        }
        
        if isHidden {
            components.append("H:true")
        }
        
        components.append(";")
        return components.joined()
    }
    
    /// Escape speciale caratteri per SSID
    private func escapeSSID(_ ssid: String) -> String {
        return ssid.replacingOccurrences(of: "\\", with: "\\\\")
                  .replacingOccurrences(of: ";", with: "\\;")
                  .replacingOccurrences(of: ",", with: "\\,")
                  .replacingOccurrences(of: ":", with: "\\:")
    }
    
    // MARK: - Validation
    
    static func validatePassword(_ password: String) -> Bool {
        guard !password.isEmpty else { return true } // Password opzionale
        return password.count >= 8 && password.count <= 63
    }
    
    static func validateSSID(_ ssid: String) -> Bool {
        return !ssid.isEmpty && ssid.count <= 32
    }
    
    // MARK: - Secure Dictionary for Storage
    
    func toSecureDictionary() -> [String: Any] {
        return [
            "ssid": ssid,
            "encryptedPassword": encryptedPasswordData as Any,
            "encryption": encryption.rawValue,
            "isHidden": isHidden
        ]
    }
    
    // MARK: - Initializers
    
    init(ssid: String, password: String = "", encryption: WiFiEncryption = .wpa, isHidden: Bool = false) {
        self.ssid = ssid
        self.encryption = encryption
        self.isHidden = isHidden
        self.password = password // Questo triggerà la cifratura
    }
    
    // MARK: - Codable Implementation
    
    enum CodingKeys: String, CodingKey {
        case ssid, encryptedPassword, encryption, isHidden
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        ssid = try container.decode(String.self, forKey: .ssid)
        
        // Gestione sicura della password cifrata
        if let encryptedPasswordString = try? container.decodeIfPresent(String.self, forKey: .encryptedPassword) {
            // Se è una stringa semplice, è il formato legacy (in chiaro)
            if encryptedPasswordString.count <= 100 { // Lunghezza stimata password
                print("Converting legacy WiFi password to encrypted format")
                self.password = encryptedPasswordString
            } else {
                // Formato cifrato
                encryptedPasswordData = try? container.decode(EncryptedString.self, forKey: .encryptedPassword)
            }
        } else {
            encryptedPasswordData = nil
        }
        
        if let encryptionRaw = try? container.decode(String.self, forKey: .encryption),
           let encryptionType = WiFiEncryption(rawValue: encryptionRaw) {
            encryption = encryptionType
        } else {
            encryption = .wpa
        }
        
        isHidden = try container.decode(Bool.self, forKey: .isHidden)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(ssid, forKey: .ssid)
        try container.encode(encryptedPasswordData, forKey: .encryptedPassword)
        try container.encode(encryption.rawValue, forKey: .encryption)
        try container.encode(isHidden, forKey: .isHidden)
    }
    
    // MARK: - Equatable
    
    static func == (lhs: WiFiData, rhs: WiFiData) -> Bool {
        return lhs.ssid == rhs.ssid &&
               lhs.encryptedPasswordData?.ciphertext == rhs.encryptedPasswordData?.ciphertext &&
               lhs.encryption == rhs.encryption &&
               lhs.isHidden == rhs.isHidden
    }
}

// MARK: - WiFi Encryption Types

enum WiFiEncryption: String, Codable, CaseIterable {
    case none = "nopass"
    case wep = "WEP"
    case wpa = "WPA"
    case wpa2 = "WPA2"
    case wpa3 = "WPA3"
    
    var displayName: String {
        switch self {
        case .none: return "Open"
        case .wep: return "WEP"
        case .wpa: return "WPA/WPA2"
        case .wpa2: return "WPA2"
        case .wpa3: return "WPA3"
        }
    }
}
