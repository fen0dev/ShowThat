//
//  ModernCard.swift
//  ShowThat
//
//  Created by Giuseppe De Masi on 02/10/2025.
//

import SwiftUI

struct ModernCard<Content: View>: View {
    let content: Content
    let style: CardStyle
    let padding: CGFloat
    
    enum CardStyle {
        case elevated, outlined, filled, glass
    }
    
    init(style: CardStyle = .elevated, padding: CGFloat = DesignTokens.Spacing.md, @ViewBuilder content: () -> Content) {
        self.style = style
        self.padding = padding
        self.content = content()
    }
    
    var body: some View {
        content
            .padding(padding)
            .background(backgroundView)
            .cornerRadius(DesignTokens.CornerRadius.md)
            .shadow(color: shadowStyle.color, radius: shadowStyle.radius, y: shadowStyle.y)
    }
    
    @ViewBuilder
    private var backgroundView: some View {
        switch style {
        case .elevated:
            DesignTokens.Colors.surface
        case .outlined:
            DesignTokens.Colors.surface
                .overlay(
                    RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.md)
                        .stroke(DesignTokens.Colors.primary.opacity(0.2), lineWidth: 1)
                )
        case .filled:
            DesignTokens.Colors.primary.opacity(0.05)
        case .glass:
            DesignTokens.Colors.surfaceElevated
                .background(.ultraThinMaterial)
        }
    }
    private var shadowStyle: (color: Color, radius: CGFloat, y: CGFloat) {
        switch style {
        case .elevated:
            return (DesignTokens.Shadow.md, 8, 4)
        case .outlined, .filled:
            return (DesignTokens.Shadow.sm, 4, 2)
        case .glass:
            return (DesignTokens.Shadow.lg, 12, 6)
        }
    }
}
