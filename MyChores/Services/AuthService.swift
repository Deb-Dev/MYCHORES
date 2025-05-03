// AuthService.swift
// MyChores
//
// Created on 2025-05-02.
//

import Foundation
import FirebaseAuth
import Combine

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
            
            if let user = user {
                self.isAuthenticated = true
                self.authState = .authenticated
                
                // Fetch the user document from Firestore
                Task {
                    do {
                        if let userProfile = try await UserService.shared.fetchCurrentUser() {
                            DispatchQueue.main.async {
                                self.currentUser = userProfile
                            }
                        }
                    } catch {
                        print("Error fetching user profile: \(error.localizedDescription)")
                    }
                }
            } else {
                self.isAuthenticated = false
                self.authState = .unauthenticated
                self.currentUser = nil
            }
        }
    }
    
    // MARK: - Authentication Methods
    
    /// Sign in with email and password
    /// - Parameters:
    ///   - email: User's email
    ///   - password: User's password
    ///   - completion: Completion handler with result
    func signIn(email: String, password: String) async throws {
        do {
            DispatchQueue.main.async {
                self.errorMessage = nil
            }
            
            let result = try await Auth.auth().signIn(withEmail: email, password: password)
            print("User signed in: \(result.user.uid)")
        } catch {
            DispatchQueue.main.async {
                self.errorMessage = error.localizedDescription
            }
            throw error
        }
    }
    
    /// Create a new account with email and password
    /// - Parameters:
    ///   - name: User's display name
    ///   - email: User's email
    ///   - password: User's password
    func signUp(name: String, email: String, password: String) async throws {
        do {
            DispatchQueue.main.async {
                self.errorMessage = nil
            }
            
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
            DispatchQueue.main.async {
                self.errorMessage = error.localizedDescription
            }
            throw error
        }
    }
    
    /// Sign the current user out
    func signOut() throws {
        do {
            try Auth.auth().signOut()
        } catch {
            DispatchQueue.main.async {
                self.errorMessage = error.localizedDescription
            }
            throw error
        }
    }
    
    /// Reset password for a given email
    /// - Parameter email: User's email address
    func resetPassword(for email: String) async throws {
        do {
            DispatchQueue.main.async {
                self.errorMessage = nil
            }
            
            try await Auth.auth().sendPasswordReset(withEmail: email)
        } catch {
            DispatchQueue.main.async {
                self.errorMessage = error.localizedDescription
            }
            throw error
        }
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
