// AuthView.swift
// MyChores
//
// Created on 2025-05-02.
//

import SwiftUI

/// Authentication container view that handles switching between sign in and sign up
struct AuthView: View {
    @State private var currentView: AuthViewType = .signIn
    
    enum AuthViewType {
        case signIn
        case signUp
        case forgotPassword
    }
    
    var body: some View {
        NavigationStack {
            Group {
                switch currentView {
                case .signIn:
                    SignInView(
                        onSignUpTapped: { currentView = .signUp },
                        onForgotPasswordTapped: { currentView = .forgotPassword }
                    )
                    
                case .signUp:
                    SignUpView(
                        onSignInTapped: { currentView = .signIn }
                    )
                    
                case .forgotPassword:
                    ForgotPasswordView(
                        onBackTapped: { currentView = .signIn }
                    )
                }
            }
            .transition(.opacity.combined(with: .move(edge: .trailing)))
            .animation(.easeInOut, value: currentView)
        }
    }
}

/// Sign in view for existing users
struct SignInView: View {
    @EnvironmentObject private var authViewModel: AuthViewModel
    
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var rememberMe: Bool = false
    @State private var isShowingError = false
    
    var onSignUpTapped: () -> Void
    var onForgotPasswordTapped: () -> Void
    
    var body: some View {
        ZStack {
            Theme.Colors.background.ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 24) {
                    // App logo and title
                    VStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 60))
                            .foregroundColor(Theme.Colors.primary)
                        
                        Text("MyChores")
                            .font(Theme.Typography.titleFontSystem)
                            .foregroundColor(Theme.Colors.text)
                        
                        Text("Welcome back!")
                            .font(Theme.Typography.bodyFontSystem)
                            .foregroundColor(Theme.Colors.textSecondary)
                    }
                    .padding(.vertical, 40)
                    
                    // Email field
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Email")
                            .font(Theme.Typography.captionFontSystem)
                            .foregroundColor(Theme.Colors.textSecondary)
                        
                        TextField("Enter your email", text: $email)
                            .keyboardType(.emailAddress)
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                            .padding()
                            .background(Theme.Colors.cardBackground)
                            .cornerRadius(Theme.Dimensions.cornerRadiusMedium)
                            .overlay(
                                RoundedRectangle(cornerRadius: Theme.Dimensions.cornerRadiusMedium)
                                    .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                            )
                    }
                    
                    // Password field
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Password")
                            .font(Theme.Typography.captionFontSystem)
                            .foregroundColor(Theme.Colors.textSecondary)
                        
                        SecureField("Enter your password", text: $password)
                            .padding()
                            .background(Theme.Colors.cardBackground)
                            .cornerRadius(Theme.Dimensions.cornerRadiusMedium)
                            .overlay(
                                RoundedRectangle(cornerRadius: Theme.Dimensions.cornerRadiusMedium)
                                    .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                            )
                    }
                    
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
                        }
                    }
                    
                    // Sign in button
                    Button(action: signIn) {
                        if authViewModel.isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle())
                                .tint(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                        } else {
                            Text("Sign In")
                                .font(Theme.Typography.bodyFontSystem.bold())
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                        }
                    }
                    .background(Theme.Colors.primary)
                    .cornerRadius(Theme.Dimensions.cornerRadiusMedium)
                    .disabled(email.isEmpty || password.isEmpty || authViewModel.isLoading)
                    .opacity(email.isEmpty || password.isEmpty || authViewModel.isLoading ? 0.7 : 1.0)
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

/// Custom checkbox toggle style
struct CheckboxToggleStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack {
            Image(systemName: configuration.isOn ? "checkmark.square.fill" : "square")
                .foregroundColor(configuration.isOn ? Theme.Colors.primary : Theme.Colors.textSecondary)
                .font(.system(size: 20, weight: .medium))
                .onTapGesture {
                    configuration.isOn.toggle()
                }
            
            configuration.label
        }
    }
}

/// Sign up view for new users
struct SignUpView: View {
    @EnvironmentObject private var authViewModel: AuthViewModel
    
    @State private var name: String = ""
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var confirmPassword: String = ""
    @State private var agreeToTerms: Bool = false
    @State private var passwordsMatch: Bool = true
    
    var onSignInTapped: () -> Void
    
    var body: some View {
        ZStack {
            Theme.Colors.background.ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 20) {
                    // App logo and title
                    VStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 60))
                            .foregroundColor(Theme.Colors.primary)
                        
                        Text("Create Account")
                            .font(Theme.Typography.titleFontSystem)
                            .foregroundColor(Theme.Colors.text)
                    }
                    .padding(.vertical, 24)
                    
                    // Name field
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Name")
                            .font(Theme.Typography.captionFontSystem)
                            .foregroundColor(Theme.Colors.textSecondary)
                        
                        TextField("Enter your name", text: $name)
                            .padding()
                            .background(Theme.Colors.cardBackground)
                            .cornerRadius(Theme.Dimensions.cornerRadiusMedium)
                            .overlay(
                                RoundedRectangle(cornerRadius: Theme.Dimensions.cornerRadiusMedium)
                                    .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                            )
                    }
                    
                    // Email field
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Email")
                            .font(Theme.Typography.captionFontSystem)
                            .foregroundColor(Theme.Colors.textSecondary)
                        
                        TextField("Enter your email", text: $email)
                            .keyboardType(.emailAddress)
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                            .padding()
                            .background(Theme.Colors.cardBackground)
                            .cornerRadius(Theme.Dimensions.cornerRadiusMedium)
                            .overlay(
                                RoundedRectangle(cornerRadius: Theme.Dimensions.cornerRadiusMedium)
                                    .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                            )
                    }
                    
                    // Password field
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Password")
                            .font(Theme.Typography.captionFontSystem)
                            .foregroundColor(Theme.Colors.textSecondary)
                        
                        SecureField("Create a password", text: $password)
                            .padding()
                            .background(Theme.Colors.cardBackground)
                            .cornerRadius(Theme.Dimensions.cornerRadiusMedium)
                            .overlay(
                                RoundedRectangle(cornerRadius: Theme.Dimensions.cornerRadiusMedium)
                                    .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                            )
                            .onChange(of: password) { _ in
                                validatePasswords()
                            }
                    }
                    
                    // Confirm password field
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Confirm Password")
                            .font(Theme.Typography.captionFontSystem)
                            .foregroundColor(Theme.Colors.textSecondary)
                        
                        SecureField("Confirm your password", text: $confirmPassword)
                            .padding()
                            .background(Theme.Colors.cardBackground)
                            .cornerRadius(Theme.Dimensions.cornerRadiusMedium)
                            .overlay(
                                RoundedRectangle(cornerRadius: Theme.Dimensions.cornerRadiusMedium)
                                    .stroke(passwordsMatch ? Color.gray.opacity(0.2) : Theme.Colors.error, lineWidth: 1)
                            )
                            .onChange(of: confirmPassword) { _ in
                                validatePasswords()
                            }
                        
                        if !passwordsMatch {
                            Text("Passwords don't match")
                                .font(Theme.Typography.captionFontSystem)
                                .foregroundColor(Theme.Colors.error)
                        }
                    }
                    
                    // Terms and conditions
                    Toggle(isOn: $agreeToTerms) {
                        Text("I agree to the Terms and Conditions")
                            .font(Theme.Typography.captionFontSystem)
                            .foregroundColor(Theme.Colors.textSecondary)
                    }
                    .toggleStyle(CheckboxToggleStyle())
                    
                    // Sign up button
                    Button(action: signUp) {
                        if authViewModel.isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle())
                                .tint(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                        } else {
                            Text("Create Account")
                                .font(Theme.Typography.bodyFontSystem.bold())
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                        }
                    }
                    .background(Theme.Colors.primary)
                    .cornerRadius(Theme.Dimensions.cornerRadiusMedium)
                    .disabled(!isFormValid() || authViewModel.isLoading)
                    .opacity(!isFormValid() || authViewModel.isLoading ? 0.7 : 1.0)
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

/// Forgot password view
struct ForgotPasswordView: View {
    @EnvironmentObject private var authViewModel: AuthViewModel
    
    @State private var email: String = ""
    @State private var resetSent = false
    
    var onBackTapped: () -> Void
    
    var body: some View {
        ZStack {
            Theme.Colors.background.ignoresSafeArea()
            
            VStack(spacing: 24) {
                // Title
                VStack(spacing: 8) {
                    Image(systemName: "lock.rotation")
                        .font(.system(size: 60))
                        .foregroundColor(Theme.Colors.primary)
                    
                    Text("Reset Password")
                        .font(Theme.Typography.titleFontSystem)
                        .foregroundColor(Theme.Colors.text)
                    
                    Text("Enter your email to receive reset instructions")
                        .font(Theme.Typography.captionFontSystem)
                        .foregroundColor(Theme.Colors.textSecondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.vertical, 40)
                
                if resetSent {
                    // Success message
                    VStack(spacing: 16) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 40))
                            .foregroundColor(Theme.Colors.success)
                        
                        Text("Reset Link Sent")
                            .font(Theme.Typography.subheadingFontSystem)
                            .foregroundColor(Theme.Colors.text)
                        
                        Text("Check your email for instructions to reset your password")
                            .font(Theme.Typography.bodyFontSystem)
                            .foregroundColor(Theme.Colors.textSecondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 24)
                } else {
                    // Email field
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Email")
                            .font(Theme.Typography.captionFontSystem)
                            .foregroundColor(Theme.Colors.textSecondary)
                        
                        TextField("Enter your email", text: $email)
                            .keyboardType(.emailAddress)
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                            .padding()
                            .background(Theme.Colors.cardBackground)
                            .cornerRadius(Theme.Dimensions.cornerRadiusMedium)
                            .overlay(
                                RoundedRectangle(cornerRadius: Theme.Dimensions.cornerRadiusMedium)
                                    .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                            )
                    }
                    .padding(.horizontal, 24)
                    
                    // Reset password button
                    Button(action: resetPassword) {
                        if authViewModel.isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle())
                                .tint(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                        } else {
                            Text("Send Reset Link")
                                .font(Theme.Typography.bodyFontSystem.bold())
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                        }
                    }
                    .background(Theme.Colors.primary)
                    .cornerRadius(Theme.Dimensions.cornerRadiusMedium)
                    .disabled(email.isEmpty || authViewModel.isLoading)
                    .opacity(email.isEmpty || authViewModel.isLoading ? 0.7 : 1.0)
                    .padding(.horizontal, 24)
                    .padding(.top, 16)
                }
                
                // Back button
                Button(action: onBackTapped) {
                    HStack {
                        Image(systemName: "chevron.left")
                        Text("Back to Sign In")
                    }
                    .font(Theme.Typography.captionFontSystem.bold())
                    .foregroundColor(Theme.Colors.primary)
                }
                .padding(.top, 16)
                
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
                    resetSent = true
                } else {
                    // Error will be shown via authViewModel.errorMessage
                    print("Reset password failed: \(error?.localizedDescription ?? "Unknown error")")
                }
            }
        }
    }
}

#Preview {
    AuthView()
        .environmentObject(AuthViewModel())
}
