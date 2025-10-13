//
//  ErrorHandlingModifier.swift
//  ShowThat
//
//  Created by Giuseppe De Masi on 30/09/2025.
//

import SwiftUI

struct ErrorHandlingModifier: ViewModifier {
    @EnvironmentObject var errorManager: ErrorManager
    
    func body(content: Content) -> some View {
        content
            .alert("Error", isPresented: $errorManager.isShowingError) {
                Button("OK") {
                    errorManager.clearError()
                }
                
                if let error = errorManager.currentError, error.canRetry {
                    Button("Try Again") {
                        errorManager.clearError()
                    }
                }
            } message: {
                if let error = errorManager.currentError {
                    Text(error.localizedDescription)
                }
            }
    }
}

extension View {
    func withErrorHandling() -> some View {
        modifier(ErrorHandlingModifier())
    }
}
