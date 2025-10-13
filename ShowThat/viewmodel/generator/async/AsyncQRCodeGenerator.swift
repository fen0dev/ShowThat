//
//  AsyncQRCodeGenerator.swift
//  ShowThat
//
//  Created by Giuseppe De Masi on 01/10/2025.
//

import Foundation
import UIKit
import CoreImage
import CoreImage.CIFilterBuiltins

/// Generatore QR asincrono con ottimizzazioni performance
@MainActor
final class AsyncQRGenerator: ObservableObject {
    static let shared = AsyncQRGenerator()
    
    // MARK: - Properties
    private let context = CIContext()
    
    private let generationQueue = DispatchQueue(label: "com.showthat.qrgeneration", qos: .userInitiated, attributes: .concurrent)
    private let maxConcurrentGenerations = 3
    private let generationSemaphore: DispatchSemaphore
    
    @Published var isGenerating = false
    @Published var generationProgress: Double = 0.0
    
    // MARK: - Initialization
    private init() {
        self.generationSemaphore = DispatchSemaphore(value: maxConcurrentGenerations)
    }
    
    // MARK: - Public Methods
    
    func generateQR(
        from content: String,
        style: QRStyle,
        size: CGSize = CGSize(width: 300, height: 300)
    ) async throws -> UIImage? {
        isGenerating = true
        generationProgress = 0.0
        
        defer {
            isGenerating = false
            generationProgress = 0.0
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            generationQueue.async {
                self.generationSemaphore.wait()
                
                Task {
                    do {
                        let image = try await self.syncGenerateQR(
                            from: content,
                            style: style,
                            size: size
                        )
                        
                        DispatchQueue.main.async {
                            self.generationProgress = 1.0
                        }
                        
                        self.generationSemaphore.signal()
                        continuation.resume(returning: image)
                    } catch {
                        self.generationSemaphore.signal()
                        continuation.resume(throwing: error)
                    }
                }
            }
        }
    }
    
    func generateBatch(
        requests: [QRGenerationRequest]
    ) async throws -> [QRGenerationResult] {
        isGenerating = true
        generationProgress = 0.0
        
        defer {
            isGenerating = false
            generationProgress = 0.0
        }
        
        var results: [QRGenerationResult] = []
        
        for (index, request) in requests.enumerated() {
            do {
                let image = try await generateQR(
                    from: request.content,
                    style: request.style,
                    size: request.size
                )
                
                results.append(QRGenerationResult(
                    request: request,
                    image: image,
                    success: true
                ))
                
                DispatchQueue.main.async {
                    self.generationProgress = Double(index + 1) / Double(requests.count)
                }
            } catch {
                results.append(QRGenerationResult(
                    request: request,
                    image: nil,
                    success: false,
                    error: error
                ))
            }
        }
        
        return results
    }
    
    // MARK: - Private Methods
    
    private func syncGenerateQR(
        from content: String,
        style: QRStyle,
        size: CGSize
    ) async throws -> UIImage? {
        guard !content.isEmpty, content.count <= 2953 else { throw QRCodeError.invalidContent }

        let filter = CIFilter.qrCodeGenerator()
        filter.message = Data(content.utf8)
        filter.correctionLevel = "M"

        guard let base = filter.outputImage else { throw QRCodeError.generationFailed }

        let scale = size.width / base.extent.width
        guard scale.isFinite, scale > 0 else { throw QRCodeError.generationFailed }

        let scaled = base.transformed(by: CGAffineTransform(scaleX: scale, y: scale))

        // Stile
        let styled = try await applyStyle(scaled, style: style, size: size)

        // Crop al rect finito del QR (evita extent infinito)
        let target = scaled.extent.integral
        let finite = styled.cropped(to: target)

        guard let cg = context.createCGImage(finite, from: target) else {
            throw QRCodeError.generationFailed
        }
        return UIImage(cgImage: cg)
    }
    
    private func applyStyle(_ image: CIImage, style: QRStyle, size: CGSize) async throws -> CIImage {
        switch style.design {
        case .minimal:
            return applyMinimalStyle(image, style: style)
        case .branded:
            return try await applyBrandedStyle(image, style: style, size: size)
        case .gradient:
            return applyGradientStyle(image, style: style)
        case .glass:
            return applyGlassStyle(image, style: style)
        case .dots:
            return applyDotsStyle(image, style: style)
        case .rounded:
            return applyRoundedStyle(image, style: style)
        }
    }
    
    private func applyMinimalStyle(_ image: CIImage, style: QRStyle) -> CIImage {
        let fg = CIColor(color: UIColor(style.foregroundColor.color))
        let bg = CIColor(color: UIColor(style.backgroundColor.color))

        let mono = CIFilter.colorMonochrome()
        mono.inputImage = image
        mono.color = fg
        mono.intensity = 1.0
        guard let colored = mono.outputImage else { return image }

        guard let constBG = CIFilter(name: "CIConstantColorGenerator") else { return colored }
        constBG.setValue(bg, forKey: kCIInputColorKey)
        // Crop del background per evitare infinito
        guard let bgImg = constBG.outputImage?.cropped(to: image.extent) else { return colored }

        let over = CIFilter.sourceOverCompositing()
        over.inputImage = colored
        over.backgroundImage = bgImg

        return (over.outputImage ?? colored).cropped(to: image.extent)
    }
    
    private func applyBrandedStyle(_ image: CIImage, style: QRStyle, size: CGSize) async throws -> CIImage {
        // Apply colors
        var styledImage = applyMinimalStyle(image, style: style)
        
        // Add logo if available
        if let logoURL = style.logoURL,
           let url = URL(string: logoURL),
           let logoImage = await ImageCache.shared.image(for: url) {
            styledImage = try addLogoToQR(styledImage, logo: logoImage, size: size)
        }
        
        return styledImage
    }
    
    private func applyGradientStyle(_ image: CIImage, style: QRStyle) -> CIImage {
        let grad = CIFilter.linearGradient()
        grad.color0 = CIColor(color: .purple)
        grad.color1 = CIColor(color: .blue)
        grad.point0 = CGPoint(x: 0, y: 0)
        grad.point1 = CGPoint(x: image.extent.width, y: image.extent.height)

        // Crop del gradiente per evitare infinito
        guard let g = grad.outputImage?.cropped(to: image.extent) else { return image }

        let mask = CIFilter.blendWithMask()
        mask.inputImage = g
        mask.backgroundImage = CIImage(color: .white).cropped(to: image.extent)
        mask.maskImage = image

        return (mask.outputImage ?? image).cropped(to: image.extent)
    }
    
    private func applyGlassStyle(_ image: CIImage, style: QRStyle) -> CIImage {
        // Evita bordi trasparenti: clampa e poi crop
        let clamped = image.clampedToExtent()

        let blur = CIFilter.gaussianBlur()
        blur.inputImage = clamped
        blur.radius = 2.0
        guard let blurred = blur.outputImage?.cropped(to: image.extent) else { return image }

        let alpha = CIFilter.colorMatrix()
        alpha.inputImage = blurred
        alpha.aVector = CIVector(x: 0, y: 0, z: 0, w: 0.8)

        return (alpha.outputImage ?? image).cropped(to: image.extent)
    }
    
    private func applyDotsStyle(_ image: CIImage, style: QRStyle) -> CIImage {
        // Convert squares to dots
        let morphFilter = CIFilter.morphologyMaximum()
        morphFilter.inputImage = image
        morphFilter.radius = 2.0
        
        guard let morphedImage = morphFilter.outputImage else { return image }
        
        let erodeFilter = CIFilter.morphologyMinimum()
        erodeFilter.inputImage = morphedImage
        erodeFilter.radius = 1.5
        
        return erodeFilter.outputImage ?? image
    }
    
    private func applyRoundedStyle(_ image: CIImage, style: QRStyle) -> CIImage {
        let rounded = CIFilter.roundedRectangleGenerator()
        rounded.extent = image.extent
        rounded.radius = 5.0
        rounded.color = .black
        guard let mask = rounded.outputImage else { return image }

        let blend = CIFilter.blendWithMask()
        blend.inputImage = image
        blend.backgroundImage = CIImage(color: .white).cropped(to: image.extent)
        blend.maskImage = mask

        return (blend.outputImage ?? image).cropped(to: image.extent)
    }
    
    private func addLogoToQR(_ qrImage: CIImage, logo: UIImage, size: CGSize) throws -> CIImage {
        guard let logoCI = CIImage(image: logo) else { throw QRCodeError.generationFailed }

        let side = floor(min(size.width, size.height) * 0.2)
        let logoRect = CGRect(
            x: floor((size.width - side) / 2),
            y: floor((size.height - side) / 2),
            width: side,
            height: side
        ).integral

        // Scala il logo alla dimensione target
        let sx = logoRect.width / logoCI.extent.width
        let sy = logoRect.height / logoCI.extent.height
        let scaledLogo = logoCI.transformed(by: CGAffineTransform(scaleX: sx, y: sy))

        // Trasla il logo nella posizione centrale
        let dx = logoRect.origin.x - scaledLogo.extent.origin.x
        let dy = logoRect.origin.y - scaledLogo.extent.origin.y
        let positionedLogo = scaledLogo.transformed(by: CGAffineTransform(translationX: dx, y: dy))

        // Sfondo bianco arrotondato sotto il logo
        guard let constBG = CIFilter(name: "CIConstantColorGenerator") else { return qrImage }
        constBG.setValue(CIColor.white, forKey: kCIInputColorKey)
        guard let bg = constBG.outputImage?.cropped(to: logoRect) else { return qrImage }

        let overLogo = CIFilter.sourceOverCompositing()
        overLogo.inputImage = positionedLogo
        overLogo.backgroundImage = bg
        guard let logoWithBG = overLogo.outputImage?.cropped(to: logoRect) else { return qrImage }

        let finalOver = CIFilter.sourceOverCompositing()
        finalOver.inputImage = logoWithBG
        finalOver.backgroundImage = qrImage

        // Crop finale all’estensione del QR
        return (finalOver.outputImage ?? qrImage).cropped(to: qrImage.extent)
    }
}

// MARK: - Supporting Types

struct QRGenerationRequest {
    let content: String
    let style: QRStyle
    let size: CGSize
    let id: String
    
    init(content: String, style: QRStyle, size: CGSize = CGSize(width: 300, height: 300), id: String = UUID().uuidString) {
        self.content = content
        self.style = style
        self.size = size
        self.id = id
    }
}

struct QRGenerationResult {
    let request: QRGenerationRequest
    let image: UIImage?
    let success: Bool
    let error: Error?
    
    init(request: QRGenerationRequest, image: UIImage?, success: Bool, error: Error? = nil) {
        self.request = request
        self.image = image
        self.success = success
        self.error = error
    }
}
