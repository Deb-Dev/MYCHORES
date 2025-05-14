//
//  MockAuthService.swift
//  MyChores
//
//  Created by Debasish Chowdhury on 2025-05-13.
//

import Foundation
import Combine
@testable import MyChores // Import your app module

class MockAuthService: AuthServiceProtocol {
    var objectWillChange = ObservableObjectPublisher() // Required by ObservableObject

    var currentUser: User?
    var isAuthenticated: Bool = false
    var authState: AuthService.AuthState = .unauthenticated
    var errorMessage: String?

    // --- Control properties for testing ---
    var currentUserIdToReturn: String? // Added
    var signInShouldSucceed: Bool = true
    var signUpShouldSucceed: Bool = true
    var refreshCurrentUserShouldSucceed: Bool = true
    var updateUserPrivacySettingsShouldSucceed: Bool = true
    var updateUserNameShouldSucceed: Bool = true
    var signOutShouldThrowError: Bool = false // New control property for signOut failure
    var errorToThrowOnSignOut: Error = NSError(domain: "MockAuthService", code: 101, userInfo: [NSLocalizedDescriptionKey: "Mocked sign out error"]) // Specific error for signOut
    var resetPasswordShouldSucceed: Bool = true // New control property for resetPassword
    var mockErrorForResetPassword: Error = NSError(domain: "MockAuthService", code: 102, userInfo: [NSLocalizedDescriptionKey: "Mocked password reset error"]) // Specific error for resetPassword

    var mockUserToReturnOnSuccess: User? = User.sample // Define a sample user for tests
    var mockErrorToReturnOnFailure: Error = NSError(domain: "MockAuthService", code: 0, userInfo: [NSLocalizedDescriptionKey: "Mocked error"])

    // --- Protocol method implementations ---
    func signIn(email: String, password: String) async throws {
        if signInShouldSucceed {
            currentUser = mockUserToReturnOnSuccess
            isAuthenticated = true
            authState = .authenticated
            errorMessage = nil
            objectWillChange.send()
        } else {
            currentUser = nil
            isAuthenticated = false
            authState = .unauthenticated
            errorMessage = mockErrorToReturnOnFailure.localizedDescription
            objectWillChange.send()
            throw mockErrorToReturnOnFailure
        }
    }

    func signUp(name: String, email: String, password: String) async throws {
        if signUpShouldSucceed {
            currentUser = mockUserToReturnOnSuccess ?? User(id: "mockUserID", name: name, email: email)
            isAuthenticated = true
            authState = .authenticated
            errorMessage = nil
            objectWillChange.send()
        } else {
            currentUser = nil
            isAuthenticated = false
            authState = .unauthenticated
            errorMessage = mockErrorToReturnOnFailure.localizedDescription
            objectWillChange.send()
            throw mockErrorToReturnOnFailure
        }
    }

    func signOut() throws {
        if signOutShouldThrowError {
            errorMessage = errorToThrowOnSignOut.localizedDescription
            objectWillChange.send() // Notify observers about the error message change
            throw errorToThrowOnSignOut
        }
        // If not throwing, proceed with successful sign out
        currentUser = nil
        isAuthenticated = false
        authState = .unauthenticated
        errorMessage = nil
        objectWillChange.send()
    }

    func resetPassword(for email: String) async throws {
        if resetPasswordShouldSucceed {
            // Simulate successful password reset, no state change needed in mock for this
            self.errorMessage = nil // Clear any previous error
            objectWillChange.send()
        } else {
            self.errorMessage = mockErrorForResetPassword.localizedDescription
            objectWillChange.send()
            throw mockErrorForResetPassword
        }
    }

    func refreshCurrentUser() async throws -> User? {
        if refreshCurrentUserShouldSucceed {
            currentUser = mockUserToReturnOnSuccess
            isAuthenticated = mockUserToReturnOnSuccess != nil
            authState = isAuthenticated ? .authenticated : .unauthenticated
            errorMessage = nil
            objectWillChange.send()
            return currentUser
        } else { // refreshCurrentUserShouldSucceed == false
            // currentUser, isAuthenticated, authState REMAIN UNCHANGED on failure.
            // Only update errorMessage and signal change for that.
            errorMessage = mockErrorToReturnOnFailure.localizedDescription
            objectWillChange.send() // Propagates the errorMessage
            throw mockErrorToReturnOnFailure
        }
    }

    func getCurrentUserId() -> String? {
        return currentUserIdToReturn // Modified
    }

    func ensureCurrentProfileExists() async {
        if refreshCurrentUserShouldSucceed {
            if currentUser == nil {
                 currentUser = mockUserToReturnOnSuccess // Simulate profile creation/fetch
                 isAuthenticated = true
                 authState = .authenticated
                 errorMessage = nil // Clear any prior error message
            }
            // If currentUser already exists, this mock doesn't change state here.
        } else { // !refreshCurrentUserShouldSucceed implies failure to ensure/create profile
            currentUser = nil
            isAuthenticated = false
            authState = .unauthenticated
            errorMessage = "Failed to ensure profile" // Specific error for this scenario
        }
        objectWillChange.send() // Send after potential modifications
    }

    func updateUserPrivacySettings(showProfile: Bool, showAchievements: Bool, shareActivity: Bool) async throws {
        if updateUserPrivacySettingsShouldSucceed {
            // Optionally update a mock user's privacy settings if needed for verification
            // e.g., if var user = currentUser { user.privacySettings = ...; currentUser = user }
            errorMessage = nil
            objectWillChange.send()
        } else {
            errorMessage = mockErrorToReturnOnFailure.localizedDescription
            objectWillChange.send()
            throw mockErrorToReturnOnFailure
        }
    }
    
    func updateUserName(newName: String) async throws {
        if updateUserNameShouldSucceed {
            if var user = currentUser {
                user.name = newName
                currentUser = user
            } else if mockUserToReturnOnSuccess != nil { // If currentUser is nil, but we have a sample to use
                var tempUser = mockUserToReturnOnSuccess! 
                tempUser.name = newName
                currentUser = tempUser // User is now created/set
            }
            
            // Ensure other states are consistent if a user profile now exists
            if currentUser != nil {
                isAuthenticated = true
                authState = .authenticated
            }
            errorMessage = nil
            objectWillChange.send()
        } else {
            // Current mock logic only sets errorMessage on failure.
            // Consider if currentUser, isAuthenticated, authState should change.
            errorMessage = mockErrorToReturnOnFailure.localizedDescription
            objectWillChange.send()
            throw mockErrorToReturnOnFailure
        }
    }
}

// Add a sample User extension for easy mock data
extension User {
    static var sample: User {
        User(id: "sampleUserId",
             name: "Sample User",
             email: "sample@example.com",
             householdIds: ["household1"],
             createdAt: Date(),
             privacySettings: UserPrivacySettings(showProfile: true, showAchievements: true, shareActivity: true)
        )
    }
}

