// filepath: /Users/debchow/Documents/coco/MyChores/MyChoresTests/ViewModelTests/ChoreViewModelTests.swift
import XCTest
import Combine
@testable import MyChores

class ChoreViewModelTests: XCTestCase {

    var mockChoreService: MockChoreService!
    var mockUserService: MockUserService!
    var mockAuthService: MockAuthService!
    var sut: ChoreViewModel!
    var cancellables: Set<AnyCancellable>!

    let testHouseholdId = "test-household"
    let testUserId = "test-user"
    let testUserName = "test-name"

    override func setUpWithError() throws {
        try super.setUpWithError()
        mockChoreService = MockChoreService()
        mockUserService = MockUserService()
        mockAuthService = MockAuthService()
        
        mockAuthService.currentUser = User(id: testUserId, name: testUserName, email: "test@example.com")
        mockAuthService.isAuthenticated = true
        mockAuthService.authState = .authenticated

        // SUT is initialized here for general tests, but specific init tests will re-initialize.
        sut = ChoreViewModel(
            householdId: testHouseholdId,
            authService: mockAuthService, choreService: mockChoreService,
            userService: mockUserService
        )
        cancellables = []
    }

    override func tearDownWithError() throws {
        sut = nil
        mockChoreService = nil
        mockUserService = nil
        mockAuthService = nil
        cancellables = nil
        try super.tearDownWithError()
    }

    // MARK: - Initialization Tests

    @MainActor func testInitialization_loadsChores() {
        let expectation = XCTestExpectation(description: "fetchChores should be called on init")
        mockChoreService.fetchChoresExpectation = expectation
        mockChoreService.fetchChoresCalled = false // Reset for this specific test as SUT in setup already called it

        // Re-initialize SUT for this specific test
        sut = ChoreViewModel(
            householdId: testHouseholdId,
            authService: mockAuthService, choreService: mockChoreService,
            userService: mockUserService
        )

        wait(for: [expectation], timeout: 1.0)
        XCTAssertTrue(mockChoreService.fetchChoresCalled, "fetchChores should have been called during initialization.")
        XCTAssertEqual(mockChoreService.lastHouseholdIdForFetchChores, testHouseholdId, "fetchChores was called with the correct householdId.")
        XCTAssertFalse(mockChoreService.lastIncludeCompletedForFetchChores ?? true, "fetchChores should initially not include completed chores by default from ChoreViewModel's loadChores -> loadChoresAsync.")
    }

    @MainActor func testInitialization_withChoreId_loadsSpecificChore() {
        let specificChoreId = "chore-123"
        let fetchChoresExp = XCTestExpectation(description: "fetchChores should be called on init")
        let fetchChoreExp = XCTestExpectation(description: "fetchChore should be called on init with choreId")
        
        mockChoreService.fetchChoresExpectation = fetchChoresExp
        mockChoreService.fetchChoreExpectation = fetchChoreExp
        mockChoreService.fetchChoresCalled = false // Reset
        mockChoreService.fetchChoreCalled = false // Reset

        // Re-initialize SUT for this specific test
        sut = ChoreViewModel(
            householdId: testHouseholdId,
            choreId: specificChoreId,
            authService: mockAuthService, choreService: mockChoreService,
            userService: mockUserService
        )

        wait(for: [fetchChoresExp, fetchChoreExp], timeout: 1.0)
        XCTAssertTrue(mockChoreService.fetchChoresCalled, "fetchChores should have been called.")
        XCTAssertTrue(mockChoreService.fetchChoreCalled, "fetchChore should have been called.")
        XCTAssertEqual(mockChoreService.lastChoreId, specificChoreId, "fetchChore was called with the correct choreId.")
    }

    // MARK: - Load Chores Tests
    @MainActor
    func testLoadChores_Success_PopulatesChores() async {
        let expectedChores = [Chore.sample, Chore.sample2]
        mockChoreService.choresToReturn = expectedChores
        
        await sut.loadChoresAsync() // Directly call the async version

        XCTAssertEqual(sut.chores.count, expectedChores.count, "Chores array should be populated.")
        XCTAssertEqual(sut.chores.first?.id, expectedChores.first?.id)
        XCTAssertFalse(sut.isLoading, "isLoading should be false after successful load.")
        XCTAssertNil(sut.errorMessage, "errorMessage should be nil after successful load.")
    }

    @MainActor
    func testLoadChores_Failure_SetsErrorMessage() async {
        let expectedError = TestError.customError("Failed to fetch chores")
        mockChoreService.errorToThrow = expectedError
        
        await sut.loadChoresAsync()

        XCTAssertTrue(sut.chores.isEmpty, "Chores array should be empty on failure.")
        XCTAssertFalse(sut.isLoading, "isLoading should be false after failure.")
        XCTAssertNotNil(sut.errorMessage, "errorMessage should be set after failure.")
        XCTAssertEqual(sut.errorMessage, expectedError.localizedDescription)
    }
    
    @MainActor
    func testLoadChores_EmptyState_HandlesCorrectly() async {
        mockChoreService.choresToReturn = [] // Service returns an empty array
        
        await sut.loadChoresAsync()

        XCTAssertTrue(sut.chores.isEmpty, "Chores array should be empty.")
        XCTAssertFalse(sut.isLoading, "isLoading should be false.")
        XCTAssertNil(sut.errorMessage, "errorMessage should be nil when an empty list is returned.")
    }
    
    // MARK: - IsLoading State Tests

    @MainActor
    func testIsLoading_TrueWhileLoadingChores() async {
        let expectation = XCTestExpectation(description: "Loading chores completes")
        mockChoreService.fetchChoresExpectation = expectation
        mockChoreService.fetchChoresDelay = 0.1 // Introduce a small delay

        // Call loadChores, which internally calls the async version
        sut.loadChores() 
        
        XCTAssertTrue(sut.isLoading, "isLoading should be true immediately after starting loadChores.")

        await fulfillment(of: [expectation], timeout: 0.5)
        
        // After the async operation completes, isLoading should be false.
        // This check might need to be on the next run loop cycle if not using await sut.loadChoresAsync() directly.
        // Since loadChores calls loadChoresAsync which is @MainActor, this should be fine.
        XCTAssertFalse(sut.isLoading, "isLoading should be false after chores have loaded.")
    }
    
    // MARK: - Load Chores Async Tests (Covered by testLoadChores_Success_PopulatesChores etc. using loadChoresAsync)
    // func testLoadChoresAsync_Success_PopulatesChores() async {…} // Already implemented above


    // MARK: - Load Chore (Single) Tests
    @MainActor
    func testLoadChore_Success_SetsSelectedChore() async {
        let specificChoreId = "chore-abc"
        let expectedChore = Chore(title: specificChoreId, description: "householdId", householdId: "householdId", createdAt: Date(), pointValue: 0)
        mockChoreService.choreToReturn = expectedChore
        
        sut.selectedChore = nil // Ensure it's nil before test
        await sut.loadChoreAsync(id: specificChoreId) // Assuming a loadChoreAsync exists or loadChore calls an async version

        XCTAssertNotNil(sut.selectedChore, "selectedChore should be set.")
        XCTAssertEqual(sut.selectedChore?.id, specificChoreId)
        XCTAssertFalse(sut.isLoading, "isLoading should be false.")
        XCTAssertNil(sut.errorMessage, "errorMessage should be nil.")
    }

    @MainActor
    func testLoadChore_Failure_SetsErrorMessage() async {
        let specificChoreId = "chore-def"
        let expectedError = TestError.customError("Failed to fetch single chore")
        mockChoreService.errorToThrow = expectedError
        
        sut.selectedChore = nil
        await sut.loadChoreAsync(id: specificChoreId)

        XCTAssertNil(sut.selectedChore, "selectedChore should remain nil on failure.")
        XCTAssertFalse(sut.isLoading, "isLoading should be false.")
        XCTAssertNotNil(sut.errorMessage, "errorMessage should be set.")
        XCTAssertEqual(sut.errorMessage, expectedError.localizedDescription)
    }

    @MainActor
    func testLoadChore_NotFound_HandlesCorrectly() async {
        let specificChoreId = "chore-ghi"
        mockChoreService.choreToReturn = nil // Service returns nil (not found)
        
        sut.selectedChore = Chore.sample // Set to something to ensure it's cleared
        await sut.loadChoreAsync(id: specificChoreId)

        XCTAssertNil(sut.selectedChore, "selectedChore should be nil if chore not found.")
        XCTAssertFalse(sut.isLoading, "isLoading should be false.")
        // Depending on desired behavior, errorMessage might be nil or indicate "not found"
        // For now, let's assume it's nil if no error was thrown, just no data.
        // If ChoreViewModel sets an error for "not found", this assertion needs to change.
        XCTAssertNil(sut.errorMessage, "errorMessage should be nil if chore not found and no error thrown.")
    }

}

// Helper Error for testing
enum TestError: Error, LocalizedError {
    case customError(String)
    var errorDescription: String? {
        switch self {
        case .customError(let message):
            return message
        }
    }
}

// Helper extension for Chore samples if not already present in test target
extension Chore {
    static var sample: Chore {
        
        Chore(
            id: "sample_chore_4",
            title: "Buy groceries",
            description: "Milk, eggs, bread, fruits, and vegetables",
            householdId: "sample_household_id",
            dueDate: Calendar.current.date(byAdding: .day, value: -1, to: Date()),
            isCompleted: false,
            createdAt: Date().addingTimeInterval(-86400 * 3),
            pointValue: 2
        )
        
    }
    static var sample2: Chore {
        
        Chore(
            id: "sample_4",
            title: "Buy groceries",
            description: "Milk, eggs, bread, fruits, and vegetables",
            householdId: "sample_household_id",
            dueDate: Calendar.current.date(byAdding: .day, value: -1, to: Date()),
            isCompleted: false,
            createdAt: Date().addingTimeInterval(-86400 * 3),
            pointValue: 2
        )
    }
}
