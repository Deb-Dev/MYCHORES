// HouseholdService.swift
// MyChores
//
// Created on 2025-05-02.
//

import Foundation
import FirebaseFirestore
import FirebaseAuth

/// Service for household data operations
class HouseholdService {
    // MARK: - Shared Instance
    
    /// Shared instance for singleton access
    static let shared = HouseholdService()
    
    // MARK: - Private Properties
    
    /// Firestore database reference
    private let db = Firestore.firestore()
    
    /// Households collection reference
    private var householdsCollection: CollectionReference {
        return db.collection("households")
    }
    
    // MARK: - Initialization
    
    /// Private initializer to enforce singleton pattern
    private init() {}
    
    // MARK: - Household CRUD Operations
    
    /// Create a new household
    /// - Parameters:
    ///   - name: Household name
    ///   - ownerUserId: User ID of the household creator/owner
    /// - Returns: The created Household
    func createHousehold(name: String, ownerUserId: String) async throws -> Household {
        // Generate a unique invite code
        let inviteCode = generateInviteCode()
        
        // Create a new household (without ID initially)
        var newHousehold = Household(
            name: name,
            ownerUserId: ownerUserId,
            memberUserIds: [ownerUserId],
            inviteCode: inviteCode,
            createdAt: Date()
        )
        
        // Add to Firestore and get document reference
        let docRef = try householdsCollection.addDocument(from: newHousehold)
        
        // Update the household with its new ID
        try await householdsCollection.document(docRef.documentID).updateData([
            "id": docRef.documentID
        ])
        
        // Update our local object with the ID
        newHousehold.id = docRef.documentID
        
        // Add household to user's list
        try await UserService.shared.addUserToHousehold(userId: ownerUserId, householdId: docRef.documentID)
        
        return newHousehold
    }
    
    /// Fetch a specific household by ID
    /// - Parameter id: Household ID
    /// - Returns: Household if found, nil otherwise
    func fetchHousehold(withId id: String) async throws -> Household? {
        // Check for empty ID to prevent "Document path cannot be empty" error
        guard !id.isEmpty else {
            print("Warning: Attempted to fetch household with empty ID")
            return nil
        }
        
        let documentSnapshot = try await householdsCollection.document(id).getDocument()
        return try documentSnapshot.data(as: Household.self)
    }
    
    /// Fetch all households for a user
    /// - Parameter userId: User ID
    /// - Returns: Array of households
    func fetchHouseholds(forUserId userId: String) async throws -> [Household] {
        let querySnapshot = try await householdsCollection
            .whereField("memberUserIds", arrayContains: userId)
            .getDocuments()
        
        return querySnapshot.documents.compactMap { document in
            try? document.data(as: Household.self)
        }
    }
    
    /// Find a household by invite code
    /// - Parameter inviteCode: The unique invite code
    /// - Returns: Household if found, nil otherwise
    func findHousehold(byInviteCode inviteCode: String) async throws -> Household? {
        let querySnapshot = try await householdsCollection
            .whereField("inviteCode", isEqualTo: inviteCode)
            .getDocuments()
        
        guard let document = querySnapshot.documents.first else {
            return nil
        }
        
        return try document.data(as: Household.self)
    }
    
    /// Add a user to a household
    /// - Parameters:
    ///   - userId: User ID to add
    ///   - householdId: Household ID
    func addMember(userId: String, toHouseholdId householdId: String) async throws {
        // Validate parameters
        guard !userId.isEmpty else {
            throw NSError(domain: "HouseholdService", code: 4, userInfo: [NSLocalizedDescriptionKey: "User ID cannot be empty"])
        }
        
        guard !householdId.isEmpty else {
            throw NSError(domain: "HouseholdService", code: 5, userInfo: [NSLocalizedDescriptionKey: "Household ID cannot be empty"])
        }
        
        // Update the household
        try await householdsCollection.document(householdId).updateData([
            "memberUserIds": FieldValue.arrayUnion([userId])
        ])
        
        // Update the user
        try await UserService.shared.addUserToHousehold(userId: userId, householdId: householdId)
    }
    
    /// Remove a user from a household
    /// - Parameters:
    ///   - userId: User ID to remove
    ///   - householdId: Household ID
    func removeMember(userId: String, fromHouseholdId householdId: String) async throws {
        // Get the household to check ownership
        guard let household = try await fetchHousehold(withId: householdId) else {
            throw NSError(domain: "HouseholdService", code: 1, userInfo: [NSLocalizedDescriptionKey: "Household not found"])
        }
        
        // Prevent removing the owner
        if household.ownerUserId == userId {
            throw NSError(domain: "HouseholdService", code: 2, userInfo: [NSLocalizedDescriptionKey: "Cannot remove the owner from the household"])
        }
        
        // Update the household
        try await householdsCollection.document(householdId).updateData([
            "memberUserIds": FieldValue.arrayRemove([userId])
        ])
        
        // Update the user
        try await UserService.shared.removeUserFromHousehold(userId: userId, householdId: householdId)
    }
    
    /// Update household name
    /// - Parameters:
    ///   - householdId: Household ID
    ///   - newName: New household name
    func updateHouseholdName(householdId: String, newName: String) async throws {
        try await householdsCollection.document(householdId).updateData([
            "name": newName
        ])
    }
    
    /// Delete a household (only owner can do this)
    /// - Parameters:
    ///   - householdId: Household ID
    ///   - userId: User ID attempting the deletion (must be owner)
    func deleteHousehold(householdId: String, userId: String) async throws {
        // Verify ownership
        guard let household = try await fetchHousehold(withId: householdId) else {
            throw NSError(domain: "HouseholdService", code: 1, userInfo: [NSLocalizedDescriptionKey: "Household not found"])
        }
        
        guard household.ownerUserId == userId else {
            throw NSError(domain: "HouseholdService", code: 3, userInfo: [NSLocalizedDescriptionKey: "Only the owner can delete the household"])
        }
        
        // Delete associated chores
        try await ChoreService.shared.deleteAllChores(forHouseholdId: householdId)
        
        // Remove household from all members
        for memberId in household.memberUserIds {
            try await UserService.shared.removeUserFromHousehold(userId: memberId, householdId: householdId)
        }
        
        // Delete the household document
        try await householdsCollection.document(householdId).delete()
    }
    
    // MARK: - Helper Methods
    
    /// Generate a unique invite code for a household
    /// - Returns: String invite code
    private func generateInviteCode() -> String {
        let letters = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
        let numbers = "0123456789"
        let characters = letters + numbers
        
        let randomString = String((0..<6).map { _ in
            let randomIndex = Int.random(in: 0..<characters.count)
            let index = characters.index(characters.startIndex, offsetBy: randomIndex)
            return characters[index]
        })
        
        return randomString
    }
}
