//
//  EncryptionService.swift
//  ShowThat
//
//  Created by Giuseppe De Masi on 11/10/2025.
//

import Foundation
import CryptoKit
import Security

final class EncryptionService {
    static let shared = EncryptionService()
    
    private let keychainService = "com.showthat.encryption"
    private let keychainAccount = "encryptionKey"
    
    private init() { }
    
    // MARK: - Key management
    
    /// generate or recover a secure crypto key from Keychain
    private func getOrCreateEncryptionKey() throws -> SymmetricKey {
        // try first to recover the key if exists or abort and make new one
        if let existingKeyData = try? getKeyFromKeychain() {
            return SymmetricKey(data: existingKeyData)
        }
        
        // create new
        let newKey = SymmetricKey(size: .bits256)
        let keyData = newKey.withUnsafeBytes { Data($0) }
        
        try saveKeyToKeychain(keyData)
        
        return newKey
    }
    
    /// save key
    private func saveKeyToKeychain(_ keyData: Data) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: keychainAccount,
            kSecValueData as String: keyData,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]
        
        // remove possible existing key
        SecItemDelete(query as CFDictionary)
        
        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw EncryptionError.keychainError(status)
        }
    }
    
    /// recover cyphered key from Keychain
    private func getKeyFromKeychain() throws -> Data {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: keychainAccount,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess,
              let keyData = result as? Data else {
            throw EncryptionError.keyNotFound
        }
        
        return keyData
    }
    
    // MARK: - Encryption methods
    
    /// cypher sensitive data using AES-GCM
    func encrypt(_ data: Data) throws -> EncryptedData {
        let key = try getOrCreateEncryptionKey()
        let nonce = AES.GCM.Nonce()
        
        let sealedBox = try AES.GCM.seal(data, using: key, nonce: nonce)
        
        return EncryptedData(
            ciphertext: sealedBox.ciphertext,
            nonce: sealedBox.nonce,
            tag: sealedBox.tag
        )
    }
    
    /// decypher
    func decrypt(_ encryptedData: EncryptedData) throws -> Data {
        let key = try getOrCreateEncryptionKey()
        
        let sealedBox = try AES.GCM.SealedBox(
            nonce: encryptedData.nonce,
            ciphertext: encryptedData.ciphertext,
            tag: encryptedData.tag
        )
        
        return try AES.GCM.open(sealedBox, using: key)
    }
    
    /// cypher a string
    func encryptString(_ string: String) throws -> EncryptedString {
        guard let data = string.data(using: .utf8) else {
            throw EncryptionError.invalidData
        }
        
        let encrypted = try encrypt(data)
        return EncryptedString(
            ciphertext: encrypted.ciphertext.base64EncodedString(),
            nonce: encrypted.nonce.withUnsafeBytes { Data($0).base64EncodedString() },
            tag: encrypted.tag.base64EncodedString()
        )
    }
    
    /// decypher a string
    func decryptString(_ encryptedString: EncryptedString) throws -> String {
        guard let ciphertextData = Data(base64Encoded: encryptedString.ciphertext),
              let nonceData = Data(base64URLEncoded: encryptedString.nonce),
              let tag = Data(base64URLEncoded: encryptedString.tag) else {
            throw EncryptionError.invalidFormat
        }
        
        let encryptedData = EncryptedData(
            ciphertext: ciphertextData,
            nonce: try AES.GCM.Nonce(data: nonceData),
            tag: tag
        )
        
        let decryptedData = try decrypt(encryptedData)
        return String(data: decryptedData, encoding: .utf8) ?? ""
    }
    
    // MARK: - Cleanup
    
    /// remove key from Keychain (for reset or uninstallation)
    func clearEncryptionKey() throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: keychainAccount
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        if status != errSecSuccess && status != errSecItemNotFound {
            throw EncryptionError.keychainError(status)
        }
    }
}

// MARK: - Supporting Types

/// Dati cifrati per archiviazione sicura
struct EncryptedData {
    let ciphertext: Data
    let nonce: AES.GCM.Nonce
    let tag: Data
    
    init(ciphertext: Data, nonce: AES.GCM.Nonce, tag: Data) {
        self.ciphertext = ciphertext
        self.nonce = nonce
        self.tag = tag
    }
}

/// Stringa cifrata per trasmissione sicura
struct EncryptedString: Encodable, Decodable {
    let ciphertext: String // Base64 encoded
    let nonce: String     // Base64 encoded
    let tag: String       // Base64 encoded
}

// MARK: - Encryption Errors

enum EncryptionError: LocalizedError {
    case keychainError(OSStatus)
    case keyNotFound
    case invalidData
    case invalidFormat
    case decryptionFailed
    
    var errorDescription: String? {
        switch self {
        case .keychainError(let status):
            return "Keychain error: \(status)"
        case .keyNotFound:
            return "Encryption key not found"
        case .invalidData:
            return "Invalid data for encryption"
        case .invalidFormat:
            return "Invalid encrypted data format"
        case .decryptionFailed:
            return "Failed to decrypt data"
        }
    }
}
