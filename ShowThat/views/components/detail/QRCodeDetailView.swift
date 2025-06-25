//
//  QRCodeDetailView.swift
//  ShowThat
//
//  Created by Giuseppe De Masi on 25/06/2025.
//

import SwiftUI

struct QRCodeDetailView: View {
    let qrCode: QRCodeModel
    let qrManager: QRCodeManager
    
    @Environment(\.dismiss) private var dismiss
    @State private var qrImage: UIImage?
    @State private var analytics: QRAnalyticsSummary?
    @State private var isLoadingAnalytics = true
    
    private let generator = QRCodeGenerator()
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
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
                    } else if let analytics = analytics {
                        AnalyticsView(analytics: analytics)
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
            }
        }
    }
    
    private func generateQRImage() {
        switch qrCode.style.design {
        case .minimal:
            qrImage = generator.generateBasicQR(from: qrCode.content.rawValue)
        case .branded:
            qrImage = generator.generateCustomQR(
                from: qrCode.content.rawValue,
                foreground: UIColor(qrCode.style.foregroundColor.color),
                background: UIColor(qrCode.style.backgroundColor.color),
                logo: nil
            )
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
}

#Preview {
    QRCodeDetailView(qrCode: QRCodeModel(userId: UUID().uuidString, name: "Giuseppe", type: .vCard, content: .vCard(VCardData(fullName: "TechnoForged Digital")), style: QRStyle()), qrManager: QRCodeManager())
}
