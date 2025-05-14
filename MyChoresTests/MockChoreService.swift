// filepath: /Users/debchow/Documents/coco/MyChores/MyChoresTests/MockChoreService.swift
import Foundation
import Combine
@testable import MyChores
import XCTest // Import XCTest

class MockChoreService: ChoreServiceProtocol {

    // Updated createChore signature to include createdByUserId and other details
    func createChore(
        title: String,
        description: String?,
        householdId: String,
        assignedToUserId: String?,
        createdByUserId: String, // Added
        dueDate: Date?,
        pointValue: Int,
        isRecurring: Bool,
        recurrenceType: RecurrenceType?,
        recurrenceInterval: Int?,
        recurrenceDaysOfWeek: [Int]?,
        recurrenceDayOfMonth: Int?,
        recurrenceEndDate: Date?
    ) async throws -> Chore {
        createChoreCalled = true
        lastCreatedChoreTitle = title
        lastHouseholdId = householdId // This likely refers to the householdId parameter of createChore
        lastAssignedToUserId = assignedToUserId
        lastCreatedByUserId = createdByUserId // Store this
        lastDueDate = dueDate
        lastPointValue = pointValue
        lastIsRecurring = isRecurring
        // Store other recurrence params if needed for assertions, e.g.:
        // self.lastRecurrenceType = recurrenceType 
        // ...

        if let error = errorToThrow {
            throw error
        }
        
        let newChore = Chore(
            id: UUID().uuidString, // Generate an ID for the new chore for mock purposes
            title: title,
            description: description ?? "",
            householdId: householdId,
            assignedToUserId: assignedToUserId,
            createdByUserId: createdByUserId, // Ensure Chore model has this
            dueDate: dueDate,
            isCompleted: false,
            createdAt: Date(),
            completedAt: nil,
            completedByUserId: nil,
            pointValue: pointValue,
            isRecurring: isRecurring,
            recurrenceType: recurrenceType,
            recurrenceInterval: recurrenceInterval,
            recurrenceDaysOfWeek: recurrenceDaysOfWeek,
            recurrenceDayOfMonth: recurrenceDayOfMonth,
            recurrenceEndDate: recurrenceEndDate,
            nextOccurrenceDate: nil // Or calculate if necessary for mock
        )
        return choreToReturn ?? newChore
    }
    
    var choresToReturn: [Chore] = []
    var choreToReturn: Chore?
    var errorToThrow: Error?
    var pointsToReturnOnComplete: Int = 0

    // --- Control properties for testing delays and specific errors ---
    var fetchChoresDelay: TimeInterval? = nil
    var fetchChoresShouldThrowAfterDelay: Error? = nil
    var fetchChoreDelay: TimeInterval? = nil
    var fetchChoreShouldThrowAfterDelay: Error? = nil
    // Add similar delay/error properties for other methods if needed

    // --- Expectations for async testing ---
    var fetchChoresExpectation: XCTestExpectation?
    var fetchChoreExpectation: XCTestExpectation?
    // Add other expectations as needed

    var fetchChoresCalled = false
    var fetchChoreCalled = false
    var createChoreCalled = false
    var updateChoreCalled = false
    var completeChoreCalled = false
    var deleteChoreCalled = false
    
    var lastHouseholdId: String?
    var lastChoreId: String?
    var lastCreatedChoreTitle: String?
    // Add properties to store all parameters of the new createChore
    var lastAssignedToUserId: String?
    var lastCreatedByUserId: String? // To store createdByUserId
    var lastDueDate: Date?
    var lastPointValue: Int?
    var lastIsRecurring: Bool?
    // Example for recurrence params if needed for detailed tests
    var lastRecurrenceType: MyChores.RecurrenceType?
    var lastRecurrenceInterval: Int?
    var lastRecurrenceDaysOfWeek: [Int]?
    var lastRecurrenceDayOfMonth: Int?
    var lastRecurrenceEndDate: Date?

    var lastUpdatedChore: Chore?
    var lastCompletedChoreId: String?
    var lastCompletedByUserId: String?
    var lastCreateNextRecurrenceFlag: Bool?

    // --- Properties to track parameters for fetchChores ---
    var lastHouseholdIdForFetchChores: String?
    var lastIncludeCompletedForFetchChores: Bool?

    // Properties for the new completeChore return type
    var mockCompletedChoreToReturn: Chore? 
    var mockNextRecurringChoreToReturn: Chore? 

    func fetchChores(forHouseholdId householdId: String, includeCompleted: Bool) async throws -> [Chore] {
        fetchChoresCalled = true
        lastHouseholdIdForFetchChores = householdId
        lastIncludeCompletedForFetchChores = includeCompleted

        if let delay = fetchChoresDelay {
            try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
        }
        
        defer { fetchChoresExpectation?.fulfill() }

        if let error = fetchChoresShouldThrowAfterDelay ?? errorToThrow {
            throw error
        }
        return choresToReturn
    }

    func fetchChore(withId choreId: String) async throws -> Chore? {
        fetchChoreCalled = true
        lastChoreId = choreId

        if let delay = fetchChoreDelay {
            try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
        }
        
        defer { fetchChoreExpectation?.fulfill() }

        if let error = fetchChoreShouldThrowAfterDelay ?? errorToThrow {
            throw error
        }
        return choreToReturn
    }

    func updateChore(_ chore: Chore) async throws {
        updateChoreCalled = true
        lastUpdatedChore = chore
        if let error = errorToThrow {
            throw error
        }
        // Optionally, update choresToReturn or choreToReturn if needed for subsequent fetches
    }

    // MODIFIED: Signature and return type to match protocol
    func completeChore(choreId: String, completedByUserId: String, createNextRecurrence: Bool) async throws -> (completedChore: Chore, pointsEarned: Int, nextRecurringChore: Chore?) {
        completeChoreCalled = true
        lastCompletedChoreId = choreId
        lastCompletedByUserId = completedByUserId
        lastCreateNextRecurrenceFlag = createNextRecurrence
        if let error = errorToThrow {
            throw error
        }

        var choreToComplete: Chore
        if let providedMock = mockCompletedChoreToReturn, providedMock.id == choreId {
            choreToComplete = providedMock
        } else if let index = choresToReturn.firstIndex(where: { $0.id == choreId }) {
            choresToReturn[index].isCompleted = true
            choresToReturn[index].completedByUserId = completedByUserId
            choresToReturn[index].completedAt = Date()
            choreToComplete = choresToReturn[index]
        } else {
            // Default mock chore if not found or no specific mock provided
            choreToComplete = Chore(
                id: choreId, title: "Mock Completed Chore", description: "", householdId: "mockHousehold",
                assignedToUserId: nil, createdByUserId: "mockCreator", dueDate: nil, 
                isCompleted: true, createdAt: Date(), completedAt: Date(), completedByUserId: completedByUserId, 
                pointValue: pointsToReturnOnComplete, isRecurring: false
            )
        }
        
        let points = choreToComplete.pointValue
        var nextChore: Chore? = nil
        if createNextRecurrence && choreToComplete.isRecurring {
            nextChore = mockNextRecurringChoreToReturn ?? choreToComplete.createNextOccurrence() // Use provided mock or generate
            if nextChore != nil && mockNextRecurringChoreToReturn == nil { // if generated, add to list for future fetches
                 // choresToReturn.append(nextChore!)
            } else if let specificNextMock = mockNextRecurringChoreToReturn {
                nextChore = specificNextMock
            }
        }

        return (completedChore: choreToComplete, pointsEarned: points, nextRecurringChore: nextChore)
    }

    func deleteChore(withId choreId: String) async throws {
        deleteChoreCalled = true
        lastChoreId = choreId // Re-using lastChoreId for simplicity
        if let error = errorToThrow {
            throw error
        }
        choresToReturn.removeAll { $0.id == choreId }
    }

    // MARK: - Added to conform to ChoreServiceProtocol
    func fetchChores(forUserId userId: String, includeCompleted: Bool) async throws -> [Chore] {
        // Basic mock implementation
        // You can add more specific tracking if needed, e.g., lastUserIdForFetchChoresByUserId
        if let error = errorToThrow {
            throw error
        }
        // Filter choresToReturn by assignedToUserId or createdByUserId based on your logic
        return choresToReturn.filter { $0.assignedToUserId == userId || $0.createdByUserId == userId }
    }

    func fetchOverdueChores(forHouseholdId householdId: String) async throws -> [Chore] {
        // Basic mock implementation
        if let error = errorToThrow {
            throw error
        }
        let now = Date()
        return choresToReturn.filter { $0.householdId == householdId && !$0.isCompleted && ($0.dueDate ?? now) < now }
    }

    func fetchCompletedChores(byCompleterUserId userId: String) async throws -> [Chore] {
        // Basic mock implementation
        if let error = errorToThrow {
            throw error
        }
        return choresToReturn.filter { $0.completedByUserId == userId && $0.isCompleted }
    }

    func deleteAllChores(forHouseholdId householdId: String) async throws {
        // Basic mock implementation
        if let error = errorToThrow {
            throw error
        }
        choresToReturn.removeAll { $0.householdId == householdId }
    }
    
    // Helper to reset mock state
    func reset() {
        fetchChoresCalled = false
        fetchChoreCalled = false
        createChoreCalled = false
        updateChoreCalled = false
        completeChoreCalled = false
        deleteChoreCalled = false

        lastHouseholdId = nil
        lastChoreId = nil
        lastCreatedChoreTitle = nil
        lastUpdatedChore = nil
        lastCompletedChoreId = nil
        lastCompletedByUserId = nil
        lastCreateNextRecurrenceFlag = nil
        
        lastHouseholdIdForFetchChores = nil
        lastIncludeCompletedForFetchChores = nil

        // Reset createChore params
        lastAssignedToUserId = nil
        lastCreatedByUserId = nil
        lastDueDate = nil
        lastPointValue = nil
        lastIsRecurring = nil
        // lastRecurrenceType = nil // etc.

        choresToReturn = []
        choreToReturn = nil
        errorToThrow = nil
        pointsToReturnOnComplete = 0
        
        fetchChoresDelay = nil
        fetchChoresShouldThrowAfterDelay = nil
        fetchChoreDelay = nil
        fetchChoreShouldThrowAfterDelay = nil
        
        fetchChoresExpectation = nil
        fetchChoreExpectation = nil
        
        // Reset new mock properties for completeChore
        mockCompletedChoreToReturn = nil
        mockNextRecurringChoreToReturn = nil
    }
}
