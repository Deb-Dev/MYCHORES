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
    private let householdService: HouseholdServiceProtocol
    
    /// User service instance
    private let userService: UserServiceProtocol

    /// Auth service instance
    private let authService: any AuthServiceProtocol
    
    // MARK: - Initialization
    
    init(selectedHouseholdId: String? = nil, householdService: HouseholdServiceProtocol = HouseholdService.shared, userService: UserServiceProtocol = UserService.shared, authService: any AuthServiceProtocol = AuthService.shared) {
        self.householdService = householdService
        self.userService = userService
        self.authService = authService

        if let householdId = selectedHouseholdId {
            fetchHousehold(id: householdId)
        } else {
            // Potentially load households or set a default state
            loadHouseholds() 
        }
        // Observe current user changes from AuthService to update local currentUser
        // This requires AuthService to be an ObservableObject and currentUser to be @Published
        // For simplicity, assuming direct access or a separate mechanism to update currentUser
        Task {
            self.currentUser = try? await self.userService.fetchUser(withId: self.authService.getCurrentUserId() ?? "")
        }
    }
    
    // MARK: - Household Methods
    
    /// Load all households for the current user
    func loadHouseholds() {
        guard let userId = authService.getCurrentUserId() else {
            errorMessage = "User not logged in."
            isLoading = false
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                let households = try await householdService.fetchHouseholds(forUserId: userId)
                await MainActor.run {
                    self.households = households
                    if selectedHousehold == nil, let firstHousehold = households.first {
                        self.selectedHousehold = firstHousehold
                        if let currentSelectedHousehold = self.selectedHousehold {
                             self.loadHouseholdMembers(household: currentSelectedHousehold)
                        }
                    }
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
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
            errorMessage = "Household ID cannot be empty."
            isLoading = false
            completion?(false)
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                let household = try await householdService.fetchHousehold(withId: id)
                await MainActor.run {
                    self.selectedHousehold = household
                    if let currentSelectedHousehold = self.selectedHousehold {
                        self.loadHouseholdMembers(household: currentSelectedHousehold)
                    }
                    self.isLoading = false
                    completion?(household != nil)
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = "Failed to fetch household: \(error.localizedDescription)"
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
        guard let userId = authService.getCurrentUserId() else {
            errorMessage = "User not logged in."
            isLoading = false
            completion?(false)
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                let newHousehold = try await householdService.createHousehold(name: name, ownerUserId: userId)
                await MainActor.run {
                    self.households.append(newHousehold)
                    self.selectedHousehold = newHousehold // Optionally select the new household
                    if let currentSelectedHousehold = self.selectedHousehold {
                        self.loadHouseholdMembers(household: currentSelectedHousehold)
                    }
                    self.isLoading = false
                    completion?(true)
                }
            } catch {
                await MainActor.run {
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
        guard let userId = authService.getCurrentUserId() else {
            errorMessage = "User not logged in."
            isLoading = false
            completion?(false)
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                guard let householdToJoin = try await householdService.findHousehold(byInviteCode: inviteCode) else {
                    await MainActor.run {
                        self.errorMessage = "Invalid invite code."
                        self.isLoading = false
                        completion?(false)
                    }
                    return
                }
                try await householdService.addMember(userId: userId, toHouseholdId: householdToJoin.id ?? "")
                try await userService.addUserToHousehold(userId: userId, householdId: householdToJoin.id ?? "")
                
                await MainActor.run {
                    // Refresh households list or add the joined household
                    self.loadHouseholds() 
                    self.isLoading = false
                    completion?(true)
                }
            } catch {
                await MainActor.run {
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
                await MainActor.run {
                    // Refresh the specific household or the list
                    if let index = self.households.firstIndex(where: { $0.id == householdId }) {
                        self.households[index].name = newName
                    }
                    if self.selectedHousehold?.id == householdId {
                        self.selectedHousehold?.name = newName
                    }
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = "Failed to update household name: \(error.localizedDescription)"
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
        guard let userId = authService.getCurrentUserId() else {
            errorMessage = "User not logged in."
            isLoading = false
            completion?(false)
            return
        }

        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                try await householdService.removeMember(userId: userId, fromHouseholdId: householdId)
                try await userService.removeUserFromHousehold(userId: userId, householdId: householdId)
                await MainActor.run {
                    self.households.removeAll { $0.id == householdId }
                    if self.selectedHousehold?.id == householdId {
                        self.selectedHousehold = self.households.first
                        if let currentSelectedHousehold = self.selectedHousehold {
                           self.loadHouseholdMembers(household: currentSelectedHousehold)
                        } else {
                            self.householdMembers = []
                        }
                    }
                    self.isLoading = false
                    completion?(true)
                }
            } catch {
                await MainActor.run {
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
        return household.ownerUserId == authService.getCurrentUserId()
    }
    
    // MARK: - Member Management
    
    /// Load members of a household
    /// - Parameter household: Household
    private func loadHouseholdMembers(household: Household) {
        guard let householdId = household.id else {
            self.householdMembers = []
            return
        }
        isLoading = true
        Task {
            do {
                let members = try await userService.fetchUsers(inHousehold: householdId)
                await MainActor.run {
                    self.householdMembers = members
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = "Failed to load household members: \(error.localizedDescription)"
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
        guard let householdId = selectedHousehold?.id else {
            errorMessage = "No household selected."
            completion?(false)
            return
        }
        // Ensure current user is owner before removing another member
        guard selectedHousehold?.ownerUserId == authService.getCurrentUserId() else {
            errorMessage = "Only the household owner can remove members."
            completion?(false)
            return
        }

        isLoading = true
        errorMessage = nil

        Task {
            do {
                try await householdService.removeMember(userId: userId, fromHouseholdId: householdId)
                try await userService.removeUserFromHousehold(userId: userId, householdId: householdId)
                await MainActor.run {
                    self.householdMembers.removeAll { $0.id == userId }
                    self.isLoading = false
                    completion?(true)
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = "Failed to remove member: \(error.localizedDescription)"
                    self.isLoading = false
                    completion?(false)
                }
            }
        }
    }
}
