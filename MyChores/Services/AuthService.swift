// AuthService.swift
// MyChores
//
// Created on 2025-05-02.
//

import Foundation
import FirebaseAuth
import Combine
import FirebaseFirestore

/// Service for handling user authentication
class AuthService: ObservableObject {
    // MARK: - Shared Instance
    
    /// Shared instance for singleton access
    static let shared = AuthService()
    
    // MARK: - Published Properties
    
    /// Current Firebase user
    @Published var currentUser: User?
    
    /// Whether a user is logged in
    @Published var isAuthenticated = false
    
    /// Current authentication state
    @Published var authState: AuthState = .unknown
    
    /// Authentication error message
    @Published var errorMessage: String?
    
    // MARK: - Private Properties
    
    /// Firebase authentication handler
    private var authStateHandler: AuthStateDidChangeListenerHandle?
    
    // MARK: - Initialization
    
    /// Private initializer to enforce singleton pattern
    private init() {
        setupAuthStateListener()
    }
    
    // MARK: - Auth State
    
    /// Authentication states
    enum AuthState {
        case unknown
        case authenticated
        case unauthenticated
    }
    
    /// Sets up Firebase authentication state listener
    private func setupAuthStateListener() {
        authStateHandler = Auth.auth().addStateDidChangeListener { [weak self] (_, user) in
            guard let self = self else { return }
            
            Task { @MainActor in
                if let user = user {
                    self.isAuthenticated = true
                    self.authState = .authenticated
                    
                    // Fetch the user document from Firestore
                    do {
                        // Try to get the user profile
                        if let userProfile = try await UserService.shared.fetchCurrentUser() {
                            self.currentUser = userProfile
                        } else {
                            // If user exists in Auth but not in Firestore, create a basic profile
                            if let name = user.displayName, let email = user.email {
                                try await UserService.shared.createUser(id: user.uid, name: name, email: email)
                                // Fetch the newly created user profile
                                self.currentUser = try await UserService.shared.fetchCurrentUser()
                            } else {
                                // Set to incomplete state so the app can prompt for profile completion
                                print("User exists in Auth but has incomplete profile data")
                                self.errorMessage = "Please complete your profile"
                            }
                        }
                    } catch {
                        print("Error fetching user profile: \(error.localizedDescription)")
                        if error.localizedDescription.contains("missing") || 
                           error.localizedDescription.contains("not found") ||
                           error.localizedDescription.contains("doesn't exist") {
                            // Common Firestore errors when document doesn't exist
                            // Try to create a basic profile if possible
                            if let name = user.displayName, let email = user.email {
                                do {
                                    try await UserService.shared.createUser(id: user.uid, name: name, email: email)
                                    // Fetch the newly created user profile
                                    self.currentUser = try await UserService.shared.fetchCurrentUser()
                                } catch {
                                    print("Error creating user profile: \(error.localizedDescription)")
                                    self.errorMessage = "Could not create user profile. Please try again."
                                }
                            }
                        } else if error.localizedDescription.contains("network") || 
                                  error.localizedDescription.contains("connection") {
                            // Network-related errors
                            self.errorMessage = "Network error. Please check your connection and try again."
                        } else {
                            // Any other errors
                            self.errorMessage = "Error loading profile. Please try again."
                        }
                    }
                } else {
                    self.isAuthenticated = false
                    self.authState = .unauthenticated
                    self.currentUser = nil
                }
            }
        }
    }
    
    // MARK: - Authentication Methods
    
    /// Sign in with email and password
    /// - Parameters:
    ///   - email: User's email
    ///   - password: User's password
    func signIn(email: String, password: String) async throws {
        errorMessage = nil
        
        do {
            let result = try await Auth.auth().signIn(withEmail: email, password: password)
            print("User signed in: \(result.user.uid)")
        } catch {
            errorMessage = error.localizedDescription
            throw error
        }
    }
    
    /// Create a new account with email and password
    /// - Parameters:
    ///   - name: User's display name
    ///   - email: User's email
    ///   - password: User's password
    func signUp(name: String, email: String, password: String) async throws {
        errorMessage = nil
        
        do {
            // Create the user in Firebase Auth
            let result = try await Auth.auth().createUser(withEmail: email, password: password)
            
            // Update display name
            let changeRequest = result.user.createProfileChangeRequest()
            changeRequest.displayName = name
            try await changeRequest.commitChanges()
            
            // Create user document in Firestore
            try await UserService.shared.createUser(id: result.user.uid, name: name, email: email)
            
            print("User created: \(result.user.uid)")
        } catch {
            errorMessage = error.localizedDescription
            throw error
        }
    }
    
    /// Sign the current user out
    func signOut() throws {
        errorMessage = nil
        
        do {
            try Auth.auth().signOut()
        } catch {
            errorMessage = error.localizedDescription
            throw error
        }
    }
    
    /// Reset password for a given email
    /// - Parameter email: User's email address
    func resetPassword(for email: String) async throws {
        errorMessage = nil
        
        do {
            try await Auth.auth().sendPasswordReset(withEmail: email)
        } catch {
            errorMessage = error.localizedDescription
            throw error
        }
    }
    
    /// Refresh the current user data from Firestore
    /// - Returns: The updated User or nil if not found
    func refreshCurrentUser() async throws -> User? {
        guard let currentUserId = getCurrentUserId() else {
            return nil
        }
        
        // Force refresh the user data from Firestore
        let refreshedUser = try await UserService.shared.fetchUser(withId: currentUserId)
        
        // Update the published currentUser property
        if let refreshedUser = refreshedUser {
            DispatchQueue.main.async {
                self.currentUser = refreshedUser
            }
        }
        
        return refreshedUser
    }
    
    /// Get the current Firebase user ID
    /// - Returns: User ID string or nil if not authenticated
    func getCurrentUserId() -> String? {
        return Auth.auth().currentUser?.uid
    }
    
    // MARK: - Cleanup
    
    deinit {
        if let authStateHandler = authStateHandler {
            Auth.auth().removeStateDidChangeListener(authStateHandler)
        }
    }
}
