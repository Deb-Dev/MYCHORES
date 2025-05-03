// MainView.swift
// MyChores
//
// Created on 2025-05-02.
//

import SwiftUI
import FirebaseAuth

/// Main view that handles authentication state and navigation
struct MainView: View {
    @EnvironmentObject private var authViewModel: AuthViewModel
    
    var body: some View {
        Group {
            switch authViewModel.authState {
            case .initializing:
                LoadingView()
                
            case .unauthenticated:
                AuthView()
                
            case .authenticatedButProfileIncomplete:
                LoadingView()
                
            case .authenticated:
                HomeView()
            }
        }
        .animation(.easeInOut, value: authViewModel.authState)
    }
}

/// Loading screen shown during authentication state changes
struct LoadingView: View {
    @EnvironmentObject private var authViewModel: AuthViewModel
    @State private var isTimedOut = false
    @State private var dots = ""
    @State private var retryCount = 0
    
    let timer = Timer.publish(every: 0.5, on: .main, in: .common).autoconnect()
    let timeoutTimer = Timer.publish(every: 15, on: .main, in: .common).autoconnect()
    
    var body: some View {
        VStack(spacing: 24) {
            if isTimedOut {
                VStack(spacing: 16) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 50))
                        .foregroundColor(Theme.Colors.error)
                    
                    Text("Loading timed out")
                        .font(Theme.Typography.headingFontSystem)
                    
                    Text(retryCount > 2 
                         ? "There might be a problem with your account or connection. Please try signing out and back in."
                         : "Please check your internet connection or try again later.")
                        .font(Theme.Typography.bodyFontSystem)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    
                    Button(action: {
                        // Force refresh
                        retryAuth()
                    }) {
                        Text("Try Again")
                            .padding()
                            .foregroundColor(.white)
                            .background(Theme.Colors.primary)
                            .cornerRadius(8)
                    }
                    .padding(.top)
                    
                    if retryCount > 1 {
                        Button(action: {
                            // Sign out as a last resort
                            forceSignOut()
                        }) {
                            Text("Sign Out")
                                .padding()
                                .foregroundColor(.white)
                                .background(Theme.Colors.error)
                                .cornerRadius(8)
                        }
                        .padding(.top, 8)
                    }
                }
            } else {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle())
                    .scaleEffect(1.5)
                
                Text("Loading\(dots)")
                    .font(Theme.Typography.headingFontSystem)
            }
        }
        .onReceive(timer) { _ in
            if dots.count < 3 {
                dots.append(".")
            } else {
                dots = ""
            }
        }
        .onReceive(timeoutTimer) { _ in
            isTimedOut = true
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Theme.Colors.background)
    }
    
    private func retryAuth() {
        isTimedOut = false
        dots = ""
        retryCount += 1
        
        // Reset timeout timer
        timeoutTimer.upstream.connect().cancel()
        
        // Force a refresh of auth state
        Task {
            // This will trigger the auth state to refresh
            if let currentUser = Auth.auth().currentUser {
                do {
                    try await currentUser.reload()
                } catch {
                    print("Error reloading user: \(error.localizedDescription)")
                }
            }
        }
    }
    
    private func forceSignOut() {
        Task {
            await authViewModel.signOut { success, error in
                if success {
                    isTimedOut = false
                    dots = ""
                    retryCount = 0
                } else {
                    print("Force sign out failed: \(error?.localizedDescription ?? "Unknown error")")
                }
            }
        }
    }
}


#Preview {
    MainView()
        .environmentObject(AuthViewModel())
}
