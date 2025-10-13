//
//  QRCodeDetailView.swift
//  ShowThat
//
//  Created by Giuseppe De Masi on 25/06/2025.
//

import SwiftUI

@available(iOS 17.0, *)
struct QRCodeDetailView: View {
    let qrCode: QRCodeModel
    let qrManager: QRCodeManager
    
    @Environment(\.dismiss) private var dismiss
    @State private var qrImage: UIImage?
    @State private var analytics: QRAnalyticsSummary?
    @State private var isLoadingAnalytics = true
    @State private var ownerName: String?
    
    private let generator = QRCodeGenerator()
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // creator
                    HStack(spacing: 8) {
                        Image(systemName: "person.circle.fill")
                            .foregroundStyle(.secondary)
                        
                        Text("Created by: \(ownerName ?? "Unknown")")
                            .font(.subheadline)
                            .foregroundStyle(.gray)
                    }
                    
                    // qr code preview
                    if let qrImage = qrImage {
                        Image(uiImage: qrImage)
                            .interpolation(.none)
                            .resizable()
                            .scaledToFit()
                            .frame(maxHeight: 250)
                            .padding()
                            .background(Color.white)
                            .cornerRadius(15)
                            .shadow(color: .black.opacity(0.1), radius: 10, y: 5)
                    }
                    
                    if qrCode.isDynamic, let url = qrCode.dynamicURL {
                        HStack {
                            Image(systemName: "link.circle.fill")
                                .foregroundColor(.blue)
                            
                            Text(url)
                                .font(.caption)
                                .foregroundColor(.blue)
                        }
                        .padding(.top)
                    }
                    
                    // analytics section
                    if isLoadingAnalytics {
                        ProgressView("Loading Analytics...")
                            .padding()
                    } else {
                        SimpleAnalyticsView(qrCode: qrCode)
                    }
                    
                    // details section
                    DetailsSection(qrCode: qrCode)
                }
                .padding()
            }
            .navigationTitle(qrCode.name)
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        withAnimation(.linear(duration: 0.3)) {
                            dismiss()
                        }
                    } label: {
                        Text("Done")
                            .foregroundStyle(.black)
                    }
                }
            }
            .onAppear {
                generateQRImage()
                loadAnalytics()
                loadOwnerName()
            }
        }
    }
    
    private func generateQRImage() {
        switch qrCode.style.design {
        case .minimal:
            qrImage = generator.generateBasicQR(from: qrCode.content.rawValue)
        case .branded:
            Task {
                var logoImage: UIImage? = nil
                if let urlString = qrCode.style.logoURL,
                   let url = URL(string: urlString) {
                    if let cached = await ImageCache.shared.image(for: url) {
                        logoImage = cached
                    } else {
                        do {
                            let (data, _) = try await URLSession.shared.data(from: url)
                            if let img = UIImage(data: data) {
                                ImageCache.shared.store(img, for: url)
                                logoImage = img
                            }
                        } catch { logoImage = nil }
                    }
                }
                
                let image = generator.generateCustomQR(
                    from: qrCode.content.rawValue,
                    foreground: UIColor(qrCode.style.foregroundColor.color),
                    background: UIColor(qrCode.style.backgroundColor.color),
                    logo: logoImage
                )
                
                await MainActor.run { self.qrImage = image }
            }
        case .gradient:
            qrImage = generator.generateGradientQR(from: qrCode.content.rawValue)
        case .glass:
            qrImage = generator.generateGlassQR(from: qrCode.content.rawValue)
        default:
            qrImage = generator.generateBasicQR(from: qrCode.content.rawValue)
        }
    }
    
    private func loadAnalytics() {
        Task {
            isLoadingAnalytics = true
            analytics = try? await qrManager.getAnalytics(for: qrCode)
            isLoadingAnalytics = false
        }
    }
    
    private func loadOwnerName() {
        Task {
            if let profile = await qrManager.fetchUserProfile(userId: qrCode.userId) {
                await MainActor.run {
                    self.ownerName = profile.displayName ?? profile.email
                }
            }
        }
    }
}

#Preview {
    if #available(iOS 17.0, *) {
        QRCodeDetailView(qrCode: QRCodeModel(userId: UUID().uuidString, name: "Giuseppe", type: .url, content: .url("https://wicte.dk"), style: QRStyle(design: .branded, foregroundColor: .init(color: Color(.cyan)), backgroundColor: .init(color: Color(.purple)), logoURL: "", cornerRadius: 20)), qrManager: QRCodeManager())
    } else {
        // Fallback on earlier versions
    }
}
