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
        do {
            let documentSnapshot = try await usersCollection.document(id).getDocument()
            
            // Check if the document exists
            guard documentSnapshot.exists else {
                print("⚠️ User document does not exist: \(id)")
                return nil
            }
            
            // Try to parse the user data
            let user = try documentSnapshot.data(as: User.self)
            print("✅ Successfully fetched user: \(user.name) (ID: \(user.id ?? "unknown"))")
            return user
            
        } catch {
            print("❌ Error fetching user \(id): \(error.localizedDescription)")
            throw error
        }
    }
    
    /// Fetch multiple users by their IDs
    /// - Parameter ids: Array of user IDs
    /// - Returns: Dictionary mapping user IDs to User objects
    func fetchUsers(withIds ids: [String]) async throws -> [String: User] {
        var userDict: [String: User] = [:]
        print("📊 Fetching \(ids.count) users: \(ids)")
        
        // First try to use the whereField query for efficiency
        do {
            // Firestore has a limit of 10 documents per query
            let chunks = ids.chunked(into: 10)
            
            for chunk in chunks {
                let querySnapshot = try await usersCollection
                    .whereField(FieldPath.documentID(), in: chunk)
                    .getDocuments()
                
                print("📊 Got \(querySnapshot.documents.count) documents from chunk of \(chunk.count)")
                
                for document in querySnapshot.documents {
                    if let user = try? document.data(as: User.self) {
                        if let userId = user.id {
                            userDict[userId] = user
                            print("✅ Successfully decoded user: \(user.name)")
                        }
                    }
                }
            }
            
            // If we got all the users, return them
            if userDict.count == ids.count {
                return userDict
            }
            
            // If we didn't get all users, try fetching them individually
            print("⚠️ Batch query didn't return all users. Fetching individually...")
        } catch (let error) {
            print("❌ Error fetching users with batch query: \(error.localizedDescription)")
            print("⚠️ Falling back to individual fetches...")
        }
        
        // Fallback: fetch each user individually
        for userId in ids {
            do {
                if let user = try await fetchUser(withId: userId) {
                    userDict[userId] = user
                    print("✅ Individually fetched user: \(user.name)")
                }
            } catch {
                print("❌ Error fetching user \(userId): \(error.localizedDescription)")
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
            throw NSError(domain: "UserService", code: 400, userInfo: [NSLocalizedDescriptionKey: "User ID cannot be empty"])
        }
        
        guard !householdId.isEmpty else {
            throw NSError(domain: "UserService", code: 400, userInfo: [NSLocalizedDescriptionKey: "Household ID cannot be empty"])
        }
        
        // First check if the user exists
        var userExists = false
        do {
            let docSnapshot = try await usersCollection.document(userId).getDocument()
            userExists = docSnapshot.exists
        } catch {
            print("Error checking if user exists: \(error.localizedDescription)")
        }
        
        if !userExists {
            // Try to create the user with basic details if it doesn't exist
            if let currentUser = Auth.auth().currentUser {
                try await createNewUserIfNeeded(
                    userId: userId,
                    name: currentUser.displayName ?? "User",
                    email: currentUser.email ?? "unknown@example.com"
                )
            } else {
                throw NSError(domain: "UserService", code: 404, userInfo: [NSLocalizedDescriptionKey: "User not found and couldn't be created"])
            }
        }
        
        // Add household to user's list with proper error handling
        do {
            try await usersCollection.document(userId).updateData([
                "householdIds": FieldValue.arrayUnion([householdId])
            ])
            print("Successfully added household \(householdId) to user \(userId)")
        } catch {
            print("Error adding household to user: \(error.localizedDescription)")
            throw NSError(domain: "UserService", code: 500, 
                          userInfo: [NSLocalizedDescriptionKey: "Failed to update user's household list: \(error.localizedDescription)"])
        }
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
    
    // MARK: - Household Methods
    
    /// Get all members of a household
    /// - Parameter householdId: Household ID
    /// - Returns: Array of users who are members of the household
    func getAllHouseholdMembers(forHouseholdId householdId: String) async throws -> [User] {
        print("🏠 Fetching members for household: \(householdId)")
        
        // First get the household to get all member IDs
        let household = try await HouseholdService.shared.fetchHousehold(withId: householdId)
        guard let memberIds = household?.memberUserIds, !memberIds.isEmpty else {
            print("⚠️ Household has no members or wasn't found")
            return []
        }
        
        print("🏠 Household \(household?.name ?? "unknown") has \(memberIds.count) members: \(memberIds)")
        
        // Get all users directly (more reliable)
        let users = try await getReliableHouseholdMembers(memberIds: memberIds)
        
        print("👥 Found \(users.count) users for household")
        
        // Return sorted by name for display purposes
        return users.sorted { $0.name < $1.name }
    }
    
    /// Get household members with multiple fallback strategies
    /// - Parameter memberIds: Array of member user IDs
    /// - Returns: Array of User objects
    private func getReliableHouseholdMembers(memberIds: [String]) async throws -> [User] {
        var users: [User] = []
        
        // Try to get each user individually - most reliable method
        for (index, userId) in memberIds.enumerated() {
            do {
                var user = try await fetchUser(withId: userId)
                
                // If user is found but has nil ID, assign the original userId
                if let foundUser = user, foundUser.id == nil {
                    // We need to create a mutable copy since User is a struct
                    var mutableUser = foundUser
                    
                    // Force unwrap is safe here because we're explicitly setting it
                    mutableUser.forceSetId(userId)
                    user = mutableUser
                    
                    print("⚠️ Fixed nil ID for user: \(mutableUser.name)")
                }
                
                if let user = user {
                    users.append(user)
                    print("✅ Successfully fetched user: \(user.name) with ID: \(user.id ?? "still nil!")")
                }
            } catch {
                print("❌ Error fetching individual user \(userId): \(error.localizedDescription)")
            }
        }
        
        // If we got all users, return them
        if users.count == memberIds.count {
            return users
        }
        
        // If direct fetching didn't work well, try our batch method as a fallback
        if users.count < memberIds.count {
            print("⚠️ Individual fetches incomplete. Trying batch query as fallback...")
            
            do {
                let userDict = try await fetchUsers(withIds: memberIds)
                
                // Add any users we didn't already have
                for (id, user) in userDict {
                    if !users.contains(where: { $0.id == id }) {
                        users.append(user)
                        print("✅ Added user from batch query: \(user.name)")
                    }
                }
            } catch {
                print("❌ Error with batch user query: \(error.localizedDescription)")
            }
        }
        
        return users
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
        var existingUser: User?
        do {
            existingUser = try await fetchUser(withId: userId)
        } catch {
            print("Error fetching user: \(error.localizedDescription) - will create new user")
            existingUser = nil
        }
        
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
            do {
                try await db.collection("users").document(userId).setData(from: newUser)
                print("Created new user: \(userId)")
            } catch {
                print("Error creating user: \(error.localizedDescription)")
                throw error
            }
        }
    }
    
    // MARK: - Privacy Settings
    
    /// Update user's privacy settings
    /// - Parameters:
    ///   - showProfile: Whether to share profile with other household members
    ///   - showAchievements: Whether to display achievements to other household members
    ///   - shareActivity: Whether to share activity history with household members
    /// - Returns: Success flag and optional error
    @MainActor
    func updatePrivacySettings(
        showProfile: Bool,
        showAchievements: Bool,
        shareActivity: Bool
    ) async {
        guard let userId = Auth.auth().currentUser?.uid else {
            print("No authenticated user found to update privacy settings")
            return
        }
        
        do {
            // Update the user document with privacy settings
            try await db.collection("users").document(userId).updateData([
                "privacySettings": [
                    "showProfile": showProfile,
                    "showAchievements": showAchievements,
                    "shareActivity": shareActivity
                ]
            ])
            
            // Update the user model with the new settings
            var userToUpdate = await getCurrentUser()
            if var user = userToUpdate {
                user.privacySettings = UserPrivacySettings(
                    showProfile: showProfile,
                    showAchievements: showAchievements,
                    shareActivity: shareActivity
                )
                
                // Store updated user in UserDefaults
                if let encodedUser = try? JSONEncoder().encode(user) {
                    UserDefaults.standard.set(encodedUser, forKey: "currentUser")
                }
            }
            
            print("Privacy settings updated successfully")
        } catch {
            print("Error updating privacy settings: \(error.localizedDescription)")
        }
    }
    
    /// Get the current authenticated user
    /// - Returns: Current user object if available, nil otherwise
    @MainActor
    func getCurrentUser() async -> User? {
        // First check if we have a cached user in UserDefaults
        if let userData = UserDefaults.standard.data(forKey: "currentUser") {
            do {
                let cachedUser = try JSONDecoder().decode(User.self, from: userData)
                return cachedUser
            } catch {
                print("Error decoding cached user: \(error.localizedDescription)")
                // Fall through to try fetching from Firestore
            }
        }
        
        // If no cached user or decoding failed, try to fetch from Firestore
        guard let userId = Auth.auth().currentUser?.uid else {
            return nil
        }
        
        do {
            let user = try await fetchUser(withId: userId)
            
            // Cache the user in UserDefaults for future use
            if let user = user, let encodedUser = try? JSONEncoder().encode(user) {
                UserDefaults.standard.set(encodedUser, forKey: "currentUser")
            }
            
            return user
        } catch {
            print("Error fetching current user: \(error.localizedDescription)")
            return nil
        }
    }
}

// MARK: - Array Extension for Chunking

extension Array {
    /// Split array into chunks of specified size
    /// - Parameter size: Maximum size of each chunk
    /// - Returns: Array of chunks
    func chunked(into size: Int) -> [[Element]] {
        stride(from: 0, to: count, by: size).map {
            Array(self[$0..<Swift.min($0 + size, count)])
        }
    }
}

// MARK: - User Service
