// HouseholdViewModel.swift
// MyChores
//
// Created on 2025-05-02.
//

import Foundation
import Combine
import FirebaseFirestore

/// ViewModel for household-related views
class HouseholdViewModel: ObservableObject {
    // MARK: - Published Properties
    
    /// List of households
    @Published var households: [Household] = []
    
    /// Currently selected household
    @Published var selectedHousehold: Household?
    
    /// Members of the current household
    @Published var householdMembers: [User] = []
    
    /// Current logged-in user
    @Published var currentUser: User?
    
    /// Loading state
    @Published var isLoading = false
    
    /// Error message
    @Published var errorMessage: String?
    
    // MARK: - Private Properties
    
    /// Household service instance
    private let householdService = HouseholdService.shared
    
    /// User service instance
    private let userService = UserService.shared
    
    // MARK: - Initialization
    
    init(selectedHouseholdId: String? = nil) {
        if let householdId = selectedHouseholdId {
            fetchHousehold(id: householdId)
        } else {
            loadHouseholds()
        }
    }
    
    // MARK: - Household Methods
    
    /// Load all households for the current user
    func loadHouseholds() {
        guard let userId = AuthService.shared.getCurrentUserId() else {
            errorMessage = "Not signed in"
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                let fetchedHouseholds = try await householdService.fetchHouseholds(forUserId: userId)
                
                // Fetch current user data
                if let currentUserData = try await userService.fetchUser(withId: userId) {
                    DispatchQueue.main.async {
                        self.households = fetchedHouseholds
                        self.currentUser = currentUserData
                        self.isLoading = false
                    }
                } else {
                    DispatchQueue.main.async {
                        self.households = fetchedHouseholds
                        self.isLoading = false
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    self.errorMessage = "Failed to load households: \(error.localizedDescription)"
                    self.isLoading = false
                }
            }
        }
    }
    
    /// Load a specific household
    /// - Parameters:
    ///   - id: Household ID
    ///   - completion: Optional completion handler with success boolean
    func fetchHousehold(id: String, completion: ((Bool) -> Void)? = nil) {
        // Validate the household ID
        guard !id.isEmpty else {
            DispatchQueue.main.async {
                self.errorMessage = "Household ID cannot be empty"
                self.isLoading = false
                completion?(false)
            }
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                if let household = try await householdService.fetchHousehold(withId: id) {
                    DispatchQueue.main.async {
                        self.selectedHousehold = household
                        self.loadHouseholdMembers(household: household)
                        completion?(true)
                    }
                } else {
                    DispatchQueue.main.async {
                        self.errorMessage = "Household not found"
                        self.isLoading = false
                        completion?(false)
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    self.errorMessage = "Failed to load household: \(error.localizedDescription)"
                    self.isLoading = false
                    completion?(false)
                }
            }
        }
    }
    
    /// Create a new household
    /// - Parameters:
    ///   - name: Household name
    ///   - completion: Optional completion handler with success boolean
    func createHousehold(name: String, completion: ((Bool) -> Void)? = nil) {
        guard let userId = AuthService.shared.getCurrentUserId() else {
            errorMessage = "Not signed in"
            completion?(false)
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                let household = try await householdService.createHousehold(name: name, ownerUserId: userId)
                
                DispatchQueue.main.async {
                    self.households.append(household)
                    self.selectedHousehold = household
                    self.isLoading = false
                    completion?(true)
                }
            } catch {
                DispatchQueue.main.async {
                    self.errorMessage = "Failed to create household: \(error.localizedDescription)"
                    self.isLoading = false
                    completion?(false)
                }
            }
        }
    }
    
    /// Join a household using an invite code
    /// - Parameters:
    ///   - inviteCode: Household invite code
    ///   - completion: Optional completion handler with success boolean
    func joinHousehold(inviteCode: String, completion: ((Bool) -> Void)? = nil) {
        guard let userId = AuthService.shared.getCurrentUserId() else {
            errorMessage = "Not signed in"
            completion?(false)
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                // Find the household
                guard let household = try await householdService.findHousehold(byInviteCode: inviteCode) else {
                    DispatchQueue.main.async {
                        self.errorMessage = "Invalid invite code"
                        self.isLoading = false
                        completion?(false)
                    }
                    return
                }
                
                // Make sure user isn't already a member
                if let id = household.id, household.memberUserIds.contains(userId) {
                    DispatchQueue.main.async {
                        self.errorMessage = "You're already a member of this household"
                        self.isLoading = false
                        completion?(false)
                    }
                    return
                }
                
                // Add user to household
                if let id = household.id {
                    try await householdService.addMember(userId: userId, toHouseholdId: id)
                    
                    // Reload the households
                    let updatedHouseholds = try await householdService.fetchHouseholds(forUserId: userId)
                    
                    DispatchQueue.main.async {
                        self.households = updatedHouseholds
                        self.selectedHousehold = household
                        self.isLoading = false
                        completion?(true)
                    }
                } else {
                    throw NSError(domain: "HouseholdViewModel", code: 1, userInfo: [NSLocalizedDescriptionKey: "Invalid household ID"])
                }
            } catch {
                DispatchQueue.main.async {
                    self.errorMessage = "Failed to join household: \(error.localizedDescription)"
                    self.isLoading = false
                    completion?(false)
                }
            }
        }
    }
    
    /// Update a household's name
    /// - Parameters:
    ///   - householdId: Household ID
    ///   - newName: New household name
    func updateHouseholdName(householdId: String, newName: String) {
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                try await householdService.updateHouseholdName(householdId: householdId, newName: newName)
                
                // Reload the household
                if let household = try await householdService.fetchHousehold(withId: householdId) {
                    DispatchQueue.main.async {
                        self.selectedHousehold = household
                        
                        // Update in the households list too
                        if let index = self.households.firstIndex(where: { $0.id == householdId }) {
                            self.households[index] = household
                        }
                        
                        self.isLoading = false
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    self.errorMessage = "Failed to update household: \(error.localizedDescription)"
                    self.isLoading = false
                }
            }
        }
    }
    
    /// Leave a household
    /// - Parameters:
    ///   - householdId: Household ID
    ///   - completion: Optional completion handler with success boolean
    func leaveHousehold(householdId: String, completion: ((Bool) -> Void)? = nil) {
        guard let userId = AuthService.shared.getCurrentUserId() else {
            errorMessage = "Not signed in"
            completion?(false)
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                // Get the household
                guard let household = try await householdService.fetchHousehold(withId: householdId) else {
                    throw NSError(domain: "HouseholdViewModel", code: 1, userInfo: [NSLocalizedDescriptionKey: "Household not found"])
                }
                
                // Check if user is the owner
                if household.ownerUserId == userId {
                    // Delete the household if user is the owner
                    try await householdService.deleteHousehold(householdId: householdId, userId: userId)
                } else {
                    // Just remove the user from the household
                    try await householdService.removeMember(userId: userId, fromHouseholdId: householdId)
                }
                
                // Reload households
                let updatedHouseholds = try await householdService.fetchHouseholds(forUserId: userId)
                
                DispatchQueue.main.async {
                    self.households = updatedHouseholds
                    
                    // Clear selected household if it was the one we left
                    if self.selectedHousehold?.id == householdId {
                        self.selectedHousehold = nil
                    }
                    
                    self.isLoading = false
                    completion?(true)
                }
            } catch {
                DispatchQueue.main.async {
                    self.errorMessage = "Failed to leave household: \(error.localizedDescription)"
                    self.isLoading = false
                    completion?(false)
                }
            }
        }
    }
    
    /// Check if the current user is the owner of a household
    /// - Parameter household: Household to check
    /// - Returns: Boolean indicating ownership
    func isCurrentUserOwner(of household: Household) -> Bool {
        guard let userId = AuthService.shared.getCurrentUserId() else {
            return false
        }
        
        return household.ownerUserId == userId
    }
    
    // MARK: - Member Management
    
    /// Load members of a household
    /// - Parameter household: Household
    private func loadHouseholdMembers(household: Household) {
        Task {
            do {
                if !household.memberUserIds.isEmpty {
                    let users = try await userService.fetchUsers(withIds: household.memberUserIds)
                    let sortedMembers = household.memberUserIds.compactMap { users[$0] }
                    
                    DispatchQueue.main.async {
                        self.householdMembers = sortedMembers
                        self.isLoading = false
                    }
                } else {
                    DispatchQueue.main.async {
                        self.householdMembers = []
                        self.isLoading = false
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    self.errorMessage = "Failed to load members: \(error.localizedDescription)"
                    self.isLoading = false
                }
            }
        }
    }
    
    /// Remove a user from the current household
    /// - Parameters:
    ///   - userId: User ID to remove
    ///   - completion: Optional completion handler with success boolean
    func removeMember(userId: String, completion: ((Bool) -> Void)? = nil) {
        guard let household = selectedHousehold, let householdId = household.id else {
            errorMessage = "No household selected"
            completion?(false)
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                try await householdService.removeMember(userId: userId, fromHouseholdId: householdId)
                
                // Reload the household
                if let updatedHousehold = try await householdService.fetchHousehold(withId: householdId) {
                    DispatchQueue.main.async {
                        self.selectedHousehold = updatedHousehold
                        self.loadHouseholdMembers(household: updatedHousehold)
                        completion?(true)
                    }
                } else {
                    DispatchQueue.main.async {
                        self.isLoading = false
                        completion?(false)
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    self.errorMessage = "Failed to remove member: \(error.localizedDescription)"
                    self.isLoading = false
                    completion?(false)
                }
            }
        }
    }
}
