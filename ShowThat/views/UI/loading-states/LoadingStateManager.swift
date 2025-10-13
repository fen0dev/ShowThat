//
//  LoadingStateManager.swift
//  ShowThat
//
//  Created by Giuseppe De Masi on 30/09/2025.
//

import SwiftUI
import Combine

/// Gestisce stati di caricamento globali dell'app
@MainActor
final class LoadingStateManager: ObservableObject {
    static let shared = LoadingStateManager()
    
    // MARK: - Published Properties
    @Published var isLoading = false
    @Published var loadingMessage = ""
    @Published var progress: Double = 0.0
    @Published var currentOperation: LoadingOperation?
    
    // MARK: - Private Properties
    private var loadingOperations: [String: LoadingOperation] = [:]
    private var cancellables = Set<AnyCancellable>()
    
    private init() {}
    
    // MARK: - Public Methods
    
    func startLoading(
        operation: LoadingOperation,
        message: String = ""
    ) {
        loadingOperations[operation.id] = operation
        currentOperation = operation
        isLoading = true
        loadingMessage = message.isEmpty ? operation.defaultMessage : message
        progress = 0.0
        
        Logger.shared.logInfo("Started loading: \(operation.type.rawValue)")
    }
    
    func updateProgress(_ progress: Double, for operationId: String? = nil) {
        let id = operationId ?? currentOperation?.id
        guard let id = id, loadingOperations[id] != nil else { return }
        
        self.progress = max(0.0, min(1.0, progress))
        
        if let operation = currentOperation, operation.id == id {
            operation.updateProgress(progress)
        }
    }
    
    func finishLoading(operationId: String? = nil, success: Bool = true) {
        let id = operationId ?? currentOperation?.id
        guard let id = id else { return }
        
        loadingOperations.removeValue(forKey: id)
        
        if currentOperation?.id == id {
            currentOperation = nil
            isLoading = false
            loadingMessage = ""
            progress = 0.0
        }
        
        Logger.shared.logInfo("Finished loading: \(id) - Success: \(success)")
    }
    
    func cancelLoading(operationId: String? = nil) {
        let id = operationId ?? currentOperation?.id
        guard let id = id else { return }
        
        loadingOperations.removeValue(forKey: id)
        
        if currentOperation?.id == id {
            currentOperation = nil
            isLoading = false
            loadingMessage = ""
            progress = 0.0
        }
        
        Logger.shared.logInfo("Cancelled loading: \(id)")
    }
    
    func setLoadingMessage(_ message: String) {
        loadingMessage = message
    }
}

// MARK: - Loading Operation

class LoadingOperation: ObservableObject {
    let id: String
    let type: LoadingType
    let startTime: Date
    @Published var progress: Double = 0.0
    @Published var message: String
    
    var defaultMessage: String {
        switch type {
        case .qrGeneration:
            return "Generando QR code..."
        case .qrScanning:
            return "Scansionando QR code..."
        case .authentication:
            return "Autenticazione in corso..."
        case .subscription:
            return "Elaborazione pagamento..."
        case .dataSync:
            return "Sincronizzazione dati..."
        case .imageDownload:
            return "Download immagine..."
        case .analytics:
            return "Caricamento analytics..."
        case .bulkOperation:
            return "Operazione in corso..."
        }
    }
    
    init(type: LoadingType, customMessage: String? = nil) {
        self.id = UUID().uuidString
        self.type = type
        self.startTime = Date()
        self.message = customMessage ?? type.defaultMessage
    }
    
    func updateProgress(_ progress: Double) {
        self.progress = max(0.0, min(1.0, progress))
    }
    
    var duration: TimeInterval {
        Date().timeIntervalSince(startTime)
    }
}

enum LoadingType: String, CaseIterable {
    case qrGeneration = "qr_generation"
    case qrScanning = "qr_scanning"
    case authentication = "authentication"
    case subscription = "subscription"
    case dataSync = "data_sync"
    case imageDownload = "image_download"
    case analytics = "analytics"
    case bulkOperation = "bulk_operation"
    
    var defaultMessage: String {
        switch self {
        case .qrGeneration:
            return "Generando QR code..."
        case .qrScanning:
            return "Scansionando QR code..."
        case .authentication:
            return "Autenticazione in corso..."
        case .subscription:
            return "Elaborazione pagamento..."
        case .dataSync:
            return "Sincronizzazione dati..."
        case .imageDownload:
            return "Download immagine..."
        case .analytics:
            return "Caricamento analytics..."
        case .bulkOperation:
            return "Operazione in corso..."
        }
    }
}
