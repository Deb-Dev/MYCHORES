// AchievementsViewModel.swift
// MyChores
//
// Created on 2025-05-02.
//

import Foundation
import Combine
import FirebaseFirestore

/// ViewModel for achievements/badges views
class AchievementsViewModel: ObservableObject {
    // MARK: - Published Properties
    
    /// All predefined badges in the system
    @Published var allBadges: [Badge] = Badge.predefinedBadges
    
    /// Badges earned by the current user
    @Published var earnedBadges: [Badge] = []
    
    /// Badges not yet earned by the user
    @Published var unearnedBadges: [Badge] = []
    
    /// Total tasks completed by the user
    @Published var totalCompletedTasks: Int = 0
    
    /// Total badges earned by the user
    @Published var totalEarnedBadges: Int = 0
    
    /// Total points earned by the user
    @Published var totalPoints: Int = 0
    
    /// Loading state
    @Published var isLoading = false
    
    /// Error message
    @Published var errorMessage: String?
    
    // MARK: - Private Properties
    
    /// Current user ID
    private var userId: String
    
    /// User service instance
    private let userService = UserService.shared
    
    /// Chore service instance
    private let choreService = ChoreService.shared
    
    // MARK: - Initialization
    
    init(userId: String? = nil) {
        // Use provided ID or current authenticated user
        self.userId = userId ?? AuthService.shared.getCurrentUserId() ?? ""
        loadBadges()
    }
    
    // MARK: - Badge Methods
    
    /// Load all badges and separate into earned and unearned
    func loadBadges() {
        guard !userId.isEmpty else {
            errorMessage = "User ID not available"
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                print("🏆 Loading badges for user: \(userId)")
                
                // Get the user to check their earned badges
                let user = try await userService.fetchUser(withId: userId)
                
                if let user = user {
                    print("✅ User found: \(user.name)")
                    
                    // Get earned badges - handle potential nil earnedBadges array
                    let earnedBadgeKeys = user.earnedBadges
                    print("📋 User has \(earnedBadgeKeys.count) earned badge keys")
                    
                    // Map badge keys to actual Badge objects
                    let earned = earnedBadgeKeys.compactMap { badgeKey in
                        Badge.getBadge(byKey: badgeKey)
                    }
                    print("🎖️ Mapped to \(earned.count) Badge objects")
                    
                    // Get unearned badges
                    let unearned = Badge.predefinedBadges.filter { badge in
                        !earnedBadgeKeys.contains(badge.badgeKey)
                    }
                    
                    // Try to fetch completed tasks, but don't fail if this errors
                    var completedCount = 0
                    do {
                        let completedChores = try await ChoreService.shared.fetchChores(forUserId: userId, includeCompleted: true)
                        completedCount = completedChores.filter { $0.isCompleted }.count
                        print("✅ Fetched \(completedChores.count) chores, \(completedCount) completed")
                    } catch {
                        print("⚠️ Error fetching chores: \(error.localizedDescription)")
                        // Continue anyway, we can still show badges
                    }
                    
                    // Calculate total points
                    let points = user.totalPoints
                    
                    await MainActor.run {
                        self.earnedBadges = earned
                        self.unearnedBadges = unearned
                        self.totalCompletedTasks = completedCount
                        self.totalEarnedBadges = earned.count
                        self.totalPoints = points
                        self.isLoading = false
                    }
                } else {
                    print("❌ User not found for ID: \(userId)")
                    // Handle missing user by showing default badges
                    await MainActor.run {
                        self.showDefaultBadges()
                        self.isLoading = false
                    }
                }
            } catch {
                print("❌ Error loading badges: \(error.localizedDescription)")
                
                // Handle the error gracefully by showing default badges
                await MainActor.run {
                    self.showDefaultBadges()
                    self.isLoading = false
                }
            }
        }
    }
    
    /// Show default badges when there's an error fetching the real ones
    private func showDefaultBadges() {
        self.earnedBadges = []
        self.unearnedBadges = Badge.predefinedBadges
        self.totalCompletedTasks = 0
        self.totalEarnedBadges = 0
        self.totalPoints = 0
        // We don't set an error message so the UI shows empty state instead of error
    }
    
    /// Calculate progress toward a badge
    /// - Parameter badge: Badge to check progress for
    /// - Returns: Progress value between 0.0 and 1.0
    func getBadgeProgress(for badge: Badge) -> Double {
        // Check if badge is already earned
        if earnedBadges.contains(where: { $0.badgeKey == badge.badgeKey }) {
            return 1.0
        }
        
        // If badge requires tasks, use the completed task count
        guard let requiredTaskCount = badge.requiredTaskCount, requiredTaskCount > 0 else {
            return 0.0
        }
        
        // Calculate progress based on total completed tasks
        let progress = min(1.0, Double(totalCompletedTasks) / Double(requiredTaskCount))
        return progress
    }
    
    /// In-memory cache of badge progress values
    private var badgeProgressMap: [String: Double] = [:]
}
