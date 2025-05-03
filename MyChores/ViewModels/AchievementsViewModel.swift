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
                // Get the user to check their earned badges
                if let user = try await userService.fetchUser(withId: userId) {
                    // Map badge keys to actual Badge objects
                    let earned = user.earnedBadges.compactMap { badgeKey in
                        Badge.getBadge(byKey: badgeKey)
                    }
                    
                    // Get unearned badges
                    let unearned = Badge.predefinedBadges.filter { badge in
                        !user.earnedBadges.contains(badge.badgeKey)
                    }
                    
                    // Fetch completed tasks to calculate totals
                    let completedChores = try await ChoreService.shared.fetchChores(forUserId: userId, includeCompleted: true)
                    let completedCount = completedChores.filter { $0.isCompleted }.count
                    
                    // Calculate total points
                    let points = user.totalPoints
                    
                    DispatchQueue.main.async {
                        self.earnedBadges = earned
                        self.unearnedBadges = unearned
                        self.totalCompletedTasks = completedCount
                        self.totalEarnedBadges = earned.count
                        self.totalPoints = points
                        self.isLoading = false
                    }
                } else {
                    DispatchQueue.main.async {
                        self.errorMessage = "User not found"
                        self.isLoading = false
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    self.errorMessage = "Failed to load badges: \(error.localizedDescription)"
                    self.isLoading = false
                }
            }
        }
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
