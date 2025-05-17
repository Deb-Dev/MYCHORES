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

#Preview {
    AuthView()
        .environmentObject(AuthViewModel())
}
