// AuthService.swift
// MyChores
//
// Created on 2025-05-02.
//

import Foundation
import FirebaseAuth
import Combine
import FirebaseFirestore

// MARK: - AuthServiceProtocol
protocol AuthServiceProtocol: ObservableObject where ObjectWillChangePublisher == ObservableObjectPublisher {
    var currentUser: User? { get }
    var isAuthenticated: Bool { get }
    var authState: AuthService.AuthState { get }
    var errorMessage: String? { get }

    func signIn(email: String, password: String) async throws
    func signUp(name: String, email: String, password: String) async throws
    func signOut() throws
    func resetPassword(for email: String) async throws
    func refreshCurrentUser() async throws -> User?
    func getCurrentUserId() -> String?
    func ensureCurrentProfileExists() async // New method
    func updateUserPrivacySettings(showProfile: Bool, showAchievements: Bool, shareActivity: Bool) async throws // New method for privacy settings
    func updateUserName(newName: String) async throws // NEW
    func updateUserTermsAcceptance(uid: String, termsAcceptance: TermsAcceptance) async throws // Method for terms acceptance
}

/// Service for handling user authentication
class AuthService: AuthServiceProtocol {
    // MARK: - Shared Instance
    
    /// Shared instance for singleton access
    static let shared = AuthService(userService: UserService.shared) // MODIFIED: Inject UserService.shared
    
    // MARK: - Published Properties
    
    /// Current Firebase user
    @Published var currentUser: User? // App-specific User model from Firestore
    
    /// Whether a user is logged in according to Firebase Auth
    @Published var isAuthenticated = false
    
    /// Detailed authentication state for the app
    @Published var authState: AuthState = .unknown
    
    /// Authentication error message
    @Published var errorMessage: String?
    
    // MARK: - Private Properties
    
    /// Firebase authentication state listener handle
    private var authStateHandler: AuthStateDidChangeListenerHandle?
    
    // MARK: - Dependencies (NEW)
    private let userService: UserServiceProtocol // NEW
    
    // MARK: - Initialization
    
    // MODIFIED: Initializer to accept UserServiceProtocol
    private init(userService: UserServiceProtocol) {
        self.userService = userService // NEW
        setupAuthStateListener()
    }
    
    // MARK: - Auth State Enum
    
    enum AuthState {
        case unknown        // Initial state before listener fires
        case authenticated  // Firebase Auth success + Firestore profile loaded/created
        case unauthenticated// No Firebase Auth user
        // Consider adding more granular states if needed, e.g.:
        // case authenticating
        // case profileCreationFailed
    }
    
    // MARK: - Auth State Management & Profile Synchronization
    
    private func setupAuthStateListener() {
        authStateHandler = Auth.auth().addStateDidChangeListener { [weak self] (_, firebaseUser) in
            guard let self = self else { return }
            
            Task { @MainActor in // Ensure UI updates are on the main thread
                if let authUser = firebaseUser {
                    self.isAuthenticated = true // Firebase Auth is successful
                    // Now, ensure our app-specific user profile exists and is loaded
                    await self.ensureUserProfileExists(for: authUser)
                } else {
                    // User is signed out from Firebase Auth
                    self.isAuthenticated = false
                    self.authState = .unauthenticated
                    self.currentUser = nil
                    self.errorMessage = nil // Clear any previous errors
                }
            }
        }
    }

    /// Ensures a user profile document exists in Firestore for the authenticated Firebase user.
    /// Fetches an existing profile or creates a new one if it doesn't exist.
    /// Updates `currentUser` and `authState` based on the outcome.
    @MainActor // Modifies @Published properties, so must be on MainActor
    private func ensureUserProfileExists(for authUser: FirebaseAuth.User) async {
        do {
            // Try to fetch the user profile from Firestore using UserService
            // MODIFIED: Use injected userService
            if let existingProfile = try await self.userService.fetchUser(withId: authUser.uid) {
                self.currentUser = existingProfile
                self.authState = .authenticated // Profile successfully fetched
                self.errorMessage = nil
                print("✅ User profile fetched for UID: \(authUser.uid). Name: \(existingProfile.name)")
                
                // Optional: Sync critical fields if necessary (e.g., email if it can change via provider)
                // var profileToUpdate = existingProfile
                // var needsFirestoreUpdate = false
                // if let authEmail = authUser.email, profileToUpdate.email != authEmail {
                //     profileToUpdate.email = authEmail
                //     needsFirestoreUpdate = true
                // }
                // if needsFirestoreUpdate {
                //     try await UserService.shared.updateUser(profileToUpdate)
                //     self.currentUser = profileToUpdate // Update local copy after successful DB update
                // }

            } else {
                // User profile does not exist in Firestore; attempt to create it.
                print("ℹ️ Firestore profile not found for UID: \(authUser.uid). Attempting to create.")
                
                let name = authUser.displayName ?? "New User" // Default name if not provided by Auth
                guard let email = authUser.email, !email.isEmpty else {
                    print("❌ Cannot create profile for UID \(authUser.uid): Email is missing from Firebase Auth user.")
                    self.errorMessage = "Failed to initialize profile: Essential information (email) is missing."
                    self.currentUser = nil
                    // User is authenticated with Firebase, but app profile creation is blocked.
                    // This is a critical state the UI needs to handle.
                    self.authState = .authenticated // Or a more specific .profileCreationFailed state
                    return
                }

                // MODIFIED: Use injected userService
                let newUser = try await self.userService.createUser(id: authUser.uid, name: name, email: email)
                self.currentUser = newUser
                self.authState = .authenticated // Profile successfully created and loaded
                self.errorMessage = nil
                print("✅ Firestore profile created and fetched for UID: \(authUser.uid). Name: \(newUser.name)")
            }
        } catch {
            print("❌ Error in ensureUserProfileExists for UID \(authUser.uid): \(error.localizedDescription)")
            self.errorMessage = "Failed to load or create user profile: \(error.localizedDescription)"
            self.currentUser = nil
            // User is authenticated with Firebase, but app profile is inaccessible.
            // This is a critical failure. UI should guide the user (e.g., retry, contact support).
            self.authState = .unauthenticated // Reverting to unauthenticated might force a re-login/retry cycle.
                                             // Alternatively, a specific .profileError state could be used.
        }
    }
    
    // MARK: - Authentication Methods (Protocol Conformance)
    
    func signIn(email: String, password: String) async throws {
        errorMessage = nil
        do {
            _ = try await Auth.auth().signIn(withEmail: email, password: password)
            // The authStateHandler will handle fetching/creating the user profile and updating state.
        } catch {
            errorMessage = error.localizedDescription
            throw error
        }
    }
    
    func signUp(name: String, email: String, password: String) async throws {
        errorMessage = nil
        do {
            // 1. Create user in Firebase Authentication
            let authResult = try await Auth.auth().createUser(withEmail: email, password: password)
            
            // 2. Update Firebase Auth user's display name
            let changeRequest = authResult.user.createProfileChangeRequest()
            changeRequest.displayName = name
            try await changeRequest.commitChanges() // Corrected: removed trailing \t
            
            // 3. Proactively create user document in Firestore via UserService
            // This makes the document available quickly. The authStateHandler will then fetch it.
            // MODIFIED: Use injected userService
            _ = try await self.userService.createUser(id: authResult.user.uid, name: name, email: email)
            
            // 4. Optionally, immediately update local state if critical for immediate UI feedback
            //    before the listener fully processes. Otherwise, rely on the listener.
            //    The listener (ensureUserProfileExists) will be the ultimate source of truth for currentUser.
            // if let userProfile = try? await UserService.shared.fetchUser(withId: authResult.user.uid) {\n            //    DispatchQueue.main.async {\n            //        self.currentUser = userProfile\n            //        self.authState = .authenticated\n            //    }\n            // }
            print("✅ User signed up and Firestore profile creation initiated for UID: \(authResult.user.uid)")

        } catch {
            errorMessage = error.localizedDescription
            throw error
        }
    }
    
    func signOut() throws {
        errorMessage = nil
        do {
            try Auth.auth().signOut()
            // authStateHandler will update currentUser, isAuthenticated, and authState.
        } catch {
            errorMessage = error.localizedDescription
            throw error
        }
    }
    
    func resetPassword(for email: String) async throws {
        errorMessage = nil
        do {
            try await Auth.auth().sendPasswordReset(withEmail: email)
        } catch {
            errorMessage = error.localizedDescription
            throw error
        }
    }
    
    @MainActor
    func refreshCurrentUser() async throws -> User? {
        guard let currentAuthUserId = Auth.auth().currentUser?.uid else {
            self.errorMessage = "No authenticated user to refresh."
            self.currentUser = nil
            self.authState = .unauthenticated
            return nil
        }
        
        print("🔄 Refreshing current user profile for UID: \(currentAuthUserId)")
        do {
            // Force a fetch from Firestore via UserService
            // MODIFIED: Use injected userService
            let refreshedProfile = try await self.userService.fetchUser(withId: currentAuthUserId)
            self.currentUser = refreshedProfile // Update @Published property
            if refreshedProfile == nil {
                // This case means user is in Auth, but not in Firestore (or fetch failed specifically)
                // ensureUserProfileExists should ideally handle this, but refresh can also encounter it.
                print("⚠️ User exists in Auth but no profile in Firestore during refresh for UID: \(currentAuthUserId).")
                self.errorMessage = "User profile not found. It might need to be recreated."
                // Consider calling ensureUserProfileExists or a similar recovery mechanism if appropriate
                // For now, just reflect the state.
                self.authState = .unauthenticated // Or a specific error state
            } else {
                self.authState = .authenticated
                self.errorMessage = nil
            }
            return refreshedProfile
        } catch {
            print("❌ Error refreshing user profile for UID \(currentAuthUserId): \(error.localizedDescription)")
            self.errorMessage = "Failed to refresh user profile: \(error.localizedDescription)"
            // Don't nullify currentUser here unless the error definitively means the profile is gone or invalid.
            // The existing currentUser might still be valid if it was a temporary network issue.
            throw error // Re-throw for the caller to handle
        }
    }
    
    func getCurrentUserId() -> String? {
        return Auth.auth().currentUser?.uid
    }

    @MainActor
    func ensureCurrentProfileExists() async {
        guard let authUser = Auth.auth().currentUser else {
            print("AuthService: No Firebase user found to ensure profile exists.")
            // If called when no user, ensure state reflects unauthenticated.
            if self.authState != .unauthenticated {
                 self.authState = .unauthenticated
                 self.currentUser = nil
                 self.errorMessage = "No authenticated user to ensure profile for."
            }
            return
        }
        
        print("AuthService: ensureCurrentProfileExists called for UID \(authUser.uid). Delegating to ensureUserProfileExists.")
        // Delegate to the existing comprehensive logic.
        // This method handles its own error reporting by updating self.errorMessage and self.authState.
        await self.ensureUserProfileExists(for: authUser)
    }
    
    @MainActor
    func updateUserPrivacySettings(showProfile: Bool, showAchievements: Bool, shareActivity: Bool) async throws {
        guard let userId = getCurrentUserId() else {
            // This error should ideally be a more specific AuthError or similar
            throw NSError(domain: "AuthService", code: 401, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])
        }
        
        do {
            // Assuming UserService.shared is accessible here. For better testability, UserService could be injected.
            // MODIFIED: Use injected userService
            try await self.userService.updatePrivacySettings(
                userId: userId,
                showProfile: showProfile,
                showAchievements: showAchievements,
                shareActivity: shareActivity
            )
            // After successful update in Firestore, refresh the local currentUser in AuthService
            // This will trigger objectWillChange and update AuthViewModel
            _ = try await self.refreshCurrentUser() // refreshCurrentUser is already @MainActor
            print("AuthService: Privacy settings updated and currentUser refreshed.")
        } catch {
            print("AuthService: Error updating privacy settings: \(error.localizedDescription)")
            // Update errorMessage to propagate the error to AuthViewModel and the UI
            self.errorMessage = "Failed to update privacy settings: \(error.localizedDescription)"
            throw error
        }
    }
    
    // MARK: - NEW: Update User Name
    
    // NEW: Method to update user's name
    @MainActor
    func updateUserName(newName: String) async throws {
        guard let _ = getCurrentUserId(), var user = self.currentUser else {
            throw NSError(domain: "AuthService", code: 401, userInfo: [NSLocalizedDescriptionKey: "User not authenticated or current user data not available"])
        }
        
        // Update Firebase Auth display name
        if let firebaseUser = Auth.auth().currentUser {
            let changeRequest = firebaseUser.createProfileChangeRequest()
            changeRequest.displayName = newName
            do {
                try await changeRequest.commitChanges()
                print("AuthService: Firebase Auth display name updated to \(newName)")
            } catch {
                print("AuthService: Error updating Firebase Auth display name: \(error.localizedDescription)")
                // Continue to update Firestore even if Auth update fails, but log the error.
                // Depending on requirements, you might want to throw here.
            }
        }
        
        // Update name in Firestore via UserService
        user.name = newName // Update the local currentUser model optimistically
        do {
            try await self.userService.updateUser(user) // userService.updateUser should save the whole user object
            // After successful update in Firestore, refresh the local currentUser in AuthService
            // This ensures the local state is consistent with the database and propagates changes.
            _ = try await self.refreshCurrentUser() // refreshCurrentUser is already @MainActor
            print("AuthService: User name updated in Firestore and currentUser refreshed to \(newName)")
            self.errorMessage = nil // Clear any previous error messages
        } catch {
            print("AuthService: Error updating user name in Firestore: \(error.localizedDescription)")
            self.errorMessage = "Failed to update user name: \(error.localizedDescription)"
            throw error
        }
    }
    
    // MARK: - NEW: Update User Terms Acceptance
    
    // NEW: Method to update user's terms acceptance status
    @MainActor
    func updateUserTermsAcceptance(uid: String, termsAcceptance: TermsAcceptance) async throws {
        guard getCurrentUserId() != nil else {
            throw NSError(domain: "AuthService", code: 401, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])
        }
        
        do {
            // Get the current user document
            let userRef = Firestore.firestore().collection("users").document(uid)
            
            // OPTION 1: Update with individual fields using dot notation
            print("🔄 Updating terms acceptance in Firestore: termsAccepted=\(termsAcceptance.termsAccepted), privacyAccepted=\(termsAcceptance.privacyAccepted)")
            
            // Convert to Dictionary for cleaner Firestore storage
            let termsData: [String: Any] = [
                "termsAccepted": termsAcceptance.termsAccepted,
                "privacyAccepted": termsAcceptance.privacyAccepted,
                "acceptanceDate": termsAcceptance.acceptanceDate as Any,
                "termsVersion": termsAcceptance.termsVersion
            ]
            
            // Update the entire terms acceptance object at once
            try await userRef.updateData(["termsAcceptance": termsData])
            
            print("✓ Firestore update complete with full termsAcceptance object")
            
            // Also update individual fields as backup approach
            try await userRef.updateData([
                "termsAcceptance.termsAccepted": termsAcceptance.termsAccepted,
                "termsAcceptance.privacyAccepted": termsAcceptance.privacyAccepted,
                "termsAcceptance.acceptanceDate": termsAcceptance.acceptanceDate as Any,
                "termsAcceptance.termsVersion": termsAcceptance.termsVersion
            ])
            
            print("✓ Firestore update complete with individual fields")
            
            // Immediately update the local user object with the new terms acceptance
            if var user = self.currentUser {
                user.termsAcceptance = termsAcceptance
                self.currentUser = user
                print("📱 Updated current user in AuthService with new terms acceptance")
            }
            
            // After updating Firestore, refresh the current user to ensure we have the latest data
            _ = try await refreshCurrentUser()
            
            print("✅ AuthService: User terms acceptance updated in Firestore and local state refreshed")
            self.errorMessage = nil
        } catch {
            print("AuthService: Error updating terms acceptance in Firestore: \(error.localizedDescription)")
            self.errorMessage = "Failed to update terms acceptance: \(error.localizedDescription)"
            throw error
        }
    }
    
    // MARK: - Cleanup
    
    deinit {
        if let authStateHandler = authStateHandler {
            Auth.auth().removeStateDidChangeListener(authStateHandler)
        }
    }
}
