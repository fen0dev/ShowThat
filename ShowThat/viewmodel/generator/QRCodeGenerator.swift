//
//  QRCodeGenerator.swift
//  ShowThat
//
//  Created by Giuseppe De Masi on 19/06/2025.
//

import Foundation
import UIKit
import CoreImage
import CoreImage.CIFilterBuiltins
import PhotosUI

class QRCodeGenerator {
    private let context = CIContext()
    
    func generateBasicQR(from string: String) -> UIImage? {
        let filter = CIFilter.qrCodeGenerator()
        filter.message = Data(string.utf8)
        filter.correctionLevel = "M"
        
        guard let outputImage = filter.outputImage else { return nil }
        
        let scaledImage = outputImage.transformed(by: CGAffineTransform(scaleX: 10, y: 10))
        
        guard let cgImage = context.createCGImage(scaledImage, from: scaledImage.extent) else { return nil }
        
        return UIImage(cgImage: cgImage)
    }
    
    func generateCustomQR(from string: String, foreground: UIColor, background: UIColor, logo: UIImage?) -> UIImage? {
        guard let basicQR = generateBasicQR(from: string) else { return nil }
        
        let size = CGSize(width: 300, height: 300)
        UIGraphicsBeginImageContextWithOptions(size, false, 0)
        
        // Draw background
        background.setFill()
        UIRectFill(CGRect(origin: .zero, size: size))
        
        // Create colored QR
        guard let cgImage = basicQR.cgImage,
              let coloredCGImage = recolorQRCode(cgImage, foreground: foreground, background: background) else {
            UIGraphicsEndImageContext()
            return nil
        }
        
        let coloredQR = UIImage(cgImage: coloredCGImage)
        coloredQR.draw(in: CGRect(origin: .zero, size: size))
        
        // Add logo if provided
        if let logo = logo {
            let logoSize = CGSize(width: 60, height: 60)
            let logoOrigin = CGPoint(
                x: (size.width - logoSize.width) / 2,
                y: (size.height - logoSize.height) / 2
            )
            
            // White background for logo
            UIColor.white.setFill()
            UIBezierPath(roundedRect: CGRect(origin: logoOrigin, size: logoSize), cornerRadius: 10).fill()
            
            // Draw logo
            logo.draw(in: CGRect(origin: logoOrigin, size: logoSize))
        }
        
        let finalImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return finalImage
    }
    
    func generateGradientQR(from string: String, foregroundColor: UIColor = .black, background: UIColor = .white) -> UIImage? {
        guard let basicQR = generateBasicQR(from: string) else { return nil }
        
        let size = CGSize(width: 300, height: 300)
        UIGraphicsBeginImageContextWithOptions(size, false, 0.0)
        guard let context = UIGraphicsGetCurrentContext() else { return nil }
        
        // Create gradient
        let gradientColors: [CGColor] = [UIColor.purple.cgColor, UIColor.systemTeal.cgColor]
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let locations: [CGFloat] = [0.0, 1.0]
        guard let gradient = CGGradient(colorsSpace: colorSpace, colors: gradientColors as CFArray, locations: locations) else {
            UIGraphicsEndImageContext()
            return nil
        }
        
        context.drawLinearGradient(gradient,
                                   start: CGPoint(x: 0, y: 0),
                                   end: CGPoint(x: size.width, y: size.height),
                                   options: [])
        
        // Apply QR as mask
        if let cgImage = basicQR.cgImage {
            context.clip(to: CGRect(origin: .zero, size: size), mask: cgImage)
            context.drawLinearGradient(gradient,
                                       start: CGPoint(x: size.width / 2, y: 0),
                                       end: CGPoint(x: size.width / 2, y: size.height),
                                       options: [])
        }
        
        let finalImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return finalImage
    }
    
    func generateGlassQR(from string: String, foreground: UIColor = .black, background: UIColor = .white) -> UIImage? {
        guard let basicQR = generateBasicQR(from: string) else { return nil }
        
        let size = CGSize(width: 300, height: 300)
        UIGraphicsBeginImageContextWithOptions(size, false, 0.0)
        guard let context = UIGraphicsGetCurrentContext() else { return nil }
        
        let glassColors = [UIColor.white.withAlphaComponent(0.8).cgColor, UIColor.clear.cgColor]
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let locations: [CGFloat] = [0.0, 1.0]
        let glassGradient = CGGradient(colorsSpace: colorSpace, colors: glassColors as CFArray, locations: locations)!
        
        context.drawLinearGradient(glassGradient,
                                   start: CGPoint(x: 0, y: 0),
                                   end: CGPoint(x: size.width, y: size.height),
                                   options: [])
        
        // simulated blur with semi-transoarent overlay
        context.setBlendMode(.multiply)
        UIColor.white.withAlphaComponent(0.5).setFill()
        context.fill(CGRect(origin: .zero, size: size))
        
        if let cgImage = basicQR.cgImage {
            context.setBlendMode(.normal)
            context.draw(cgImage, in: CGRect(origin: CGPoint(x: 50, y: 50), size: CGSize(width: 200, height: 200)))
        }
        
        let finalImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return finalImage
    }
    
    func generateDotsQR(from string: String, foreground: UIColor = .black, background: UIColor = .white) -> UIImage? {
        guard let basicQR = generateBasicQR(from: string) else { return nil }
        
        let size = CGSize(width: 300, height: 300)
        UIGraphicsBeginImageContextWithOptions(size, false, 0.0)
        guard let context = UIGraphicsGetCurrentContext() else { return nil }
        
        // solid background
        background.setFill()
        context.fill(CGRect(origin: .zero, size: size))
        
        // design like circles
        if let cgImage = basicQR.cgImage,
           let pixelData = cgImage.dataProvider?.data,
           let data = CFDataGetBytePtr(pixelData) {
            let bytesPerPixel = 4
            let width = Int(cgImage.width)
            let height = Int(cgImage.height)
            let scale = size.width / CGFloat(width)
            
            for y in 0..<height {
                for x in 0..<width {
                    let pixelIndex = (y * width + 1) * bytesPerPixel
                    let alpha = data[pixelIndex + 3]
                    if alpha > 128 {
                        let center = CGPoint(x: CGFloat(x) * scale + scale / 2, y: CGFloat(y) * scale + scale / 2)
                        let radius = scale / 2 * 0.8
                        let circlePath = UIBezierPath(arcCenter: center, radius: radius, startAngle: 0, endAngle: 2 * .pi, clockwise: true)
                        foreground.setFill()
                        circlePath.fill()
                    }
                }
            }
        }
        
        let finalImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return finalImage
    }
    
    func generateRoundedQR(from string: String, foreground: UIColor = .black, background: UIColor = .white, cornerRadius: CFloat = 5.0) -> UIImage? {
        guard let basicQR = generateBasicQR(from: string) else { return nil }
        
        let size = CGSize(width: 300, height: 300)
        UIGraphicsBeginImageContextWithOptions(size, false, 0.0)
        guard let context = UIGraphicsGetCurrentContext() else { return nil }
        
        background.setFill()
        context.fill(CGRect(origin: .zero, size: size))
        
        if let cgImage = basicQR.cgImage,
           let pixelData = cgImage.dataProvider?.data,
           let data = CFDataGetBytePtr(pixelData) {
            let bytesPerPixel = 4
            let width = Int(cgImage.width)
            let height = Int(cgImage.height)
            let scale = size.width / CGFloat(width)
            let moduleSize = scale
            
            for y in 0..<height {
                for x in 0..<width {
                    let pixelIndex = (y * width + x)
                    let alpha = data[pixelIndex + 3]
                    if alpha > 128 {
                        let rect = CGRect(x: CGFloat(x) * moduleSize, y: CGFloat(y) * moduleSize, width: moduleSize, height: moduleSize)
                        let roundedPath = UIBezierPath(roundedRect: rect, cornerRadius: CGFloat(cornerRadius))
                        foreground.setFill()
                        roundedPath.fill()
                    }
                }
            }
        }
        
        let finalImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return finalImage
    }
    
    private func recolorQRCode(_ image: CGImage, foreground: UIColor, background: UIColor) -> CGImage? {
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let width = image.width
        let height = image.height
        
        let bytesPerPixel = 4
        let bytesPerRow = bytesPerPixel * width
        let bitsPerComponent = 8
        
        guard let context = CGContext(data: nil,
                                    width: width,
                                    height: height,
                                    bitsPerComponent: bitsPerComponent,
                                    bytesPerRow: bytesPerRow,
                                    space: colorSpace,
                                    bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else {
            return nil
        }
        
        context.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))
        
        guard let pixelBuffer = context.data else { return nil }
        
        let pixels = pixelBuffer.bindMemory(to: UInt8.self, capacity: width * height * bytesPerPixel)
        
        var fr: CGFloat = 0, fg: CGFloat = 0, fb: CGFloat = 0, fa: CGFloat = 0
        var br: CGFloat = 0, bg: CGFloat = 0, bb: CGFloat = 0, ba: CGFloat = 0
        
        foreground.getRed(&fr, green: &fg, blue: &fb, alpha: &fa)
        background.getRed(&br, green: &bg, blue: &bb, alpha: &ba)
        
        for y in 0..<height {
            for x in 0..<width {
                let offset = (y * width + x) * bytesPerPixel
                
                let alpha = CGFloat(pixels[offset + 3]) / 255.0
                let intensity = (CGFloat(pixels[offset]) + CGFloat(pixels[offset + 1]) + CGFloat(pixels[offset + 2])) / (3.0 * 255.0)
                
                if intensity < 0.5 {
                    pixels[offset] = UInt8(fr * 255)
                    pixels[offset + 1] = UInt8(fg * 255)
                    pixels[offset + 2] = UInt8(fb * 255)
                    pixels[offset + 3] = UInt8(fa * alpha * 255)
                } else {
                    pixels[offset] = UInt8(br * 255)
                    pixels[offset + 1] = UInt8(bg * 255)
                    pixels[offset + 2] = UInt8(bb * 255)
                    pixels[offset + 3] = UInt8(ba * alpha * 255)
                }
            }
        }
        
        return context.makeImage()
    }
}

