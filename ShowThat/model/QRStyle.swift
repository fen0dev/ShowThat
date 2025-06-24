//
//  QRStyle.swift
//  ShowThat
//
//  Created by Giuseppe De Masi on 24/06/2025.
//

import Foundation
import SwiftUI

struct QRStyle: Codable {
    var design: QRDesignStyle = .minimal
    var foregroundColor: CodableColor = CodableColor(color: .black)
    var backgroundColor: CodableColor = CodableColor(color: .white)
    var logoURL: String? // Store logo in Firebase Storage
    var cornerRadius: Double = 0
    
    enum QRDesignStyle: String, CaseIterable, Codable {
        case minimal = "Minimal"
        case branded = "Branded"
        case gradient = "Gradient"
        case glass = "Glass"
        case dots = "Dots"
        case rounded = "Rounded"
    }
}
