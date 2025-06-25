//
//  QRCodeManager.swift
//  ShowThat
//
//  Created by Giuseppe De Masi on 24/06/2025.
//

import SwiftUI
import Combine
import StoreKit
import Foundation
import FirebaseAuth
import FirebaseStorage
import FirebaseFirestore
import FirebaseAnalytics
import FirebaseFirestoreCombineSwift

@MainActor
class QRCodeManager: ObservableObject {
    @Published var qrCodes: [QRCodeModel] = []
    @Published var userProfile: UserProfile?
    @Published var currentTeam: Team?
    @Published var isLoading = false
    @Published var error: Error?
    @Published var isAuthenticated = false
    
    private var db = Firestore.firestore()
    private var storage = Storage.storage()
    private var auth = Auth.auth()
    private var listener: ListenerRegistration?
    private var userListener: ListenerRegistration?
    private var cancellables = Set<AnyCancellable>()
    
    var currentUserId: String? {
        auth.currentUser?.uid
    }
    
    var currentSubscription: UserSubscription? {
        // First check StoreKit for active subscription
        if let storeTier = PaymentManager.shared.currentSubscription {
            // Return a subscription object based on StoreKit status
            return UserSubscription(
                tier: storeTier,
                startDate: Date(),
                endDate: nil,
                isActive: true,
                subscriptionId: nil,
                customerId: nil
            )
        }
        // Fall back to Firebase stored subscription
        return userProfile?.subscription
    }
    
    init() {
        setupAuthListener()
    }
    
    deinit {
        listener?.remove()
        userListener?.remove()
    }
    
    // MARK: - Authentication
    
    private func setupAuthListener() {
        _ = auth.addStateDidChangeListener { [weak self] _, user in
            guard let self = self else { return }
            
            self.isAuthenticated = user != nil
            
            if let user = user {
                Task {
                    await self.loadUserProfile(userId: user.uid)
                    self.setupQRCodesListener(userId: user.uid)
                }
            } else {
                self.userProfile = nil
                self.qrCodes = []
                self.listener?.remove()
                self.userListener?.remove()
            }
        }
    }
    
    func signIn(email: String, password: String) async throws {
        isLoading = true
        defer { isLoading = false }
        
        try await auth.signIn(withEmail: email, password: password)
        Analytics.logEvent("login", parameters: ["method": "email"])
    }
    
    func signUp(email: String, password: String, displayName: String) async throws {
        isLoading = true
        defer { isLoading = false }
        
        let result = try await auth.createUser(withEmail: email, password: password)
        
        // Create user profile in Firestore
        let newProfile = UserProfile(
            email: email,
            displayName: displayName,
            subscription: UserSubscription(
                tier: .free,
                isActive: true
            )
        )
        
        _ = db.collection("users").document(result.user.uid).setData(from: newProfile)
        
        Analytics.logEvent("sign_up", parameters: ["method": "email"])
    }
    
    func signOut() throws {
        try auth.signOut()
        Analytics.logEvent("logout", parameters: nil)
    }
    
    // MARK: - User Profile Management
    
    private func loadUserProfile(userId: String) async {
        do {
            let document = try await db.collection("users").document(userId).getDocument()
            self.userProfile = try document.data(as: UserProfile.self)
            
            // Setup real-time listener for user profile
            userListener = db.collection("users").document(userId)
                .addSnapshotListener { [weak self] snapshot, error in
                    if let error = error {
                        print("Error listening to user profile: \(error)")
                        return
                    }
                    
                    if let snapshot = snapshot, snapshot.exists {
                        self?.userProfile = try? snapshot.data(as: UserProfile.self)
                    }
                }
        } catch {
            print("Error loading user profile: \(error)")
            self.error = error
        }
    }
    
    // MARK: - QR Code Real-time Sync
    
    private func setupQRCodesListener(userId: String) {
        let query = db.collection("qrCodes")
            .whereField("userId", isEqualTo: userId)
            .order(by: "createdAt", descending: true)
        
        listener = query.addSnapshotListener { [weak self] snapshot, error in
            guard let self = self else { return }
            
            if let error = error {
                print("Error listening to QR codes: \(error)")
                self.error = error
                return
            }
            
            guard let documents = snapshot?.documents else { return }
            
            self.qrCodes = documents.compactMap { document in
                try? document.data(as: QRCodeModel.self)
            }
        }
    }
    
    // MARK: - QR Code CRUD Operations
    
    func createQRCode(name: String, type: QRCodeType, content: QRContent, style: QRStyle, isDynamic: Bool = false, logoImage: UIImage? = nil) async throws {
        guard let userId = currentUserId else { throw QRError.notAuthenticated }
        
        // Check subscription limits
        guard canCreateQRCode(isDynamic: isDynamic) else {
            throw QRError.subscriptionLimitReached
        }
        
        isLoading = true
        defer { isLoading = false }
        
        var qrStyle = style
        
        // Upload logo if provided
        if let logoImage = logoImage {
            let logoURL = try await uploadLogo(logoImage, userId: userId)
            qrStyle.logoURL = logoURL
        }
        
        // Create QR code
        let newQR = QRCodeModel(
            userId: userId,
            name: name,
            type: type,
            content: content,
            style: qrStyle,
            isDynamic: isDynamic
        )
        
        // Save to Firestore
        let docRef = db.collection("qrCodes").document()
        _ = docRef.setData(from: newQR)
        
        // Update user counters
        let increment = FieldValue.increment(Int64(1))
        let userUpdate: [String: Any] = isDynamic ?
            ["dynamicQRsCreated": increment] :
            ["qrCodesCreated": increment]
        
        _ = db.collection("users").document(userId).updateData(userUpdate)
        
        // Log analytics
        Analytics.logEvent("qr_code_created", parameters: [
            "type": type.rawValue,
            "is_dynamic": isDynamic,
            "style": style.design.rawValue
        ])
        
        // If dynamic, create routing document
        if isDynamic, let shortCode = newQR.shortCode {
            try await createDynamicRoute(
                shortCode: shortCode,
                qrCodeId: docRef.documentID,
                destination: content.rawValue
            )
        }
    }
    
    func updateQRCode(_ qrCode: QRCodeModel) async throws {
        guard let qrId = qrCode.id else { throw QRError.invalidQRCode }
        
        isLoading = true
        defer { isLoading = false }
        
        var updated = qrCode
        updated.updatedAt = Date()
        
        _ = db.collection("qrCodes").document(qrId).setData(from: updated, merge: true)
        
        // If dynamic and content changed, update route
        if qrCode.isDynamic, let shortCode = qrCode.shortCode {
            try await updateDynamicRoute(shortCode: shortCode, destination: qrCode.content.rawValue)
        }
        
        Analytics.logEvent("qr_code_updated", parameters: ["qr_id": qrId])
    }
    
    func deleteQRCode(_ qrCode: QRCodeModel) async throws {
        guard let qrId = qrCode.id,
              let userId = currentUserId else { throw QRError.invalidQRCode }
        
        isLoading = true
        defer { isLoading = false }
        
        // Delete QR code
        try await db.collection("qrCodes").document(qrId).delete()
        
        // Delete analytics
        let analyticsQuery = db.collection("analytics")
            .whereField("qrCodeId", isEqualTo: qrId)
        
        let analytics = try await analyticsQuery.getDocuments()
        for doc in analytics.documents {
            try await doc.reference.delete()
        }
        
        // Update user counters
        let decrement = FieldValue.increment(Int64(-1))
        let userUpdate: [String: Any] = qrCode.isDynamic ?
            ["dynamicQRsCreated": decrement] :
            ["qrCodesCreated": decrement]
        
        _ = db.collection("users").document(userId).updateData(userUpdate)
        
        // If dynamic, delete route
        if let shortCode = qrCode.shortCode {
            try await deleteDynamicRoute(shortCode: shortCode)
        }
        
        Analytics.logEvent("qr_code_deleted", parameters: ["qr_id": qrId])
    }
    
    // MARK: - Dynamic QR Routes
    
    private func createDynamicRoute(shortCode: String, qrCodeId: String, destination: String) async throws {
        let route = [
            "qrCodeId": qrCodeId,
            "destination": destination,
            "createdAt": FieldValue.serverTimestamp()
        ] as [String : Any]
        
        try await db.collection("routes").document(shortCode).setData(route)
    }
    
    private func updateDynamicRoute(shortCode: String, destination: String) async throws {
        let updatedData: [String: Any] = [
            "destination": destination,
            "updatedAt": FieldValue.serverTimestamp()
        ]
        
        _ = db.collection("routes").document(shortCode).updateData(updatedData)
    }
    
    private func deleteDynamicRoute(shortCode: String) async throws {
        try await db.collection("routes").document(shortCode).delete()
    }
    
    // MARK: - Analytics
    
    func recordScan(shortCode: String, device: DeviceInfo, location: ScanLocation? = nil) async {
        // This would be called from your Firebase Function when someone scans
        // For now, we'll implement the client-side version
        
        guard let qrCode = qrCodes.first(where: { $0.shortCode == shortCode }),
              let qrId = qrCode.id else { return }
        
        let scanEvent = ScanEvent(
            qrCodeId: qrId,
            location: location,
            device: device,
            referrer: nil
        )
        
        do {
            // Record scan event
            _ = db.collection("scans").addDocument(from: scanEvent)
            
            // Update scan count
            let updateData: [String: Any] = [
                "scanCount": FieldValue.increment(Int64(1))
            ]
            
            _ = db.collection("qrCodes").document(qrId).updateData(updateData)
            
            // Update analytics summary
            await updateAnalyticsSummary(qrCodeId: qrId, scanEvent: scanEvent)
            
        }
    }
    
    private func updateAnalyticsSummary(qrCodeId: String, scanEvent: ScanEvent) async {
        let summaryRef = db.collection("analytics").document(qrCodeId)
        
        do {
            let dateKey = ISO8601DateFormatter().string(from: Date()).prefix(10).description
            
            var updates: [String: Any] = [
                "qrCodeId": qrCodeId,
                "totalScans": FieldValue.increment(Int64(1)),
                "scansByDay.\(dateKey)": FieldValue.increment(Int64(1)),
                "scansByDevice.\(scanEvent.device.platform)": FieldValue.increment(Int64(1)),
                "lastUpdated": FieldValue.serverTimestamp()
            ]
            
            if let country = scanEvent.location?.country {
                updates["scansByCountry.\(country)"] = FieldValue.increment(Int64(1))
            }
            
            try await summaryRef.setData(updates, merge: true)
        } catch {
            print("Error updating analytics summary: \(error)")
        }
    }
    
    func getAnalytics(for qrCode: QRCodeModel) async throws -> QRAnalyticsSummary? {
        guard let qrId = qrCode.id else { return nil }
        
        let document = try await db.collection("analytics").document(qrId).getDocument()
        return try document.data(as: QRAnalyticsSummary.self)
    }
    
    // MARK: - Subscription Management
    
    func canCreateQRCode(isDynamic: Bool) -> Bool {
        guard let subscription = currentSubscription else {
            return !isDynamic && qrCodes.count < 3 // Free tier defaults
        }
        
        if isDynamic {
            let dynamicCount = qrCodes.filter { $0.isDynamic }.count
            return dynamicCount < subscription.tier.dynamicQRLimit
        } else {
            let staticCount = qrCodes.filter { !$0.isDynamic }.count
            return staticCount < subscription.tier.qrLimit
        }
    }
    
    func upgradeSubscription(to tier: UserSubscription.Tier, subscriptionId: String) async throws {
        guard let userId = currentUserId else { throw QRError.notAuthenticated }
        
        let subscription = UserSubscription(
            tier: tier,
            startDate: Date(),
            endDate: Calendar.current.date(byAdding: .month, value: 1, to: Date()),
            isActive: true,
            subscriptionId: subscriptionId
        )
        
        let updateData: [String: Any] = [
            "subscription": try Firestore.Encoder().encode(subscription)
        ]
        
        _ = db.collection("users").document(userId).updateData(updateData)
        
        Analytics.logEvent("subscription_upgraded", parameters: [
            "tier": tier.rawValue,
            "price": tier.price
        ])
    }
    
    // MARK: - Team Management
    
    func createTeam(name: String) async throws {
        guard let userId = currentUserId else { throw QRError.notAuthenticated }
        
        let team = Team(
            name: name,
            ownerId: userId,
            memberIds: [userId],
            settings: TeamSettings()
        )
        
        let docRef = db.collection("teams").document()
        _ = docRef.setData(from: team)
        
        // Update user with team ID
        let updateData: [String: Any] = [
            "teamId": docRef.documentID
        ]
        
        _ = db.collection("users").document(userId).updateData(updateData)
    }
    
    // MARK: - Storage Operations
    
    private func uploadLogo(_ image: UIImage, userId: String) async throws -> String {
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            throw QRError.imageProcessingFailed
        }
        
        let filename = "\(userId)/logos/\(UUID().uuidString).jpg"
        let storageRef = storage.reference().child(filename)
        
        _ = try await storageRef.putDataAsync(imageData)
        let downloadURL = try await storageRef.downloadURL()
        
        return downloadURL.absoluteString
    }
    
    // MARK: - Bulk Operations
    
    func bulkCreateQRCodes(from csvData: String) async throws {
        let lines = csvData.components(separatedBy: .newlines)
        var successCount = 0
        var errors: [String] = []
        
        for (index, line) in lines.enumerated() where !line.isEmpty {
            let components = line.components(separatedBy: ",")
            guard components.count >= 2 else {
                errors.append("Line \(index + 1): Invalid format")
                continue
            }
            
            let name = components[0].trimmingCharacters(in: .whitespaces)
            let urlString = components[1].trimmingCharacters(in: .whitespaces)
            
            do {
                try await createQRCode(
                    name: name,
                    type: .url,
                    content: .url(urlString),
                    style: QRStyle(),
                    isDynamic: false
                )
                successCount += 1
            } catch {
                errors.append("Line \(index + 1): \(error.localizedDescription)")
            }
        }
        
        Analytics.logEvent("bulk_import_completed", parameters: [
            "success_count": successCount,
            "error_count": errors.count
        ])
        
        if !errors.isEmpty {
            throw QRError.bulkImportPartialFailure(errors: errors)
        }
    }
}
