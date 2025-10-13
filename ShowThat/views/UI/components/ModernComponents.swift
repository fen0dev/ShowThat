//
//  ModernComponents.swift
//  ShowThat
//
//  Created by Giuseppe De Masi on 30/09/2025.
//

import SwiftUI

// MARK: - Design Tokens

struct DesignTokens {
    struct Colors {
        static let primary = Color(red: 0.4, green: 0.2, blue: 0.8)
        static let secondary = Color(red: 0.2, green: 0.4, blue: 0.9)
        static let success = Color.green
        static let error = Color.red
        static let warning = Color.orange
        static let info = Color.blue
        
        // Background colors
        static let backgroundPrimary = Color(red: 0.95, green: 0.95, blue: 1.0)
        static let backgroundSecondary = Color(red: 0.92, green: 0.94, blue: 1.0)
        static let surface = Color.white
        static let surfaceElevated = Color.white.opacity(0.95)
        
        // Text colors
        static let textPrimary = Color.primary
        static let textSecondary = Color.secondary
        static let textTertiary = Color.secondary.opacity(0.6)
    }
    
    struct Spacing {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 16
        static let lg: CGFloat = 24
        static let xl: CGFloat = 32
        static let xxl: CGFloat = 48
    }
    
    struct Typography {
        static let title = Font.largeTitle.weight(.bold)
        static let headline = Font.headline.weight(.semibold)
        static let subheadline = Font.subheadline.weight(.medium)
        static let body = Font.body
        static let caption = Font.caption
        static let caption2 = Font.caption2
    }
    
    struct CornerRadius {
        static let sm: CGFloat = 8
        static let md: CGFloat = 12
        static let lg: CGFloat = 16
        static let xl: CGFloat = 20
    }
    
    struct Shadow {
        static let sm = Color.black.opacity(0.05)
        static let md = Color.black.opacity(0.1)
        static let lg = Color.black.opacity(0.15)
    }
}

// MARK: - Loading View

struct LoadingView: View {
    let message: String
    let progress: Double
    let showProgress: Bool
    
    init(message: String = "Loading...", progress: Double = 0.8, showProgress: Bool = true) {
        self.message = message
        self.progress = progress
        self.showProgress = showProgress
    }
    
    var body: some View {
        VStack(spacing: DesignTokens.Spacing.md) {
            ProgressView()
                .scaleEffect(1.2)
                .tint(DesignTokens.Colors.primary)
            
            Text(message)
                .font(DesignTokens.Typography.body)
                .foregroundColor(DesignTokens.Colors.textSecondary)
                .multilineTextAlignment(.center)
            
            if showProgress {
                ProgressView(value: progress)
                    .progressViewStyle(LinearProgressViewStyle(tint: DesignTokens.Colors.primary))
                    .frame(width: 200)
                
                Text("\(Int(progress * 100))%")
                    .font(DesignTokens.Typography.caption)
                    .foregroundColor(DesignTokens.Colors.textTertiary)
            }
        }
        .padding(DesignTokens.Spacing.xl)
        .background(DesignTokens.Colors.surface)
        .cornerRadius(DesignTokens.CornerRadius.lg)
        .shadow(color: DesignTokens.Shadow.lg, radius: 20, y: 10)
    }
}

#Preview {
    LoadingView()
}

struct ErrorView: View {
    let error: AppError
    let retryAction: (() -> Void)?
    
    init(error: AppError, retryAction: (() -> Void)? = nil) {
        self.error = error
        self.retryAction = retryAction
    }
    
    var body: some View {
        VStack(spacing: DesignTokens.Spacing.lg) {
            Image(systemName: errorIcon)
                .font(.system(size: 48))
                .foregroundColor(DesignTokens.Colors.error)
            
            Text(errorTitle)
                .font(DesignTokens.Typography.headline)
                .foregroundColor(DesignTokens.Colors.textPrimary)
                .multilineTextAlignment(.center)
            
            Text(error.localizedDescription)
                .font(DesignTokens.Typography.body)
                .foregroundColor(DesignTokens.Colors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, DesignTokens.Spacing.md)
            
            if let retryAction = retryAction, error.canRetry {
                Button("Try Again") {
                    retryAction()
                }
                .buttonStyle(PrimaryButtonStyle())
            }
        }
        .padding(DesignTokens.Spacing.xl)
        .background(DesignTokens.Colors.surface)
        .cornerRadius(DesignTokens.CornerRadius.lg)
        .shadow(color: DesignTokens.Shadow.md, radius: 10, y: 5)
    }
    
    private var errorIcon: String {
        switch error.type {
        case .network:
            return "wifi.exclamationmark"
        case .authentication:
            return "person.crop.circle.badge.exclamationmark"
        case .subscription:
            return "creditcard.trianglebadge.exclamationmark"
        case .qrCode:
            return "qrcode.viewfinder"
        case .validation:
            return "exclamationmark.triangle"
        case .system:
            return "gear.badge.xmark"
        }
    }
    
    private var errorTitle: String {
        switch error.type {
        case .network:
            return "Connection Error"
        case .authentication:
            return "Authentication Error"
        case .subscription:
            return "Payment Error"
        case .qrCode:
            return "QR Code Error"
        case .validation:
            return "Invalid Data"
        case .system:
            return "System Error"
        }
    }
}

#Preview {
    ErrorView(error: .qrCode(.fileTooLarge))
}

// MARK: - Empty State View

struct EmptyStateView: View {
    let icon: String
    let title: String
    let message: String
    let actionTitle: String?
    let action: (() -> Void)?
    
    init(
        icon: String,
        title: String,
        message: String,
        actionTitle: String? = nil,
        action: (() -> Void)? = nil
    ) {
        self.icon = icon
        self.title = title
        self.message = message
        self.actionTitle = actionTitle
        self.action = action
    }
    
    var body: some View {
        VStack(spacing: DesignTokens.Spacing.lg) {
            Image(systemName: icon)
                .font(.system(size: 60))
                .foregroundStyle(
                    LinearGradient(
                        colors: [DesignTokens.Colors.primary.opacity(0.6), DesignTokens.Colors.secondary.opacity(0.6)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            
            Text(title)
                .font(DesignTokens.Typography.title)
                .foregroundColor(DesignTokens.Colors.textPrimary)
                .multilineTextAlignment(.center)
            
            Text(message)
                .font(DesignTokens.Typography.body)
                .foregroundColor(DesignTokens.Colors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, DesignTokens.Spacing.xl)
            
            if let actionTitle = actionTitle, let action = action {
                Button(actionTitle) {
                    action()
                }
                .buttonStyle(PrimaryButtonStyle())
            }
        }
        .padding(DesignTokens.Spacing.xxl)
    }
}

#Preview {
    EmptyStateView(icon: "magnifyingglass", title: "Unavailable", message: "The content was not found.")
}

// MARK: - Button Styles

struct ButtonStylePrimary: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(DesignTokens.Typography.headline)
            .foregroundColor(.white)
            .padding(.horizontal, DesignTokens.Spacing.xl)
            .padding(.vertical, DesignTokens.Spacing.md)
            .background(
                LinearGradient(
                    colors: [DesignTokens.Colors.primary, DesignTokens.Colors.secondary],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(DesignTokens.CornerRadius.lg)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .shadow(color: DesignTokens.Colors.primary.opacity(0.3), radius: 10, y: 5)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

struct ButtonStyleSecondary: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(DesignTokens.Typography.headline)
            .foregroundColor(DesignTokens.Colors.primary)
            .padding(.horizontal, DesignTokens.Spacing.xl)
            .padding(.vertical, DesignTokens.Spacing.md)
            .background(DesignTokens.Colors.primary.opacity(0.1))
            .cornerRadius(DesignTokens.CornerRadius.lg)
            .overlay(
                RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.lg)
                    .stroke(DesignTokens.Colors.primary, lineWidth: 2)
            )
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

// MARK: - Text Field Style

struct TextFieldStyleModern: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding(DesignTokens.Spacing.md)
            .background(DesignTokens.Colors.surface)
            .cornerRadius(DesignTokens.CornerRadius.md)
            .overlay(
                RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.md)
                    .stroke(DesignTokens.Colors.primary.opacity(0.3), lineWidth: 1)
            )
            .shadow(color: DesignTokens.Shadow.sm, radius: 4, y: 2)
    }
}
