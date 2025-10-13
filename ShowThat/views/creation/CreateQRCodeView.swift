//
//  CreateQRCodeView.swift
//  ShowThat
//
//  Created by Giuseppe De Masi on 25/06/2025.
//

import SwiftUI
import PhotosUI

@available(iOS 16.0, *)
struct CreateQRCodeView: View {
    let qrManager: QRCodeManager
    
    @Environment(\.dismiss) var dismiss
    
    @State private var selectedType: QRCodeType = .url
    @State private var qrName = ""
    @State private var isDynamic = false
    @State private var selectedStyle = QRStyle()
    
    // Content fields
    @State private var urlString = ""
    @State private var vCardData = VCardData(fullName: "")
    @State private var wifiData = WiFiData(ssid: "", password: "")
    @State private var emailData = EmailData(email: "")
    @State private var textContent = ""
    
    // UI State
    @State private var showingImagePicker = false
    @State private var logoImage: UIImage?
    @State private var showingPreview = false
    @State private var previewQRImage: UIImage?
    @State private var isLoading = false
    
    private let generator = QRCodeGenerator()
    
    var canCreate: Bool {
        !qrName.isEmpty && isContentValid
    }
    
    var isContentValid: Bool {
        switch selectedType {
        case .url:
            if let u = URL(string: urlString), let _ = u.scheme, let _ = u.host { return true }
            return false
        case .vCard:
            return !vCardData.fullName.isEmpty
        case .wifi:
            return !wifiData.ssid.isEmpty
        case .email:
            return !emailData.email.isEmpty
        case .sms, .whatsapp, .linkedIn:
            return !textContent.isEmpty
        }
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 25) {
                    // Type Selector
                    TypeSelectorSection(selectedType: $selectedType)
                    
                    // Name Input
                    VStack(alignment: .leading, spacing: 10) {
                        Label("QR Code Name", systemImage: "textformat")
                            .font(.headline)
                        
                        TextField("e.g., Business Card, WiFi Guest", text: $qrName)
                            .textFieldStyle(ModernTextFieldStyle())
                    }
                    .padding(.horizontal)
                    
                    // Dynamic QR Toggle (Pro feature)
                    if qrManager.currentSubscription?.tier != .free {
                        DynamicQRToggle(
                            isDynamic: $isDynamic,
                            canCreate: qrManager.canCreateQRCode(isDynamic: true)
                        )
                        .padding(.horizontal)
                    }
                    
                    // Content Input Section
                    Group {
                        switch selectedType {
                        case .url:
                            URLInputSection(urlString: $urlString)
                        case .vCard:
                            vCardInputSection(vCardData: $vCardData)
                        case .wifi:
                            WiFiInputSection(wifiData: $wifiData)
                        case .email:
                            EmailInputSection(emailData: $emailData)
                        case .sms, .whatsapp:
                            PhoneInputSection(
                                type: selectedType,
                                content: $textContent
                            )
                        case .linkedIn:
                            LinkedInInputSection(content: $textContent)
                        }
                    }
                    .padding(.horizontal)
                    
                    // Style Section
                    StyleCustomizationSection(
                        style: $selectedStyle,
                        logoImage: $logoImage,
                        showingImagePicker: $showingImagePicker
                    )
                    .padding(.horizontal)
                    
                    // Preview Button
                    Button(action: generatePreview) {
                        Label("Preview QR Code", systemImage: "eye")
                            .font(.headline)
                            .foregroundColor(.blue)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 15)
                                    .stroke(Color.blue, lineWidth: 2)
                            )
                    }
                    .padding(.horizontal)
                    .disabled(!isContentValid)
                    
                    // Create Button
                    Button(action: createQRCode) {
                        HStack {
                            if isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(0.8)
                            } else {
                                Image(systemName: "checkmark.circle.fill")
                                Text("Create QR Code")
                                    .fontWeight(.semibold)
                            }
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            LinearGradient(
                                colors: canCreate ? [.purple, .blue] : [.gray],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(15)
                        .shadow(color: canCreate ? .purple.opacity(0.3) : .clear, radius: 10, y: 5)
                    }
                    .padding(.horizontal)
                    .disabled(!canCreate || isLoading)
                    
                    Spacer(minLength: 30)
                }
                .padding(.vertical)
            }
            .navigationTitle("Create QR Code")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingImagePicker) {
                ImagePicker(image: $logoImage)
            }
            .sheet(isPresented: $showingPreview) {
                if let previewQRImage = previewQRImage {
                    QRPreviewSheet(image: previewQRImage, qrName: qrName)
                }
            }
        }
    }
    
    // MARK: - Actions
    
    private func generatePreview() {
        let content = getQRContent()
        previewQRImage = generateQRImage(content: content)
        showingPreview = true
    }
    
    private func createQRCode() {
        let content = getQRContent()
        
        isLoading = true
        
        Task {
            do {
                try await qrManager.createQRCode(
                    name: qrName,
                    type: selectedType,
                    content: content,
                    style: selectedStyle,
                    isDynamic: isDynamic,
                    logoImage: logoImage
                )
                
                await MainActor.run {
                    isLoading = false
                    dismiss()
                }
                
                AlertManager.shared.showSuccessToast("QR Code Created!")
                
            } catch QRError.subscriptionLimitReached {
                isLoading = false
                
                AlertManager.shared.showError(
                    title: "Upgrade Required",
                    message: "You've reached the limit for \(isDynamic ? "dynamic" : "static") QR codes in your current plan."
                ) {
                    if isDynamic {
                        isDynamic = false
                    }
                }
                
            } catch QRError.networkError {
                isLoading = false
                
                AlertManager.shared.showError(
                    title: "Connection Error",
                    message: "Please check your internet connection and try again."
                ) {
                    createQRCode()
                }
                
            } catch {
                isLoading = false
                
                AlertManager.shared.showError(
                    message: error.localizedDescription
                )
            }
        }
    }
    
    private func getQRContent() -> QRContent {
        switch selectedType {
        case .url:
            return .url(urlString)
        case .vCard:
            return .vCard(vCardData)
        case .wifi:
            return .wifi(wifiData)
        case .email:
            return .email(emailData)
        case .sms, .whatsapp, .linkedIn:
            return .text(textContent)
        }
    }
    
    private func generateQRImage(content: QRContent) -> UIImage? {
        switch selectedStyle.design {
        case .minimal:
            return generator.generateBasicQR(from: content.rawValue)
        case .branded:
            return generator.generateCustomQR(
                from: content.rawValue,
                foreground: UIColor(selectedStyle.foregroundColor.color),
                background: UIColor(selectedStyle.backgroundColor.color),
                logo: logoImage
            )
        case .gradient:
            return generator.generateGradientQR(from: content.rawValue)
        case .glass:
            return generator.generateGlassQR(from: content.rawValue)
        default:
            return generator.generateBasicQR(from: content.rawValue)
        }
    }
}

#Preview {
    if #available(iOS 16.0, *) {
        CreateQRCodeView(qrManager: QRCodeManager())
    } else {
        // Fallback on earlier versions
    }
}
