// AuthViewModel.swift
// MyChores
//
// Created on 2025-05-02.
//

import Foundation
import Combine
import SwiftUI

/// ViewModel for authentication-related views
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
            .sink { [weak self] state in
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
            .sink { [weak self] user in
                self?.currentUser = user
                if user != nil && self?.authState == .authenticatedButProfileIncomplete {
                    self?.authState = .authenticated
                }
            }
            .store(in: &cancellables)
        
        authService.$errorMessage
            .receive(on: DispatchQueue.main)
            .assign(to: \.errorMessage, on: self)
            .store(in: &cancellables)
    }
    
    // MARK: - Authentication Methods
    
    /// Sign in with email and password
    /// - Parameters:
    ///   - email: User's email
    ///   - password: User's password
    func signIn(email: String, password: String, completion: @escaping (Bool, Error?) -> Void) {
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                try await authService.signIn(email: email, password: password)
                DispatchQueue.main.async {
                    self.isLoading = false
                    completion(true, nil)
                }
            } catch {
                DispatchQueue.main.async {
                    self.isLoading = false
                    self.errorMessage = error.localizedDescription
                    completion(false, error)
                }
            }
        }
    }
    
    /// Create a new account
    /// - Parameters:
    ///   - name: User's name
    ///   - email: User's email
    ///   - password: User's password
    func signUp(name: String, email: String, password: String) {
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                try await authService.signUp(name: name, email: email, password: password)
                DispatchQueue.main.async {
                    self.isLoading = false
                }
            } catch {
                DispatchQueue.main.async {
                    self.isLoading = false
                    self.errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    /// Sign out the current user
    func signOut() {
        isLoading = true
        errorMessage = nil
        
        do {
            try authService.signOut()
            isLoading = false
        } catch {
            isLoading = false
            errorMessage = error.localizedDescription
        }
    }
    
    /// Reset password for a user
    /// - Parameter email: User's email
    func resetPassword(for email: String) {
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                try await authService.resetPassword(for: email)
                DispatchQueue.main.async {
                    self.isLoading = false
                }
            } catch {
                DispatchQueue.main.async {
                    self.isLoading = false
                    self.errorMessage = error.localizedDescription
                }
            }
        }
    }
}
