//
//  InteractiveElement.swift
//  ShowThat
//
//  Created by Giuseppe De Masi on 16/10/2025.
//

import SwiftUI

struct InteractiveElementView: View {
    let element: OnboardingStep.InteractiveElement
    
    var body: some View {
        Button(action: element.action) {
            HStack {
                Text(element.title)
                    .font(.headline)
                    .foregroundColor(.white)
                
                Spacer()
                
                Image(systemName: "arrow.right")
                    .foregroundColor(.white.opacity(0.7))
            }
            .padding()
            .background(.ultraThinMaterial)
            .cornerRadius(15)
        }
        .buttonStyle(.plain)
    }
}
