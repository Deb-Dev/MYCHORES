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
    let timeoutTimer = Timer.publish(every: 10, on: .main, in: .common).autoconnect() // Reduced from 15 to 10 seconds
    
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
        .onAppear {
            // Proactively try to refresh user data when the loading view appears
            if authViewModel.authState == .authenticatedButProfileIncomplete {
                Task {
                    await forceRefreshUser()
                }
            }
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
            await forceRefreshUser()
        }
    }
    
    private func forceRefreshUser() async {
        // First try to reload the Firebase user
        if let currentUser = Auth.auth().currentUser {
            do {
                try await currentUser.reload()
                
                // Then force a refresh of the Firestore user data
                let refreshSuccess = await authViewModel.refreshCurrentUser()
                print("User refresh result: \(refreshSuccess ? "success" : "failed")")
                
                // If we still don't have a valid user, try a more aggressive approach
                if !refreshSuccess {
                    // Short delay to let any pending Firestore operations complete
                    try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
                    
                    // Try fetching again after the delay
                    let delayedRefresh = await authViewModel.refreshCurrentUser()
                    print("Delayed refresh attempt: \(delayedRefresh ? "success" : "failed")")
                    
                    // If still unsuccessful, try to recreate the user
                    if !delayedRefresh, let firebaseUser = Auth.auth().currentUser {
                        print("Trying to create user as fallback")
                        do {
                            try await UserService.shared.createNewUserIfNeeded(
                                userId: firebaseUser.uid,
                                name: firebaseUser.displayName ?? "User",
                                email: firebaseUser.email ?? "unknown@example.com"
                            )
                            
                            // Try one final refresh
                            let finalAttempt = await authViewModel.refreshCurrentUser() 
                            print("Final refresh attempt: \(finalAttempt ? "success" : "failed")")
                            
                            // If all else failed, force a state transition
                            if !finalAttempt && authViewModel.authState == .authenticatedButProfileIncomplete {
                                await MainActor.run {
                                    print("Forcing state transition to authenticated")
                                    authViewModel.authState = .authenticated
                                }
                            }
                        } catch {
                            print("Failed to create user: \(error.localizedDescription)")
                        }
                    }
                }
            } catch {
                print("Error reloading user: \(error.localizedDescription)")
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
