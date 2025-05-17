// ForgotPasswordView.swift
// MyChores
//
// Created on 2025-05-16.
//

import SwiftUI

/// Forgot password view
struct ForgotPasswordView: View {
    @EnvironmentObject private var authViewModel: AuthViewModel
    
    @State private var email: String = ""
    @State private var resetSent = false
    
    // Animation states
    @State private var headerAppeared = false
    @State private var contentAppeared = false
    @State private var buttonAppeared = false
    
    var onBackTapped: () -> Void
    
    var body: some View {
        ZStack {
            // Background with subtle gradient overlay
            Theme.Colors.background.ignoresSafeArea()
                .overlay(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Theme.Colors.accent.opacity(0.05),
                            Theme.Colors.background
                        ]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
            
            VStack(spacing: 24) {
                // Title with animation
                VStack(spacing: 12) {
                    Image(systemName: "lock.rotation")
                        .font(.system(size: 60))
                        .foregroundColor(Theme.Colors.primary)
                        .background(
                            Circle()
                                .fill(Theme.Colors.primary.opacity(0.1))
                                .frame(width: 100, height: 100)
                        )
                        .scaleEffect(headerAppeared ? 1.0 : 0.5)
                        .opacity(headerAppeared ? 1.0 : 0.0)
                    
                    Text("Reset Password")
                        .font(Theme.Typography.titleFontSystem)
                        .foregroundColor(Theme.Colors.text)
                        .opacity(headerAppeared ? 1.0 : 0.0)
                        .offset(y: headerAppeared ? 0 : 10)
                    
                    Text("Enter your email to receive reset instructions")
                        .font(Theme.Typography.captionFontSystem)
                        .foregroundColor(Theme.Colors.textSecondary)
                        .multilineTextAlignment(.center)
                        .opacity(headerAppeared ? 0.8 : 0.0)
                        .offset(y: headerAppeared ? 0 : 10)
                }
                .padding(.vertical, 40)
                .onAppear {
                    withAnimation(.spring(response: 0.6, dampingFraction: 0.8, blendDuration: 0).delay(0.1)) {
                        headerAppeared = true
                    }
                    withAnimation(.easeOut(duration: 0.5).delay(0.3)) {
                        contentAppeared = true
                    }
                    withAnimation(.easeOut(duration: 0.5).delay(0.5)) {
                        buttonAppeared = true
                    }
                }
                
                if resetSent {
                    // Success message with animation
                    VStack(spacing: 20) {
                        ZStack {
                            Circle()
                                .fill(Theme.Colors.success.opacity(0.1))
                                .frame(width: 80, height: 80)
                            
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 40))
                                .foregroundColor(Theme.Colors.success)
                        }
                        .scaleEffect(contentAppeared ? 1.0 : 0.5)
                        .opacity(contentAppeared ? 1.0 : 0.0)
                        
                        Text("Reset Link Sent")
                            .font(Theme.Typography.subheadingFontSystem)
                            .foregroundColor(Theme.Colors.text)
                            .opacity(contentAppeared ? 1.0 : 0.0)
                            .offset(y: contentAppeared ? 0 : 10)
                        
                        Text("Check your email for instructions to reset your password")
                            .font(Theme.Typography.bodyFontSystem)
                            .foregroundColor(Theme.Colors.textSecondary)
                            .multilineTextAlignment(.center)
                            .opacity(contentAppeared ? 0.8 : 0.0)
                            .offset(y: contentAppeared ? 0 : 10)
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 24)
                } else {
                    // Email field with animation
                    VStack(alignment: .leading, spacing: 12) {
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
                    .padding(.horizontal, 24)
                    .opacity(contentAppeared ? 1.0 : 0.0)
                    .offset(y: contentAppeared ? 0 : 20)
                    
                    // Reset password button with animation
                    Button(action: resetPassword) {
                        if authViewModel.isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle())
                                .tint(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                        } else {
                            HStack {
                                Text("Send Reset Link")
                                    .font(Theme.Typography.bodyFontSystem.bold())
                                    .foregroundColor(.white)
                                
                                Image(systemName: "envelope.arrow.triangle.branch")
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
                    .disabled(email.isEmpty || authViewModel.isLoading)
                    .opacity(buttonAppeared ? (email.isEmpty || authViewModel.isLoading ? 0.7 : 1.0) : 0.0)
                    .offset(y: buttonAppeared ? 0 : 20)
                    .padding(.horizontal, 24)
                    .padding(.top, 24)
                }
                
                // Back button with animation
                Button(action: onBackTapped) {
                    HStack {
                        Image(systemName: "arrow.left")
                            .font(.system(size: 14))
                            .foregroundColor(Theme.Colors.primary)
                        
                        Text("Back to Sign In")
                            .font(Theme.Typography.captionFontSystem)
                            .foregroundColor(Theme.Colors.primary)
                    }
                }
                .padding(.top, 16)
                .opacity(buttonAppeared ? 1.0 : 0.0)
                .offset(y: buttonAppeared ? 0 : 20)
                
                Spacer()
            }
            .padding(.vertical, 16)
        }
        .alert(
            "Reset Failed",
            isPresented: .init(
                get: { authViewModel.errorMessage != nil },
                set: { if !$0 { authViewModel.errorMessage = nil } }
            ),
            actions: { Button("OK", role: .cancel) {} },
            message: { Text(authViewModel.errorMessage ?? "") }
        )
    }
    
    private func resetPassword() {
        guard !email.isEmpty else { return }
        
        Task {
            await authViewModel.resetPassword(for: email) { success, error in
                if success {
                    withAnimation {
                        resetSent = true
                    }
                }
            }
        }
    }
}

#Preview {
    ForgotPasswordView(
        onBackTapped: {}
    )
    .environmentObject(AuthViewModel())
}
