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
    // MODIFIED: Changed return type to include earned badges
    func completeChore(choreId: String, completedByUserId: String, createNextRecurrence: Bool) async throws -> (completedChore: Chore, pointsEarned: Int, nextRecurringChore: Chore?, earnedBadges: [Badge])
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
            createdByUserId: createdByUserId, // Using parameter
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
            nextOccurrenceDate: dueDate // Assuming nextOccurrenceDate is initially the due date for new chores
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
    /// - Returns: Tuple containing the completed chore, points awarded, earned badges, and optionally the next recurring chore
    func completeChore(choreId: String, completedByUserId: String, createNextRecurrence: Bool = true) async throws -> (completedChore: Chore, pointsEarned: Int, nextRecurringChore: Chore?, earnedBadges: [Badge]) {
        // Fetch the chore
        guard var chore = try await fetchChore(withId: choreId) else {
            throw NSError(domain: "ChoreService", code: 1, userInfo: [NSLocalizedDescriptionKey: "Chore not found"])
        }
        
        // Make sure it's not already completed
        guard !chore.isCompleted else {
            // Consider if this should throw or return current state. Throwing is fine.
            throw NSError(domain: "ChoreService", code: 2, userInfo: [NSLocalizedDescriptionKey: "Chore is already completed"])
        }
        
        // Fetch user before completing to check which badges they already have
        guard var user = try await userService.fetchUser(withId: completedByUserId) else {
            throw NSError(domain: "ChoreService", code: 404, userInfo: [NSLocalizedDescriptionKey: "User not found"])
        }
        let existingBadges = Set(user.earnedBadges)
        
        // Update completion status
        let completionDate = Date()
        chore.isCompleted = true
        chore.completedAt = completionDate
        chore.completedByUserId = completedByUserId
        
        // Save changes
        try await updateChore(chore) // updateChore will also handle notification removal
        
        // Update streak information
        user.updateStreakInfo(completionDate: completionDate)
        
        // Check if the chore was completed early (before due date)
        if let dueDate = chore.dueDate {
            user.checkAndUpdateEarlyCompletion(completionDate: completionDate, dueDate: dueDate)
        }
        
        // Save user changes
        try await userService.updateUser(user)
        
        // Award points to the user
        try await self.userService.updateUserPoints(userId: completedByUserId, points: chore.pointValue)
        
        // Check for and award badges based on completion count
        try await checkAndAwardBadges(forUserId: completedByUserId)
        
        // Fetch user again to see which new badges were earned
        guard let updatedUser = try await userService.fetchUser(withId: completedByUserId) else {
            throw NSError(domain: "ChoreService", code: 404, userInfo: [NSLocalizedDescriptionKey: "User not found after badge update"])
        }
        
        // Determine newly earned badges
        let updatedBadges = Set(updatedUser.earnedBadges)
        let newlyEarnedBadgeKeys = updatedBadges.subtracting(existingBadges)
        let earnedBadges = newlyEarnedBadgeKeys.compactMap { Badge.getBadge(byKey: $0) }

        var nextCreatedChore: Chore? = nil
        // Create next occurrence if recurring
        if createNextRecurrence && chore.isRecurring {
            if let nextChoreTemplate = chore.createNextOccurrence() { // createNextOccurrence should return a Chore struct
                let creatorOfNextInstance = nextChoreTemplate.createdByUserId ?? completedByUserId // Fallback

                nextCreatedChore = try await self.createChore(
                    title: nextChoreTemplate.title,
                    description: nextChoreTemplate.description,
                    householdId: nextChoreTemplate.householdId,
                    assignedToUserId: nextChoreTemplate.assignedToUserId,
                    createdByUserId: creatorOfNextInstance,
                    dueDate: nextChoreTemplate.dueDate,
                    pointValue: nextChoreTemplate.pointValue,
                    isRecurring: nextChoreTemplate.isRecurring,
                    recurrenceType: nextChoreTemplate.recurrenceType,
                    recurrenceInterval: nextChoreTemplate.recurrenceInterval,
                    recurrenceDaysOfWeek: nextChoreTemplate.recurrenceDaysOfWeek,
                    recurrenceDayOfMonth: nextChoreTemplate.recurrenceDayOfMonth,
                    recurrenceEndDate: nextChoreTemplate.recurrenceEndDate
                )
            }
        }
        return (completedChore: chore, pointsEarned: chore.pointValue, nextRecurringChore: nextCreatedChore, earnedBadges: earnedBadges)
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
        // Fetch the user to check badges based on stored task count
        guard var user = try await userService.fetchUser(withId: userId) else {
            throw NSError(domain: "ChoreService", code: 404, userInfo: [NSLocalizedDescriptionKey: "User not found for badges"])
        }
        
        // Use the user's total points to approximate completed task count
        // Each completed task rewards points, so this gives us a good estimate
        let choreCount = user.totalPoints
        
        // Check for milestones badges (including first_chore badge)
        await checkMilestoneBadges(userId: userId, choreCount: choreCount)
        
        // Check for streak badges using the user's streak tracking
        if user.highestStreakDays >= 7 && !user.earnedBadges.contains("daily_streak") {
            let badgeAwarded = try await self.userService.awardBadge(to: userId, badgeKey: "daily_streak")
            if badgeAwarded {
                self.notificationService.sendBadgeEarnedNotification(toUserId: userId, badgeKey: "daily_streak")
            }
        }
        
        // Check for early completion badges using the user's early completion tracking
        if user.earlyCompletionCount >= 5 && !user.earnedBadges.contains("early_bird") {
            let badgeAwarded = try await self.userService.awardBadge(to: userId, badgeKey: "early_bird")
            if badgeAwarded {
                self.notificationService.sendBadgeEarnedNotification(toUserId: userId, badgeKey: "early_bird")
            }
        }
        
        // Check for household participation badge
        if user.householdIds.count > 1 {
            let badgeAwarded = try await self.userService.awardBadge(to: userId, badgeKey: "household_helper")
            if badgeAwarded {
                self.notificationService.sendBadgeEarnedNotification(toUserId: userId, badgeKey: "household_helper")
            }
        }
        
        // Safety check for first_chore badge
        // This ensures backward compatibility for users who might have completed chores
        // before the totalPoints tracking was implemented
        if choreCount > 0 && !user.earnedBadges.contains("first_chore") {
            let badgeAwarded = try await self.userService.awardBadge(to: userId, badgeKey: "first_chore")
            if badgeAwarded {
                self.notificationService.sendBadgeEarnedNotification(toUserId: userId, badgeKey: "first_chore")
            }
        }
    }
    
    // Helper methods for different badge types
    
    private func checkMilestoneBadges(userId: String, choreCount: Int) async {
        do {
            // Milestone badges for completing X number of chores
            let milestoneBadges = [
                (count: 1, key: "first_chore"),
                (count: 10, key: "ten_chores"),
                (count: 50, key: "fifty_chores"),
                (count: 100, key: "hundred_chores")
            ]
            
            // Sort by count descending to award highest badges first
            for milestone in milestoneBadges.sorted(by: { $0.count > $1.count }) where choreCount >= milestone.count {
                let badgeAwarded = try await self.userService.awardBadge(to: userId, badgeKey: milestone.key)
                if badgeAwarded {
                    self.notificationService.sendBadgeEarnedNotification(toUserId: userId, badgeKey: milestone.key)
                }
            }
        } catch {
            print("Error checking milestone badges: \(error.localizedDescription)")
        }
    }
}
