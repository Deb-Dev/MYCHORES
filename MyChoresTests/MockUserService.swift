// filepath: /Users/debchow/Documents/coco/MyChores/MyChoresTests/MockUserService.swift
import Foundation
import Combine
@testable import MyChores

class MockUserService: UserServiceProtocol {
    var userToReturn: User?
    var usersToReturn: [User] = []
    var errorToThrow: Error?
    var shouldUpdateUserPointsSucceed = true
    var awardBadgeShouldSucceed = true

    var lastUserId: String?
    var lastHouseholdId: String?
    var lastUpdatedUser: User?
    var lastUpdatedPoints: Int?
    var lastUpdatedName: String?
    var lastUpdatedEmail: String?
    var lastPrivacySettings: (showProfile: Bool, showAchievements: Bool, shareActivity: Bool)?
    var lastFCMToken: String?
    var lastAwardedBadgeKey: String?


    var createUserCalled = false
    var fetchUserCalled = false
    var updateUserCalled = false
    var deleteUserCalled = false
    var addUserToHouseholdCalled = false
    var removeUserFromHouseholdCalled = false
    var updateUserPointsCalled = false
    var fetchUsersInHouseholdCalled = false
    var searchUsersByNameCalled = false
    var getCurrentUserCalled = false
    var getWeeklyLeaderboardCalled = false
    var getMonthlyLeaderboardCalled = false
    var updatePrivacySettingsCalled = false
    var updateFCMTokenCalled = false
    var awardBadgeCalled = false

    func createUser(id: String, name: String, email: String) async throws -> User {
        createUserCalled = true
        lastUserId = id
        lastUpdatedName = name
        lastUpdatedEmail = email
        if let error = errorToThrow {
            throw error
        }
        let newUser = User(id: id, name: name, email: email, createdAt: Date())
        self.userToReturn = newUser
        self.usersToReturn.append(newUser)
        return newUser
    }

    func fetchUser(withId id: String) async throws -> User? {
        fetchUserCalled = true
        lastUserId = id
        if let error = errorToThrow {
            throw error
        }
        return userToReturn ?? usersToReturn.first(where: { $0.id == id })
    }

    func updateUser(_ user: User) async throws {
        updateUserCalled = true
        lastUpdatedUser = user
        if let error = errorToThrow {
            throw error
        }
        if let index = usersToReturn.firstIndex(where: { $0.id == user.id }) {
            usersToReturn[index] = user
        }
        if self.userToReturn?.id == user.id {
            self.userToReturn = user
        }
    }

    func deleteUser(withId id: String) async throws {
        deleteUserCalled = true
        lastUserId = id
        if let error = errorToThrow {
            throw error
        }
        usersToReturn.removeAll { $0.id == id }
        if userToReturn?.id == id {
            userToReturn = nil
        }
    }

    func addUserToHousehold(userId: String, householdId: String) async throws {
        addUserToHouseholdCalled = true
        lastUserId = userId
        lastHouseholdId = householdId
        if let error = errorToThrow {
            throw error
        }
        // Simulate adding user to household if needed for tests
    }

    func removeUserFromHousehold(userId: String, householdId: String) async throws {
        removeUserFromHouseholdCalled = true
        lastUserId = userId
        lastHouseholdId = householdId
        if let error = errorToThrow {
            throw error
        }
        // Simulate removing user from household
    }

    func updateUserPoints(userId: String, points: Int) async throws {
        updateUserPointsCalled = true
        lastUserId = userId
        lastUpdatedPoints = points
        if let error = errorToThrow, !shouldUpdateUserPointsSucceed {
            throw error
        }
        if var user = userToReturn, user.id == userId {
            user.totalPoints += points // Assuming update affects totalPoints
            user.weeklyPoints += points // And weekly/monthly for simplicity in mock
            user.monthlyPoints += points
            userToReturn = user
        } else if let index = usersToReturn.firstIndex(where: { $0.id == userId }) {
            usersToReturn[index].totalPoints += points
            usersToReturn[index].weeklyPoints += points
            usersToReturn[index].monthlyPoints += points
        }
    }

    func fetchUsers(inHousehold householdId: String) async throws -> [User] {
        fetchUsersInHouseholdCalled = true
        lastHouseholdId = householdId
        if let error = errorToThrow {
            throw error
        }
        // This mock will return all users if householdId matches, or filter if more specific data is set up
        return usersToReturn.filter { $0.householdIds.contains(householdId) }
    }

    func searchUsers(byName name: String) async throws -> [User] {
        searchUsersByNameCalled = true
        lastUpdatedName = name // Using this to store search query
        if let error = errorToThrow {
            throw error
        }
        return usersToReturn.filter { $0.name.lowercased().contains(name.lowercased()) }
    }

    func getCurrentUser() async throws -> User? {
        getCurrentUserCalled = true
        if let error = errorToThrow {
            throw error
        }
        // This typically would rely on an auth service to know current user ID,
        // then fetch. For mock, just return userToReturn or first user.
        return userToReturn ?? usersToReturn.first
    }

    func getWeeklyLeaderboard(forHouseholdId householdId: String) async throws -> [User] {
        getWeeklyLeaderboardCalled = true
        lastHouseholdId = householdId
        if let error = errorToThrow {
            throw error
        }
        // Return users sorted by weeklyPoints, descending
        return usersToReturn.filter { $0.householdIds.contains(householdId) }.sorted { $0.weeklyPoints > $1.weeklyPoints }
    }

    func getMonthlyLeaderboard(forHouseholdId householdId: String) async throws -> [User] {
        getMonthlyLeaderboardCalled = true
        lastHouseholdId = householdId
        if let error = errorToThrow {
            throw error
        }
        // Return users sorted by monthlyPoints, descending
        return usersToReturn.filter { $0.householdIds.contains(householdId) }.sorted { $0.monthlyPoints > $1.monthlyPoints }
    }

    func updatePrivacySettings(userId: String, showProfile: Bool, showAchievements: Bool, shareActivity: Bool) async throws {
        updatePrivacySettingsCalled = true
        lastUserId = userId
        lastPrivacySettings = (showProfile, showAchievements, shareActivity)
        if let error = errorToThrow {
            throw error
        }
        // Simulate update
    }

    func updateFCMToken(_ token: String) async throws {
        updateFCMTokenCalled = true
        lastFCMToken = token
        // Assuming this updates the current user's FCM token
        // For a more specific mock, you might need a current user context or pass userId
        if let error = errorToThrow {
            throw error
        }
        if userToReturn != nil {
            userToReturn?.fcmToken = token
        } else if !usersToReturn.isEmpty {
            // Apply to the first user for simplicity if no specific userToReturn is set
            // usersToReturn[0].fcmToken = token
            // This might be better if it requires a userId. The protocol implies it's for the current user.
        }
    }

    func awardBadge(to userId: String, badgeKey: String) async throws -> Bool {
        awardBadgeCalled = true
        lastUserId = userId
        lastAwardedBadgeKey = badgeKey
        if let error = errorToThrow {
            throw error
        }
        if awardBadgeShouldSucceed {
            if var user = userToReturn, user.id == userId {
                if !user.earnedBadges.contains(badgeKey) {
                    user.earnedBadges.append(badgeKey)
                    userToReturn = user
                    return true // Badge awarded
                }
                return false // Already had badge
            } else if let index = usersToReturn.firstIndex(where: { $0.id == userId }) {
                 if !usersToReturn[index].earnedBadges.contains(badgeKey) {
                    usersToReturn[index].earnedBadges.append(badgeKey)
                    return true // Badge awarded
                }
                return false // Already had badge
            }
        }
        return false // Award failed or user not found
    }

    // Helper to reset mock state
    func reset() {
        userToReturn = nil
        usersToReturn = []
        errorToThrow = nil
        shouldUpdateUserPointsSucceed = true
        awardBadgeShouldSucceed = true
        
        lastUserId = nil
        lastHouseholdId = nil
        lastUpdatedUser = nil
        lastUpdatedPoints = nil
        lastUpdatedName = nil
        lastUpdatedEmail = nil
        lastPrivacySettings = nil
        lastFCMToken = nil
        lastAwardedBadgeKey = nil

        createUserCalled = false
        fetchUserCalled = false
        updateUserCalled = false
        deleteUserCalled = false
        addUserToHouseholdCalled = false
        removeUserFromHouseholdCalled = false
        updateUserPointsCalled = false
        fetchUsersInHouseholdCalled = false
        searchUsersByNameCalled = false
        getCurrentUserCalled = false
        getWeeklyLeaderboardCalled = false
        getMonthlyLeaderboardCalled = false
        updatePrivacySettingsCalled = false
        updateFCMTokenCalled = false
        awardBadgeCalled = false
    }
}
