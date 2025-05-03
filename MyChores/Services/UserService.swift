// UserService.swift
// MyChores
//
// Created on 2025-05-02.
//

import Foundation
import FirebaseFirestore
import FirebaseAuth

/// Service for user data operations
class UserService {
    // MARK: - Shared Instance
    
    /// Shared instance for singleton access
    static let shared = UserService()
    
    // MARK: - Private Properties
    
    /// Firestore database reference
    private let db = Firestore.firestore()
    
    /// Users collection reference
    private var usersCollection: CollectionReference {
        return db.collection("users")
    }
    
    // MARK: - Initialization
    
    /// Private initializer to enforce singleton pattern
    private init() {}
    
    // MARK: - User CRUD Operations
    
    /// Create a new user document in Firestore
    /// - Parameters:
    ///   - id: User ID from Firebase Auth
    ///   - name: User's display name
    ///   - email: User's email address
    /// - Returns: The created User
    func createUser(id: String, name: String, email: String) async throws {
        // Create a new user model
        let newUser = User(
            id: id,
            name: name,
            email: email,
            photoURL: nil,
            householdIds: [],
            fcmToken: nil,
            createdAt: Date(),
            totalPoints: 0,
            weeklyPoints: 0,
            monthlyPoints: 0,
            currentWeekStartDate: getCurrentWeekStartDate(),
            currentMonthStartDate: getCurrentMonthStartDate(),
            earnedBadges: []
        )
        
        // Save to Firestore
        try usersCollection.document(id).setData(from: newUser)
    }
    
    /// Fetch the current user's data
    /// - Returns: User object if found, nil otherwise
    func fetchCurrentUser() async throws -> User? {
        guard let userId = Auth.auth().currentUser?.uid else {
            return nil
        }
        
        return try await fetchUser(withId: userId)
    }
    
    /// Fetch a specific user by ID
    /// - Parameter id: User ID
    /// - Returns: User object if found, nil otherwise
    func fetchUser(withId id: String) async throws -> User? {
        let documentSnapshot = try await usersCollection.document(id).getDocument()
        return try documentSnapshot.data(as: User.self)
    }
    
    /// Fetch multiple users by their IDs
    /// - Parameter ids: Array of user IDs
    /// - Returns: Dictionary mapping user IDs to User objects
    func fetchUsers(withIds ids: [String]) async throws -> [String: User] {
        var userDict: [String: User] = [:]
        
        // Firestore has a limit of 10 documents per query
        let chunks = ids.chunked(into: 10)
        
        for chunk in chunks {
            let querySnapshot = try await usersCollection
                .whereField(FieldPath.documentID(), in: chunk)
                .getDocuments()
            
            for document in querySnapshot.documents {
                if let user = try? document.data(as: User.self) {
                    if let userId = user.id {
                        userDict[userId] = user
                    }
                }
            }
        }
        
        return userDict
    }
    
    /// Update the FCM token for push notifications
    /// - Parameter token: The new FCM token
    func updateFCMToken(_ token: String) {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        usersCollection.document(userId).updateData([
            "fcmToken": token
        ]) { error in
            if let error = error {
                print("Error updating FCM token: \(error.localizedDescription)")
            }
        }
    }
    
    /// Update a user's household memberships
    /// - Parameters:
    ///   - userId: User ID
    ///   - householdId: Household ID to add
    func addUserToHousehold(userId: String, householdId: String) async throws {
        // Validate parameters
        guard !userId.isEmpty else {
            throw NSError(domain: "UserService", code: 4, userInfo: [NSLocalizedDescriptionKey: "User ID cannot be empty"])
        }
        
        guard !householdId.isEmpty else {
            throw NSError(domain: "UserService", code: 5, userInfo: [NSLocalizedDescriptionKey: "Household ID cannot be empty"])
        }
        
        // Add household to user's list
        try await usersCollection.document(userId).updateData([
            "householdIds": FieldValue.arrayUnion([householdId])
        ])
    }
    
    /// Remove a user from a household
    /// - Parameters:
    ///   - userId: User ID
    ///   - householdId: Household ID to remove
    func removeUserFromHousehold(userId: String, householdId: String) async throws {
        try await usersCollection.document(userId).updateData([
            "householdIds": FieldValue.arrayRemove([householdId])
        ])
    }
    
    /// Award points to a user for completing a chore
    /// - Parameters:
    ///   - userId: User ID
    ///   - points: Points to award
    func awardPoints(to userId: String, points: Int) async throws {
        // Get the current user
        guard let user = try await fetchUser(withId: userId) else {
            throw NSError(domain: "UserService", code: 1, userInfo: [NSLocalizedDescriptionKey: "User not found"])
        }
        
        // Check if we need to reset weekly/monthly points
        var newWeeklyPoints = user.weeklyPoints
        var newMonthlyPoints = user.monthlyPoints
        var newWeekStartDate = user.currentWeekStartDate
        var newMonthStartDate = user.currentMonthStartDate
        
        let currentWeekStart = getCurrentWeekStartDate()
        let currentMonthStart = getCurrentMonthStartDate()
        
        // Reset weekly points if we're in a new week
        if newWeekStartDate != currentWeekStart {
            newWeeklyPoints = 0
            newWeekStartDate = currentWeekStart
        }
        
        // Reset monthly points if we're in a new month
        if newMonthStartDate != currentMonthStart {
            newMonthlyPoints = 0
            newMonthStartDate = currentMonthStart
        }
        
        // Award the points
        try await usersCollection.document(userId).updateData([
            "totalPoints": FieldValue.increment(Int64(points)),
            "weeklyPoints": FieldValue.increment(Int64(points)),
            "monthlyPoints": FieldValue.increment(Int64(points)),
            "currentWeekStartDate": newWeekStartDate,
            "currentMonthStartDate": newMonthStartDate
        ])
    }
    
    /// Award a badge to a user
    /// - Parameters:
    ///   - userId: User ID
    ///   - badgeKey: The badge key/identifier
    /// - Returns: Bool indicating if the badge was newly awarded
    func awardBadge(to userId: String, badgeKey: String) async throws -> Bool {
        // Get the current user to check if they already have the badge
        guard let user = try await fetchUser(withId: userId) else {
            throw NSError(domain: "UserService", code: 1, userInfo: [NSLocalizedDescriptionKey: "User not found"])
        }
        
        // Check if user already has this badge
        if user.earnedBadges.contains(badgeKey) {
            return false
        }
        
        // Award the new badge
        try await usersCollection.document(userId).updateData([
            "earnedBadges": FieldValue.arrayUnion([badgeKey])
        ])
        
        return true
    }
    
    // MARK: - Leaderboard Methods
    
    /// Get the weekly leaderboard for a household
    /// - Parameter householdId: Household ID
    /// - Returns: Array of users sorted by weekly points
    func getWeeklyLeaderboard(forHouseholdId householdId: String) async throws -> [User] {
        // First get the household to get all member IDs
        let household = try await HouseholdService.shared.fetchHousehold(withId: householdId)
        guard let memberIds = household?.memberUserIds, !memberIds.isEmpty else {
            return []
        }
        
        let users = try await fetchUsers(withIds: memberIds)
        
        // Sort by weekly points (descending)
        return users.values.sorted { $0.weeklyPoints > $1.weeklyPoints }
    }
    
    /// Get the monthly leaderboard for a household
    /// - Parameter householdId: Household ID
    /// - Returns: Array of users sorted by monthly points
    func getMonthlyLeaderboard(forHouseholdId householdId: String) async throws -> [User] {
        // First get the household to get all member IDs
        let household = try await HouseholdService.shared.fetchHousehold(withId: householdId)
        guard let memberIds = household?.memberUserIds, !memberIds.isEmpty else {
            return []
        }
        
        let users = try await fetchUsers(withIds: memberIds)
        
        // Sort by monthly points (descending)
        return users.values.sorted { $0.monthlyPoints > $1.monthlyPoints }
    }
    
    // MARK: - Helper Methods
    
    /// Get the start date of the current week (Monday)
    /// - Returns: Date representing the start of the week
    private func getCurrentWeekStartDate() -> Date {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let weekday = calendar.component(.weekday, from: today)
        let weekdayOrdinal = calendar.firstWeekday
        var daysToSubtract = weekday - weekdayOrdinal
        if daysToSubtract < 0 {
            daysToSubtract += 7
        }
        return calendar.date(byAdding: .day, value: -daysToSubtract, to: today)!
    }
    
    /// Get the start date of the current month
    /// - Returns: Date representing the first day of the month
    private func getCurrentMonthStartDate() -> Date {
        let calendar = Calendar.current
        let today = Date()
        let components = calendar.dateComponents([.year, .month], from: today)
        return calendar.date(from: components)!
    }
    
    /// Create a new user after signup or login
    /// - Parameters:
    ///   - userId: User ID
    ///   - name: User's display name
    ///   - email: User's email address
    /// - Returns: The created User
    func createNewUserIfNeeded(userId: String, name: String, email: String) async throws {
        // Try to fetch the user first
        let existingUser = try await fetchUser(withId: userId)
        
        // If user doesn't exist, create a new one
        if existingUser == nil {
            let newUser = User(
                id: userId,
                name: name.isEmpty ? "New User" : name,
                email: email,
                photoURL: nil,
                householdIds: [],
                fcmToken: nil,
                createdAt: Date(),
                totalPoints: 0,
                weeklyPoints: 0,
                monthlyPoints: 0,
                currentWeekStartDate: getCurrentWeekStartDate(),
                currentMonthStartDate: getCurrentMonthStartDate(),
                earnedBadges: []
            )
            
            // Save the new user
            try await db.collection("users").document(userId).setData(from: newUser)
            print("Created new user: \(userId)")
        }
    }
}

// MARK: - Array Extension for Chunking

extension Array {
    /// Split an array into chunks of specified size
    /// - Parameter size: Chunk size
    /// - Returns: Array of array chunks
    func chunked(into size: Int) -> [[Element]] {
        return stride(from: 0, to: count, by: size).map {
            Array(self[$0 ..< Swift.min($0 + size, count)])
        }
    }
}
