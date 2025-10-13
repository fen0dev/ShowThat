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
    @Published private(set) var qrCodes: [QRCodeModel] = []
    @Published var userProfile: UserProfile?
    @Published var currentTeam: Team?
    @Published private(set) var isLoading = false
    @Published private(set) var error: Error?
    @Published private(set) var lastScannedQRCode: QRCodeModel?
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
    
    var currentSubscriptionTier: UserSubscription.Tier {
        // store kit is source of truth
        if let storeKitTier = PaymentManager.shared.currentSubscription {
            return storeKitTier
        }
        
        // fallback
        return userProfile?.subscription.tier ?? .free
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
                    
                    // Set up subscription sync after auth
                    self.setupSubscriptionSync()
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
    
    // synching StoreKit subscription status to firestore
    @MainActor
    func syncSubscriptionStatus() async {
        guard let userId = currentUserId else { return }
        
        // get current StoreKit status
        let storeKitTier = PaymentManager.shared.currentSubscription ?? .free
        let hasActiveSubscription = PaymentManager.shared.hasActiveSubscription
        
        do {
            let data: [String: Any] = [
                "subscription.tier": storeKitTier.rawValue,
                "subscription.isActive": hasActiveSubscription,
                "updatedAt": FieldValue.serverTimestamp()
            ]
            
            _ = db.collection("users").document(userId).updateData(data)
            print("[QRCodeManager] Synced subscription status: \(storeKitTier.rawValue)")
        }
    }
    
    // Set up subscription sync listeners
    func setupSubscriptionSync() {
        // Listen for StoreKit subscription changes
        NotificationCenter.default.publisher(for: .subscriptionStatusChanged)
            .sink { [weak self] _ in
                Task {
                    await self?.syncSubscriptionStatus()
                }
            }
            .store(in: &cancellables)
        
        // Listen for app becoming active to refresh status
        NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)
            .sink { [weak self] _ in
                Task {
                    await PaymentManager.shared.refreshSubscriptionStatus()
                    await self?.syncSubscriptionStatus()
                }
            }
            .store(in: &cancellables)
        
        // Initial sync
        Task {
            await syncSubscriptionStatus()
        }
    }
    
    // MARK: - Public Methods
    
    func addQRCode(_ qrCode: QRCodeModel) async throws {
        do {
            let docRef = db.collection("qrCodes").addDocument(from: qrCode)
            var updatedQRCode = qrCode
            updatedQRCode.id = try await docRef.value.documentID
            
            Logger.shared.logInfo("QR Code added successfully: \(qrCode.name)")
        } catch {
            Logger.shared.logError("Failed to add QR Code: \(error)")
            throw error
        }
    }
    
    func incrementScanCount(for qrCodeId: String, referrer: String? = nil) async throws {
        guard let index = qrCodes.firstIndex(where: { $0.id == qrCodeId }) else {
            Logger.shared.logError("QR Code not found for scan increment: \(qrCodeId)")
            return
        }
        
        let updatedQRCode = qrCodes[index]
        
        do {
            let updated: [String: Any] = [
                "scanCount": FieldValue.increment(Int64(1)),
                "lastScanned": FieldValue.serverTimestamp()
            ]
            // Aggiorna il conteggio scans nel database
            _ = db.collection("qrCodes").document(qrCodeId).updateData(updated)
            
            // Registra l'evento analytics
            await AnalyticsManager.shared.recordScanAutomatically(qrCodeId: qrCodeId, referrer: referrer)
            
            // Aggiorna localmente
            qrCodes[index].scanCount += 1
            qrCodes[index].lastScanned = Date()
            lastScannedQRCode = qrCodes[index]
            
            Logger.shared.logInfo("Scan count incremented for QR Code: \(updatedQRCode.name)")
        }
    }
    
    /// Scansiona un QR Code e registra automaticamente l'evento
    func scanQRCode(_ content: String, referrer: String? = nil) async throws {
        // Trova il QR Code corrispondente al contenuto
        guard let qrCode = qrCodes.first(where: { $0.content.rawValue == content }) else {
            throw NSError(domain: "QRCodeManager", code: 1, userInfo: [NSLocalizedDescriptionKey: "QR Code not found"])
        }
        
        try await incrementScanCount(for: qrCode.id ?? "", referrer: referrer)
    }
    
    // MARK: - QR Code CRUD Operations
    
    func createQRCode(name: String, type: QRCodeType, content: QRContent, style: QRStyle, isDynamic: Bool = false, logoImage: UIImage? = nil) async throws {
        let measurer = PerformanceMeasurer("Create QR Code")
        defer { measurer.finish() }
        
        guard let userId = currentUserId else { throw QRError.notAuthenticated }
        
        // Check subscription limits
        guard canCreateQRCode(isDynamic: isDynamic) else {
            throw QRError.subscriptionLimitReached
        }
        
        // Validate input
        try ValidationManager.shared.validateQRCode(name: name, type: type, content: content)
        
        // Start loading state
        let operation = LoadingOperation(type: .qrGeneration)
        LoadingStateManager.shared.startLoading(operation: operation, message: "Creando QR code...")
        
        var opSuccess = false
        defer {
            LoadingStateManager.shared.finishLoading(operationId: operation.id, success: opSuccess)
        }
        
        do {
            // Upload logo first (if provided)
            var qrStyle = style
            if let logoImage = logoImage {
                do {
                    LoadingStateManager.shared.setLoadingMessage("Caricamento logo...")
                    let logoURL = try await uploadLogo(logoImage, userId: userId)
                    qrStyle.logoURL = logoURL
                } catch {
                    Logger.shared.logWarning("Logo upload failed, continuing without logo: \(error)")
                }
            }
            
            // Generate QR code asynchronously
            LoadingStateManager.shared.updateProgress(0.2, for: operation.id)
            Logger.shared.logInfo("Starting QR code generation for content type: \(type.rawValue), length: \(content.rawValue.count)")
            
            _ = try await AsyncQRGenerator.shared.generateQR(
                from: content.rawValue,
                style: qrStyle
            )
            
            Logger.shared.logInfo("QR code generation completed successfully")
            LoadingStateManager.shared.updateProgress(0.5, for: operation.id)
            
            // Create QR code model
            let newQR = QRCodeModel(
                userId: userId,
                name: name,
                type: type,
                content: content,
                style: qrStyle,
                isDynamic: isDynamic
            )
            
            LoadingStateManager.shared.updateProgress(0.7, for: operation.id)
            LoadingStateManager.shared.setLoadingMessage("Salvataggio...")
            
            // Save to Firestore with retry
            let savedId = try await NetworkRetryManager.shared.executeWithRetry(
                operation: {
                    let docRef = self.db.collection("qrCodes").document()
                    _ = docRef.setData(from: newQR)
                    return docRef.documentID
                },
                context: "Save QR Code"
            )
            
            LoadingStateManager.shared.updateProgress(0.9, for: operation.id)
            
            do {
                // Update user counters
                try await updateUserCounters(userId: userId, isDynamic: isDynamic, increment: 1)
                Logger.shared.logInfo("User counters updated successfully")
            } catch {
                Logger.shared.logWarning("Failed to update user counters: \(error)")
            }
            
            // Create dynamic route if needed
            if isDynamic, let shortCode = newQR.shortCode {
                do {
                    try await createDynamicRouteAsync(
                        shortCode: shortCode,
                        qrCodeId: savedId,
                        destination: content.rawValue
                    )
                    Logger.shared.logInfo("Dynamic route created successfully for shortCode: \(shortCode)")
                } catch {
                    Logger.shared.logWarning("Failed to create dynamic route: \(error.localizedDescription)")
                }
            }
            
            LoadingStateManager.shared.updateProgress(1.0, for: operation.id)
            opSuccess = true
            
            // Analytics
            Analytics.logEvent("qr_code_created", parameters: [
                "type": type.rawValue,
                "is_dynamic": isDynamic,
                "style": style.design.rawValue
            ])
            
            // Haptic feedback
            HapticManager.shared.qrCodeGenerated()
            
        } catch {
            HapticManager.shared.errorOccurred()
            throw error
        }
    }
    
    // MARK: - Async User Counters Update
    
    private func updateUserCounters(userId: String, isDynamic: Bool, increment: Int) async throws {
        try await NetworkRetryManager.shared.executeWithRetry(
            operation: {
                let fieldUpdate = isDynamic ? "dynamicQRsCreated" : "qrCodesCreated"
                let updateData: [String: Any] = [
                    fieldUpdate: FieldValue.increment(Int64(increment)),
                    "updatedAt": FieldValue.serverTimestamp()
                ]
                
                _ = try await self.db.collection("users").document(userId).updateData(updateData)
            },
            context: "Update User Counters"
        )
    }
    
    // MARK: - Async Dynamic Route Creation
    
    private func createDynamicRouteAsync(shortCode: String, qrCodeId: String, destination: String) async throws {
        try await NetworkRetryManager.shared.executeWithRetry(
            operation: {
                let route = [
                    "qrCodeId": qrCodeId,
                    "destination": destination,
                    "createdAt": FieldValue.serverTimestamp()
                ] as [String : Any]
                
                try await self.db.collection("routes").document(shortCode).setData(route)
            },
            context: "Create Dynamic Route"
        )
    }
    
    func updateQRCode(_ qrCode: QRCodeModel) async throws {
        guard let qrId = qrCode.id else { throw QRError.invalidQRCode }
        
        isLoading = true
        defer { isLoading = false }
        
        var updated = qrCode
        updated.updatedAt = Date()
        
        do {
            _ = db.collection("qrCodes").document(qrId).setData(from: qrCode, merge: true)
            Logger.shared.logInfo("QR Code updated successfully: \(qrCode.name)")
        }
        
        // If dynamic and content changed, update route
        if qrCode.isDynamic, let shortCode = qrCode.shortCode {
            try await updateDynamicRoute(shortCode: shortCode, destination: qrCode.content.rawValue)
        }
        
        Analytics.logEvent("qr_code_updated", parameters: ["qr_id": qrId])
    }
    
    // Get remaining QR codes user can create
    func remainingQRCodes(isDynamic: Bool) -> Int {
        let tier = currentSubscriptionTier
        
        if isDynamic {
            let dynamicCount = qrCodes.filter { $0.isDynamic }.count
            return max(0, tier.dynamicQRLimit - dynamicCount)
        } else {
            let staticCount = qrCodes.filter { !$0.isDynamic }.count
            return max(0, tier.qrLimit - staticCount)
        }
    }
    
    // MARK: - Batch Operations
    
    func bulkCreateQRCodesAsync(from csvData: String) async throws -> BulkImportResult {
        let measurer = PerformanceMeasurer("Bulk Import")
        defer { measurer.finish() }
        
        let lines = csvData.components(separatedBy: .newlines)
        var successCount = 0
        var errors: [String] = []
        
        let operation = LoadingOperation(type: .bulkOperation, customMessage: "Importazione in corso...")
        LoadingStateManager.shared.startLoading(operation: operation)
        
        defer {
            LoadingStateManager.shared.finishLoading(operationId: operation.id)
        }
        
        for (index, line) in lines.enumerated() where !line.isEmpty {
            let progress = Double(index) / Double(lines.count)
            LoadingStateManager.shared.updateProgress(progress, for: operation.id)
            
            let components = line.components(separatedBy: ",")
            guard components.count >= 2 else {
                errors.append("Linea \(index + 1): Formato non valido")
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
                errors.append("Linea \(index + 1): \(error.localizedDescription)")
            }
        }
        
        LoadingStateManager.shared.updateProgress(1.0, for: operation.id)
        
        let result = BulkImportResult(
            totalLines: lines.count,
            successCount: successCount,
            errorCount: errors.count,
            errors: errors
        )
        
        Analytics.logEvent("bulk_import_completed", parameters: [
            "total_lines": lines.count,
            "success_count": successCount,
            "error_count": errors.count
        ])
        
        if !errors.isEmpty {
            throw QRError.bulkImportPartialFailure(errors: errors)
        }
        
        return result
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
        let tier = currentSubscriptionTier
        
        if isDynamic {
            let dynamicCount = qrCodes.filter { $0.isDynamic }.count
            return dynamicCount < tier.dynamicQRLimit
        } else {
            let staticCount = qrCodes.filter { !$0.isDynamic }.count
            return staticCount < tier.qrLimit
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
        return try await NetworkRetryManager.shared.executeWithRetry(
            operation: {
                guard let imageData = image.jpegData(compressionQuality: 0.8) else {
                    throw QRError.imageProcessingFailed
                }
                
                let filename = "\(userId)/logos/\(UUID().uuidString).jpg"
                let storageRef = self.storage.reference().child(filename)
                
                _ = try await storageRef.putDataAsync(imageData)
                let downloadURL = try await storageRef.downloadURL()
                
                return downloadURL.absoluteString
            },
            context: "Upload Logo"
        )
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
    
    // MARK: - Scan helpers

    func fetchUserProfile(userId: String) async -> UserProfile? {
        do {
            let doc = try await db.collection("users").document(userId).getDocument()
            return try doc.data(as: UserProfile.self)
        } catch {
            Logger.shared.logWarning("Failed to fetch user profile: \(error)")
            return nil
        }
    }

    func fetchQRCodeByShortCode(_ shortCode: String) async -> QRCodeModel? {
        do {
            // Prova prima direttamente sulla collezione qrCodes
            let snap = try await db.collection("qrCodes")
                .whereField("shortCode", isEqualTo: shortCode)
                .limit(to: 1)
                .getDocuments()
            if let doc = snap.documents.first {
                return try doc.data(as: QRCodeModel.self)
            }
            // Fallback: risali dalla routes (shortCode -> qrCodeId)
            let routeDoc = try await db.collection("routes").document(shortCode).getDocument()
            if let qrCodeId = routeDoc.data()?["qrCodeId"] as? String {
                let qrDoc = try await db.collection("qrCodes").document(qrCodeId).getDocument()
                if qrDoc.exists {
                    return try qrDoc.data(as: QRCodeModel.self)
                }
            }
        } catch {
            Logger.shared.logWarning("Failed to fetch QR by shortCode: \(error)")
        }
        return nil
    }

    func extractShortCode(from value: String) -> String? {
        // URL tipo .../qr/<short>
        if let range = value.range(of: "/qr/") {
            let codePart = value[range.upperBound...]
            let trimmed = codePart.split(whereSeparator: { "/?#".contains($0) }).first
            if let s = trimmed, !s.isEmpty { return String(s) }
        }
        // Se è solo il codice (6-12 alfanumerici)
        if value.range(of: "^[A-Za-z0-9]{6,12}$", options: .regularExpression) != nil {
            return value
        }
        return nil
    }

    func fetchQRCodeByScannedValue(_ value: String) async -> QRCodeModel? {
        if let short = extractShortCode(from: value) {
            if let local = qrCodes.first(where: { $0.shortCode == short }) { return local }
            if let remote = await fetchQRCodeByShortCode(short) { return remote }
        }
        // Fallback: match locale sul contenuto esatto
        if let local = qrCodes.first(where: { $0.content.rawValue == value }) {
            return local
        }
        return nil
    }
}

// MARK: - Supporting Types

struct BulkImportResult {
    let totalLines: Int
    let successCount: Int
    let errorCount: Int
    let errors: [String]
    
    var successRate: Double {
        guard totalLines > 0 else { return 0 }
        return Double(successCount) / Double(totalLines)
    }
}
