//
//  SocialSignInButton.swift
//  ShowThat
//
//  Created by Giuseppe De Masi on 24/06/2025.
//

import SwiftUI

struct SocialSignInButton: View {
    let provider: String
    let icon: String
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .font(.title3.bold())
                
                Text("Continue with \(provider)")
                    .fontWeight(.semibold)
                
                Spacer()
            }
            .foregroundStyle(.black)
            .padding()
            .background(.white, in: RoundedRectangle(cornerRadius: 12))
        }
    }
}

#Preview {
    SocialSignInButton(provider: "Apple", icon: "apple.logo", action: {})
}
