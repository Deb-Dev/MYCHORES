// ChoreViewModel.swift
// MyChores
//
// Created on 2025-05-02.
//

import Foundation
import Combine
import SwiftUI
import FirebaseFirestore
import FirebaseAuth

/// ViewModel for chore-related views
class ChoreViewModel: ObservableObject {
    // MARK: - Published Properties
    
    /// All chores for the current household
    @Published var chores: [Chore] = []
    
    /// Currently selected chore
    @Published var selectedChore: Chore?
    
    /// Filter mode for the chores list
    @Published var filterMode: FilterMode = .all
    
    /// Loading state
    @Published var isLoading = false
    
    /// Error message
    @Published var errorMessage: String?
    
    /// Points earned message (when completing a chore)
    @Published var pointsEarnedMessage: String?
    
    /// Badge earned message
    @Published var badgeEarnedMessage: String?
    
    // MARK: - Private Properties
    
    /// Current household ID
    let householdId: String
    
    /// Chore service instance
    private let choreService: ChoreServiceProtocol
    
    /// User service instance
    private let userService: UserServiceProtocol
    
    /// Auth service instance
    let authService: any AuthServiceProtocol

    
    // MARK: - Filter Modes
    
    /// Filter options for the chores list
    enum FilterMode: String, CaseIterable, Identifiable {
        case all = "All"
        case mine = "Assigned to Me"
        case pending = "Pending"
        case overdue = "Overdue"
        case completed = "Completed"
        
        var id: String { self.rawValue }
    }
    
    // MARK: - Computed Properties
    
    /// Filtered chores based on current filter mode
    var filteredChores: [Chore] {
        let currentUserId = authService.getCurrentUserId() ?? ""
        
        switch filterMode {
        case .all:
            return sortedChores(chores: chores)
            
        case .mine:
            return sortedChores(chores: chores.filter { $0.assignedToUserId == currentUserId })
            
        case .pending:
            return sortedChores(chores: chores.filter { !$0.isCompleted })
            
        case .overdue:
            return sortedChores(chores: chores.filter { $0.isOverdue })
            
        case .completed:
            return sortedChores(chores: chores.filter { $0.isCompleted })
        }
    }
    
    // MARK: - Initialization
    
    init(householdId: String, choreId: String? = nil, authService: any AuthServiceProtocol = AuthService.shared, choreService: ChoreServiceProtocol = ChoreService.shared, userService: UserServiceProtocol = UserService.shared) {
        self.householdId = householdId
        self.authService = authService
        self.choreService = choreService
        self.userService = userService
        Task { // Keep Task for initial load
            await loadChoresAsync() // Changed to loadChoresAsync for clarity if it's the preferred async version
            if let choreId = choreId {
                await loadChoreAsync(id: choreId) // Assuming a loadChoreAsync exists or create one
            }
        }
    }
    
    // MARK: - Chore Methods
    
    /// Load all chores for the current household
    @MainActor
    func loadChores() { // This is a synchronous wrapper for the Task-based load
        Task {
            await loadChoresAsync()
        }
    }
    
    /// Load all chores for the current household (async version)
    @MainActor
    func loadChoresAsync() async {
        isLoading = true
        errorMessage = nil
        
        do {
            let fetchedChores = try await choreService.fetchChores(forHouseholdId: householdId, includeCompleted: true)
            self.chores = fetchedChores
            // Note: We keep the debug print but don't show error to user for empty state
            // as this is a normal condition, especially for new users
            if fetchedChores.isEmpty {
                print("No chores found for household: \\(self.householdId)")
            }
        } catch {
            // Handle specific error types more gracefully
            if let nsError = error as NSError? {
                // Network connectivity issues
                if nsError.domain == NSURLErrorDomain {
                    self.errorMessage = "Network error: Please check your connection and try again."
                }
                // Permission errors (common with Firebase)
                else if error.localizedDescription.contains("permission") || 
                        error.localizedDescription.contains("Missing or insufficient permissions") {
                    self.errorMessage = "Permission error: You may not have access to this household's chores."
                    print("Permission error loading chores: \\(error.localizedDescription)")
                }
                else {
                    self.errorMessage = "Failed to load chores: \\(error.localizedDescription)"
                    print("Error loading chores: \\(error.localizedDescription)")
                }
            } else {
                self.errorMessage = "Failed to load chores: \\(error.localizedDescription)"
                print("Error loading chores: \\(error.localizedDescription)")
            }
        }
        self.isLoading = false // Ensure isLoading is set to false in all paths
    }
    
    /// Load a specific chore
    /// - Parameter id: Chore ID
    @MainActor
    func loadChore(id: String) { // Synchronous wrapper
        Task {
            await loadChoreAsync(id: id)
        }
    }

    /// Load a specific chore (async version)
    @MainActor
    func loadChoreAsync(id: String) async {
        // Consider setting isLoading = true here if it's a distinct loading operation
        // For now, assuming it might be part of a larger loading sequence or quick enough not to warrant it.
        do {
            if let chore = try await choreService.fetchChore(withId: id) {
                self.selectedChore = chore
            }
        } catch {
            self.errorMessage = "Failed to load chore: \\(error.localizedDescription)"
        }
    }
    
    /// Create a new chore
    /// - Parameters:
    ///   - title: Chore title
    ///   - description: Detailed description
    ///   - assignedToUserId: User ID the chore is assigned to (optional)
    ///   - dueDate: Due date for completion (optional)
    ///   - pointValue: Points awarded for completion
    ///   - isRecurring: Whether this is a recurring chore
    ///   - recurrenceType: Type of recurrence (daily, weekly, monthly)
    ///   - recurrenceInterval: Interval between recurrences
    ///   - recurrenceDaysOfWeek: Days of week for weekly recurrence
    ///   - recurrenceDayOfMonth: Day of month for monthly recurrence
    ///   - recurrenceEndDate: End date for recurring chores
    @MainActor
    func createChore(
        title: String,
        description: String = "",
        assignedToUserId: String? = nil,
        dueDate: Date? = nil,
        pointValue: Int = 1,
        isRecurring: Bool = false,
        recurrenceType: RecurrenceType? = nil,
        recurrenceInterval: Int? = nil,
        recurrenceDaysOfWeek: [Int]? = nil,
        recurrenceDayOfMonth: Int? = nil,
        recurrenceEndDate: Date? = nil
    ) {
        isLoading = true
        errorMessage = nil
        
        Task {
            defer { self.isLoading = false } // Ensure isLoading is reset
            do {
                guard let userid = authService.getCurrentUserId() else {
                    self.errorMessage = "User not authenticated. Please sign in again."
                    return
                }
                
                let newChore = try await choreService.createChore(
                    title: title,
                    description: description,
                    householdId: householdId,
                    assignedToUserId: assignedToUserId, 
                    createdByUserId: userid,
                    dueDate: dueDate,
                    pointValue: pointValue,
                    isRecurring: isRecurring,
                    recurrenceType: recurrenceType,
                    recurrenceInterval: recurrenceInterval,
                    recurrenceDaysOfWeek: recurrenceDaysOfWeek,
                    recurrenceDayOfMonth: recurrenceDayOfMonth,
                    recurrenceEndDate: recurrenceEndDate
                )
                
                self.chores.append(newChore)
            } catch {
                self.errorMessage = "Failed to create chore: \\(error.localizedDescription)"
            }
        }
    }
    
    /// Update an existing chore
    /// - Parameter chore: The updated chore
    @MainActor
    func updateChore(_ chore: Chore) {
        guard let id = chore.id else {
            errorMessage = "Invalid chore ID"
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        Task {
            defer { self.isLoading = false } // Ensure isLoading is reset
            do {
                try await choreService.updateChore(chore)
                
                // Update in the chores array
                if let index = self.chores.firstIndex(where: { $0.id == id }) {
                    self.chores[index] = chore
                }
                
                // Update selected chore if needed
                if self.selectedChore?.id == id {
                    self.selectedChore = chore
                }
            } catch {
                self.errorMessage = "Failed to update chore: \\(error.localizedDescription)"
            }
        }
    }
    
    /// Delete a chore
    /// - Parameter choreId: Chore ID to delete
    @MainActor
    func deleteChore(choreId: String) {
        isLoading = true
        errorMessage = nil
        
        Task {
            defer { self.isLoading = false } // Ensure isLoading is reset
            do {
                try await choreService.deleteChore(withId: choreId)
                
                // Remove from the chores array
                self.chores.removeAll { $0.id == choreId }
                
                // Clear selected chore if it was the deleted one
                if self.selectedChore?.id == choreId {
                    self.selectedChore = nil
                }
            } catch {
                self.errorMessage = "Failed to delete chore: \\(error.localizedDescription)"
            }
        }
    }
    
    /// Mark a chore as completed
    /// - Parameter choreId: Chore ID to complete
    @MainActor
    func completeChore(choreId: String) {
        isLoading = true // Set loading at the beginning of the whole operation
        errorMessage = nil
        pointsEarnedMessage = nil
        badgeEarnedMessage = nil
        
        Task {
            defer { self.isLoading = false } // Ensure isLoading is reset at the end of the task

            guard let userId = authService.getCurrentUserId() else {
                self.errorMessage = "User not authenticated. Please sign in again."
                return
            }
            
            do {
                // Complete the chore and get back the completed chore, points, and any new recurring chore
                let result = try await choreService.completeChore(choreId: choreId, completedByUserId: userId, createNextRecurrence: true) // Assuming we want to create next recurrence
                
                let completedChore = result.completedChore
                let pointsEarned = result.pointsEarned
                let nextRecurringChore = result.nextRecurringChore

                // Update in the chores array
                if let index = self.chores.firstIndex(where: { $0.id == choreId }) {
                    self.chores[index] = completedChore
                }
                
                // Update selected chore if needed
                if self.selectedChore?.id == choreId {
                    self.selectedChore = completedChore
                }
                
                // Show points earned message
                self.pointsEarnedMessage = "You earned \\(pointsEarned) points!"
                
                // If a new recurring chore was created, add it to the list
                if let newChore = nextRecurringChore {
                    self.chores.append(newChore)
                    // Optionally, sort chores again if order matters immediately
                    // self.chores = sortedChores(chores: self.chores)
                }
                
                // Check if any new badges were earned
                // This can potentially be slow, consider if it needs to block the main chore completion flow
                if let user = try await userService.fetchUser(withId: userId) {
                    let badgeMessages = self.checkNewlyEarnedBadges(user)
                    if !badgeMessages.isEmpty {
                        self.badgeEarnedMessage = badgeMessages.joined(separator: "\\n")
                    }
                }
                // No need to call self.loadChores() anymore if service returns all necessary data
                
            } catch {
                self.errorMessage = "Failed to complete chore: \\(error.localizedDescription)"
            }
        }
    }
    
    /// Refreshes chores from Firebase
    @MainActor
    func refreshChores() async {
        await loadChoresAsync()
    }
    
    // MARK: - Helper Methods
    
    /// Sort chores in a sensible order (overdue & upcoming first, then by due date)
    /// - Parameter chores: Chores to sort
    /// - Returns: Sorted array of chores
    private func sortedChores(chores: [Chore]) -> [Chore] {
        return chores.sorted { chore1, chore2 in
            // First, prioritize non-completed chores
            if chore1.isCompleted != chore2.isCompleted {
                return !chore1.isCompleted
            }
            
            // For non-completed chores, prioritize overdue
            if !chore1.isCompleted && !chore2.isCompleted {
                if chore1.isOverdue != chore2.isOverdue {
                    return chore1.isOverdue
                }
                
                // Then sort by due date (if both have due dates)
                if let date1 = chore1.dueDate, let date2 = chore2.dueDate {
                    return date1 < date2
                } else if chore1.dueDate != nil {
                    return true
                } else if chore2.dueDate != nil {
                    return false
                }
            }
            
            // For completed chores, sort by completion date (newest first)
            if chore1.isCompleted && chore2.isCompleted {
                if let date1 = chore1.completedAt, let date2 = chore2.completedAt {
                    return date1 > date2
                }
            }
            
            // Fall back to creation date
            return chore1.createdAt > chore2.createdAt
        }
    }
    
    /// Check if new badges were earned
    /// - Parameter user: User to check
    /// - Returns: Array of badge message strings
    private func checkNewlyEarnedBadges(_ user: User) -> [String] {
        var messages: [String] = []
        
        for badgeKey in user.earnedBadges {
            if let badge = Badge.getBadge(byKey: badgeKey) {
                messages.append("🏆 New Badge Earned: \(badge.name)")
            }
        }
        
        return messages
    }
}
