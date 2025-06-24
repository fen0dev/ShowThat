//
//  AuthenticationView.swift
//  ShowThat
//
//  Created by Giuseppe De Masi on 24/06/2025.
//

import SwiftUI
import FirebaseAuth

struct AuthenticationView: View {
    @StateObject private var authManager = AuthenticationManager()
    @State private var isSignUp = false
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var displayName = ""
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var isLoading = false
    var body: some View {
        ZStack {
            // background
            AnimatedGradientBackground()
            
            ScrollView {
                VStack(spacing: 30) {
                    // logo and title
                    VStack(spacing: 20) {
                        Image(systemName: "qrcode.viewfinder")
                            .font(.system(size: 80, weight: .bold, design: .rounded))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.purple, .blue],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .shadow(color: .purple.opacity(0.3), radius: 20)
                        
                        Text("ShowThat")
                            .font(.system(size: 48, weight: .bold, design: .rounded))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.white, .white.opacity(0.8)],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                        
                        Text("Business QR Studio")
                            .font(.title3)
                            .foregroundColor(.white.opacity(0.8))
                    }
                    .padding(.top, 60)
                    
                    // auth form
                    VStack(spacing: 20) {
                        // Toggle between Sign In and Sign Up
                        Picker("", selection: $isSignUp) {
                            Text("Sign In").tag(false)
                            Text("Sign Up").tag(true)
                        }
                        .pickerStyle(SegmentedPickerStyle())
                        .padding(.horizontal)
                        
                        // form fields
                        VStack(spacing: 15) {
                            if isSignUp {
                                CustomTextField(
                                    placeholder: "Display Name",
                                    text: $displayName,
                                    icon: "person.fill"
                                )
                                .textContentType(.name)
                            }
                            
                            CustomTextField(
                                placeholder: "email@example.here",
                                text: $email,
                                icon: "envelope"
                            )
                            .textContentType(.emailAddress)
                            .keyboardType(.emailAddress)
                            .textInputAutocapitalization(.never)
                            
                            CustomSecureTextField(
                                placeholder: "Password",
                                text: $password,
                                icon: "lock.fill"
                            )
                            .textContentType(isSignUp ? .newPassword : .password)
                            
                            if isSignUp {
                                CustomSecureTextField(
                                    placeholder: "Confirm Password",
                                    text: $confirmPassword,
                                    icon: "lock.fill"
                                )
                                .textContentType(.newPassword)
                            }
                        }
                        .padding(.horizontal)
                        
                        // action btn
                        Button(action: { authenticate() }) {
                            HStack {
                                if isLoading {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle())
                                        .tint(.white)
                                        .scaleEffect(0.8)
                                } else {
                                    Text(isSignUp ? "Create Account" : "Sign In")
                                        .fontWeight(.semibold)

                                    Image(systemName: isSignUp ? "person.badge.plus" : "arrow.right.circle.fill")
                                }
                            }
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical)
                            .background {
                                LinearGradient(
                                    colors: [.purple, .blue],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            }
                            .cornerRadius(15)
                            .shadow(color: .purple.opacity(0.3), radius: 10, y: 5)
                        }
                        .padding(.horizontal)
                        .disabled(isLoading || !isFormValid)
                        .opacity(isFormValid ? 1 : 0.6)
                        
                        // alternative options for log in
                        VStack(spacing: 15) {
                            // divider
                            HStack {
                                Rectangle()
                                    .fill(.white.opacity(0.3))
                                    .frame(height: 1)
                                
                                Text("OR")
                                    .font(.caption)
                                    .foregroundStyle(.white.opacity(0.6))
                                    .padding(.horizontal, 10)
                                
                                Rectangle()
                                    .fill(.white.opacity(0.3))
                                    .frame(height: 1)
                            }
                            .padding(.horizontal)
                            
                            // sign in with social buttons
                            VStack(spacing: 12) {
                                SocialSignInButton(
                                    provider: "Google",
                                    icon: "globe",
                                    action: { authManager.signInWithGoogle() }
                                )
                                
                                SocialSignInButton(
                                    provider: "Apple",
                                    icon: "apple.logo",
                                    action: { authManager.signInWithApple() }
                                )
                            }
                            .padding(.horizontal)
                        }
                        .padding(.top, 10)
                        
                        // footer links
                        VStack(spacing: 15) {
                            if !isSignUp {
                                Button("Forgot Password?") {
                                    // implement pass reset
                                }
                                .font(.footnote)
                                .foregroundStyle(.white.opacity(0.7))
                            }
                            
                            HStack {
                                Text(isSignUp ? "Already have an account?" : "Don't have an account?")
                                    .font(.footnote)
                                    .foregroundStyle(.white.opacity(0.6))
                                
                                Button(isSignUp ? "Sign In" : "Sign Up") {
                                    withAnimation(.spring(duration: 0.3)) {
                                        isSignUp.toggle()
                                    }
                                }
                                .font(.footnote.bold())
                                .foregroundStyle(.white)
                            }
                        }
                        .padding(.bottom, 40)
                    }
                }
            }
        }
        .alert("Error", isPresented: $showError) {
            Button("OK") { }
        } message: {
            Text(errorMessage)
        }
    }
    
    var isFormValid: Bool {
        if isSignUp {
            return !email.isEmpty &&
            !password.isEmpty &&
            !displayName.isEmpty &&
            password == confirmPassword &&
            password.count >= 6
        } else {
            return !email.isEmpty && !password.isEmpty
        }
    }
    
    // MARK: - Authentication
    
    private func authenticate() {
        Task {
            isLoading = true
            
            do {
                if isSignUp {
                    try await authManager.signUp(
                        email: email,
                        password: password,
                        displayName: displayName
                    )
                } else {
                    try await authManager.signIn(
                        email: email,
                        password: password
                    )
                }
            } catch {
                errorMessage = error.localizedDescription
                showError = true
            }
            
            isLoading = false
        }
    }
}

#Preview {
    AuthenticationView()
}
