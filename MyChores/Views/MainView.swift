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
                ZStack {
                    HomeView()
                    
                    // Terms check overlay
                    TermsCheckView()
                }
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
        // Re-create the timer subscription to reset it
        _ = timeoutTimer.upstream.connect() // This re-establishes the subscription
        
        // Force a refresh of auth state
        Task {
            await forceRefreshUser()
        }
    }
    
    private func forceRefreshUser() async {
        // First try to reload the Firebase user. This is a direct Firebase SDK call.
        // It's acceptable here as it's about the raw auth state before dealing with our app's user profile.
        guard let currentUser = Auth.auth().currentUser else {
            print("LoadingView: No Firebase user to refresh.")
            // If no Firebase user, AuthViewModel should eventually reflect this via its listener to AuthService.
            // We might want to ensure AuthViewModel is nudged if it's stuck.
            await authViewModel.refreshCurrentUser() // Call refresh to potentially update state if stuck.
            return
        }

        do {
            try await currentUser.reload()
            print("LoadingView: Firebase user reloaded successfully.")

            // Then force a refresh of the Firestore user data via AuthViewModel
            let refreshSuccess = await authViewModel.refreshCurrentUser()
            print("LoadingView: AuthViewModel.refreshCurrentUser() result: \(refreshSuccess ? "success" : "failed")")
            
            // If we still don't have a valid user profile (e.g., authState is still .authenticatedButProfileIncomplete
            // or currentUser is nil in AuthViewModel), try the more direct profile existence check.
            if !refreshSuccess || authViewModel.currentUser == nil || authViewModel.authState == .authenticatedButProfileIncomplete {
                print("LoadingView: Refresh failed or profile still incomplete. Attempting to ensure profile exists via AuthViewModel.")
                // Short delay to let any pending Firestore operations complete
                try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 second
                
                await authViewModel.ensureUserProfileExists() // Use the ViewModel method
                print("LoadingView: AuthViewModel.ensureUserProfileExists() called.")

                // After attempting to ensure the profile, try one final refresh to update the local state.
                let finalAttempt = await authViewModel.refreshCurrentUser()
                print("LoadingView: Final refreshCurrentUser() attempt after ensureUserProfileExists: \(finalAttempt ? "success" : "failed")")
                
                // If all else failed, and we are still stuck in .authenticatedButProfileIncomplete,
                // but we have a Firebase user, this is a tricky state.
                // Forcing to .authenticated might be too optimistic if the profile truly couldn't be loaded/created.
                // However, if ensureUserProfileExists was supposed to fix it, and refreshCurrentUser still fails,
                // it might point to other issues. For now, let's rely on authState being correctly set by AuthService.
                if !finalAttempt && authViewModel.authState == .authenticatedButProfileIncomplete {
                    print("LoadingView: Still authenticatedButProfileIncomplete after all attempts. This state should be resolved by AuthService.")
                    // Consider if any direct action is needed here or if we trust AuthService to eventually resolve.
                    // Forcing authState = .authenticated directly in the View is generally not recommended.
                }
            }
        } catch {
            print("LoadingView: Error reloading Firebase user: \(error.localizedDescription)")
            // If reloading the Firebase user fails, it might indicate a session issue.
            // Triggering a refresh in AuthViewModel might help reconcile the state.
            _ = await authViewModel.refreshCurrentUser()
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
