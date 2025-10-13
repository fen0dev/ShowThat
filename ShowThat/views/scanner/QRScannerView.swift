//
//  QRScannerView.swift
//  ShowThat
//
//  Created by Giuseppe De Masi on 09/08/2025.
//

import SwiftUI
import UIKit
import AVFoundation

// MARK: - UIKit controller che gestisce permessi + sessione
final class ScannerViewController: UIViewController {
    let session = AVCaptureSession()
    private let metadataOutput = AVCaptureMetadataOutput()
    private var previewLayer: AVCaptureVideoPreviewLayer?
    
    // UI per stato "permesso negato"
    private let permissionLabel = UILabel()
    private let settingsButton = UIButton(type: .system)
    
    weak var metadataDelegate: AVCaptureMetadataOutputObjectsDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        setupDeniedUI()
        configureIfAuthorized()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        previewLayer?.frame = view.bounds
    }
    
    deinit {
        stopSession()
    }
    
    // MARK: - Permissions
    func configureIfAuthorized() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            configureSession()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                DispatchQueue.main.async {
                    guard let self else { return }
                    if granted { self.configureSession() }
                    else { self.showDeniedUI() }
                }
            }
        case .denied, .restricted:
            showDeniedUI()
        @unknown default:
            showDeniedUI()
        }
    }
    
    // MARK: - Session
    private func configureSession() {
        permissionLabel.isHidden = true
        settingsButton.isHidden = true
        
        session.beginConfiguration()
        session.sessionPreset = .high
        
        guard let device = AVCaptureDevice.default(for: .video),
              let input = try? AVCaptureDeviceInput(device: device),
              session.canAddInput(input) else {
            showDeniedUI()
            session.commitConfiguration()
            return
        }
        session.addInput(input)
        
        if session.canAddOutput(metadataOutput) {
            session.addOutput(metadataOutput)
            metadataOutput.setMetadataObjectsDelegate(metadataDelegate, queue: .main)
            if metadataOutput.availableMetadataObjectTypes.contains(.qr) {
                metadataOutput.metadataObjectTypes = [.qr]
            } else {
                metadataOutput.metadataObjectTypes = metadataOutput.availableMetadataObjectTypes
            }
        }
        
        session.commitConfiguration()
        
        let layer = AVCaptureVideoPreviewLayer(session: session)
        layer.videoGravity = .resizeAspectFill
        layer.frame = view.bounds
        view.layer.insertSublayer(layer, at: 0)
        previewLayer = layer
        
        startSession()
    }
    
    func startSession() {
        guard !session.isRunning else { return }
        DispatchQueue.global(qos: .userInitiated).async {
            self.session.startRunning()
        }
    }
    
    func stopSession() {
        guard session.isRunning else { return }
        DispatchQueue.global(qos: .userInitiated).async {
            self.session.stopRunning()
        }
    }
    
    // MARK: - Denied UI
    private func setupDeniedUI() {
        permissionLabel.text = "Allow Access to Camer in Settings to Scan QR Codes."
        permissionLabel.textColor = .white
        permissionLabel.numberOfLines = 0
        permissionLabel.textAlignment = .center
        permissionLabel.translatesAutoresizingMaskIntoConstraints = false
        
        settingsButton.setTitle("Open Settings", for: .normal)
        settingsButton.translatesAutoresizingMaskIntoConstraints = false
        settingsButton.addTarget(self, action: #selector(openSettings), for: .touchUpInside)
        
        view.addSubview(permissionLabel)
        view.addSubview(settingsButton)
        
        NSLayoutConstraint.activate([
            permissionLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            permissionLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -20),
            permissionLabel.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: 24),
            permissionLabel.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -24),
            settingsButton.topAnchor.constraint(equalTo: permissionLabel.bottomAnchor, constant: 12),
            settingsButton.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        ])
        
        permissionLabel.isHidden = true
        settingsButton.isHidden = true
    }
    
    private func showDeniedUI() {
        permissionLabel.isHidden = false
        settingsButton.isHidden = false
    }
    
    @objc private func openSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString),
              UIApplication.shared.canOpenURL(url) else { return }
        UIApplication.shared.open(url)
    }
}

// MARK: - SwiftUI bridge
struct QRScannerViewRepresentable: UIViewControllerRepresentable {
    final class Coordinator: NSObject, AVCaptureMetadataOutputObjectsDelegate {
        let parent: QRScannerViewRepresentable
        private var didEmitResult = false
        
        init(parent: QRScannerViewRepresentable) {
            self.parent = parent
        }
        
        func metadataOutput(
            _ output: AVCaptureMetadataOutput,
            didOutput metadataObjects: [AVMetadataObject],
            from connection: AVCaptureConnection
        ) {
            guard !didEmitResult,
                  let obj = metadataObjects.first as? AVMetadataMachineReadableCodeObject,
                  obj.type == .qr,
                  let value = obj.stringValue else { return }
            didEmitResult = true
            parent.onResult(value)
        }
    }
    
    var onResult: (String) -> Void
    
    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }
    
    func makeUIViewController(context: Context) -> ScannerViewController {
        let controller = ScannerViewController()
        controller.metadataDelegate = context.coordinator
        return controller
    }
    
    func updateUIViewController(_ uiViewController: ScannerViewController, context: Context) { }
    
    static func dismantleUIViewController(_ uiViewController: ScannerViewController, coordinator: Coordinator) {
        uiViewController.stopSession()
    }
}

// MARK: - Screen
@available(iOS 17.0, *)
struct QRScanScreen: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var qrManager: QRCodeManager
    @State private var scannedQRCode: QRCodeModel?
    @State private var showResult = false
    
    var body: some View {
        ZStack {
            QRScannerViewRepresentable { result in
                handleScanResult(result)
            }
    
            VStack {
                HStack {
                    Button{
                        dismiss()
                    } label: {
                        Text("Close")
                            .foregroundStyle(.black)
                            .bold()
                            .padding(10)
                            .background(.ultraThinMaterial, in: Capsule())
                    }
                    .padding(.top, 20)
                    
                    Spacer()
                }
                .padding()
                
                Spacer()
            }
        }
        .ignoresSafeArea()
        .sheet(isPresented: $showResult) {
            if let qr = scannedQRCode {
                QRCodeDetailView(qrCode: qr, qrManager: qrManager)
            }
        }
    }
    
    private func handleScanResult(_ result: String) {
        AlertManager.shared.showSuccessToast("QR Code scanned!")
        Task {
            if let qr = await qrManager.fetchQRCodeByScannedValue(result) {
                // analytics and counting only if it's QR from current user
                if qr.userId == qrManager.currentUserId,
                   let id = qr.id {
                    await AnalyticsManager.shared.recordScanAutomatically(qrCodeId: id, referrer: "scanner")
                    try? await qrManager.incrementScanCount(for: id, referrer: "scanner")
                }
                
                await MainActor.run {
                    self.scannedQRCode = qr
                    self.showResult = true
                }
            } else {
                AlertManager.shared.showError(message: "QR Code not recognized!")
            }
        }
    }
}

#Preview {
    if #available(iOS 17.0, *) {
        QRScanScreen()
    } else {
        // Fallback on earlier versions
    }
}
