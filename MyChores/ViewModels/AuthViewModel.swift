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
    private let authService = AuthService.shared
    
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
    
    init() {
        // Subscribe to auth service changes
        authService.$authState
            .receive(on: DispatchQueue.main)
            .sink { [weak self] (state: AuthService.AuthState) in
                switch state {
                case .unknown:
                    self?.authState = .initializing
                case .unauthenticated:
                    self?.authState = .unauthenticated
                    self?.currentUser = nil
                case .authenticated:
                    // Wait for user data to be fetched
                    if self?.currentUser != nil {
                        self?.authState = .authenticated
                    } else {
                        self?.authState = .authenticatedButProfileIncomplete
                    }
                }
            }
            .store(in: &cancellables)
        
        authService.$currentUser
            .receive(on: DispatchQueue.main)
            .sink { [weak self] (user: User?) in
                self?.currentUser = user
                if user != nil && self?.authState == .authenticatedButProfileIncomplete {
                    self?.authState = .authenticated
                }
            }
            .store(in: &cancellables)
        
        authService.$errorMessage
            .receive(on: DispatchQueue.main)
            .sink { [weak self] errorMessage in
                self?.errorMessage = errorMessage
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Authentication Methods
    
    /// Sign in with email and password
    /// - Parameters:
    ///   - email: User's email
    ///   - password: User's password
    ///   - completion: Completion handler with success boolean and optional error
    func signIn(email: String, password: String, completion: @escaping (Bool, Error?) -> Void) async {
        guard isValidEmail(email) else {
            errorMessage = "Please enter a valid email address"
            completion(false, NSError(domain: "AuthViewModel", code: 100, userInfo: [NSLocalizedDescriptionKey: "Invalid email format"]))
            return
        }
        
        guard !password.isEmpty else {
            errorMessage = "Please enter your password"
            completion(false, NSError(domain: "AuthViewModel", code: 103, userInfo: [NSLocalizedDescriptionKey: "Password is required"]))
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            try await authService.signIn(email: email, password: password)
            isLoading = false
            completion(true, nil)
        } catch {
            isLoading = false
            errorMessage = mapAuthError(error)
            completion(false, error)
        }
    }
    
    /// Create a new account
    /// - Parameters:
    ///   - name: User's name
    ///   - email: User's email
    ///   - password: User's password
    ///   - completion: Completion handler with success boolean and optional error
    func signUp(name: String, email: String, password: String, completion: @escaping (Bool, Error?) -> Void = {_,_ in }) async {
        guard !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            errorMessage = "Please enter your name"
            completion(false, NSError(domain: "AuthViewModel", code: 102, userInfo: [NSLocalizedDescriptionKey: "Name is required"]))
            return
        }
        
        guard isValidEmail(email) else {
            errorMessage = "Please enter a valid email address"
            completion(false, NSError(domain: "AuthViewModel", code: 100, userInfo: [NSLocalizedDescriptionKey: "Invalid email format"]))
            return
        }
        
        guard password.count >= 6 else {
            errorMessage = "Password must be at least 6 characters"
            completion(false, NSError(domain: "AuthViewModel", code: 101, userInfo: [NSLocalizedDescriptionKey: "Password too short"]))
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            try await authService.signUp(name: name, email: email, password: password)
            isLoading = false
            completion(true, nil)
        } catch {
            isLoading = false
            errorMessage = mapAuthError(error)
            completion(false, error)
        }
    }
    
    /// Refresh the current user profile data from Firestore
    /// - Returns: Success boolean
    @MainActor
    func refreshCurrentUser() async -> Bool {
        guard let userId = authService.getCurrentUserId() else {
            print("refreshCurrentUser: No current user ID")
            return false
        }
        
        isLoading = true
        
        do {
            print("Attempting to refresh user: \(userId)")
            if let updatedUser = try await authService.refreshCurrentUser() {
                print("Successfully refreshed user")
                self.currentUser = updatedUser
                isLoading = false
                return true
            } else {
                print("User refresh returned nil")
                
                // Try to make sure the user exists in Firestore
                if let firebaseUser = Auth.auth().currentUser {
                    print("Attempting to create user if needed: \(userId)")
                    do {
                        try await UserService.shared.createNewUserIfNeeded(
                            userId: userId,
                            name: firebaseUser.displayName ?? "User",
                            email: firebaseUser.email ?? "unknown@example.com"
                        )
                        
                        // Try to fetch the user again
                        if let createdUser = try await authService.refreshCurrentUser() {
                            print("Successfully created and fetched user")
                            self.currentUser = createdUser
                            isLoading = false
                            return true
                        }
                    } catch {
                        print("Error creating user: \(error.localizedDescription)")
                    }
                }
                
                isLoading = false
                return false
            }
        } catch {
            print("Error refreshing user: \(error.localizedDescription)")
            isLoading = false
            return false
        }
    }
    
    /// Sign out the current user
    /// - Parameter completion: Completion handler with success boolean and optional error
    func signOut(completion: @escaping (Bool, Error?) -> Void = {_,_ in }) async {
        isLoading = true
        errorMessage = nil
        
        do {
            try authService.signOut()
            isLoading = false
            completion(true, nil)
        } catch {
            isLoading = false
            errorMessage = mapAuthError(error)
            completion(false, error)
        }
    }
    
    /// Reset password for a user
    /// - Parameters:
    ///   - email: User's email
    ///   - completion: Completion handler with success boolean and optional error
    func resetPassword(for email: String, completion: @escaping (Bool, Error?) -> Void = {_,_ in }) async {
        guard isValidEmail(email) else {
            errorMessage = "Please enter a valid email address"
            completion(false, NSError(domain: "AuthViewModel", code: 100, userInfo: [NSLocalizedDescriptionKey: "Invalid email format"]))
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            try await authService.resetPassword(for: email)
            isLoading = false
            completion(true, nil)
        } catch {
            isLoading = false
            errorMessage = mapAuthError(error)
            completion(false, error)
        }
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
    
    /// Maps Firebase Auth errors to user-friendly error messages
    /// - Parameter error: Firebase Auth error
    /// - Returns: User-friendly error message
    private func mapAuthError(_ error: Error) -> String {
        let nsError = error as NSError
        
        // Check if it's a network-related error
        if nsError.domain == NSURLErrorDomain {
            return "Network error. Please check your connection and try again."
        }
        
        // For Firebase Auth errors
        if nsError.domain == AuthErrorDomain {
            switch nsError.code {
            case 17009, 17011: // Invalid email or password
                return "Invalid email or password. Please try again."
            case 17008: // Invalid email format
                return "Please enter a valid email address."
            case 17007: // Email already in use
                return "This email is already in use. Try signing in or use a different email."
            case 17026: // Weak password
                return "Password is too weak. Please use a stronger password."
            case 17005: // User disabled
                return "This account has been disabled. Please contact support."
            case 17020: // Network error
                return "Network error. Please check your connection and try again."
            case 17010: // Too many failed attempts
                return "Too many failed attempts. Please try again later."
            default:
                return error.localizedDescription
            }
        }
        
        // For Firestore errors
        if nsError.domain == FirestoreErrorDomain {
            switch nsError.code {
            case 7: // Not found
                return "User profile not found. Please try signing in again."
            case 14: // Unavailable
                return "Service temporarily unavailable. Please try again later."
            case 2: // Internal error
                return "An unexpected error occurred. Please try again."
            default:
                return error.localizedDescription
            }
        }
        
        return error.localizedDescription
    }
}
