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

    /// Rules for the selected household (NEW)
    @Published var householdRules: [HouseholdRule] = []
    
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
        
        // Set current user from authService
        if let firebaseUser = authService.currentUser {
            self.currentUser = firebaseUser // Assuming authService.currentUser is your app's User model
        }
        
        if let initialId = selectedHouseholdId {
            fetchHousehold(id: initialId)
        } else {
            // If no specific household is pre-selected, try to load the user's households
            // and potentially select the first one or a previously selected one.
            loadUserHouseholdsAndSelectDefault()
        }
    }
    
    private func loadUserHouseholdsAndSelectDefault() {
        guard let userId = authService.getCurrentUserId() else {
            errorMessage = "User not authenticated."
            return
        }
        isLoading = true
        Task {
            do {
                let fetchedHouseholds = try await householdService.fetchHouseholds(forUserId: userId)
                await MainActor.run {
                    self.households = fetchedHouseholds
                    if let firstHousehold = fetchedHouseholds.first {
                        self.selectHousehold(firstHousehold) // Automatically select the first household
                    } else {
                        // Handle case where user has no households yet
                        self.selectedHousehold = nil
                        self.householdMembers = []
                        self.householdRules = [] // Clear rules if no household
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

    /// Selects a household and fetches its details, members, and rules.
    func selectHousehold(_ household: Household) {
        self.selectedHousehold = household
        if let householdId = household.id {
            fetchHouseholdDetails(id: householdId)
            loadHouseholdRules() // Load rules when a household is selected
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
        isLoading = true
        Task {
            do {
                let fetchedHousehold = try await householdService.fetchHousehold(withId: id)
                await MainActor.run {
                    if let household = fetchedHousehold {
                        self.selectHousehold(household) // Use selectHousehold to also load members and rules
                        completion?(true)
                    } else {
                        self.errorMessage = "Household with ID \(id) not found."
                        completion?(false)
                    }
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = "Failed to fetch household: \(error.localizedDescription)"
                    isLoading = false
                    completion?(false)
                }
            }
        }
    }

    /// Fetches details for the currently selected household, including its members.
    private func fetchHouseholdDetails(id: String) {
        // This function is now primarily for fetching members, as household object is already set.
        // Rules are fetched by loadHouseholdRules()
        isLoading = true
        Task {
            do {
                let members = try await userService.fetchUsers(inHousehold: id)
                await MainActor.run {
                    self.householdMembers = members
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = "Failed to fetch household members: \(error.localizedDescription)"
                    isLoading = false
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
            errorMessage = "User not authenticated."
            completion?(false)
            return
        }
        isLoading = true
        Task {
            do {
                try await householdService.removeMember(userId: userId, fromHouseholdId: householdId)
                await MainActor.run {
                    // Refresh user's households list and potentially select another one or show empty state
                    self.loadUserHouseholdsAndSelectDefault()
                    isLoading = false
                    completion?(true)
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = "Failed to leave household: \(error.localizedDescription)"
                    isLoading = false
                    completion?(false)
                }
            }
        }
    }
    
    // MARK: - Household Rules Methods (NEW)

    /// Load rules for the currently selected household
    func loadHouseholdRules() {
        guard let householdId = selectedHousehold?.id else {
            self.householdRules = [] // Clear rules if no household is selected
            // errorMessage = "No household selected to load rules from."
            return
        }
        isLoading = true
        Task {
            do {
                let rules = try await householdService.fetchHouseholdRules(forHouseholdId: householdId)
                await MainActor.run {
                    self.householdRules = rules.sorted(by: { ($0.displayOrder ?? Int.max) < ($1.displayOrder ?? Int.max) }) // Sort by displayOrder, then createdAt if displayOrder is nil or same
                    // As a secondary sort, if displayOrder is not used or items have same displayOrder:
                    // self.householdRules = rules.sorted(by: { $0.createdAt < $1.createdAt })
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = "Failed to load household rules: \(error.localizedDescription)"
                    isLoading = false
                }
            }
        }
    }

    /// Add a new rule to the selected household
    func addHouseholdRule(ruleText: String) {
        guard let householdId = selectedHousehold?.id, let userId = authService.getCurrentUserId() else {
            errorMessage = "Cannot add rule: No household selected or user not authenticated."
            return
        }
        guard !ruleText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            errorMessage = "Rule text cannot be empty."
            return
        }
        
        isLoading = true
        Task {
            do {
                let newRule = try await householdService.createHouseholdRule(householdId: householdId, ruleText: ruleText, createdByUserId: userId)
                await MainActor.run {
                    self.householdRules.append(newRule)
                    // Optionally re-sort or just append
                    self.householdRules.sort(by: { ($0.displayOrder ?? Int.max) < ($1.displayOrder ?? Int.max) })
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = "Failed to add household rule: \(error.localizedDescription)"
                    isLoading = false
                }
            }
        }
    }

    /// Update an existing household rule
    func updateHouseholdRule(rule: HouseholdRule, newText: String? = nil, newDisplayOrder: Int? = nil) {
        guard let householdId = selectedHousehold?.id else {
            errorMessage = "Cannot update rule: No household selected."
            return
        }
        
        var ruleToUpdate = rule
        if let text = newText, !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            ruleToUpdate.ruleText = text
        }
        if let order = newDisplayOrder {
            ruleToUpdate.displayOrder = order
        }

        isLoading = true
        Task {
            do {
                let updatedRule = try await householdService.updateHouseholdRule(ruleToUpdate)
                await MainActor.run {
                    if let index = self.householdRules.firstIndex(where: { $0.id == updatedRule.id }) {
                        self.householdRules[index] = updatedRule
                        self.householdRules.sort(by: { ($0.displayOrder ?? Int.max) < ($1.displayOrder ?? Int.max) })
                    }
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = "Failed to update household rule: \(error.localizedDescription)"
                    isLoading = false
                }
            }
        }
    }

    /// Delete a household rule
    func deleteHouseholdRule(rule: HouseholdRule) {
        guard let ruleId = rule.id, let householdId = selectedHousehold?.id else {
            errorMessage = "Cannot delete rule: Rule ID or Household ID missing."
            return
        }
        isLoading = true
        Task {
            do {
                // Using the corrected service method that requires householdId
                try await householdService.deleteHouseholdRule(ruleId: ruleId)
                await MainActor.run {
                    self.householdRules.removeAll { $0.id == ruleId }
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = "Failed to delete household rule: \(error.localizedDescription)"
                    isLoading = false
                }
            }
        }
    }
}
