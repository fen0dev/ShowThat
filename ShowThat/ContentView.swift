//
//  ContentView.swift
//  ShowThat
//
//  Created by Giuseppe De Masi on 19/06/2025.
//

import SwiftUI
import CoreImage
import CoreImage.CIFilterBuiltins
import PhotosUI

struct ContentView: View {
    @State private var websiteURL = ""
    @State private var companyName = ""
    @State private var qrImage: UIImage?
    @State private var selectedColor = Color.black
    @State private var backgroundColor = Color.white
    @State private var showingImagePicker = false
    @State private var logoImage: UIImage?
    @State private var isGenerating = false
    @State private var showShareSheet = false
    @State private var selectedStyle = QRStyle.minimal
    @State private var animateQR = false
    @State private var showToast = false
    @State private var toastMessage = ""
    @State private var toastType: ToastStyle = .success
    
    enum QRStyle: String, CaseIterable {
        case minimal = "Minimal"
        case branded = "Branded"
        case gradient = "Gradient"
        case glass = "Glass"
        
        var icon: String {
            switch self {
            case .minimal: return "square"
            case .branded: return "paintbrush.fill"
            case .gradient: return "wand.and.rays"
            case .glass: return "cube.transparent.fill"
            }
        }
    }
    
    enum ToastStyle {
        case success
        case error
        case info
        
        var icon: String {
            switch self {
            case .success: return "checkmark.circle.fill"
            case .error: return "xmark.circle.fill"
            case .info: return "info.circle.fill"
            }
        }
        
        var color: Color {
            switch self {
            case .success: return .green
            case .error: return .pink
            case .info: return .blue
            }
        }
    }
    var body: some View {
        NavigationView {
            ZStack {
                // background
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(red: 0.95, green: 0.95, blue: 1.0),
                        Color(red: 0.85, green: 0.9, blue: 1.0),
                        Color(red: 0.9, green: 0.85, blue: 1.0)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                .overlay {
                    GeometryReader { geometry in
                        ForEach(0..<3) { i in
                            Circle()
                                .fill(
                                    LinearGradient(
                                        gradient: Gradient(colors: [
                                            Color.white.opacity(0.3),
                                            Color.purple.opacity(0.1)
                                        ]),
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                                .frame(width: 200, height: 200)
                                .blur(radius: 30)
                                .offset(
                                    x: CGFloat.random(in: 0...geometry.size.width),
                                    y: CGFloat.random(in: 0...geometry.size.height)
                                )
                                .animation(.easeInOut(duration: Double.random(in: 15...25)).repeatForever(autoreverses: true), value: animateQR
                                )
                        }
                    }
                }
                
                ScrollView {
                    VStack(spacing: 25) {
                        // header with floating animation
                        VStack(spacing: 10) {
                            Image(systemName: "qrcode.viewfinder")
                                .font(.system(size: 60))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [.purple, .blue],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .shadow(color: .purple.opacity(0.3), radius: 10)
                                .scaleEffect(animateQR ? 1.1 : 1.0)
                                .animation(
                                    .easeInOut(duration: 2).repeatForever(autoreverses: true),
                                    value: animateQR
                                )
                            
                            Text("QR Code Studio")
                                .font(.largeTitle)
                                .fontWeight(.bold)
                                .foregroundStyle(.black.opacity(0.8))
                        }
                        .padding(.top, 20)
                        
                        // input section with glass morphism
                        VStack(spacing: 20) {
                            // url input
                            HStack {
                                Image(systemName: "globe")
                                    .foregroundStyle(.blue)
                                    .font(.title2.bold())
                                
                                TextField("Website URL", text: $websiteURL)
                                    .textFieldStyle(.plain)
                                    .font(.body)
                                    .textInputAutocapitalization(.never)
                                    .keyboardType(.URL)
                            }
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 15)
                                    .fill(.ultraThinMaterial)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 15)
                                            .stroke(
                                                LinearGradient(
                                                    colors: [.white.opacity(0.5), .clear],
                                                    startPoint: .topLeading,
                                                    endPoint: .bottomTrailing
                                                ),
                                                lineWidth: 1
                                            )
                                    )
                            )
                            
                            // company name input
                            HStack {
                                Image(systemName: "building.2.fill")
                                    .foregroundStyle(.purple)
                                    .font(.title3.bold())
                                
                                TextField("Company Name", text: $companyName)
                                    .textFieldStyle(.plain)
                                    .font(.body)
                            }
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 15)
                                    .fill(.ultraThinMaterial)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 15)
                                            .stroke(
                                                LinearGradient(
                                                    colors: [.white.opacity(0.5), .clear],
                                                    startPoint: .topLeading,
                                                    endPoint: .bottomTrailing
                                                ),
                                                lineWidth: 1
                                            )
                                    )
                            )
                        }
                        .padding(.horizontal)
                        
                        // style selector
                        VStack(alignment: .leading, spacing: 15) {
                            Text("Style")
                                .font(.headline)
                                .foregroundStyle(.primary)
                                .padding(.horizontal)
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 15) {
                                    ForEach(QRStyle.allCases, id: \.self) { style in
                                        StyleCard(
                                            style: style,
                                            isSelected: selectedStyle == style,
                                            action: {
                                                withAnimation(.spring()) {
                                                    selectedStyle = style
                                                }
                                            }
                                        )
                                    }
                                }
                                .padding(.vertical, 4)
                                .padding(.horizontal)
                            }
                        }
                        
                        // color customization
                        if selectedStyle == .branded {
                            VStack(spacing: 20) {
                                ColorPickerRow(
                                    title: "QR Color",
                                    selectedColor: $selectedColor,
                                    icon: "paintpalette.fill"
                                )
                                
                                ColorPickerRow(
                                    title: "Background",
                                    selectedColor: $backgroundColor,
                                    icon: "square.fill.on.square.fill"
                                )
                                
                                // logo upload
                                Button(action: { showingImagePicker = true }) {
                                    HStack {
                                        Image(systemName: logoImage == nil ? "photo.badge.plus" : "photo.fill.on.rectangle.fill")
                                            .font(.title3)
                                        
                                        Text(logoImage == nil ? "Add Logo" : "Logo Added")
                                            .fontWeight(.medium)
                                        
                                        Spacer()
                                        
                                        if logoImage != nil {
                                            Image(systemName: "checkmark.circle.fill")
                                                .foregroundColor(.green)
                                        }
                                    }
                                    .padding()
                                    .background(
                                        RoundedRectangle(cornerRadius: 15)
                                            .fill(.ultraThinMaterial)
                                    )
                                }
                                .buttonStyle(.plain)
                                .padding(.horizontal)
                            }
                            .transition(.opacity.combined(with: .move(edge: .top)))
                        }
                        
                        // Generate Button
                        Button(action: generateQRCode) {
                            HStack {
                                if isGenerating {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                        .scaleEffect(0.8)
                                } else {
                                    Image(systemName: "wand.and.stars")
                                        .font(.title3)
                                }
                                
                                Text(isGenerating ? "Generating..." : "Generate QR Code")
                                    .fontWeight(.semibold)
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(
                                LinearGradient(
                                    colors: [.purple, .blue],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(15)
                            .shadow(color: .purple.opacity(0.3), radius: 10, y: 5)
                            .scaleEffect(isGenerating ? 0.95 : 1.0)
                        }
                        .padding(.horizontal)
                        .disabled(websiteURL.isEmpty || isGenerating)
                        .opacity(websiteURL.isEmpty ? 0.6 : 1.0)
                        
                        // QR Code Display
                        if let qrImage = qrImage {
                            VStack(spacing: 20) {
                                // QR Code with animation
                                Image(uiImage: qrImage)
                                    .interpolation(.none)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 250, height: 250)
                                    .padding()
                                    .background(
                                        RoundedRectangle(cornerRadius: 20)
                                            .fill(.white)
                                            .shadow(color: .black.opacity(0.1), radius: 20, y: 10)
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 20)
                                            .stroke(
                                                LinearGradient(
                                                    colors: [.purple.opacity(0.3), .blue.opacity(0.3)],
                                                    startPoint: .topLeading,
                                                    endPoint: .bottomTrailing
                                                ),
                                                lineWidth: 2
                                            )
                                    )
                                    .scaleEffect(animateQR ? 1.0 : 0.8)
                                    .opacity(animateQR ? 1.0 : 0.0)
                                    .animation(.spring(response: 0.6, dampingFraction: 0.8), value: animateQR)
                                
                                // Action Buttons
                                HStack(spacing: 15) {
                                    ActionButton(
                                        title: "Save",
                                        icon: "square.and.arrow.down",
                                        color: .green,
                                        action: saveQRCode
                                    )
                                    
                                    ActionButton(
                                        title: "Share",
                                        icon: "square.and.arrow.up",
                                        color: .blue,
                                        action: { showShareSheet = true }
                                    )
                                }
                                .padding(.horizontal)
                            }
                            .transition(.scale.combined(with: .opacity))
                        }
                        
                        Spacer(minLength: 30)
                    }
                }
            }
            .navigationBarHidden(true)
            .onAppear {
                animateQR = true
            }
            .sheet(isPresented: $showingImagePicker) {
                ImagePicker(image: $logoImage)
                    .onDisappear {
                        if logoImage != nil {
                            toastMessage = "Logo added successfully!"
                            toastType = .success
                            withAnimation(.spring()) {
                                showToast = true
                            }
                        }
                    }
            }
            .sheet(isPresented: $showShareSheet) {
                if let qrImage = qrImage {
                    ShareSheet(items: [qrImage])
                }
            }
        }
    }
    
    func generateQRCode() {
        guard !websiteURL.isEmpty else { return }
        
        withAnimation {
            isGenerating = true
            animateQR = false
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            let generator = QRCodeGenerator()
            
            switch selectedStyle {
            case .minimal:
                qrImage = generator.generateBasicQR(from: websiteURL)
            case .branded:
                qrImage = generator.generateCustomQR(from: websiteURL, foreground: UIColor(selectedColor), background: UIColor(backgroundColor), logo: logoImage)
            case .gradient:
                qrImage = generator.generateGradientQR(from: websiteURL)
            case .glass:
                qrImage = generator.generateGlassQR(from: websiteURL)
            }
            
            withAnimation(.spring()) {
                isGenerating = false
                animateQR = true
            }
        }
    }
    
    func saveQRCode() {
        guard let qrImage = qrImage else { return }
        UIImageWriteToSavedPhotosAlbum(qrImage, nil, nil, nil)
        
        // Show toast
        withAnimation(.spring()) {
            showToast = true
        }
        
        // show success feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: toastType == .success ? .medium : .soft)
        impactFeedback.impactOccurred()
    }
}

#Preview {
    ContentView()
}
