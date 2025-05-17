// SignInView.swift
// MyChores
//
// Created on 2025-05-16.
//

import SwiftUI

/// Sign in view for existing users
struct SignInView: View {
    @EnvironmentObject private var authViewModel: AuthViewModel
    
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var rememberMe: Bool = false
    @State private var isShowingError = false
    
    // Animation states
    @State private var logoAppeared = false
    @State private var fieldsAppeared = false
    @State private var buttonAppeared = false
    
    var onSignUpTapped: () -> Void
    var onForgotPasswordTapped: () -> Void
    
    var body: some View {
        ZStack {
            // Background with subtle gradient overlay
            Theme.Colors.background.ignoresSafeArea()
                .overlay(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Theme.Colors.primary.opacity(0.05),
                            Theme.Colors.background
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            
            ScrollView {
                VStack(spacing: 24) {
                    // App logo and title with animation
                    VStack(spacing: 12) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 70))
                            .foregroundColor(Theme.Colors.primary)
                            .background(
                                Circle()
                                    .fill(Theme.Colors.primary.opacity(0.1))
                                    .frame(width: 100, height: 100)
                            )
                            .scaleEffect(logoAppeared ? 1.0 : 0.5)
                            .opacity(logoAppeared ? 1.0 : 0.0)
                        
                        Text("MyChores")
                            .font(Theme.Typography.titleFontSystem)
                            .foregroundColor(Theme.Colors.text)
                            .opacity(logoAppeared ? 1.0 : 0.0)
                            .offset(y: logoAppeared ? 0 : 10)
                        
                        Text("Welcome back!")
                            .font(Theme.Typography.bodyFontSystem)
                            .foregroundColor(Theme.Colors.textSecondary)
                            .opacity(logoAppeared ? 1.0 : 0.0)
                            .offset(y: logoAppeared ? 0 : 10)
                    }
                    .padding(.vertical, 40)
                    .onAppear {
                        withAnimation(.spring(response: 0.6, dampingFraction: 0.8, blendDuration: 0).delay(0.1)) {
                            logoAppeared = true
                        }
                        withAnimation(.easeOut(duration: 0.5).delay(0.3)) {
                            fieldsAppeared = true
                        }
                        withAnimation(.easeOut(duration: 0.5).delay(0.5)) {
                            buttonAppeared = true
                        }
                    }
                    
                    // Email and password fields with animation
                    VStack(spacing: 20) {
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
                                
                                SecureField("Enter your password", text: $password)
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
                    }
                    .opacity(fieldsAppeared ? 1.0 : 0.0)
                    .offset(y: fieldsAppeared ? 0 : 20)
                    
                    // Remember me and forgot password row
                    HStack {
                        Toggle("Remember me", isOn: $rememberMe)
                            .font(Theme.Typography.captionFontSystem)
                            .foregroundColor(Theme.Colors.textSecondary)
                            .toggleStyle(CheckboxToggleStyle())
                        
                        Spacer()
                        
                        Button(action: onForgotPasswordTapped) {
                            Text("Forgot Password?")
                                .font(Theme.Typography.captionFontSystem)
                                .foregroundColor(Theme.Colors.primary)
                                .underline()
                        }
                    }
                    .opacity(fieldsAppeared ? 1.0 : 0.0)
                    .offset(y: fieldsAppeared ? 0 : 20)
                    
                    // Sign in button with animation
                    Button(action: signIn) {
                        if authViewModel.isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle())
                                .tint(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                        } else {
                            HStack {
                                Text("Sign In")
                                    .font(Theme.Typography.bodyFontSystem.bold())
                                    .foregroundColor(.white)
                                
                                Image(systemName: "arrow.right")
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
                    .disabled(email.isEmpty || password.isEmpty || authViewModel.isLoading)
                    .opacity(buttonAppeared ? (email.isEmpty || password.isEmpty || authViewModel.isLoading ? 0.7 : 1.0) : 0.0)
                    .offset(y: buttonAppeared ? 0 : 20)
                    .padding(.top, 16)
                    
                    // Sign up link
                    HStack {
                        Text("Don't have an account?")
                            .font(Theme.Typography.captionFontSystem)
                            .foregroundColor(Theme.Colors.textSecondary)
                        
                        Button(action: onSignUpTapped) {
                            Text("Sign Up")
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
            "Sign In Failed",
            isPresented: .init(
                get: { authViewModel.errorMessage != nil },
                set: { if !$0 { authViewModel.errorMessage = nil } }
            ),
            actions: { Button("OK", role: .cancel) {} },
            message: { Text(authViewModel.errorMessage ?? "") }
        )
    }
    
    private func signIn() {
        Task {
            await authViewModel.signIn(email: email, password: password) { success, error in
                // Navigation will happen automatically through the MainView when auth state changes
                if !success {
                    print("Sign in failed: \(error?.localizedDescription ?? "Unknown error")")
                }
            }
        }
    }
}

#Preview {
    SignInView(
        onSignUpTapped: {},
        onForgotPasswordTapped: {}
    )
    .environmentObject(AuthViewModel())
}
