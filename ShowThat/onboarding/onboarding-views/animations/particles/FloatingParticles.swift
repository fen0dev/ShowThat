//
//  FloatingParticles.swift
//  ShowThat
//
//  Created by Giuseppe De Masi on 17/10/2025.
//

import SwiftUI

struct FloatingParticles: View {
    let delay: Double
    @State private var position: CGPoint = .zero
    @State private var opacity: Double = 0
    
    var body: some View {
        Circle()
            .fill(Color.white.opacity(0.05))  // Much more subtle particles
            .frame(width: 3, height: 3)       // Slightly smaller
            .position(position)
            .opacity(opacity)
            .onAppear {
                let screenSize = UIScreen.main.bounds.size
                position = CGPoint(
                    x: CGFloat.random(in: 0...screenSize.width),
                    y: CGFloat.random(in: 0...screenSize.height)
                )
                
                withAnimation(.easeInOut(duration: 3.0).delay(delay).repeatForever()) {
                    opacity = Double.random(in: 0.1...0.3)  // Lower opacity range
                    position.x += CGFloat.random(in: -30...30)
                    position.y += CGFloat.random(in: -30...30)
                }
            }
    }
}

#Preview {
    FloatingParticles(
        delay: 0.175
    )
}
