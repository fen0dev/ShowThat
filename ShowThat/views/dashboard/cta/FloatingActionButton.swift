//
//  FloatingActionButton.swift
//  ShowThat
//
//  Created by Giuseppe De Masi on 25/06/2025.
//

import SwiftUI

struct FloatingActionButton: View {
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            Image(systemName: "plus")
                .font(.title2.bold())
                .foregroundStyle(.white)
                .frame(width: 60, height: 60)
                .background {
                    LinearGradient(
                        colors: [
                            .blue, .purple
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                }
                .clipShape(.circle)
                .shadow(color: .purple.opacity(0.3), radius: 10, y: 5)
        }
    }
}

#Preview {
    FloatingActionButton(action: {})
}
