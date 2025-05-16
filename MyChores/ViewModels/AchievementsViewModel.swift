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
    private let userService: UserServiceProtocol
    
    /// Chore service instance
    private let choreService: ChoreServiceProtocol
    
    // MARK: - Initialization
    
    init(userId: String? = nil, userService: UserServiceProtocol = UserService.shared, choreService: ChoreServiceProtocol = ChoreService.shared, authService: any AuthServiceProtocol = AuthService.shared) {
        // Use provided ID or current authenticated user
        self.userId = userId ?? authService.getCurrentUserId() ?? ""
        self.userService = userService
        self.choreService = choreService
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
                    
                    // Determine completed tasks count
                    var completedCount = user.totalPoints  // Use totalPoints as a proxy for completed chores
                    
                    // Calculate earned badges based on user's earned badges array
                    let earned = Badge.predefinedBadges.filter { badge in
                        return user.earnedBadges.contains(badge.badgeKey)
                    }
                    
                    // All badges not in earned are unearned
                    let unearned = Badge.predefinedBadges.filter { badge in
                        return !user.earnedBadges.contains(badge.badgeKey)
                    }
                    
                    print("🎖️ Found \(earned.count) earned badges from user's earned badges list")
                    // Use user's stored total points
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
    func getBadgeProgress(for badge: Badge) async -> Double {
        // Check if badge is already earned
        if earnedBadges.contains(where: { $0.badgeKey == badge.badgeKey }) {
            return 1.0
        }
        
        // If badge requires tasks, use the totalPoints as a proxy for completed tasks
        if let requiredTaskCount = badge.requiredTaskCount, requiredTaskCount > 0 {
            // Calculate progress based on total points
            let progress = min(1.0, Double(totalPoints) / Double(requiredTaskCount))
            return progress
        }
        
        // For special badges, use specific logic
        switch badge.badgeKey {
        case "daily_streak":
            // Show progress based on current streak days
            if let user = try? await userService.fetchUser(withId: userId) {
                let streakThreshold = 7 // Days needed for the badge
                let progress = min(1.0, Double(user.currentStreakDays) / Double(streakThreshold))
                
                await MainActor.run {
                    self.badgeProgressMap[badge.badgeKey] = progress
                    self.objectWillChange.send()
                }
            }
            return badgeProgressMap[badge.badgeKey] ?? 0.0
            
        case "household_helper":
            // Get user and check household count
            Task {
                do {
                    if let user = try await userService.fetchUser(withId: userId) {
                        let householdCount = user.householdIds.count
                        let progress = min(1.0, Double(householdCount) / 2.0) // Need at least 2 households
                        
                        await MainActor.run {
                            self.badgeProgressMap[badge.badgeKey] = progress
                            self.objectWillChange.send()
                        }
                    }
                } catch {
                    print("Error fetching user for household badge progress: \(error)")
                }
            }
            return badgeProgressMap[badge.badgeKey] ?? 0.0
            
        case "early_bird":
            // Show progress based on early completions
            if let user = try? await userService.fetchUser(withId: userId) {
                let earlyThreshold = 5 // Early completions needed for the badge
                let progress = min(1.0, Double(user.earlyCompletionCount) / Double(earlyThreshold))
                
                await MainActor.run {
                    self.badgeProgressMap[badge.badgeKey] = progress
                    self.objectWillChange.send()
                }
            }
            return badgeProgressMap[badge.badgeKey] ?? 0.0
            
        default:
            return 0.0
        }
    }
    
    /// In-memory cache of badge progress values
    private var badgeProgressMap: [String: Double] = [:]
}
