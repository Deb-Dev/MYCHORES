// AuthView.swift
// MyChores
//
// Created on 2025-05-02.
//

import SwiftUI

/// Authentication container view that handles switching between sign in and sign up
struct AuthView: View {
    @State private var currentView: AuthViewType = .signIn
    @State private var slideDirection: SlideDirection = .right
    
    enum AuthViewType {
        case signIn
        case signUp
        case forgotPassword
    }
    
    enum SlideDirection {
        case left
        case right
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Add a subtle background pattern
                Color.white
                    .overlay(
                        Image(systemName: "checkmark.circle")
                            .font(.system(size: 200))
                            .foregroundColor(Theme.Colors.primary.opacity(0.03))
                            .rotationEffect(Angle(degrees: -15))
                            .offset(x: 50, y: -200)
                    )
                    .ignoresSafeArea()
                
                // Current auth view
                Group {
                    switch currentView {
                    case .signIn:
                        SignInView(
                            onSignUpTapped: {
                                slideDirection = .left
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    currentView = .signUp
                                }
                            },
                            onForgotPasswordTapped: {
                                slideDirection = .left
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    currentView = .forgotPassword
                                }
                            }
                        )
                        .transition(slideTransition(for: slideDirection))
                        
                    case .signUp:
                        SignUpView(
                            onSignInTapped: {
                                slideDirection = .right
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    currentView = .signIn
                                }
                            }
                        )
                        .transition(slideTransition(for: slideDirection))
                        
                    case .forgotPassword:
                        ForgotPasswordView(
                            onBackTapped: {
                                slideDirection = .right
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    currentView = .signIn
                                }
                            }
                        )
                        .transition(slideTransition(for: slideDirection))
                    }
                }
            }
        }
    }
    
    private func slideTransition(for direction: SlideDirection) -> AnyTransition {
        switch direction {
        case .left:
            return .asymmetric(
                insertion: .move(edge: .trailing).combined(with: .opacity),
                removal: .move(edge: .leading).combined(with: .opacity)
            )
        case .right:
            return .asymmetric(
                insertion: .move(edge: .leading).combined(with: .opacity),
                removal: .move(edge: .trailing).combined(with: .opacity)
            )
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

/// Custom checkbox toggle style
struct CheckboxToggleStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack {
            ZStack {
                RoundedRectangle(cornerRadius: 4)
                    .stroke(configuration.isOn ? Theme.Colors.primary : Color.gray.opacity(0.4), lineWidth: 1.5)
                    .frame(width: 20, height: 20)
                    .background(
                        RoundedRectangle(cornerRadius: 4)
                            .fill(configuration.isOn ? Theme.Colors.primary.opacity(0.1) : Color.clear)
                    )
                
                if configuration.isOn {
                    Image(systemName: "checkmark")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(Theme.Colors.primary)
                        .transition(.scale.combined(with: .opacity))
                }
            }
            .contentShape(Rectangle())
            .onTapGesture {
                withAnimation(.spring(response: 0.2, dampingFraction: 0.7)) {
                    configuration.isOn.toggle()
                }
            }
            
            configuration.label
                .padding(.leading, 4)
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
                                
                                Image(systemName: "paperplane.fill")
                                    .font(.system(size: 14, weight: .semibold))
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
                    .padding(.top, 20)
                }
                
                // Back button with animation
                Button(action: onBackTapped) {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 14))
                        Text("Back to Sign In")
                            .font(Theme.Typography.captionFontSystem.bold())
                    }
                    .foregroundColor(Theme.Colors.primary)
                    .padding(.vertical, 8)
                    .padding(.horizontal, 16)
                    .background(
                        Capsule()
                            .fill(Theme.Colors.primary.opacity(0.1))
                    )
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
                    withAnimation(.spring()) {
                        resetSent = true
                    }
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
