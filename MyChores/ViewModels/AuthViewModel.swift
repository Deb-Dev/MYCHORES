// AuthViewModel.swift
// MyChores
//
// Created on 2025-05-02.
//

import Foundation
import Combine
import SwiftUI
import FirebaseAuth
import FirebaseFirestore

/// ViewModel for authentication-related views
@MainActor
class AuthViewModel: ObservableObject {
    // MARK: - Published Properties
    
    /// Current authentication state
    @Published var authState: AuthState = .initializing
    
    /// Current user
    @Published var currentUser: User?
    
    /// Loading state for auth operations
    @Published var isLoading = false
    
    /// Error message
    @Published var errorMessage: String?
    
    // MARK: - Private Properties
    
    /// Auth service instance
    private let authService: any AuthServiceProtocol
    
    /// Cancellables set for managing subscriptions
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Authentication States
    
    /// States of authentication
    enum AuthState {
        case initializing
        case unauthenticated
        case authenticatedButProfileIncomplete
        case authenticated
    }
    
    // MARK: - Initialization
    
    init(authService: any AuthServiceProtocol = AuthService.shared) {
        self.authService = authService
        
        // Subscribe to changes from the authService
        // When authService's objectWillChange fires (due to its @Published properties changing),
        // we update AuthViewModel's corresponding @Published properties.
        // This will, in turn, trigger AuthViewModel's objectWillChange and update any observing views.
        authService.objectWillChange
            .receive(on: DispatchQueue.main) // Ensure updates are on the main thread
            .sink { [weak self] _ in // We don't need the specific output of objectWillChange, just the signal
                guard let self = self else { return }
                self.currentUser = self.authService.currentUser
                self.authState = self.mapAuthState(self.authService.authState)
                self.errorMessage = self.authService.errorMessage
            }
            .store(in: &cancellables)
        
        // Initial state mapping is important for the first load.
        self.currentUser = authService.currentUser
        self.authState = mapAuthState(authService.authState)
        self.errorMessage = authService.errorMessage
    }
    
    private func mapAuthState(_ serviceState: AuthService.AuthState) -> AuthState {
        switch serviceState {
        case .unknown:
            return .initializing // Or a more appropriate mapping
        case .authenticated:
            // Further check if profile is complete if that logic remains relevant
            // For now, directly mapping to authenticated
            if let user = authService.currentUser, !user.name.isEmpty { // Basic check for profile completeness
                return .authenticated
            } else {
                return .authenticatedButProfileIncomplete
            }
        case .unauthenticated:
            return .unauthenticated
        }
    }
    
    // MARK: - Authentication Methods
    
    /// Sign in with email and password
    /// - Parameters:
    ///   - email: User's email
    ///   - password: User's password
    ///   - completion: Completion handler with success boolean and optional error
    func signIn(email: String, password: String, completion: @escaping (Bool, Error?) -> Void) async {
        guard isValidEmail(email) else {
            let error = NSError(domain: "AuthViewModel", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid email format."])
            completion(false, error)
            return
        }
        
        guard !password.isEmpty else {
            let error = NSError(domain: "AuthViewModel", code: 0, userInfo: [NSLocalizedDescriptionKey: "Password cannot be empty."])
            completion(false, error)
            return
        }
        
        isLoading = true
        // errorMessage = nil // Error message is now handled by observing authService.errorMessage
        
        do {
            try await authService.signIn(email: email, password: password)
            completion(true, nil)
        } catch {
            // errorMessage = mapAuthError(error) // Error message is now handled by observing authService.errorMessage
            completion(false, error)
        }
        isLoading = false
    }
    
    /// Create a new account
    /// - Parameters:
    ///   - name: User's name
    ///   - email: User's email
    ///   - password: User's password
    ///   - completion: Completion handler with success boolean and optional error
    func signUp(name: String, email: String, password: String, completion: @escaping (Bool, Error?) -> Void = {_,_ in }) async {
        guard !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            let error = NSError(domain: "AuthViewModel", code: 0, userInfo: [NSLocalizedDescriptionKey: "Name cannot be empty."])
            completion(false, error)
            return
        }
        
        guard isValidEmail(email) else {
            let error = NSError(domain: "AuthViewModel", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid email format."])
            completion(false, error)
            return
        }
        
        guard password.count >= 6 else {
            let error = NSError(domain: "AuthViewModel", code: 0, userInfo: [NSLocalizedDescriptionKey: "Password must be at least 6 characters."])
            completion(false, error)
            return
        }
        
        isLoading = true
        // errorMessage = nil // Error message is now handled by observing authService.errorMessage
        
        do {
            try await authService.signUp(name: name, email: email, password: password)
            completion(true, nil)
        } catch {
            // errorMessage = mapAuthError(error) // Error message is now handled by observing authService.errorMessage
            completion(false, error)
        }
        isLoading = false
    }
    
    /// Refresh the current user profile data from Firestore
    /// - Returns: Success boolean
    @MainActor
    func refreshCurrentUser() async -> Bool {
        guard authService.getCurrentUserId() != nil else {
            // errorMessage = "User not logged in." // Error message is now handled by observing authService.errorMessage
            return false
        }
        
        isLoading = true
        
        do {
            _ = try await authService.refreshCurrentUser()
            // self.currentUser = refreshedUser // currentUser is now handled by observing authService.currentUser
            isLoading = false
            return true
        } catch {
            // errorMessage = "Failed to refresh user: \(error.localizedDescription)" // Error message is now handled by observing authService.errorMessage
            isLoading = false
            return false
        }
    }
    
    /// Sign out the current user
    /// - Parameter completion: Completion handler with success boolean and optional error
    func signOut(completion: @escaping (Bool, Error?) -> Void = {_,_ in }) async {
        isLoading = true
        // errorMessage = nil // Error message is now handled by observing authService.errorMessage
        
        do {
            try authService.signOut()
            completion(true, nil)
        } catch {
            // errorMessage = "Failed to sign out: \(error.localizedDescription)" // Error message is now handled by observing authService.errorMessage
            completion(false, error)
        }
        isLoading = false
    }
    
    /// Reset password for a user
    /// - Parameters:
    ///   - email: User's email
    ///   - completion: Completion handler with success boolean and optional error
    func resetPassword(for email: String, completion: @escaping (Bool, Error?) -> Void = {_,_ in }) async {
        isLoading = true
        // errorMessage = nil // Error message is now handled by observing authService.errorMessage
        do {
            try await authService.resetPassword(for: email)
            completion(true, nil)
        } catch {
            // errorMessage = "Failed to send password reset: \(error.localizedDescription)" // Error message is now handled by observing authService.errorMessage
            completion(false, error)
        }
        isLoading = false
    }
    
    /// Attempts to ensure the current user's profile exists in Firestore, creating it if necessary.
    /// This is intended as a recovery mechanism if the profile is missing.
    func ensureUserProfileExists() async {
        isLoading = true
        // Error messages and state changes (currentUser, authState) are handled by authService
        // and propagated via the objectWillChange sink.
        await authService.ensureCurrentProfileExists()
        isLoading = false
    }
    
    /// Updates the current user's privacy settings.
    /// - Parameters:
    ///   - showProfile: Whether to show the profile to others.
    ///   - showAchievements: Whether to show achievements to others.
    ///   - shareActivity: Whether to share activity with the household.
    func updateUserPrivacySettings(showProfile: Bool, showAchievements: Bool, shareActivity: Bool) async {
        isLoading = true
        // errorMessage will be updated by authService via Combine if an error occurs.
        // currentUser and authState will also be updated by authService if the operation is successful (due to refreshCurrentUser).
        do {
            try await authService.updateUserPrivacySettings(
                showProfile: showProfile,
                showAchievements: showAchievements,
                shareActivity: shareActivity
            )
            // Optionally, provide a success message or handle UI updates if needed directly after success,
            // though most state changes should come from observing authService.
            print("AuthViewModel: updateUserPrivacySettings call completed.")
        } catch {
            // Error is already set on authService.errorMessage and propagated.
            // No need to set self.errorMessage here as it's driven by authService.
            print("AuthViewModel: Error during updateUserPrivacySettings: \(error.localizedDescription)")
        }
        isLoading = false
    }
    
    /// Updates the current user's name.
    /// - Parameter newName: The new name for the user.
    func updateUserName(newName: String) async {
        guard !newName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            self.errorMessage = "Name cannot be empty."
            // Or handle this via a specific error type if preferred
            return
        }
        
        isLoading = true
        // errorMessage will be updated by authService via Combine if an error occurs.
        // currentUser and authState will also be updated by authService if the operation is successful.
        do {
            // Assuming AuthServiceProtocol is extended with updateUserName
            try await authService.updateUserName(newName: newName)
            print("AuthViewModel: updateUserName call completed for \(newName)")
            // Optionally, trigger a manual refresh or rely on the Combine sink from authService
            // await self.refreshCurrentUser() // This might be redundant
        } catch {
            // Error is already set on authService.errorMessage and propagated.
            print("AuthViewModel: Error during updateUserName: \(error.localizedDescription)")
        }
        isLoading = false
    }
    
    /// Update user's terms and privacy policy acceptance
    /// - Parameters:
    ///   - termsAccepted: Whether the terms are accepted
    ///   - privacyAccepted: Whether the privacy policy is accepted
    ///   - acceptanceDate: Date of acceptance
    func updateUserTermsAcceptance(termsAccepted: Bool, privacyAccepted: Bool, acceptanceDate: Date) async {
        guard let uid = Auth.auth().currentUser?.uid else {
            print("Cannot update terms acceptance: No authenticated user")
            return
        }
        
        do {
            // Update only the terms acceptance fields
            let termsAcceptance = TermsAcceptance(
                termsAccepted: termsAccepted,
                privacyAccepted: privacyAccepted,
                acceptanceDate: acceptanceDate,
                termsVersion: "1.0" // Current version
            )
            
            // Log the terms acceptance values before updating
            print("📝 Updating terms acceptance: termsAccepted=\(termsAccepted), privacyAccepted=\(privacyAccepted)")
            
            try await authService.updateUserTermsAcceptance(uid: uid, termsAcceptance: termsAcceptance)
            
            // Update the local user object immediately
            if var updatedUser = currentUser {
                updatedUser.termsAcceptance = termsAcceptance
                currentUser = updatedUser
                print("📱 Updated local user terms acceptance: termsAccepted=\(updatedUser.termsAcceptance.termsAccepted), privacyAccepted=\(updatedUser.termsAcceptance.privacyAccepted)")
            }
            
            // Force a refresh of the user data from Firestore to ensure we have the latest values
            _ = await refreshCurrentUser()
            
            // Double check after refresh to ensure values were updated correctly
            if let refreshedUser = currentUser {
                print("♻️ After refresh: termsAccepted=\(refreshedUser.termsAcceptance.termsAccepted), privacyAccepted=\(refreshedUser.termsAcceptance.privacyAccepted)")
            }
            
            print("✅ Terms acceptance updated successfully")
        } catch {
            print("❌ Failed to update terms acceptance: \(error.localizedDescription)")
            errorMessage = "Failed to update terms: \(error.localizedDescription)"
        }
    }
    
    /// Check if user has accepted terms and privacy policy
    var hasAcceptedTerms: Bool {
        guard let user = currentUser else { return false }
        return user.termsAcceptance.termsAccepted && user.termsAcceptance.privacyAccepted
    }
    
    // MARK: - Helper Methods
    
    /// Validates email format
    /// - Parameter email: Email to validate
    /// - Returns: True if email is valid
    private func isValidEmail(_ email: String) -> Bool {
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPred = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
        return emailPred.evaluate(with: email)
    }
}
