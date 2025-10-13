//
//  QRCodeCard.swift
//  ShowThat
//
//  Created by Giuseppe De Masi on 25/06/2025.
//

import SwiftUI

@available(iOS 17.0, *)
struct QRCodeCard: View {
    let qrCode: QRCodeModel
    let qrManager: QRCodeManager
    
    @State private var showingDetailSheet = false
    @State private var showingShareSheet = false
    @State private var photoSaver: PhotoSaver?
    @State private var qrImage: UIImage?
    @State private var isExpanded = false
    
    private let generator = QRCodeGenerator()
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            headerView
            
            statsRow
            
            quickActions
            
            // expandable QR Preview
            if isExpanded {
                Divider()
                    .padding(.horizontal)
                
                if let qrImage = qrImage {
                    Image(uiImage: qrImage)
                        .interpolation(.none)
                        .resizable()
                        .scaledToFit()
                        .frame(height: 200)
                        .padding()
                        .background(Color.white)
                        .cornerRadius(10)
                        .padding()
                        .transition(.asymmetric(
                            insertion: .scale.combined(with: .opacity),
                            removal: .scale.combined(with: .opacity)
                        ))
                }
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.05), radius: 10, y: 5)
        )
        .onAppear {
            Task { await generateQRImage() }
        }
        .sheet(isPresented: $showingDetailSheet) {
            QRCodeDetailView(qrCode: qrCode, qrManager: qrManager)
        }
        .sheet(isPresented: $showingShareSheet) {
            if let qrImage = qrImage {
                ShareSheet(items: [qrImage])
            }
        }
    }
    
    private var headerView: some View {
        HStack {
            // QR Type Icon
            Image(systemName: qrCode.type.icon)
                .font(.title2)
                .foregroundStyle(
                    LinearGradient(
                        colors: [.purple, .blue],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 40, height: 40)
                .background(
                    Circle()
                        .fill(Color.purple.opacity(0.1))
                )
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(qrCode.name)
                        .font(.headline)
                        .lineLimit(1)
                    
                    if qrCode.isDynamic {
                        Label("Dynamic", systemImage: "arrow.triangle.2.circlepath.circle.fill")
                            .font(.caption2)
                            .foregroundColor(.green)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(
                                Capsule()
                                    .fill(Color.green.opacity(0.1))
                            )
                    }
                }
                
                Text(qrCode.content.displayText)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            
            Spacer()
            
            // Menu Button
            Menu {
                Button(action: { showingDetailSheet = true }) {
                    Label("View Details", systemImage: "eye")
                }
                
                Button(action: { showingShareSheet = true }) {
                    Label("Share", systemImage: "square.and.arrow.up")
                }
                
                Button(action: { duplicateQRCode() }) {
                    Label("Duplicate", systemImage: "doc.on.doc")
                }
                
                Divider()
                
                Button(role: .destructive, action: { deleteQRCode() }) {
                    Label("Delete", systemImage: "trash")
                }
            } label: {
                Image(systemName: "ellipsis")
                    .font(.title3)
                    .foregroundColor(.secondary)
                    .frame(width: 30, height: 30)
            }
        }
        .padding()
    }
    
    private var quickActions: some View {
        HStack(spacing: 12) {
            QuickActionButton(
                icon: "qrcode.viewfinder",
                title: "Preview",
                color: .blue
            ) {
                withAnimation(.spring()) {
                    isExpanded.toggle()
                }
            }
            
            QuickActionButton(
                icon: "chart.line.uptrend.xyaxis",
                title: "Analytics",
                color: .green
            ) {
                showingDetailSheet = true
            }
            
            QuickActionButton(
                icon: "square.and.arrow.down",
                title: "Download",
                color: .purple
            ) {
                downloadQRCode()
            }
        }
        .padding(.horizontal)
        .padding(.bottom, 15)
    }
    
    private var statsRow: some View {
        HStack(spacing: 30) {
            StatItem(
                icon: "eye.fill",
                value: "\(qrCode.scanCount)",
                label: "Scans"
            )
            
            StatItem(
                icon: "calendar",
                value: formatDate(qrCode.createdAt ?? Date()),
                label: "Created"
            )
            
            if qrCode.isDynamic {
                StatItem(
                    icon: "link",
                    value: String(qrCode.shortCode?.suffix(4) ?? "N/A"),
                    label: "Short Code"
                )
            }
        }
        .padding(.horizontal)
        .padding(.bottom, 15)
    }
    
    // MARK: - Helper Methods
    
    @MainActor
    private func generateQRImage() async {
        // Generate based on style
        switch qrCode.style.design {
        case .minimal:
            qrImage = generator.generateBasicQR(from: qrCode.content.rawValue)
        case .branded:
            var logoImage: UIImage? = nil
            if let urlString = qrCode.style.logoURL, let url = URL(string: urlString) {
                let nsurl = url as NSURL
                if let cached = await ImageCache.shared.image(for: nsurl as URL) {
                    logoImage = cached
                } else {
                    do {
                        let (data, _) = try await URLSession.shared.data(from: url)
                        if let img = UIImage(data: data) {
                            ImageCache.shared.store(img, for: nsurl as URL)
                            logoImage = img
                        }
                    } catch {
                        logoImage = nil
                    }
                }
            }
            qrImage = generator.generateCustomQR(
                from: qrCode.content.rawValue,
                foreground: UIColor(qrCode.style.foregroundColor.color),
                background: UIColor(qrCode.style.backgroundColor.color),
                logo: logoImage
            )
        case .gradient:
            qrImage = generator.generateGradientQR(from: qrCode.content.rawValue)
        case .glass:
            qrImage = generator.generateGlassQR(from: qrCode.content.rawValue)
        default:
            qrImage = generator.generateBasicQR(from: qrCode.content.rawValue)
        }
    }
    
    private func duplicateQRCode() {
        Task {
            do {
                // Create a copy of the QR code with a new name
                try await qrManager.createQRCode(
                    name: "\(qrCode.name) (Copy)",
                    type: qrCode.type,
                    content: qrCode.content,
                    style: qrCode.style,
                    isDynamic: false // Always create static copy to avoid limits
                )
                
                AlertManager.shared.showSuccessToast("QR Code duplicated successfully!")
                
            } catch QRError.subscriptionLimitReached {
                AlertManager.shared.showError(
                    title: "Limit Reached",
                    message: "You've reached your plan's QR code limit. Upgrade to create more QR codes."
                )
            } catch {
                AlertManager.shared.showErrorToast("Failed to duplicate QR code")
            }
        }
    }
    
    private func deleteQRCode() {
        AlertManager.shared.showCustom(config: AlertConfig(
            type: .error,
            title: "Delete QR Code?",
            message: "Are you sure you want to delete '\(qrCode.name)'? This action cannot be undone.",
            icon: "trash.fill",
            primaryAction: AlertAction(
                title: "Delete",
                style: .destructive
            ) {
                Task {
                    do {
                        try await qrManager.deleteQRCode(qrCode)
                        AlertManager.shared.showSuccessToast("QR Code deleted")
                    } catch {
                        AlertManager.shared.showErrorToast("Failed to delete QR code")
                    }
                }
            },
            secondaryAction: AlertAction(title: "Cancel")
        ))
    }
    
    private func downloadQRCode() {
        guard let qrImage = qrImage else { return }
        let saver = PhotoSaver { error in
            if let error = error {
                AlertManager.shared.showErrorToast("Failed to save: \(error.localizedDescription)")
            } else {
                AlertManager.shared.showSuccess(
                    title: "Saved!",
                    message: "QR code has been saved to your photo library",
                    icon: "square.and.arrow.down.fill"
                )
            }
        }
        self.photoSaver = saver
        UIImageWriteToSavedPhotosAlbum(qrImage, saver, #selector(PhotoSaver.didFinishSaving(_:didFinishSavingWithError:contextInfo:)), nil)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
}

final class PhotoSaver: NSObject {
    private let completion: (Error?) -> Void
    init(completion: @escaping (Error?) -> Void) {
        self.completion = completion
    }
    @objc func didFinishSaving(_ image: UIImage, didFinishSavingWithError error: Error?, contextInfo: UnsafeMutableRawPointer?) {
        completion(error)
    }
}

#Preview {
    if #available(iOS 17.0, *) {
        QRCodeCard(qrCode: QRCodeModel(userId: UUID().uuidString, name: "Giuseppe", type: .vCard, content: .vCard(VCardData(fullName: "TechnoForged Digital")), style: QRStyle()), qrManager: QRCodeManager())
    } else {
        // Fallback on earlier versions
    }
}
