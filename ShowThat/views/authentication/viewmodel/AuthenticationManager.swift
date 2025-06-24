//
//  AuthenticationManager.swift
//  ShowThat
//
//  Created by Giuseppe De Masi on 24/06/2025.
//

import Foundation
import FirebaseFirestore
import FirebaseAuth

class AuthenticationManager: ObservableObject {
    @Published var isLoading = false
    
    func signIn(email: String, password: String) async throws {
        isLoading = true
        defer { isLoading = false }
        
        try await Auth.auth().signIn(withEmail: email, password: password)
    }
    
    func signUp(email: String, password: String, displayName: String) async throws {
        isLoading = true
        defer { isLoading = false }
        
        let result = try await Auth.auth().createUser(withEmail: email, password: password)
        
        // update display name
        let changeRequest = result.user.createProfileChangeRequest()
        changeRequest.displayName = displayName
        try await changeRequest.commitChanges()
        
        // create user profile
        let userProfile = UserProfile(
            email: email,
            displayName: displayName,
            subscription: UserSubscription(
                tier: .free,
                isActive: true
            )
        )
        
        let db = Firestore.firestore()
        _ = db.collection("users")
            .document(result.user.uid)
            .setData(from: userProfile)
    }
    
    func signInWithGoogle() {
        // to be done
    }
    
    func signInWithApple() {
        // to be done
    }
}
