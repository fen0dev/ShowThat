//
//  ValidationManager.swift
//  ShowThat
//
//  Created by Giuseppe De Masi on 30/09/2025.
//

import Foundation

/// Gestisce validazione robusta di tutti i dati utente
final class ValidationManager {
    static let shared = ValidationManager()
    
    private init() {}
    
    // MARK: - Public Methods
    
    func validateQRCode(name: String, type: QRCodeType, content: QRContent) throws {
        try validateQRName(name)
        
        switch content {
        case .url(let urlString):
            try validateURL(urlString)
        case .email(let data):
            try validateEmail(data.email)
        case .wifi(let data):
            try validateWiFiSSID(data.ssid)
            if data.encryption.rawValue != "nopass" {
                try validateWiFiPassword(data.password)
            }
        case .vCard(let data):
            try validateDisplayName(data.fullName)
            if let email = data.email, !email.isEmpty { try validateEmail(email) }
            if let phone = data.phone, !phone.isEmpty { try validatePhoneNumber(phone) }
            if let website = data.website, !website.isEmpty { try validateURL(website) }
        case .text(let text):
            switch type {
            case .sms, .whatsapp:
                try validatePhoneNumber(text)
            case .linkedIn:
                try validateURL(text)
            default:
                break
            }
        }
    }
    
    func validateEmail(_ email: String) throws {
        guard !email.isEmpty else {
            throw ValidationError.emptyField("Email")
        }
        
        let emailRegex = #"^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$"#
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        
        guard emailPredicate.evaluate(with: email) else {
            throw ValidationError.invalidFormat("Email")
        }
        
        guard email.count <= 254 else {
            throw ValidationError.tooLong("Email", 254)
        }
    }
    
    func validatePassword(_ password: String) throws {
        guard !password.isEmpty else {
            throw ValidationError.emptyField("Password")
        }
        
        guard password.count >= 6 else {
            throw ValidationError.tooShort("Password", 6)
        }
        
        guard password.count <= 128 else {
            throw ValidationError.tooLong("Password", 128)
        }
    }
    
    func validateURL(_ urlString: String) throws {
        guard !urlString.isEmpty else {
            throw ValidationError.emptyField("URL")
        }
        
        guard let url = URL(string: urlString) else {
            throw ValidationError.invalidFormat("URL")
        }
        
        guard url.scheme != nil else {
            throw ValidationError.invalidFormat("URL - manca il protocollo (http/https)")
        }
        
        guard url.host != nil else {
            throw ValidationError.invalidFormat("URL - dominio non valido")
        }
        
        guard urlString.count <= 2048 else {
            throw ValidationError.tooLong("URL", 2048)
        }
    }
    
    func validateQRName(_ name: String) throws {
        guard !name.isEmpty else {
            throw ValidationError.emptyField("Nome QR Code")
        }
        
        guard name.count >= 1 else {
            throw ValidationError.tooShort("Nome QR Code", 1)
        }
        
        guard name.count <= 100 else {
            throw ValidationError.tooLong("Nome QR Code", 100)
        }
        
        // Rimuovi caratteri pericolosi
        let sanitized = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard sanitized == name else {
            throw ValidationError.invalidFormat("Nome QR Code - rimuovi spazi extra")
        }
    }
    
    func validatePhoneNumber(_ phone: String) throws {
        guard !phone.isEmpty else {
            throw ValidationError.emptyField("Numero di telefono")
        }
        
        // Rimuovi spazi e caratteri speciali
        let cleaned = phone.replacingOccurrences(of: "[^0-9+]", with: "", options: .regularExpression)
        
        guard cleaned.count >= 7 && cleaned.count <= 15 else {
            throw ValidationError.invalidFormat("Numero di telefono - formato non valido")
        }
    }
    
    func validateDisplayName(_ name: String) throws {
        guard !name.isEmpty else {
            throw ValidationError.emptyField("Nome visualizzato")
        }
        
        guard name.count >= 2 else {
            throw ValidationError.tooShort("Nome visualizzato", 2)
        }
        
        guard name.count <= 50 else {
            throw ValidationError.tooLong("Nome visualizzato", 50)
        }
        
        // Controlla caratteri pericolosi
        let dangerousChars = CharacterSet(charactersIn: "<>\"'&")
        guard name.rangeOfCharacter(from: dangerousChars) == nil else {
            throw ValidationError.invalidFormat("Nome visualizzato - caratteri non consentiti")
        }
    }
    
    func validateWiFiSSID(_ ssid: String) throws {
        guard !ssid.isEmpty else {
            throw ValidationError.emptyField("Nome WiFi")
        }
        
        guard ssid.count <= 32 else {
            throw ValidationError.tooLong("Nome WiFi", 32)
        }
        
        // SSID non può contenere caratteri di controllo
        let controlChars = CharacterSet.controlCharacters
        guard ssid.rangeOfCharacter(from: controlChars) == nil else {
            throw ValidationError.invalidFormat("Nome WiFi - caratteri non consentiti")
        }
    }
    
    func validateWiFiPassword(_ password: String) throws {
        guard !password.isEmpty else {
            throw ValidationError.emptyField("Password WiFi")
        }
        
        guard password.count >= 8 else {
            throw ValidationError.tooShort("Password WiFi", 8)
        }
        
        guard password.count <= 63 else {
            throw ValidationError.tooLong("Password WiFi", 63)
        }
    }
    
    func sanitizeInput(_ input: String, maxLength: Int = 1000) -> String {
        // Rimuovi caratteri di controllo
        let controlChars = CharacterSet.controlCharacters
        let sanitized = input.components(separatedBy: controlChars).joined()
        
        // Tronca se troppo lungo
        if sanitized.count > maxLength {
            return String(sanitized.prefix(maxLength))
        }
        
        return sanitized.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    // MARK: - Bulk Validation
    
    func validateQRCodeData(_ data: QRCodeData) throws {
        try validateQRName(data.name)
        
        switch data.type {
        case .url:
            try validateURL(data.content)
        case .email:
            try validateEmail(data.content)
        case .sms, .whatsapp:
            try validatePhoneNumber(data.content)
        case .wifi:
            // Per WiFi, il contenuto dovrebbe essere JSON
            try validateWiFiData(data.content)
        case .vCard:
            // Per vCard, il contenuto dovrebbe essere JSON
            try validateVCardData(data.content)
        case .linkedIn:
            try validateURL(data.content)
        }
    }
    
    private func validateWiFiData(_ jsonString: String) throws {
        guard let data = jsonString.data(using: .utf8) else {
            throw ValidationError.invalidFormat("Dati WiFi")
        }
        
        do {
            let wifiData = try JSONDecoder().decode(WiFiData.self, from: data)
            try validateWiFiSSID(wifiData.ssid)
            try validateWiFiPassword(wifiData.password)
        } catch {
            throw ValidationError.invalidFormat("Dati WiFi - formato JSON non valido")
        }
    }
    
    private func validateVCardData(_ jsonString: String) throws {
        guard let data = jsonString.data(using: .utf8) else {
            throw ValidationError.invalidFormat("Dati vCard")
        }
        
        do {
            let vCardData = try JSONDecoder().decode(VCardData.self, from: data)
            try validateDisplayName(vCardData.fullName)
            
            if let email = vCardData.email, !email.isEmpty {
                try validateEmail(email)
            }
            
            if let phone = vCardData.phone, !phone.isEmpty {
                try validatePhoneNumber(phone)
            }
        } catch {
            throw ValidationError.invalidFormat("Dati vCard - formato JSON non valido")
        }
    }
}

// MARK: - Supporting Types

struct QRCodeData {
    let name: String
    let type: QRCodeType
    let content: String
}
