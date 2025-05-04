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
    private let choreService = ChoreService.shared
    
    /// User service instance
    private let userService = UserService.shared
    
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
        let currentUserId = AuthService.shared.getCurrentUserId() ?? ""
        
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
    
    init(householdId: String, choreId: String? = nil) {
        self.householdId = householdId
        loadChores()
        
        if let choreId = choreId {
            loadChore(id: choreId)
        }
    }
    
    // MARK: - Chore Methods
    
    /// Load all chores for the current household
    func loadChores() {
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                let fetchedChores = try await choreService.fetchChores(forHouseholdId: householdId)
                
                DispatchQueue.main.async {
                    self.isLoading = false
                    self.chores = fetchedChores
                    
                    // Note: We keep the debug print but don't show error to user for empty state
                    // as this is a normal condition, especially for new users
                    if fetchedChores.isEmpty {
                        print("No chores found for household: \(self.householdId)")
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    self.isLoading = false
                    
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
                            print("Permission error loading chores: \(error.localizedDescription)")
                        }
                        else {
                            self.errorMessage = "Failed to load chores: \(error.localizedDescription)"
                            print("Error loading chores: \(error.localizedDescription)")
                        }
                    } else {
                        self.errorMessage = "Failed to load chores: \(error.localizedDescription)"
                        print("Error loading chores: \(error.localizedDescription)")
                    }
                }
            }
        }
    }
    
    /// Load all chores for the current household (async version)
    @MainActor
    func loadChoresAsync() async {
        isLoading = true
        errorMessage = nil
        
        do {
            let fetchedChores = try await choreService.fetchChores(forHouseholdId: householdId)
            self.chores = fetchedChores
            self.isLoading = false
        } catch {
            self.errorMessage = "Failed to load chores: \(error.localizedDescription)"
            self.isLoading = false
        }
    }
    
    /// Load a specific chore
    /// - Parameter id: Chore ID
    func loadChore(id: String) {
        Task {
            do {
                if let chore = try await choreService.fetchChore(withId: id) {
                    DispatchQueue.main.async {
                        self.selectedChore = chore
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    self.errorMessage = "Failed to load chore: \(error.localizedDescription)"
                }
            }
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
    func createChore(
        title: String,
        description: String = "",
        assignedToUserId: String? = nil,
        dueDate: Date? = nil,
        pointValue: Int = 1,
        isRecurring: Bool = false,
        recurrenceType: Chore.RecurrenceType? = nil,
        recurrenceInterval: Int? = nil,
        recurrenceDaysOfWeek: [Int]? = nil,
        recurrenceDayOfMonth: Int? = nil,
        recurrenceEndDate: Date? = nil
    ) {
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                let newChore = try await choreService.createChore(
                    title: title,
                    description: description,
                    householdId: householdId,
                    assignedToUserId: assignedToUserId,
                    dueDate: dueDate,
                    pointValue: pointValue,
                    isRecurring: isRecurring,
                    recurrenceType: recurrenceType,
                    recurrenceInterval: recurrenceInterval,
                    recurrenceDaysOfWeek: recurrenceDaysOfWeek,
                    recurrenceDayOfMonth: recurrenceDayOfMonth,
                    recurrenceEndDate: recurrenceEndDate
                )
                
                DispatchQueue.main.async {
                    self.chores.append(newChore)
                    self.isLoading = false
                }
            } catch {
                DispatchQueue.main.async {
                    self.errorMessage = "Failed to create chore: \(error.localizedDescription)"
                    self.isLoading = false
                }
            }
        }
    }
    
    /// Update an existing chore
    /// - Parameter chore: The updated chore
    func updateChore(_ chore: Chore) {
        guard let id = chore.id else {
            errorMessage = "Invalid chore ID"
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                try await choreService.updateChore(chore)
                
                DispatchQueue.main.async {
                    // Update in the chores array
                    if let index = self.chores.firstIndex(where: { $0.id == id }) {
                        self.chores[index] = chore
                    }
                    
                    // Update selected chore if needed
                    if self.selectedChore?.id == id {
                        self.selectedChore = chore
                    }
                    
                    self.isLoading = false
                }
            } catch {
                DispatchQueue.main.async {
                    self.errorMessage = "Failed to update chore: \(error.localizedDescription)"
                    self.isLoading = false
                }
            }
        }
    }
    
    /// Delete a chore
    /// - Parameter choreId: Chore ID to delete
    func deleteChore(choreId: String) {
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                try await choreService.deleteChore(withId: choreId)
                
                DispatchQueue.main.async {
                    // Remove from the chores array
                    self.chores.removeAll { $0.id == choreId }
                    
                    // Clear selected chore if it was the deleted one
                    if self.selectedChore?.id == choreId {
                        self.selectedChore = nil
                    }
                    
                    self.isLoading = false
                }
            } catch {
                DispatchQueue.main.async {
                    self.errorMessage = "Failed to delete chore: \(error.localizedDescription)"
                    self.isLoading = false
                }
            }
        }
    }
    
    /// Mark a chore as completed
    /// - Parameter choreId: Chore ID to complete
    func completeChore(choreId: String) {
        guard let userId = AuthService.shared.getCurrentUserId() else {
            errorMessage = "Not signed in"
            return
        }
        
        isLoading = true
        errorMessage = nil
        pointsEarnedMessage = nil
        badgeEarnedMessage = nil
        
        Task {
            do {
                // Complete the chore
                let points = try await choreService.completeChore(choreId: choreId, completedByUserId: userId)
                
                // Reload the chore to get updated data
                if let updatedChore = try await choreService.fetchChore(withId: choreId) {
                    DispatchQueue.main.async {
                        // Update in the chores array
                        if let index = self.chores.firstIndex(where: { $0.id == choreId }) {
                            self.chores[index] = updatedChore
                        }
                        
                        // Update selected chore if needed
                        if self.selectedChore?.id == choreId {
                            self.selectedChore = updatedChore
                        }
                        
                        // Show points earned message
                        self.pointsEarnedMessage = "You earned \(points) points!"
                        
                        self.isLoading = false
                    }
                }
                
                // Check if any new badges were earned
                let user = try await userService.fetchUser(withId: userId)
                if let user = user {
                    // Check badge progress
                    let badgeMessages = self.checkNewlyEarnedBadges(user)
                    if !badgeMessages.isEmpty {
                        DispatchQueue.main.async {
                            self.badgeEarnedMessage = badgeMessages.joined(separator: "\n")
                        }
                    }
                }
                
                // Reload all chores to show any new recurring instances
                self.loadChores()
                
            } catch {
                DispatchQueue.main.async {
                    self.errorMessage = "Failed to complete chore: \(error.localizedDescription)"
                    self.isLoading = false
                }
            }
        }
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
