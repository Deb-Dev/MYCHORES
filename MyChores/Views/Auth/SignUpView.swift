// SignUpView.swift
// MyChores
//
// Created on 2025-05-16.
//

import SwiftUI

/// Sign up view for new users
struct SignUpView: View {
    @EnvironmentObject private var authViewModel: AuthViewModel
    
    @State private var name: String = ""
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var confirmPassword: String = ""
    @State private var agreeToTerms: Bool = false
    @State private var passwordsMatch: Bool = true
    
    // Animation states
    @State private var headerAppeared = false
    @State private var fieldsAppeared = false
    @State private var buttonAppeared = false
    
    var onSignInTapped: () -> Void
    
    var body: some View {
        ZStack {
            // Background with subtle gradient overlay
            Theme.Colors.background.ignoresSafeArea()
                .overlay(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Theme.Colors.secondary.opacity(0.05),
                            Theme.Colors.background
                        ]),
                        startPoint: .topTrailing,
                        endPoint: .bottomLeading
                    )
                )
            
            ScrollView {
                VStack(spacing: 20) {
                    // App logo and title with animation
                    VStack(spacing: 12) {
                        Image(systemName: "person.crop.circle.badge.plus")
                            .font(.system(size: 60))
                            .foregroundColor(Theme.Colors.primary)
                            .background(
                                Circle()
                                    .fill(Theme.Colors.primary.opacity(0.1))
                                    .frame(width: 100, height: 100)
                            )
                            .scaleEffect(headerAppeared ? 1.0 : 0.5)
                            .opacity(headerAppeared ? 1.0 : 0.0)
                        
                        Text("Create Account")
                            .font(Theme.Typography.titleFontSystem)
                            .foregroundColor(Theme.Colors.text)
                            .opacity(headerAppeared ? 1.0 : 0.0)
                            .offset(y: headerAppeared ? 0 : 10)
                        
                        Text("Join MyChores and start organizing")
                            .font(Theme.Typography.bodyFontSystem)
                            .foregroundColor(Theme.Colors.textSecondary)
                            .multilineTextAlignment(.center)
                            .opacity(headerAppeared ? 1.0 : 0.0)
                            .offset(y: headerAppeared ? 0 : 10)
                    }
                    .padding(.vertical, 24)
                    .onAppear {
                        withAnimation(.spring(response: 0.6, dampingFraction: 0.8, blendDuration: 0).delay(0.1)) {
                            headerAppeared = true
                        }
                        withAnimation(.easeOut(duration: 0.5).delay(0.3)) {
                            fieldsAppeared = true
                        }
                        withAnimation(.easeOut(duration: 0.5).delay(0.5)) {
                            buttonAppeared = true
                        }
                    }
                    
                    // Form fields with animation
                    VStack(spacing: 16) {
                        // Name field
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Name")
                                .font(Theme.Typography.captionFontSystem)
                                .foregroundColor(Theme.Colors.textSecondary)
                            
                            HStack {
                                Image(systemName: "person.fill")
                                    .foregroundColor(Theme.Colors.primary.opacity(0.7))
                                    .font(.system(size: 16))
                                    .frame(width: 24)
                                
                                TextField("Enter your name", text: $name)
                            }
                            .padding()
                            .background(Theme.Colors.cardBackground)
                            .cornerRadius(Theme.Dimensions.cornerRadiusMedium)
                            .overlay(
                                RoundedRectangle(cornerRadius: Theme.Dimensions.cornerRadiusMedium)
                                    .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                            )
                            .shadow(color: Color.black.opacity(0.03), radius: 8, x: 0, y: 4)
                        }
                        
                        // Email field
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Email")
                                .font(Theme.Typography.captionFontSystem)
                                .foregroundColor(Theme.Colors.textSecondary)
                            
                            HStack {
                                Image(systemName: "envelope.fill")
                                    .foregroundColor(Theme.Colors.primary.opacity(0.7))
                                    .font(.system(size: 16))
                                    .frame(width: 24)
                                
                                TextField("Enter your email", text: $email)
                                    .keyboardType(.emailAddress)
                                    .autocapitalization(.none)
                                    .disableAutocorrection(true)
                            }
                            .padding()
                            .background(Theme.Colors.cardBackground)
                            .cornerRadius(Theme.Dimensions.cornerRadiusMedium)
                            .overlay(
                                RoundedRectangle(cornerRadius: Theme.Dimensions.cornerRadiusMedium)
                                    .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                            )
                            .shadow(color: Color.black.opacity(0.03), radius: 8, x: 0, y: 4)
                        }
                        
                        // Password field
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Password")
                                .font(Theme.Typography.captionFontSystem)
                                .foregroundColor(Theme.Colors.textSecondary)
                            
                            HStack {
                                Image(systemName: "lock.fill")
                                    .foregroundColor(Theme.Colors.primary.opacity(0.7))
                                    .font(.system(size: 16))
                                    .frame(width: 24)
                                
                                SecureField("Create a password", text: $password)
                            }
                            .padding()
                            .background(Theme.Colors.cardBackground)
                            .cornerRadius(Theme.Dimensions.cornerRadiusMedium)
                            .overlay(
                                RoundedRectangle(cornerRadius: Theme.Dimensions.cornerRadiusMedium)
                                    .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                            )
                            .shadow(color: Color.black.opacity(0.03), radius: 8, x: 0, y: 4)
                            .onChange(of: password) { _ in
                                validatePasswords()
                            }
                        }
                        
                        // Confirm password field
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Confirm Password")
                                .font(Theme.Typography.captionFontSystem)
                                .foregroundColor(Theme.Colors.textSecondary)
                            
                            HStack {
                                Image(systemName: "lock.shield.fill")
                                    .foregroundColor(Theme.Colors.primary.opacity(0.7))
                                    .font(.system(size: 16))
                                    .frame(width: 24)
                                
                                SecureField("Confirm your password", text: $confirmPassword)
                            }
                            .padding()
                            .background(Theme.Colors.cardBackground)
                            .cornerRadius(Theme.Dimensions.cornerRadiusMedium)
                            .overlay(
                                RoundedRectangle(cornerRadius: Theme.Dimensions.cornerRadiusMedium)
                                    .stroke(passwordsMatch ? Color.gray.opacity(0.2) : Theme.Colors.error, lineWidth: 1)
                            )
                            .shadow(color: Color.black.opacity(0.03), radius: 8, x: 0, y: 4)
                            .onChange(of: confirmPassword) { _ in
                                validatePasswords()
                            }
                            
                            if !passwordsMatch {
                                HStack {
                                    Image(systemName: "exclamationmark.triangle.fill")
                                        .foregroundColor(Theme.Colors.error)
                                        .font(.system(size: 12))
                                    
                                    Text("Passwords don't match")
                                        .font(Theme.Typography.captionFontSystem)
                                        .foregroundColor(Theme.Colors.error)
                                }
                                .padding(.top, 4)
                                .transition(.opacity)
                            }
                        }
                    }
                    .opacity(fieldsAppeared ? 1.0 : 0.0)
                    .offset(y: fieldsAppeared ? 0 : 20)
                    
                    // Terms and conditions with animation
                    Toggle(isOn: $agreeToTerms) {
                        HStack {
                            Text("I agree to the ")
                                .font(Theme.Typography.captionFontSystem)
                                .foregroundColor(Theme.Colors.textSecondary)
                            
                            Text("Terms and Conditions")
                                .font(Theme.Typography.captionFontSystem.bold())
                                .foregroundColor(Theme.Colors.primary)
                                .underline()
                        }
                    }
                    .toggleStyle(CheckboxToggleStyle())
                    .padding(.top, 8)
                    .opacity(fieldsAppeared ? 1.0 : 0.0)
                    .offset(y: fieldsAppeared ? 0 : 20)
                    
                    // Sign up button with animation
                    Button(action: signUp) {
                        if authViewModel.isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle())
                                .tint(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                        } else {
                            HStack {
                                Text("Create Account")
                                    .font(Theme.Typography.bodyFontSystem.bold())
                                    .foregroundColor(.white)
                                
                                Image(systemName: "checkmark.circle")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.white)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                        }
                    }
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [Theme.Colors.primary, Theme.Colors.primary.opacity(0.8)]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .cornerRadius(Theme.Dimensions.cornerRadiusMedium)
                    .shadow(color: Theme.Colors.primary.opacity(0.3), radius: 10, x: 0, y: 5)
                    .disabled(!isFormValid() || authViewModel.isLoading)
                    .opacity(buttonAppeared ? (!isFormValid() || authViewModel.isLoading ? 0.7 : 1.0) : 0.0)
                    .offset(y: buttonAppeared ? 0 : 20)
                    .padding(.top, 16)
                    
                    // Sign in link
                    HStack {
                        Text("Already have an account?")
                            .font(Theme.Typography.captionFontSystem)
                            .foregroundColor(Theme.Colors.textSecondary)
                        
                        Button(action: onSignInTapped) {
                            Text("Sign In")
                                .font(Theme.Typography.captionFontSystem.bold())
                                .foregroundColor(Theme.Colors.primary)
                        }
                    }
                    .padding(.top, 16)
                    .opacity(buttonAppeared ? 1.0 : 0.0)
                    .offset(y: buttonAppeared ? 0 : 20)
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 16)
            }
        }
        .alert(
            "Sign Up Failed",
            isPresented: .init(
                get: { authViewModel.errorMessage != nil },
                set: { if !$0 { authViewModel.errorMessage = nil } }
            ),
            actions: { Button("OK", role: .cancel) {} },
            message: { Text(authViewModel.errorMessage ?? "") }
        )
    }
    
    private func validatePasswords() {
        if confirmPassword.isEmpty {
            passwordsMatch = true
        } else {
            passwordsMatch = password == confirmPassword
        }
    }
    
    private func isFormValid() -> Bool {
        return !name.isEmpty && 
               !email.isEmpty && 
               !password.isEmpty && 
               password.count >= 6 && 
               passwordsMatch && 
               (!confirmPassword.isEmpty && confirmPassword == password) && 
               agreeToTerms
    }
    
    private func signUp() {
        if isFormValid() {
            Task {
                await authViewModel.signUp(name: name, email: email, password: password) { success, error in
                    // Navigation will happen automatically through the MainView when auth state changes
                    if !success {
                        print("Sign up failed: \(error?.localizedDescription ?? "Unknown error")")
                    }
                }
            }
        }
    }
}

#Preview {
    SignUpView(
        onSignInTapped: {}
    )
    .environmentObject(AuthViewModel())
}
