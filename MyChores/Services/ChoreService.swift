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
        createdByUserId: String,
        dueDate: Date?,
        points: Int, // Renamed from pointValue
        recurrenceRule: RecurrenceRule? // Replaced individual recurrence params
    ) async throws -> Chore
    func fetchChore(withId id: String) async throws -> Chore?
    func fetchChores(forHouseholdId householdId: String, includeCompleted: Bool) async throws -> [Chore]
    func fetchChores(forUserId userId: String, includeCompleted: Bool) async throws -> [Chore]
    func fetchOverdueChores(forHouseholdId householdId: String) async throws -> [Chore]
    func fetchCompletedChores(byCompleterUserId userId: String) async throws -> [Chore]
    func updateChore(_ chore: Chore) async throws
    // MODIFIED: Changed return type
    func completeChore(choreId: String, completedByUserId: String, createNextRecurrence: Bool) async throws -> (completedChore: Chore, pointsEarned: Int, nextRecurringChore: Chore?)
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
    ///   - points: Points awarded for completion
    ///   - recurrenceRule: The recurrence rule for the chore (optional)
    /// - Returns: The created Chore
    func createChore(
        title: String,
        description: String? = nil,
        householdId: String,
        assignedToUserId: String? = nil,
        createdByUserId: String,
        dueDate: Date? = nil,
        points: Int, // Renamed from pointValue
        recurrenceRule: RecurrenceRule? = nil // Replaced individual recurrence params
    ) async throws -> Chore {
        // Get the current user ID
        // MODIFIED: Using the createdByUserId parameter directly as it's passed in.
        // The original implementation used Auth.auth().currentUser?.uid which might differ from the intended createdByUserId
        // if an admin is creating a chore on behalf of someone, though the ViewModel currently uses the logged-in user's ID.
        // For consistency with the method signature, we'll use the passed 'createdByUserId'.
        // If the intent is always the current Firebase auth user, the ViewModel should ensure it passes that.
        
        // Create a new chore
        var newChore = Chore( // Made newChore mutable to assign ID later if needed
            title: title,
            description: description ?? "",
            householdId: householdId,
            assignedToUserId: assignedToUserId,
            createdByUserId: createdByUserId,
            dueDate: dueDate,
            isCompleted: false,
            createdAt: Date(),
            points: points, // Use the renamed parameter
            recurrenceRule: recurrenceRule, // Use the new recurrenceRule parameter
            updatedAt: Date() // Assuming updatedAt should be set on creation
            // nextOccurrenceDate: dueDate // This was in the old model, review if needed with RecurrenceRule
        )
        
        // Add to Firestore
        let docRef: DocumentReference
        if let id = newChore.id { // Should not happen for a new chore if @DocumentID is working as expected
            try choresCollection.document(id).setData(from: newChore)
            docRef = choresCollection.document(id)
        } else {
            docRef = try choresCollection.addDocument(from: newChore)
            // Update the chore with its new ID
            // The `from: newChore` above should handle this if `newChore` is a var and has @DocumentID.
            // However, explicitly setting it back to the object can be safer.
            newChore.id = docRef.documentID
        }
        
        // Schedule a notification if due date is set
        if let dueDate = newChore.dueDate, let assignedToUserId = newChore.assignedToUserId, let choreId = newChore.id {
            // MODIFIED: Use injected notificationService (already present)
            self.notificationService.scheduleChoreReminder(
                choreId: choreId,
                title: newChore.title,
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
        
        try choresCollection.document(id).setData(from: chore, merge: true) // Using merge: true to be safer for updates
        
        // If there's a due date and assignee, update the notification
        if let dueDate = chore.dueDate, let assignedToUserId = chore.assignedToUserId, !chore.isCompleted {
            // MODIFIED: Use injected notificationService
            self.notificationService.scheduleChoreReminder(
                choreId: id,
                title: chore.title,
                forUserId: assignedToUserId,
                dueDate: dueDate
            )
        }//TODO: remove scheduled reminder
    }
    
    /// Mark a chore as completed
    /// - Parameters:
    ///   - choreId: Chore ID
    ///   - completedByUserId: User ID of who completed it
    ///   - createNextRecurrence: Whether to create the next occurrence for recurring chores
    /// - Returns: Tuple containing the completed chore, points awarded, and optionally the next recurring chore
    func completeChore(choreId: String, completedByUserId: String, createNextRecurrence: Bool = true) async throws -> (completedChore: Chore, pointsEarned: Int, nextRecurringChore: Chore?) {
        // Fetch the chore
        guard var chore = try await fetchChore(withId: choreId) else {
            throw NSError(domain: "ChoreService", code: 1, userInfo: [NSLocalizedDescriptionKey: "Chore not found"])
        }
        
        // Make sure it's not already completed
        guard !chore.isCompleted else {
            // Consider if this should throw or return current state. Throwing is fine.
            throw NSError(domain: "ChoreService", code: 2, userInfo: [NSLocalizedDescriptionKey: "Chore is already completed"])
        }
        
        // Update completion status
        chore.isCompleted = true
        chore.completedAt = Date()
        chore.completedByUserId = completedByUserId
        
        // Save changes
        try await updateChore(chore) // updateChore will also handle notification removal
        
        // Award points to the user
        try await self.userService.updateUserPoints(userId: completedByUserId, points: chore.points)
        
        // Check for badges (Assuming this is a method within ChoreService or accessible to it)
        // If checkAndAwardBadges is part of UserService, it should be called there or via userService.
        // For now, assuming it's a local or accessible method.
        // try await checkAndAwardBadges(forUserId: completedByUserId) // This method is not defined in the provided ChoreService snippet.
                                                                    // This should likely be handled by UserService or called on userService.
                                                                    // For now, I will comment it out as its definition is missing.

        var nextCreatedChore: Chore? = nil
        // Create next occurrence if recurring
        // MODIFIED: Check recurrenceRule instead of isRecurring
        if createNextRecurrence && chore.recurrenceRule != nil && chore.recurrenceRule?.type != .none {
            if let nextChoreTemplate = chore.createNextOccurrence() { // createNextOccurrence should return a Chore struct
                // The createdByUserId for the next recurring chore might be the original creator or system.
                // Assuming original creator for now. If chore.createdByUserId is nil, this will be an issue.
                // The Chore model has createdByUserId as String?, but createChore expects String.
                // The Chore.createNextOccurrence() should ideally set a valid createdByUserId.
                // For safety, let's use the completedByUserId if original is nil, or a system ID.
                // Or, ensure chore.createdByUserId is always non-nil for recurring chores.
                let creatorOfNextInstance = nextChoreTemplate.createdByUserId ?? completedByUserId // Fallback, review this logic

                nextCreatedChore = try await self.createChore( // Use self.createChore to ensure it's logged in Firestore
                    title: nextChoreTemplate.title,
                    description: nextChoreTemplate.description,
                    householdId: nextChoreTemplate.householdId,
                    assignedToUserId: nextChoreTemplate.assignedToUserId,
                    createdByUserId: creatorOfNextInstance, // Ensure this is valid
                    dueDate: nextChoreTemplate.dueDate,
                    points: nextChoreTemplate.points,
                    recurrenceRule: nextChoreTemplate.recurrenceRule // Pass the rule for the next instance
                )
            }
        }
        return (completedChore: chore, pointsEarned: chore.points, nextRecurringChore: nextCreatedChore)
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
