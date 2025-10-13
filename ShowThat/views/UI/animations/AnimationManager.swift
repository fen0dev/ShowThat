//
//  AnimationManager.swift
//  ShowThat
//
//  Created by Giuseppe De Masi on 30/09/2025.
//

import SwiftUI

/// Gestisce animazioni avanzate e transizioni
final class AnimationManager {
    static let shared = AnimationManager()
    
    private init() {}
    
    // MARK: - Animation Presets
    
    static let springBouncy = Animation.spring(response: 0.6, dampingFraction: 0.8, blendDuration: 0)
    static let springSmooth = Animation.spring(response: 0.5, dampingFraction: 0.9, blendDuration: 0)
    static let springQuick = Animation.spring(response: 0.3, dampingFraction: 0.8, blendDuration: 0)
    
    static let easeInOut = Animation.easeInOut(duration: 0.3)
    static let easeOut = Animation.easeOut(duration: 0.3)
    static let easeIn = Animation.easeIn(duration: 0.3)
    
    static let quick = Animation.easeInOut(duration: 0.2)
    static let medium = Animation.easeInOut(duration: 0.4)
    static let slow = Animation.easeInOut(duration: 0.6)
}

// MARK: - Animation Modifiers

struct FadeInModifier: ViewModifier {
    @State private var opacity: Double = 0
    
    let delay: Double
    let duration: Double
    
    init(delay: Double = 0, duration: Double = 0.5) {
        self.delay = delay
        self.duration = duration
    }
    
    func body(content: Content) -> some View {
        content
            .opacity(opacity)
            .onAppear {
                withAnimation(.easeInOut(duration: duration).delay(delay)) {
                    opacity = 1
                }
            }
    }
}

struct SlideInModifier: ViewModifier {
    @State private var offset: CGSize = CGSize(width: 0, height: 50)
    @State private var opacity: Double = 0
    
    let direction: SlideDirection
    let delay: Double
    let duration: Double
    
    enum SlideDirection {
        case fromTop, fromBottom, fromLeading, fromTrailing
    }
    
    init(direction: SlideDirection = .fromBottom, delay: Double = 0, duration: Double = 0.5) {
        self.direction = direction
        self.delay = delay
        self.duration = duration
        
        // Set initial offset based on direction
        switch direction {
        case .fromTop:
            self._offset = State(initialValue: CGSize(width: 0, height: -50))
        case .fromBottom:
            self._offset = State(initialValue: CGSize(width: 0, height: 50))
        case .fromLeading:
            self._offset = State(initialValue: CGSize(width: -50, height: 0))
        case .fromTrailing:
            self._offset = State(initialValue: CGSize(width: 50, height: 0))
        }
    }
    
    func body(content: Content) -> some View {
        content
            .offset(offset)
            .opacity(opacity)
            .onAppear {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(delay)) {
                    offset = CGSize.zero
                    opacity = 1
                }
            }
    }
}

struct ScaleInModifier: ViewModifier {
    @State private var scale: CGFloat = 0.8
    @State private var opacity: Double = 0
    
    let delay: Double
    let duration: Double
    
    init(delay: Double = 0, duration: Double = 0.4) {
        self.delay = delay
        self.duration = duration
    }
    
    func body(content: Content) -> some View {
        content
            .scaleEffect(scale)
            .opacity(opacity)
            .onAppear {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.7).delay(delay)) {
                    scale = 1
                    opacity = 1
                }
            }
    }
}

struct ShakeModifier: ViewModifier {
    @State private var offset: CGFloat = 0
    
    let intensity: CGFloat
    let duration: Double
    
    init(intensity: CGFloat = 10, duration: Double = 0.5) {
        self.intensity = intensity
        self.duration = duration
    }
    
    func body(content: Content) -> some View {
        content
            .offset(x: offset)
            .onAppear {
                withAnimation(.easeInOut(duration: duration).repeatCount(3, autoreverses: true)) {
                    offset = intensity
                }
            }
    }
}

struct PulseModifier: ViewModifier {
    @State private var scale: CGFloat = 1.0
    
    let minScale: CGFloat
    let maxScale: CGFloat
    let duration: Double
    
    init(minScale: CGFloat = 0.95, maxScale: CGFloat = 1.05, duration: Double = 1.0) {
        self.minScale = minScale
        self.maxScale = maxScale
        self.duration = duration
    }
    
    func body(content: Content) -> some View {
        content
            .scaleEffect(scale)
            .onAppear {
                withAnimation(.easeInOut(duration: duration).repeatForever(autoreverses: true)) {
                    scale = maxScale
                }
            }
    }
}

// MARK: - View Extensions

extension View {
    func fadeIn(delay: Double = 0, duration: Double = 0.5) -> some View {
        modifier(FadeInModifier(delay: delay, duration: duration))
    }
    
    func slideIn(direction: SlideInModifier.SlideDirection = .fromBottom, delay: Double = 0, duration: Double = 0.5) -> some View {
        modifier(SlideInModifier(direction: direction, delay: delay, duration: duration))
    }
    
    func scaleIn(delay: Double = 0, duration: Double = 0.4) -> some View {
        modifier(ScaleInModifier(delay: delay, duration: duration))
    }
    
    func shake(intensity: CGFloat = 10, duration: Double = 0.5) -> some View {
        modifier(ShakeModifier(intensity: intensity, duration: duration))
    }
    
    func pulse(minScale: CGFloat = 0.95, maxScale: CGFloat = 1.05, duration: Double = 1.0) -> some View {
        modifier(PulseModifier(minScale: minScale, maxScale: maxScale, duration: duration))
    }
}
