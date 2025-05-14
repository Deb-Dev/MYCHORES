//
//  AuthViewModelTests.swift
//  MyChoresTests
//
//  Created by Debasish Chowdhury on 2025-05-13.
//

import XCTest
import Combine
@testable import MyChores

@MainActor
class AuthViewModelTests: XCTestCase {

    var mockAuthService: MockAuthService!
    var viewModel: AuthViewModel!
    private var cancellables: Set<AnyCancellable>!

    override func setUpWithError() throws {
        try super.setUpWithError()
        mockAuthService = MockAuthService()
        viewModel = AuthViewModel(authService: mockAuthService)
        cancellables = []
    }

    override func tearDownWithError() throws {
        mockAuthService = nil
        viewModel = nil
        cancellables = nil
        try super.tearDownWithError()
    }

    func testSignIn_Success() async {
        // Arrange
        mockAuthService.signInShouldSucceed = true
        mockAuthService.mockUserToReturnOnSuccess = User.sample
        let expectation = XCTestExpectation(description: "Sign in completes and updates state")

        // Act
        var signInError: Error?
        await viewModel.signIn(email: "test@example.com", password: "password") { success, error in
            XCTAssertTrue(success)
            XCTAssertNil(error)
            signInError = error
            expectation.fulfill()
        }
        
        await fulfillment(of: [expectation], timeout: 1.0)

        // Assert
        XCTAssertNil(signInError)
        XCTAssertEqual(viewModel.authState, .authenticated)
        XCTAssertNotNil(viewModel.currentUser)
        XCTAssertEqual(viewModel.currentUser?.email, "sample@example.com")
        XCTAssertNil(viewModel.errorMessage) // ErrorMessage on ViewModel should be nil
        XCTAssertNil(mockAuthService.errorMessage) // ErrorMessage on Service should be nil
    }

    func testSignIn_Failure() async {
        // Arrange
        mockAuthService.signInShouldSucceed = false
        let expectedError = NSError(domain: "MockAuthService", code: 123, userInfo: [NSLocalizedDescriptionKey: "Mocked sign in failure"])
        mockAuthService.mockErrorToReturnOnFailure = expectedError
        
        // Pre-condition: ViewModel's errorMessage should be nil initially
        XCTAssertNil(viewModel.errorMessage, "Pre-condition: ViewModel errorMessage should be nil.")

        let signInMethodCompletionExpectation = XCTestExpectation(description: "viewModel.signIn completion handler executed")
        let errorMessageUpdateExpectation = XCTestExpectation(description: "ViewModel errorMessage updated to the expected error message")
        
        // Subscribe to viewModel.errorMessage changes
        let cancellable = viewModel.$errorMessage
            .sink { [weak self] currentErrorMessage in
                // This sink will be called with the initial value (nil)
                // and then with the new value when it's set.
                guard self != nil else { return } // Ensure test context is still valid
                
                if currentErrorMessage == expectedError.localizedDescription {
                    errorMessageUpdateExpectation.fulfill()
                }
            }
        cancellables.insert(cancellable) // Manage the subscription

        // Act
        var signInErrorFromCompletion: Error?
        await viewModel.signIn(email: "test@example.com", password: "password") { success, error in
            XCTAssertFalse(success, "signIn success should be false on failure.")
            XCTAssertNotNil(error, "signIn error should not be nil on failure.")
            signInErrorFromCompletion = error
            signInMethodCompletionExpectation.fulfill()
        }
        
        // Wait for both the signIn method's own completion handler AND the errorMessage to be updated in the ViewModel
        await fulfillment(of: [signInMethodCompletionExpectation, errorMessageUpdateExpectation], timeout: 2.0)

        // Assert
        XCTAssertNotNil(signInErrorFromCompletion, "Error object from signIn completion should exist.")
        if let nsError = signInErrorFromCompletion as NSError? {
            XCTAssertEqual(nsError.domain, expectedError.domain, "Error domain should match.")
            XCTAssertEqual(nsError.code, expectedError.code, "Error code should match.")
            XCTAssertEqual(nsError.localizedDescription, expectedError.localizedDescription, "Error localizedDescription should match.")
        }
        
        // Assert final ViewModel state
        XCTAssertEqual(viewModel.authState, .unauthenticated, "ViewModel authState should be .unauthenticated.")
        XCTAssertNil(viewModel.currentUser, "ViewModel currentUser should be nil.")
        XCTAssertEqual(viewModel.errorMessage, expectedError.localizedDescription, "ViewModel errorMessage should be the expected error message.")
    }

    func testSignUp_Success() async {
        // Arrange
        mockAuthService.signUpShouldSucceed = true
        let sampleUser = User(id: "newUser123", name: "New User", email: "new@example.com")
        mockAuthService.mockUserToReturnOnSuccess = sampleUser
        let expectation = XCTestExpectation(description: "Sign up completes and updates state")

        // Act
        var signUpError: Error?
        await viewModel.signUp(name: "New User", email: "new@example.com", password: "password123") { success, error in
            XCTAssertTrue(success)
            XCTAssertNil(error)
            signUpError = error
            expectation.fulfill()
        }
        
        await fulfillment(of: [expectation], timeout: 1.0)

        // Assert
        XCTAssertNil(signUpError)
        XCTAssertEqual(viewModel.authState, .authenticated)
        XCTAssertNotNil(viewModel.currentUser)
        XCTAssertEqual(viewModel.currentUser?.name, "New User")
        XCTAssertNil(viewModel.errorMessage)
    }
    
    func testSignIn_InvalidEmail_Empty() async {
        // Arrange
        let expectation = XCTestExpectation(description: "Sign in with empty email fails")

        // Act
        var signInError: Error?
        await viewModel.signIn(email: "", password: "password") { success, error in
            XCTAssertFalse(success)
            XCTAssertNotNil(error)
            signInError = error
            expectation.fulfill()
        }
        
        await fulfillment(of: [expectation], timeout: 1.0)

        // Assert
        XCTAssertNotNil(signInError)
        XCTAssertEqual((signInError as NSError?)?.localizedDescription, "Invalid email format.")
    }

    func testCurrentUserUpdateFromService() {
        // Arrange
        let expectation = XCTestExpectation(description: "ViewModel's currentUser updates when service's currentUser changes")
        
        viewModel.$currentUser
            .dropFirst() // Ignore initial value
            .sink { user in
                XCTAssertEqual(user?.id, "serviceUpdateUser")
                expectation.fulfill()
            }
            .store(in: &cancellables)

        // Act
        let updatedUser = User(id: "serviceUpdateUser", name: "Updated Name", email: "updated@example.com")
        mockAuthService.currentUser = updatedUser // Directly set on mock
        mockAuthService.objectWillChange.send() // Manually trigger the publisher

        // Assert
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testUpdateUserName_Success() async {
        // Arrange
        let initialUser = User.sample

        let initialLoadExpectation = XCTestExpectation(description: "Initial user loaded into ViewModel")

        viewModel.$currentUser
            .first(where: { $0?.id == initialUser.id })
            .sink { user in
                XCTAssertNotNil(user, "User should not be nil when initial load expectation is fulfilled.")
                XCTAssertEqual(user?.id, initialUser.id, "User ID should match initialUser.id.")
                initialLoadExpectation.fulfill()
            }
            .store(in: &cancellables)

        mockAuthService.currentUser = initialUser
        mockAuthService.authState = .authenticated
        mockAuthService.isAuthenticated = true
        mockAuthService.objectWillChange.send()

        await fulfillment(of: [initialLoadExpectation], timeout: 2.0)

        XCTAssertEqual(viewModel.currentUser?.name, initialUser.name, "Pre-condition: ViewModel currentUser name should be the initial name after load.")
        XCTAssertEqual(viewModel.currentUser?.id, initialUser.id, "Pre-condition: ViewModel currentUser ID should be the initial ID after load.")


        mockAuthService.updateUserNameShouldSucceed = true
        let newName = "Updated Name"
        
        let userNameUpdatedExpectation = XCTestExpectation(description: "ViewModel currentUser name updates to newName")

        viewModel.$currentUser
            .first(where: { user -> Bool in
                return user?.name == newName && user?.id == initialUser.id
            })
            .sink { [weak self] updatedUser in
                guard let self = self else { return }
                XCTAssertNotNil(updatedUser, "Updated user should not be nil.")
                XCTAssertEqual(updatedUser?.name, newName, "User's name should be updated to newName in the sink.")
                XCTAssertNil(self.viewModel.errorMessage, "Error message should be nil on successful name update in the sink.")
                userNameUpdatedExpectation.fulfill()
            }
            .store(in: &cancellables)

        // Act: Call the method that should trigger the update
        await viewModel.updateUserName(newName: newName)
        
        await fulfillment(of: [userNameUpdatedExpectation], timeout: 2.0)
        
        XCTAssertEqual(self.viewModel.currentUser?.name, newName, "ViewModel currentUser name should be updated (final direct check).")
        XCTAssertNil(self.viewModel.errorMessage, "ViewModel errorMessage should be nil on success (final direct check).")
    }

    // MARK: - Sign Up Tests

    func testSignUp_Failure() async {
        // Arrange
        mockAuthService.signUpShouldSucceed = false
        let expectedError = NSError(domain: "MockAuthService", code: 456, userInfo: [NSLocalizedDescriptionKey: "Mocked sign up failure"])
        mockAuthService.mockErrorToReturnOnFailure = expectedError

        let signUpCompletionExpectation = XCTestExpectation(description: "viewModel.signUp completion handler executed for failure")
        let errorMessageExpectation = XCTestExpectation(description: "ViewModel errorMessage updated after failed signUp")

        viewModel.$errorMessage
            .dropFirst() // Ignore initial nil
            .sink { errorMessage in
                if errorMessage == expectedError.localizedDescription {
                    errorMessageExpectation.fulfill()
                }
            }
            .store(in: &cancellables)

        // Act
        var signUpError: Error?
        await viewModel.signUp(name: "Test User", email: "test@example.com", password: "password123") { success, error in
            XCTAssertFalse(success)
            XCTAssertNotNil(error)
            signUpError = error
            signUpCompletionExpectation.fulfill()
        }

        await fulfillment(of: [signUpCompletionExpectation, errorMessageExpectation], timeout: 2.0)

        // Assert
        XCTAssertNotNil(signUpError)
        XCTAssertEqual(viewModel.authState, .unauthenticated)
        XCTAssertNil(viewModel.currentUser)
        XCTAssertEqual(viewModel.errorMessage, expectedError.localizedDescription)
    }

    func testSignUp_InvalidInput_EmptyName() async {
        // Arrange
        let expectation = XCTestExpectation(description: "Sign up with empty name fails")

        // Act
        var signUpError: Error?
        await viewModel.signUp(name: "", email: "test@example.com", password: "password123") { success, error in
            XCTAssertFalse(success)
            XCTAssertNotNil(error)
            signUpError = error
            expectation.fulfill()
        }
        
        await fulfillment(of: [expectation], timeout: 1.0)

        // Assert
        XCTAssertNotNil(signUpError)
        XCTAssertEqual((signUpError as NSError?)?.localizedDescription, "Name cannot be empty.")
        XCTAssertEqual(viewModel.authState, .unauthenticated) // Should not change state
        XCTAssertNil(viewModel.currentUser)
    }

    func testSignUp_InvalidInput_InvalidEmail() async {
        // Arrange
        let expectation = XCTestExpectation(description: "Sign up with invalid email fails")

        // Act
        var signUpError: Error?
        await viewModel.signUp(name: "Test User", email: "invalid-email", password: "password123") { success, error in
            XCTAssertFalse(success)
            XCTAssertNotNil(error)
            signUpError = error
            expectation.fulfill()
        }
        
        await fulfillment(of: [expectation], timeout: 1.0)

        // Assert
        XCTAssertNotNil(signUpError)
        XCTAssertEqual((signUpError as NSError?)?.localizedDescription, "Invalid email format.")
    }

    func testSignUp_InvalidInput_ShortPassword() async {
        // Arrange
        let expectation = XCTestExpectation(description: "Sign up with short password fails")

        // Act
        var signUpError: Error?
        await viewModel.signUp(name: "Test User", email: "test@example.com", password: "123") { success, error in
            XCTAssertFalse(success)
            XCTAssertNotNil(error)
            signUpError = error
            expectation.fulfill()
        }
        
        await fulfillment(of: [expectation], timeout: 1.0)

        // Assert
        XCTAssertNotNil(signUpError)
        XCTAssertEqual((signUpError as NSError?)?.localizedDescription, "Password must be at least 6 characters.")
    }

    // MARK: - Refresh Current User Tests

    func testRefreshCurrentUser_Success() async {
        // Arrange
        let refreshedUser = User(id: "refreshedUser123", name: "Refreshed User", email: "refreshed@example.com")
        mockAuthService.mockUserToReturnOnSuccess = refreshedUser // User to be returned on refresh
        mockAuthService.refreshCurrentUserShouldSucceed = true
        
        // Set an initial different user or nil to ensure refresh causes a change
        let initialUser = User.sample
        mockAuthService.currentUser = initialUser
        mockAuthService.authState = .authenticated // Ensure service is in an authenticated state
        mockAuthService.isAuthenticated = true
        mockAuthService.objectWillChange.send() // Ensure viewModel picks up initial state
        
        // Expectation for currentUser to be updated to the refreshedUser
        let refreshExpectation = XCTestExpectation(description: "ViewModel currentUser updates after refreshCurrentUser")
        
        viewModel.$currentUser
            .first(where: { $0?.id == refreshedUser.id })
            .sink { user in
                XCTAssertEqual(user?.name, refreshedUser.name)
                refreshExpectation.fulfill()
            }
            .store(in: &cancellables)
        
        // Act
        let success = await viewModel.refreshCurrentUser()
        
        // Assert
        XCTAssertTrue(success, "refreshCurrentUser should return true on success.")
        await fulfillment(of: [refreshExpectation], timeout: 2.0)
        XCTAssertEqual(viewModel.currentUser?.id, refreshedUser.id)
        XCTAssertEqual(viewModel.currentUser?.name, refreshedUser.name)
        XCTAssertNil(viewModel.errorMessage, "Error message should be nil on successful refresh.")
        XCTAssertFalse(viewModel.isLoading, "isLoading should be false after operation.")
        XCTAssertEqual(viewModel.authState, .authenticated) // Verify auth state
    }

    func testRefreshCurrentUser_Failure() async {
        // Arrange
        let initialUser = User.sample // User that is currently "logged in"

        // Expectation for the ViewModel to correctly reflect the initial authenticated state
        let initialStateExpectation = XCTestExpectation(description: "ViewModel correctly reflects initial authenticated state from mock service")

        // Subscribe to changes that indicate the desired initial state
        // This sink will fulfill the expectation when both currentUser and authState are correctly set.
        viewModel.$currentUser
            .combineLatest(viewModel.$authState)
            .first(where: { user, authState in
                // Check if the ViewModel's currentUser matches the initialUser's ID
                // and if the ViewModel's authState is .authenticated.
                // Note: AuthViewModel.mapAuthState maps AuthService.AuthState.authenticated to AuthViewModel.AuthState.authenticated
                // if the user's name is not empty (which is true for User.sample).
                return user?.id == initialUser.id && authState == .authenticated
            })
            .sink { _ in
                initialStateExpectation.fulfill()
            }
            .store(in: &cancellables)

        // Set up the mock service state
        mockAuthService.currentUser = initialUser
        mockAuthService.isAuthenticated = true
        mockAuthService.authState = .authenticated // This is AuthService.AuthState
        mockAuthService.objectWillChange.send() // Trigger the ViewModel's sink to update its state

        // Wait for the ViewModel to update to the initial state
        await fulfillment(of: [initialStateExpectation], timeout: 2.0)

        // Pre-condition checks (should now pass)
        XCTAssertEqual(viewModel.currentUser?.id, initialUser.id, "Pre-condition: ViewModel should have the initial user.")
        XCTAssertEqual(viewModel.authState, .authenticated, "Pre-condition: ViewModel authState should be authenticated.")

        // Now, configure the mock service for the refresh failure
        mockAuthService.refreshCurrentUserShouldSucceed = false
        let expectedError = NSError(domain: "MockAuthService", code: 789, userInfo: [NSLocalizedDescriptionKey: "Mocked refresh user failure"])
        mockAuthService.mockErrorToReturnOnFailure = expectedError
        
        let errorMessageExpectation = XCTestExpectation(description: "ViewModel errorMessage updated after failed refreshCurrentUser")
        
        viewModel.$errorMessage
            .first(where: { $0 == expectedError.localizedDescription }) // Expect the specific error message
            .sink { _ in
                errorMessageExpectation.fulfill()
            }
            .store(in: &cancellables)

        // Act
        let success = await viewModel.refreshCurrentUser()

        // Assert
        XCTAssertFalse(success, "refreshCurrentUser should return false on failure.")
        await fulfillment(of: [errorMessageExpectation], timeout: 2.0)
        
        XCTAssertEqual(viewModel.errorMessage, expectedError.localizedDescription, "ViewModel errorMessage should match the expected error.")
        
        // Verify that the user state in the ViewModel remains unchanged
        XCTAssertNotNil(viewModel.currentUser, "ViewModel currentUser should not be nil after a failed refresh.")
        XCTAssertEqual(viewModel.currentUser?.id, initialUser.id, "ViewModel currentUser ID should remain that of the initial user.")
        XCTAssertEqual(viewModel.currentUser?.name, initialUser.name, "ViewModel currentUser name should remain that of the initial user.")
        
        // Verify that the auth state in the ViewModel remains authenticated
        XCTAssertEqual(viewModel.authState, .authenticated, "ViewModel authState should remain .authenticated after a failed refresh.")
        
        XCTAssertFalse(viewModel.isLoading, "isLoading should be false after operation.")
    }

    func testRefreshCurrentUser_UserNotLoggedIn() async {
        // Arrange
        // Expectation for the ViewModel to correctly reflect the initial unauthenticated state
        let initialStateExpectation = XCTestExpectation(description: "ViewModel correctly reflects initial unauthenticated state")

        viewModel.$currentUser
            .combineLatest(viewModel.$authState)
            .first(where: { user, authState in
                // Expect currentUser to be nil and authState to be .unauthenticated
                // AuthViewModel.mapAuthState maps AuthService.AuthState.unauthenticated to AuthViewModel.AuthState.unauthenticated
                return user == nil && authState == .unauthenticated
            })
            .sink { _ in
                initialStateExpectation.fulfill()
            }
            .store(in: &cancellables)

        // Set up the mock service for an unauthenticated state
        mockAuthService.currentUser = nil
        mockAuthService.isAuthenticated = false
        mockAuthService.authState = .unauthenticated // This is AuthService.AuthState
        mockAuthService.objectWillChange.send() // Trigger the ViewModel's sink

        // Wait for the ViewModel to update to the initial unauthenticated state
        await fulfillment(of: [initialStateExpectation], timeout: 2.0)

        // Pre-condition checks (should now pass)
        XCTAssertNil(viewModel.currentUser, "Pre-condition: currentUser should be nil.")
        XCTAssertEqual(viewModel.authState, .unauthenticated, "Pre-condition: authState should be unauthenticated.")

        // Act
        let success = await viewModel.refreshCurrentUser()

        // Assert
        XCTAssertFalse(success, "refreshCurrentUser should return false if no user is logged in.")
        XCTAssertNil(viewModel.errorMessage, "Error message should be nil as no service call was made for refresh.")
        XCTAssertFalse(viewModel.isLoading, "isLoading should be false as no operation started.")
        XCTAssertEqual(viewModel.authState, .unauthenticated) // AuthState should remain unauthenticated
    }

    // MARK: - Sign Out Tests

    func testSignOut_Success() async {
        // Arrange
        let initialUser = User.sample

        // Expectation for the ViewModel to correctly reflect the initial authenticated state
        let initialStateExpectation = XCTestExpectation(description: "ViewModel correctly reflects initial authenticated state for sign out success test")

        viewModel.$currentUser
            .combineLatest(viewModel.$authState)
            .first(where: { user, authState in
                return user?.id == initialUser.id && authState == .authenticated
            })
            .sink { _ in
                initialStateExpectation.fulfill()
            }
            .store(in: &cancellables)
        
        // Simulate an authenticated user state in the service
        mockAuthService.currentUser = initialUser
        mockAuthService.isAuthenticated = true
        mockAuthService.authState = .authenticated // AuthService.AuthState
        mockAuthService.objectWillChange.send() // Propagate initial state

        // Wait for ViewModel to reflect the initial authenticated state
        await fulfillment(of: [initialStateExpectation], timeout: 2.0)

        // Pre-condition: Ensure ViewModel is in an authenticated state before sign out
        XCTAssertEqual(viewModel.authState, .authenticated, "Pre-condition: ViewModel should be authenticated.")
        XCTAssertNotNil(viewModel.currentUser, "Pre-condition: ViewModel currentUser should not be nil.")

        let signOutStateExpectation = XCTestExpectation(description: "Sign out completes and updates state to unauthenticated")
        
        // Observe authState for change to .unauthenticated
        viewModel.$authState
            .first(where: { $0 == .unauthenticated })
            .sink { _ in
                signOutStateExpectation.fulfill()
            }
            .store(in: &cancellables)

        var signOutError: Error?
        var signOutSuccess: Bool = false

        // Act
        await viewModel.signOut { success, error in
            signOutSuccess = success
            signOutError = error
        }

        // Assert
        await fulfillment(of: [signOutStateExpectation], timeout: 2.0)
        
        XCTAssertTrue(signOutSuccess, "signOut completion success should be true.")
        XCTAssertNil(signOutError, "signOut completion error should be nil.")
        
        XCTAssertEqual(viewModel.authState, .unauthenticated, "ViewModel authState should be .unauthenticated after sign out.")
        XCTAssertNil(viewModel.currentUser, "ViewModel currentUser should be nil after sign out.")
        XCTAssertNil(viewModel.errorMessage, "ViewModel errorMessage should be nil on successful sign out.")
        XCTAssertFalse(viewModel.isLoading, "isLoading should be false after operation.")
    }

    func testSignOut_Failure() async {
        // Arrange
        let initialUser = User.sample
        let expectedError = NSError(domain: "MockAuthService", code: 101, userInfo: [NSLocalizedDescriptionKey: "Mocked sign out failure"])

        // Expectation for the ViewModel to correctly reflect the initial authenticated state
        let initialStateExpectation = XCTestExpectation(description: "ViewModel correctly reflects initial authenticated state for sign out failure test")

        viewModel.$currentUser
            .combineLatest(viewModel.$authState)
            .first(where: { user, authState in
                return user?.id == initialUser.id && authState == .authenticated
            })
            .sink { _ in
                initialStateExpectation.fulfill()
            }
            .store(in: &cancellables)

        // Simulate an authenticated user state in the service
        mockAuthService.currentUser = initialUser
        mockAuthService.isAuthenticated = true
        mockAuthService.authState = .authenticated // AuthService.AuthState
        mockAuthService.objectWillChange.send() // Propagate initial state
        
        // Wait for ViewModel to reflect the initial authenticated state
        await fulfillment(of: [initialStateExpectation], timeout: 2.0)

        // Pre-condition: Ensure ViewModel is in an authenticated state
        XCTAssertEqual(viewModel.authState, .authenticated, "Pre-condition: ViewModel should be authenticated.")
        XCTAssertNotNil(viewModel.currentUser, "Pre-condition: ViewModel currentUser should not be nil.")

        // Configure mock service for sign out failure
        mockAuthService.signOutShouldThrowError = true
        mockAuthService.errorToThrowOnSignOut = expectedError
        
        let errorMessageExpectation = XCTestExpectation(description: "ViewModel errorMessage updated after failed signOut")
        
        viewModel.$errorMessage
            .first(where: { $0 == expectedError.localizedDescription })
            .sink { _ in
                errorMessageExpectation.fulfill()
            }
            .store(in: &cancellables)

        var signOutError: Error?
        var signOutSuccess: Bool = true

        // Act
        await viewModel.signOut { success, error in
            signOutSuccess = success
            signOutError = error
        }

        // Assert
        await fulfillment(of: [errorMessageExpectation], timeout: 2.0)
        
        XCTAssertFalse(signOutSuccess, "signOut completion success should be false on failure.")
        XCTAssertNotNil(signOutError, "signOut completion error should not be nil on failure.")
        XCTAssertEqual((signOutError as NSError?)?.domain, expectedError.domain)
        XCTAssertEqual((signOutError as NSError?)?.code, expectedError.code)
        XCTAssertEqual((signOutError as NSError?)?.localizedDescription, expectedError.localizedDescription)
        
        XCTAssertEqual(viewModel.errorMessage, expectedError.localizedDescription, "ViewModel errorMessage should be the expected error message.")
        XCTAssertEqual(viewModel.authState, .authenticated, "ViewModel authState should remain .authenticated on signOut failure.")
        XCTAssertNotNil(viewModel.currentUser, "ViewModel currentUser should not be nil on signOut failure.")
        XCTAssertEqual(viewModel.currentUser?.id, initialUser.id, "ViewModel currentUser ID should remain unchanged.")
        XCTAssertFalse(viewModel.isLoading, "isLoading should be false after operation.")
    }
    
    func testSignOut_CompletionHandlerCalled() async {
        // Arrange
        let expectation = XCTestExpectation(description: "SignOut completion handler called")
        mockAuthService.currentUser = User.sample // Start as logged in
        mockAuthService.isAuthenticated = true
        mockAuthService.authState = .authenticated
        mockAuthService.objectWillChange.send()

        // Act
        await viewModel.signOut { success, error in
            // We just care that it's called. Success/error content is tested elsewhere.
            expectation.fulfill()
        }

        // Assert
        await fulfillment(of: [expectation], timeout: 1.0)
    }

    // MARK: - Reset Password Tests

    func testResetPassword_Success() async {
        // Arrange
        mockAuthService.resetPasswordShouldSucceed = true
        let email = "test@example.com"
        
        let expectation = XCTestExpectation(description: "Reset password completion handler called with success")
        var callbackSuccess: Bool = false
        var callbackError: Error?

        // Act
        await viewModel.resetPassword(for: email) { success, error in
            callbackSuccess = success
            callbackError = error
            expectation.fulfill()
        }

        // Assert
        await fulfillment(of: [expectation], timeout: 1.0)
        
        XCTAssertTrue(callbackSuccess, "Callback success should be true.")
        XCTAssertNil(callbackError, "Callback error should be nil.")
        XCTAssertNil(viewModel.errorMessage, "ViewModel errorMessage should be nil on successful password reset.")
        XCTAssertFalse(viewModel.isLoading, "isLoading should be false after operation.")
    }

    func testResetPassword_Failure() async {
        // Arrange
        mockAuthService.resetPasswordShouldSucceed = false
        let expectedError = NSError(domain: "MockAuthService", code: 102, userInfo: [NSLocalizedDescriptionKey: "Mocked password reset error"])
        mockAuthService.mockErrorForResetPassword = expectedError // Ensure this is set in the mock
        
        let email = "test@example.com"
        
        let completionExpectation = XCTestExpectation(description: "Reset password completion handler called with failure")
        let errorMessageExpectation = XCTestExpectation(description: "ViewModel errorMessage updated after failed password reset")

        var callbackSuccess: Bool = true
        var callbackError: Error?

        viewModel.$errorMessage
            .first(where: { $0 == expectedError.localizedDescription })
            .sink { _ in
                errorMessageExpectation.fulfill()
            }
            .store(in: &cancellables)

        // Act
        await viewModel.resetPassword(for: email) { success, error in
            callbackSuccess = success
            callbackError = error
            completionExpectation.fulfill()
        }

        // Assert
        await fulfillment(of: [completionExpectation, errorMessageExpectation], timeout: 2.0)
        
        XCTAssertFalse(callbackSuccess, "Callback success should be false on failure.")
        XCTAssertNotNil(callbackError, "Callback error should not be nil on failure.")
        XCTAssertEqual((callbackError as NSError?)?.localizedDescription, expectedError.localizedDescription, "Callback error message should match expected.")
        XCTAssertEqual(viewModel.errorMessage, expectedError.localizedDescription, "ViewModel errorMessage should be the expected error message.")
        XCTAssertFalse(viewModel.isLoading, "isLoading should be false after operation.")
    }

    func testResetPassword_CompletionHandlerCalled() async {
        // Arrange
        let email = "test@example.com"
        let expectation = XCTestExpectation(description: "Reset password completion handler called")

        // Act
        await viewModel.resetPassword(for: email) { success, error in
            expectation.fulfill()
        }

        // Assert
        await fulfillment(of: [expectation], timeout: 1.0)
    }

    // MARK: - Ensure User Profile Exists Tests

    func testEnsureUserProfileExists_Success_ProfileAlreadyExists() async {
        // Arrange
        let existingUser = User.sample
        mockAuthService.currentUser = existingUser
        mockAuthService.isAuthenticated = true
        mockAuthService.authState = .authenticated
        mockAuthService.refreshCurrentUserShouldSucceed = true // Used by ensureCurrentProfileExists in mock
        mockAuthService.objectWillChange.send() // Ensure ViewModel picks up initial state

        let initialStateExpectation = XCTestExpectation(description: "ViewModel reflects initial authenticated state")
        viewModel.$currentUser
            .combineLatest(viewModel.$authState)
            .first(where: { user, authState in
                user?.id == existingUser.id && authState == .authenticated
            })
            .sink { _ in initialStateExpectation.fulfill() }
            .store(in: &cancellables)
        
        await fulfillment(of: [initialStateExpectation], timeout: 1.0)
        XCTAssertEqual(viewModel.currentUser?.id, existingUser.id)
        XCTAssertEqual(viewModel.authState, .authenticated)

        // Act
        await viewModel.ensureUserProfileExists()

        // Assert
        XCTAssertEqual(viewModel.currentUser?.id, existingUser.id, "User should remain the same.")
        XCTAssertEqual(viewModel.authState, .authenticated, "Auth state should remain authenticated.")
        XCTAssertNil(viewModel.errorMessage, "Error message should be nil.")
        XCTAssertFalse(viewModel.isLoading, "isLoading should be false.")
    }

    func testEnsureUserProfileExists_Success_ProfileCreated() async {
        // Arrange
        let newUser = User(id: "newUserEnsure", name: "Ensured User", email: "ensure@example.com")
        mockAuthService.currentUser = nil // No user initially
        mockAuthService.isAuthenticated = false
        mockAuthService.authState = .unauthenticated
        mockAuthService.refreshCurrentUserShouldSucceed = true // To allow profile creation
        mockAuthService.mockUserToReturnOnSuccess = newUser // This user will be "created"
        mockAuthService.objectWillChange.send()

        let initialStateExpectation = XCTestExpectation(description: "ViewModel reflects initial unauthenticated state")
        viewModel.$currentUser
            .combineLatest(viewModel.$authState)
            .first(where: { user, authState in
                user == nil && authState == .unauthenticated
            })
            .sink { _ in initialStateExpectation.fulfill() }
            .store(in: &cancellables)
        await fulfillment(of: [initialStateExpectation], timeout: 1.0)
        XCTAssertNil(viewModel.currentUser)
        XCTAssertEqual(viewModel.authState, .unauthenticated)

        let profileCreatedExpectation = XCTestExpectation(description: "ViewModel updates with newly created user profile")
        viewModel.$currentUser
            .combineLatest(viewModel.$authState)
            .first(where: { user, authState in
                user?.id == newUser.id && authState == .authenticated
            })
            .sink { _ in profileCreatedExpectation.fulfill() }
            .store(in: &cancellables)

        // Act
        await viewModel.ensureUserProfileExists()

        // Assert
        await fulfillment(of: [profileCreatedExpectation], timeout: 2.0)
        XCTAssertEqual(viewModel.currentUser?.id, newUser.id, "User should be the newly created user.")
        XCTAssertEqual(viewModel.currentUser?.name, newUser.name)
        XCTAssertEqual(viewModel.authState, .authenticated, "Auth state should become authenticated.")
        XCTAssertNil(viewModel.errorMessage, "Error message should be nil.")
        XCTAssertFalse(viewModel.isLoading, "isLoading should be false.")
    }

    func testEnsureUserProfileExists_Failure() async {
        // Arrange
        mockAuthService.currentUser = nil // No user initially
        mockAuthService.isAuthenticated = false
        mockAuthService.authState = .unauthenticated
        mockAuthService.refreshCurrentUserShouldSucceed = false // To simulate failure
        let expectedErrorMessage = "Failed to ensure profile" // Specific error from mock
        // mockAuthService.mockErrorToReturnOnFailure is not directly used by ensureUserProfileExists, it sets its own error.
        mockAuthService.objectWillChange.send()

        let initialStateExpectation = XCTestExpectation(description: "ViewModel reflects initial unauthenticated state")
        viewModel.$currentUser
            .combineLatest(viewModel.$authState, viewModel.$errorMessage)
            .first(where: { user, authState, errMsg in
                user == nil && authState == .unauthenticated && errMsg == nil
            })
            .sink { _ in initialStateExpectation.fulfill() }
            .store(in: &cancellables)
        await fulfillment(of: [initialStateExpectation], timeout: 1.0)

        let profileCreationFailedExpectation = XCTestExpectation(description: "ViewModel updates error message on failure")
        viewModel.$errorMessage
            .first(where: { $0 == expectedErrorMessage })
            .sink { _ in profileCreationFailedExpectation.fulfill() }
            .store(in: &cancellables)

        // Act
        await viewModel.ensureUserProfileExists()

        // Assert
        await fulfillment(of: [profileCreationFailedExpectation], timeout: 2.0)
        XCTAssertNil(viewModel.currentUser, "User should remain nil.")
        XCTAssertEqual(viewModel.authState, .unauthenticated, "Auth state should remain unauthenticated.")
        XCTAssertEqual(viewModel.errorMessage, expectedErrorMessage, "Error message should be set.")
        XCTAssertFalse(viewModel.isLoading, "isLoading should be false.")
    }

    // MARK: - Update User Privacy Settings Tests

    func testUpdateUserPrivacySettings_Success() async {
        // Arrange
        let existingUser = User.sample
        mockAuthService.currentUser = existingUser
        mockAuthService.isAuthenticated = true
        mockAuthService.authState = .authenticated
        mockAuthService.updateUserPrivacySettingsShouldSucceed = true
        mockAuthService.objectWillChange.send()

        let initialStateExpectation = XCTestExpectation(description: "ViewModel reflects initial authenticated state")
        viewModel.$currentUser
            .first(where: { $0?.id == existingUser.id })
            .sink { _ in initialStateExpectation.fulfill() }
            .store(in: &cancellables)
        await fulfillment(of: [initialStateExpectation], timeout: 1.0)
        
        viewModel.errorMessage = "previous error" // Set a dummy error to ensure it's cleared

        // Act
        await viewModel.updateUserPrivacySettings(showProfile: true, showAchievements: true, shareActivity: false)

        // Assert
        XCTAssertNil(viewModel.errorMessage, "Error message should be nil on success.")
        XCTAssertFalse(viewModel.isLoading, "isLoading should be false.")
        // We cannot easily assert the change in privacySettings itself as the mock doesn't modify the User object directly in a way the ViewModel would re-publish.
        // The primary check is that no error occurred.
    }

    func testUpdateUserPrivacySettings_Failure() async {
        // Arrange
        let existingUser = User.sample
        mockAuthService.currentUser = existingUser
        mockAuthService.isAuthenticated = true
        mockAuthService.authState = .authenticated
        mockAuthService.updateUserPrivacySettingsShouldSucceed = false
        let expectedError = NSError(domain: "MockAuthService.Privacy", code: 99, userInfo: [NSLocalizedDescriptionKey: "Failed to update privacy settings"])
        mockAuthService.mockErrorToReturnOnFailure = expectedError // This error will be thrown by the mock
        mockAuthService.objectWillChange.send()

        let initialStateExpectation = XCTestExpectation(description: "ViewModel reflects initial authenticated state")
        viewModel.$currentUser
            .first(where: { $0?.id == existingUser.id })
            .sink { _ in initialStateExpectation.fulfill() }
            .store(in: &cancellables)
        await fulfillment(of: [initialStateExpectation], timeout: 1.0)

        let privacyUpdateFailedExpectation = XCTestExpectation(description: "ViewModel updates error message on privacy update failure")
        viewModel.$errorMessage
            .first(where: { $0 == expectedError.localizedDescription })
            .sink { _ in privacyUpdateFailedExpectation.fulfill() }
            .store(in: &cancellables)

        // Act
        await viewModel.updateUserPrivacySettings(showProfile: true, showAchievements: true, shareActivity: false)

        // Assert
        await fulfillment(of: [privacyUpdateFailedExpectation], timeout: 2.0)
        XCTAssertEqual(viewModel.errorMessage, expectedError.localizedDescription, "Error message should be set to the expected error.")
        XCTAssertFalse(viewModel.isLoading, "isLoading should be false.")
    }
    
    // MARK: - Update User Name Input Validation Tests

    func testUpdateUserName_InvalidInput_EmptyName() async {
        // Arrange
        let initialUser = User.sample
        mockAuthService.currentUser = initialUser
        mockAuthService.isAuthenticated = true
        mockAuthService.authState = .authenticated
        mockAuthService.objectWillChange.send()

        let initialStateExpectation = XCTestExpectation(description: "ViewModel reflects initial authenticated state")
        viewModel.$currentUser
            .first(where: { $0?.id == initialUser.id })
            .sink { _ in initialStateExpectation.fulfill() }
            .store(in: &cancellables)
        await fulfillment(of: [initialStateExpectation], timeout: 1.0)
        
        let originalName = viewModel.currentUser?.name
        XCTAssertNotNil(originalName, "Initial name should not be nil")

        let errorMessageExpectation = XCTestExpectation(description: "ViewModel errorMessage updated for empty name")
        viewModel.$errorMessage
            .first(where: { $0 == "Name cannot be empty." })
            .sink { _ in errorMessageExpectation.fulfill() }
            .store(in: &cancellables)

        // Act
        await viewModel.updateUserName(newName: "")

        // Assert
        await fulfillment(of: [errorMessageExpectation], timeout: 1.0)
        XCTAssertEqual(viewModel.errorMessage, "Name cannot be empty.")
        XCTAssertEqual(viewModel.currentUser?.name, originalName, "User name should not have changed.")
        XCTAssertFalse(viewModel.isLoading, "isLoading should be false as the service call was not made.")
    }

    func testUpdateUserName_InvalidInput_WhitespaceName() async {
        // Arrange
        let initialUser = User.sample
        mockAuthService.currentUser = initialUser
        mockAuthService.isAuthenticated = true
        mockAuthService.authState = .authenticated
        mockAuthService.objectWillChange.send()

        let initialStateExpectation = XCTestExpectation(description: "ViewModel reflects initial authenticated state")
        viewModel.$currentUser
            .first(where: { $0?.id == initialUser.id })
            .sink { _ in initialStateExpectation.fulfill() }
            .store(in: &cancellables)
        await fulfillment(of: [initialStateExpectation], timeout: 1.0)
        
        let originalName = viewModel.currentUser?.name
        XCTAssertNotNil(originalName, "Initial name should not be nil")

        let errorMessageExpectation = XCTestExpectation(description: "ViewModel errorMessage updated for whitespace name")
        viewModel.$errorMessage
            .first(where: { $0 == "Name cannot be empty." })
            .sink { _ in errorMessageExpectation.fulfill() }
            .store(in: &cancellables)
        
        // Act
        await viewModel.updateUserName(newName: "   ")

        // Assert
        await fulfillment(of: [errorMessageExpectation], timeout: 1.0)
        XCTAssertEqual(viewModel.errorMessage, "Name cannot be empty.")
        XCTAssertEqual(viewModel.currentUser?.name, originalName, "User name should not have changed.")
        XCTAssertFalse(viewModel.isLoading, "isLoading should be false as the service call was not made.")
    }
}

