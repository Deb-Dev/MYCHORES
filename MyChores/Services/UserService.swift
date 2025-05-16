// UserService.swift
// MyChores
//
// Created on 2025-05-02.
//

import Foundation
import FirebaseFirestore
import FirebaseAuth

// MARK: - UserServiceProtocol
protocol UserServiceProtocol {
    func createUser(id: String, name: String, email: String) async throws -> User
    func fetchUser(withId id: String) async throws -> User?
    func updateUser(_ user: User) async throws
    func deleteUser(withId id: String) async throws
    func addUserToHousehold(userId: String, householdId: String) async throws
    func removeUserFromHousehold(userId: String, householdId: String) async throws
    func updateUserPoints(userId: String, points: Int) async throws
    func fetchUsers(inHousehold householdId: String) async throws -> [User]
    func searchUsers(byName name: String) async throws -> [User]
    func getCurrentUser() async throws -> User?
    func getWeeklyLeaderboard(forHouseholdId householdId: String) async throws -> [User]
    func getMonthlyLeaderboard(forHouseholdId householdId: String) async throws -> [User]
    func updatePrivacySettings(userId: String, showProfile: Bool, showAchievements: Bool, shareActivity: Bool) async throws
    func updateFCMToken(_ token: String) async throws // Added
    func awardBadge(to userId: String, badgeKey: String) async throws -> Bool // Added
}

/// Service for user data operations
class UserService: UserServiceProtocol {
    // MARK: - Shared Instance
    
    /// Shared instance for singleton access
    static let shared = UserService()
    
    // MARK: - Private Properties
    
    /// Firestore database reference
    private let db = Firestore.firestore()
    
    /// Users collection reference
    private var usersCollection: CollectionReference {
        db.collection("users")
    }
    
    // MARK: - Initialization
    
    /// Private initializer to enforce singleton pattern
    private init() {}
    
    // MARK: - User CRUD Operations
    
    func createUser(id: String, name: String, email: String) async throws -> User {
        var newUser = User(
            id: id,
            name: name,
            email: email
        )
        
        // Set the initial values for required fields
        newUser.createdAt = Date()
        newUser.currentWeekStartDate = getCurrentWeekStartDate()
        newUser.currentMonthStartDate = getCurrentMonthStartDate()
        
        try usersCollection.document(id).setData(from: newUser)
        return newUser
    }
    
    func fetchUser(withId id: String) async throws -> User? {
        do {
            let documentSnapshot = try await usersCollection.document(id).getDocument()
            guard documentSnapshot.exists else {
                print("⚠️ User document does not exist: \(id)")
                return nil
            }
            var user = try documentSnapshot.data(as: User.self)
            // Ensure the user object has its ID, especially if it's not stored in the document body
            if user.id == nil {
                user.id = documentSnapshot.documentID
            }
            print("✅ Successfully fetched user: \(user.name) (ID: \(user.id ?? "unknown"))")
            return user
        } catch {
            print("❌ Error fetching user \(id): \(error.localizedDescription)")
            throw error
        }
    }
    
    func updateUser(_ user: User) async throws {
        guard let userId = user.id else {
            throw NSError(domain: "UserService", code: 1, userInfo: [NSLocalizedDescriptionKey: "User ID is missing for update"])
        }
        try usersCollection.document(userId).setData(from: user, merge: true)
    }
    
    func deleteUser(withId id: String) async throws {
        try await usersCollection.document(id).delete()
    }
    
    func addUserToHousehold(userId: String, householdId: String) async throws {
        guard !userId.isEmpty, !householdId.isEmpty else {
            throw NSError(domain: "UserService", code: 400, userInfo: [NSLocalizedDescriptionKey: "User ID or Household ID cannot be empty"])
        }
        
        let userDocRef = usersCollection.document(userId)
        let userSnapshot = try? await userDocRef.getDocument()

        if !(userSnapshot?.exists ?? false) {
            if let currentUserAuth = Auth.auth().currentUser, currentUserAuth.uid == userId {
                 _ = try await createUser(
                    id: userId,
                    name: currentUserAuth.displayName ?? "User",
                    email: currentUserAuth.email ?? "unknown@example.com"
                )
            } else {
                print("⚠️ Attempted to add a non-existent user ('\(userId)') to household and cannot create it.")
                throw NSError(domain: "UserService", code: 404, userInfo: [NSLocalizedDescriptionKey: "User not found and couldn't be created"])
            }
        }
        
        try await userDocRef.updateData([
            "householdIds": FieldValue.arrayUnion([householdId])
        ])
        print("Successfully added household \(householdId) to user \(userId)")
    }
    
    func removeUserFromHousehold(userId: String, householdId: String) async throws {
        try await usersCollection.document(userId).updateData([
            "householdIds": FieldValue.arrayRemove([householdId])
        ])
    }
    
    func updateUserPoints(userId: String, points: Int) async throws {
        guard var user = try await fetchUser(withId: userId) else { // Make user mutable
            throw NSError(domain: "UserService", code: 404, userInfo: [NSLocalizedDescriptionKey: "User \(userId) not found for points update"])
        }
        
        let currentWeekStart = getCurrentWeekStartDate()
        let currentMonthStart = getCurrentMonthStartDate()
        
        if user.currentWeekStartDate != currentWeekStart {
            user.weeklyPoints = points
            user.currentWeekStartDate = currentWeekStart
        } else {
            user.weeklyPoints += points
        }
        
        if user.currentMonthStartDate != currentMonthStart {
            user.monthlyPoints = points
            user.currentMonthStartDate = currentMonthStart
        } else {
            user.monthlyPoints += points
        }
        user.totalPoints += points
        
        // Update the entire user object to ensure all point fields and dates are saved
        try await updateUser(user)
    }
    
    func fetchUsers(inHousehold householdId: String) async throws -> [User] {
        guard let household = try await HouseholdService.shared.fetchHousehold(withId: householdId),
              !household.memberUserIds.isEmpty else {
            print("⚠️ Household \(householdId) has no members or wasn't found")
            return []
        }
        
        print("🏠 Household \(household.name) has \(household.memberUserIds.count) members: \(household.memberUserIds)")
        let users = try await getReliableHouseholdMembers(memberIds: household.memberUserIds)
        print("👥 Found \(users.count) users for household \(householdId)")
        return users.sorted { $0.name < $1.name }
    }
    
    func searchUsers(byName name: String) async throws -> [User] {
        let querySnapshot = try await usersCollection
            .whereField("name", isGreaterThanOrEqualTo: name)
            .whereField("name", isLessThanOrEqualTo: name + "\u{f8ff}") // Firestore prefix search
            .getDocuments()
        
        return querySnapshot.documents.compactMap { document in
            var user = try? document.data(as: User.self)
            if user?.id == nil { // Ensure ID is set
                user?.id = document.documentID
            }
            return user
        }
    }
    
    func getCurrentUser() async throws -> User? {
        guard let userId = Auth.auth().currentUser?.uid else {
            return nil
        }
        return try await fetchUser(withId: userId)
    }
    
    // MARK: - Helper methods

    private func fetchUsers(withIds ids: [String]) async throws -> [User] {
        var users: [User] = []
        if ids.isEmpty { return users }

        let chunks = ids.chunked(into: 10) // Firestore 'in' query limit
        
        for chunk in chunks {
            if chunk.isEmpty { continue }
            let querySnapshot = try await usersCollection
                .whereField(FieldPath.documentID(), in: chunk)
                .getDocuments()
            
            for document in querySnapshot.documents {
                if var user = try? document.data(as: User.self) {
                    if user.id == nil { user.id = document.documentID } // Assign document ID if user.id is nil
                    users.append(user)
                } else {
                    print("⚠️ Failed to decode user from document: \(document.documentID) in batch fetch")
                }
            }
        }
        
        // Fallback for any IDs not fetched (e.g., if a document ID was mistyped or user deleted between calls)
        if users.count < ids.count {
            let fetchedUserIds = Set(users.compactMap { $0.id })
            for userId in ids where !fetchedUserIds.contains(userId) {
                if let user = try? await fetchUser(withId: userId) { // fetchUser ensures ID is set
                    users.append(user)
                }
            }
        }
        return users
    }
    
    // This method was not part of the protocol but existed in the class.
    // It's kept here as a public utility method of UserService.
    // Converted to async throws to match protocol and handle errors properly.
    func updateFCMToken(_ token: String) async throws {
        guard let userId = Auth.auth().currentUser?.uid else {
            // Consider throwing a specific error if user is not authenticated
            print("Error updating FCM token: User not authenticated.")
            throw NSError(domain: "UserService", code: 401, userInfo: [NSLocalizedDescriptionKey: "User not authenticated to update FCM token."])
        }
        
        do {
            try await usersCollection.document(userId).updateData([
                "fcmToken": token
            ])
            print("✅ FCM token updated successfully for user \(userId).")
        } catch {
            print("❌ Error updating FCM token for user \(userId): \(error.localizedDescription)")
            throw error // Re-throw the Firestore error
        }
    }
    
    // This method was not part of the protocol but existed in the class.
    // It's kept here as a public utility method of UserService.
    func awardBadge(to userId: String, badgeKey: String) async throws -> Bool {
        guard var user = try await fetchUser(withId: userId) else { // user needs to be mutable to update earnedBadges
            throw NSError(domain: "UserService", code: 404, userInfo: [NSLocalizedDescriptionKey: "User \(userId) not found for badge award"])
        }
        
        if user.earnedBadges.contains(badgeKey) {
            return false // Badge already awarded
        }
        
        user.earnedBadges.append(badgeKey) // Append to local model
        try await updateUser(user) // Save the updated user
        
        return true
    }
    
    private func getReliableHouseholdMembers(memberIds: [String]) async throws -> [User] {
        if memberIds.isEmpty { return [] }
        return try await fetchUsers(withIds: memberIds) // Directly use the improved batch fetcher
    }
    
    // MARK: - Leaderboard Methods
    
    func getWeeklyLeaderboard(forHouseholdId householdId: String) async throws -> [User] {
        let usersInHousehold = try await fetchUsers(inHousehold: householdId)
        return usersInHousehold.sorted { $0.weeklyPoints > $1.weeklyPoints }
    }
    
    func getMonthlyLeaderboard(forHouseholdId householdId: String) async throws -> [User] {
        let usersInHousehold = try await fetchUsers(inHousehold: householdId)
        return usersInHousehold.sorted { $0.monthlyPoints > $1.monthlyPoints }
    }
    
    // MARK: - Privacy Settings

    func updatePrivacySettings(userId: String, showProfile: Bool, showAchievements: Bool, shareActivity: Bool) async throws {
        _ = UserPrivacySettings( // Changed from User.PrivacySettings
            showProfile: showProfile,
            showAchievements: showAchievements,
            shareActivity: shareActivity
        )
        // Update the privacySettings field within the user document
        // We need to use dot notation for updating nested objects in Firestore if User.PrivacySettings is a sub-collection or a map.
        // Assuming it's a map (struct) within the User document:
        try await usersCollection.document(userId).updateData([
            "privacySettings.showProfile": showProfile,
            "privacySettings.showAchievements": showAchievements,
            "privacySettings.shareActivity": shareActivity
            // "privacySettings": settings // Alternative: update the whole map if Codable works directly here.
                                         // However, individual field updates are often safer and more common.
        ])
        print("✅ Privacy settings updated for user \\(userId)")
    }

    // MARK: - Private Date Helper
    private func getCurrentWeekStartDate() -> Date {
        var calendar = Calendar.current
        calendar.firstWeekday = 1 // Consider Sunday as the first day of the week
        let today = calendar.startOfDay(for: Date())
        let dayOfWeek = calendar.component(.weekday, from: today)
        return calendar.date(byAdding: .day, value: -(dayOfWeek - 1), to: today)!
    }

    private func getCurrentMonthStartDate() -> Date {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month], from: Date())
        return calendar.date(from: components)!
    }
}

// Helper extension for chunking arrays, useful for Firestore 'in' queries
extension Array {
    func chunked(into size: Int) -> [[Element]] {
        return stride(from: 0, to: count, by: size).map {
            Array(self[$0 ..< Swift.min($0 + size, count)])
        }
    }
}
