// LeaderboardViewModel.swift
// MyChores
//
// Created on 2025-05-02.
//

import Foundation
import Combine
import FirebaseFirestore // Added import

/// ViewModel for leaderboard-related views
class LeaderboardViewModel: ObservableObject {
    // MARK: - Published Properties
    
    /// Users for the weekly leaderboard
    @Published var weeklyLeaderboard: [User] = []
    
    /// Users for the monthly leaderboard
    @Published var monthlyLeaderboard: [User] = []
    
    /// Currently selected time period
    @Published var selectedPeriod: LeaderboardPeriod = .weekly
    
    /// Loading state
    @Published var isLoading = false
    
    /// Error message
    @Published var errorMessage: String?
    
    // MARK: - Private Properties
    
    /// Current household ID
    private let householdId: String
    
    /// User service instance
    private let userService: UserServiceProtocol // Changed to protocol
    
    // MARK: - Leaderboard Periods
    
    /// Time periods for the leaderboard
    enum LeaderboardPeriod: String, CaseIterable, Identifiable {
        case weekly = "This Week"
        case monthly = "This Month"
        
        var id: String { self.rawValue }
    }
    
    // MARK: - Initialization
    
    init(householdId: String, userService: UserServiceProtocol = UserService.shared) { // Added protocol injection
        self.householdId = householdId
        self.userService = userService
        loadLeaderboards()
    }
    
    // MARK: - Leaderboard Methods
    
    /// Load both weekly and monthly leaderboards
    func loadLeaderboards() {
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                // Load both leaderboards in parallel
                async let weeklyUsers = userService.getWeeklyLeaderboard(forHouseholdId: householdId)
                async let monthlyUsers = userService.getMonthlyLeaderboard(forHouseholdId: householdId)
                
                let (weekly, monthly) = try await (weeklyUsers, monthlyUsers)
                
                DispatchQueue.main.async {
                    self.weeklyLeaderboard = weekly
                    self.monthlyLeaderboard = monthly
                    self.isLoading = false
                }
            } catch {
                DispatchQueue.main.async {
                    self.errorMessage = "Failed to load leaderboard: \(error.localizedDescription)"
                    self.isLoading = false
                }
            }
        }
    }
    
    /// Get current leaderboard based on selected period
    var currentLeaderboard: [User] {
        switch selectedPeriod {
        case .weekly:
            return weeklyLeaderboard
        case .monthly:
            return monthlyLeaderboard
        }
    }
    
    /// Get ranking information for a user
    /// - Parameter userId: User ID
    /// - Returns: Tuple with rank and total users
    func getRanking(for userId: String) -> (rank: Int, total: Int)? {
        let users = currentLeaderboard
        
        guard !users.isEmpty else {
            return nil
        }
        
        if let index = users.firstIndex(where: { $0.id == userId }) {
            return (rank: index + 1, total: users.count)
        }
        
        return nil
    }
    
    /// Check if a user is in the top 3
    /// - Parameter userId: User ID
    /// - Returns: Boolean indicating if in top 3
    func isInTopThree(userId: String) -> Bool {
        let users = currentLeaderboard
        
        guard users.count >= 3, let index = users.firstIndex(where: { $0.id == userId }) else {
            return false
        }
        
        return index < 3
    }
    
    /// Get points for the current period for a specific user
    /// - Parameter userId: User ID
    /// - Returns: Points for the selected period
    func getPointsForCurrentPeriod(userId: String) -> Int {
        guard let user = currentLeaderboard.first(where: { $0.id == userId }) else {
            return 0
        }
        
        switch selectedPeriod {
        case .weekly:
            return user.weeklyPoints
        case .monthly:
            return user.monthlyPoints
        }
    }
}
