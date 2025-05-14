// ChoreService.swift
// MyChores
//
// Created on 2025-05-02.
//

import Foundation
import FirebaseFirestore
import FirebaseAuth

// MARK: - ChoreServiceProtocol
protocol ChoreServiceProtocol {
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
    ) async throws -> Chore
    func fetchChore(withId id: String) async throws -> Chore?
    func fetchChores(forHouseholdId householdId: String, includeCompleted: Bool) async throws -> [Chore]
    func fetchChores(forUserId userId: String, includeCompleted: Bool) async throws -> [Chore]
    func fetchOverdueChores(forHouseholdId householdId: String) async throws -> [Chore]
    func fetchCompletedChores(byCompleterUserId userId: String) async throws -> [Chore]
    func updateChore(_ chore: Chore) async throws
    func completeChore(choreId: String, completedByUserId: String, createNextRecurrence: Bool) async throws -> Int
    func deleteChore(withId choreId: String) async throws
    func deleteAllChores(forHouseholdId householdId: String) async throws
}

/// Service for chore data operations
class ChoreService: ChoreServiceProtocol {
    // MARK: - Shared Instance
    
    /// Shared instance for singleton access
    static let shared = ChoreService(userService: UserService.shared, notificationService: NotificationService.shared)
    
    // MARK: - Private Properties
    
    /// Firestore database reference
    private let db = Firestore.firestore()
    
    /// Chores collection reference
    private var choresCollection: CollectionReference {
        return db.collection("chores")
    }
    
    // MARK: - Dependencies (NEW)
    private let userService: UserServiceProtocol // NEW
    private let notificationService: NotificationServiceProtocol // NEW
    
    // MARK: - Initialization
    
    /// Private initializer to enforce singleton pattern
    private init(userService: UserServiceProtocol, notificationService: NotificationServiceProtocol) {
        self.userService = userService // NEW
        self.notificationService = notificationService // NEW
    }
    
    // MARK: - Chore CRUD Operations
    
    /// Create a new chore
    /// - Parameters:
    ///   - title: Chore title
    ///   - description: Detailed description
    ///   - householdId: Household ID
    ///   - assignedToUserId: User ID the chore is assigned to (optional)
    ///   - dueDate: Due date for completion (optional)
    ///   - pointValue: Points awarded for completion
    ///   - isRecurring: Whether this is a recurring chore
    ///   - recurrenceType: Type of recurrence (daily, weekly, monthly)
    ///   - recurrenceInterval: Interval between recurrences
    ///   - recurrenceDaysOfWeek: Days of week for weekly recurrence
    ///   - recurrenceDayOfMonth: Day of month for monthly recurrence
    ///   - recurrenceEndDate: End date for recurring chores
    /// - Returns: The created Chore
    func createChore(
        title: String,
        description: String? = nil,
        householdId: String,
        assignedToUserId: String? = nil,
        createdByUserId: String, // Added
        dueDate: Date? = nil,
        pointValue: Int,
        isRecurring: Bool = false,
        recurrenceType: RecurrenceType? = nil,
        recurrenceInterval: Int? = nil,
        recurrenceDaysOfWeek: [Int]? = nil,
        recurrenceDayOfMonth: Int? = nil,
        recurrenceEndDate: Date? = nil
    ) async throws -> Chore {
        // Get the current user ID
        guard let currentUserId = Auth.auth().currentUser?.uid else {
            throw NSError(domain: "ChoreService", code: 401, userInfo: [NSLocalizedDescriptionKey: "User must be logged in to create a chore"])
        }
        
        // Create a new chore
        let newChore = Chore(
            title: title,
            description: description ?? "",
            householdId: householdId,
            assignedToUserId: assignedToUserId,
            createdByUserId: currentUserId,
            dueDate: dueDate,
            isCompleted: false,
            createdAt: Date(),
            pointValue: pointValue,
            isRecurring: isRecurring,
            recurrenceType: recurrenceType,
            recurrenceInterval: recurrenceInterval,
            recurrenceDaysOfWeek: recurrenceDaysOfWeek,
            recurrenceDayOfMonth: recurrenceDayOfMonth,
            recurrenceEndDate: recurrenceEndDate,
            nextOccurrenceDate: dueDate
        )
        
        // Add to Firestore
        if let id = newChore.id {
            try choresCollection.document(id).setData(from: newChore)
        } else {
            let docRef = try choresCollection.addDocument(from: newChore)
            // Update the chore with its new ID
            try await choresCollection.document(docRef.documentID).updateData([
                "id": docRef.documentID
            ])
        }
        
        // Schedule a notification if due date is set
        if let dueDate = dueDate, let assignedToUserId = assignedToUserId {
            NotificationService.shared.scheduleChoreReminder(
                choreId: newChore.id ?? "",
                title: title,
                forUserId: assignedToUserId,
                dueDate: dueDate
            )
        }
        
        return newChore
    }
    
    /// Fetch a specific chore by ID
    /// - Parameter id: Chore ID
    /// - Returns: Chore if found, nil otherwise
    func fetchChore(withId id: String) async throws -> Chore? {
        let documentSnapshot = try await choresCollection.document(id).getDocument()
        return try documentSnapshot.data(as: Chore.self)
    }
    
    /// Fetch all chores for a household
    /// - Parameters:
    ///   - householdId: Household ID
    ///   - includeCompleted: Whether to include completed chores
    /// - Returns: Array of chores
    func fetchChores(forHouseholdId householdId: String, includeCompleted: Bool = true) async throws -> [Chore] {
        var query = choresCollection
            .whereField("householdId", isEqualTo: householdId)
        
        if !includeCompleted {
            query = query.whereField("isCompleted", isEqualTo: false)
        }
        
        let querySnapshot = try await query.getDocuments()
        
        return querySnapshot.documents.compactMap { document in
            try? document.data(as: Chore.self)
        }
    }
    
    /// Fetch chores assigned to a specific user
    /// - Parameters:
    ///   - userId: User ID
    ///   - includeCompleted: Whether to include completed chores
    /// - Returns: Array of chores
    func fetchChores(forUserId userId: String, includeCompleted: Bool = true) async throws -> [Chore] {
        var query = choresCollection
            .whereField("assignedToUserId", isEqualTo: userId)
        
        if !includeCompleted {
            query = query.whereField("isCompleted", isEqualTo: false)
        }
        
        let querySnapshot = try await query.getDocuments()
        
        return querySnapshot.documents.compactMap { document in
            try? document.data(as: Chore.self)
        }
    }
    
    /// Fetch overdue chores for a household
    /// - Parameter householdId: Household ID
    /// - Returns: Array of overdue chores
    func fetchOverdueChores(forHouseholdId householdId: String) async throws -> [Chore] {
        let now = Date()
        
        let querySnapshot = try await choresCollection
            .whereField("householdId", isEqualTo: householdId)
            .whereField("isCompleted", isEqualTo: false)
            .whereField("dueDate", isLessThan: now)
            .getDocuments()
        
        return querySnapshot.documents.compactMap { document in
            try? document.data(as: Chore.self)
        }
    }
    
    /// Fetch chores completed by a specific user
    /// - Parameter userId: User ID who completed the chores
    /// - Returns: Array of completed chores
    func fetchCompletedChores(byCompleterUserId userId: String) async throws -> [Chore] {
        let query = choresCollection
            .whereField("completedByUserId", isEqualTo: userId)
            .whereField("isCompleted", isEqualTo: true)
        
        let querySnapshot = try await query.getDocuments()
        
        return querySnapshot.documents.compactMap { document in
            try? document.data(as: Chore.self)
        }
    }

    /// Update a chore
    /// - Parameter chore: The updated chore object
    func updateChore(_ chore: Chore) async throws {
        guard let id = chore.id else {
            throw NSError(domain: "ChoreService", code: 1, userInfo: [NSLocalizedDescriptionKey: "Chore has no ID"])
        }
        
        try choresCollection.document(id).setData(from: chore)
        
        // If there's a due date and assignee, update the notification
        if let dueDate = chore.dueDate, let assignedToUserId = chore.assignedToUserId, !chore.isCompleted {
            // MODIFIED: Use injected notificationService
            self.notificationService.scheduleChoreReminder(
                choreId: id,
                title: chore.title,
                forUserId: assignedToUserId,
                dueDate: dueDate
            )
        }
    }
    
    /// Mark a chore as completed
    /// - Parameters:
    ///   - choreId: Chore ID
    ///   - completedByUserId: User ID of who completed it
    ///   - createNextRecurrence: Whether to create the next occurrence for recurring chores
    /// - Returns: Points awarded for completion
    func completeChore(choreId: String, completedByUserId: String, createNextRecurrence: Bool = true) async throws -> Int {
        // Fetch the chore
        guard var chore = try await fetchChore(withId: choreId) else {
            throw NSError(domain: "ChoreService", code: 1, userInfo: [NSLocalizedDescriptionKey: "Chore not found"])
        }
        
        // Make sure it's not already completed
        guard !chore.isCompleted else {
            throw NSError(domain: "ChoreService", code: 2, userInfo: [NSLocalizedDescriptionKey: "Chore is already completed"])
        }
        
        // Update completion status
        chore.isCompleted = true
        chore.completedAt = Date()
        chore.completedByUserId = completedByUserId
        
        // Save changes
        try await updateChore(chore)
        
        // Award points to the user
        // MODIFIED: Use injected userService
        try await self.userService.updateUserPoints(userId: completedByUserId, points: chore.pointValue)
        
        // Check for badges
        try await checkAndAwardBadges(forUserId: completedByUserId)
        
        // Create next occurrence if recurring
        if createNextRecurrence && chore.isRecurring {
            if let nextChore = chore.createNextOccurrence() {
                _ = try await createChore(
                    title: nextChore.title,
                    description: nextChore.description,
                    householdId: nextChore.householdId,
                    assignedToUserId: nextChore.assignedToUserId, createdByUserId: nextChore.createdByUserId ?? "",
                    dueDate: nextChore.dueDate,
                    pointValue: nextChore.pointValue,
                    isRecurring: nextChore.isRecurring,
                    recurrenceType: nextChore.recurrenceType,
                    recurrenceInterval: nextChore.recurrenceInterval,
                    recurrenceDaysOfWeek: nextChore.recurrenceDaysOfWeek,
                    recurrenceDayOfMonth: nextChore.recurrenceDayOfMonth,
                    recurrenceEndDate: nextChore.recurrenceEndDate
                )
            }
        }
        
        return chore.pointValue
    }
    
    /// Delete a chore
    /// - Parameter choreId: Chore ID to delete
    func deleteChore(withId choreId: String) async throws {
        try await choresCollection.document(choreId).delete()
        
        // Cancel any notifications
        // MODIFIED: Use injected notificationService
        self.notificationService.cancelChoreReminder(choreId: choreId)
    }
    
    /// Delete all chores for a household
    /// - Parameter householdId: Household ID
    func deleteAllChores(forHouseholdId householdId: String) async throws {
        let chores = try await fetchChores(forHouseholdId: householdId)
        
        for chore in chores {
            if let id = chore.id {
                try await deleteChore(withId: id)
            }
        }
    }
    
    // MARK: - Badge Management
    
    /// Check and award badges based on completed chore count
    /// - Parameter userId: User ID to check
    private func checkAndAwardBadges(forUserId userId: String) async throws {
        // Get completed chore count
        let completedChores = try await choresCollection
            .whereField("completedByUserId", isEqualTo: userId)
            .whereField("isCompleted", isEqualTo: true)
            .getDocuments()
        
        let choreCount = completedChores.documents.count
        
        // Check for first chore badge
        if choreCount >= 1 {
            // MODIFIED: Use injected userService
            _ = try await self.userService.awardBadge(to: userId, badgeKey: "first_chore")
        }
        
        // Check for 10 chores badge
        if choreCount >= 10 {
            // MODIFIED: Use injected userService
            _ = try await self.userService.awardBadge(to: userId, badgeKey: "ten_chores")
        }
        
        // Check for 50 chores badge
        if choreCount >= 50 {
            // MODIFIED: Use injected userService
            _ = try await self.userService.awardBadge(to: userId, badgeKey: "fifty_chores")
        }
    }
}
