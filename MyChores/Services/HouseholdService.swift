// HouseholdService.swift
// MyChores
//
// Created on 2025-05-02.
//

import Foundation
import FirebaseFirestore
import FirebaseAuth

// MARK: - HouseholdServiceProtocol
protocol HouseholdServiceProtocol {
    func createHousehold(name: String, ownerUserId: String) async throws -> Household
    func fetchHousehold(withId id: String) async throws -> Household?
    func fetchHouseholds(forUserId userId: String) async throws -> [Household]
    func findHousehold(byInviteCode inviteCode: String) async throws -> Household?
    func addMember(userId: String, toHouseholdId householdId: String) async throws
    func removeMember(userId: String, fromHouseholdId householdId: String) async throws
    func updateHouseholdName(householdId: String, newName: String) async throws
    func deleteHousehold(householdId: String, userId: String) async throws
    // MARK: - Household Rules
    func createHouseholdRule(householdId: String, ruleText: String, createdByUserId: String) async throws -> HouseholdRule
    func fetchHouseholdRules(forHouseholdId householdId: String) async throws -> [HouseholdRule]
    func updateHouseholdRule(_ rule: HouseholdRule) async throws -> HouseholdRule
    func deleteHouseholdRule(ruleId: String) async throws
}

/// Service for household data operations
class HouseholdService: HouseholdServiceProtocol {
    // MARK: - Shared Instance
    
    /// Shared instance for singleton access
    static let shared = HouseholdService(userService: UserService.shared, choreService: ChoreService.shared)
    
    // MARK: - Private Properties
    
    /// Firestore database reference
    private let db = Firestore.firestore()
    
    /// Households collection reference
    private var householdsCollection: CollectionReference {
        db.collection("households")
    }
    
    /// Household rules subcollection reference
    private func householdRulesCollection(forHouseholdId householdId: String) -> CollectionReference {
        householdsCollection.document(householdId).collection("rules")
    }
    
    // MARK: - Dependencies (NEW)
    private let userService: UserServiceProtocol // NEW
    private let choreService: ChoreServiceProtocol // NEW
    
    // MARK: - Initialization
    
    /// Private initializer to enforce singleton pattern
    private init(userService: UserServiceProtocol, choreService: ChoreServiceProtocol) {
        self.userService = userService // NEW
        self.choreService = choreService // NEW
    }
    
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
        try await self.userService.addUserToHousehold(userId: ownerUserId, householdId: docRef.documentID)
        
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
        let querySnapshot = try await householdsCollection.whereField("inviteCode", isEqualTo: inviteCode).limit(to: 1).getDocuments()
        guard let document = querySnapshot.documents.first else {
            return nil
        }
        return try document.data(as: Household.self)
    }

    /// Add a user to a household
    /// - Parameters:
    ///   - userId: User ID to add
    ///   - householdId: Household ID to join
    func addMember(userId: String, toHouseholdId householdId: String) async throws {
        let householdRef = householdsCollection.document(householdId)
        try await householdRef.updateData([
            "memberUserIds": FieldValue.arrayUnion([userId])
        ])
        // Also update the user's householdIds
        try await userService.addUserToHousehold(userId: userId, householdId: householdId)
    }

    /// Remove a user from a household
    /// - Parameters:
    ///   - userId: User ID to remove
    ///   - householdId: Household ID to leave
    func removeMember(userId: String, fromHouseholdId householdId: String) async throws {
        let householdRef = householdsCollection.document(householdId)
        // Fetch the household to check if the user is the owner
        guard let household = try await fetchHousehold(withId: householdId) else {
            throw NSError(domain: "HouseholdService", code: 0, userInfo: [NSLocalizedDescriptionKey: "Household not found."])
        }

        // Prevent owner from being removed if they are the only member or handle ownership transfer (complex, not implemented here)
        if household.ownerUserId == userId && household.memberUserIds.count == 1 {
            // Or, if this is the intended behavior, delete the household
            // For now, let's prevent this scenario or require ownership transfer logic
            throw NSError(domain: "HouseholdService", code: 1, userInfo: [NSLocalizedDescriptionKey: "Owner cannot leave the household as the sole member. Delete the household instead or transfer ownership."])
        }
        
        try await householdRef.updateData([
            "memberUserIds": FieldValue.arrayRemove([userId])
        ])
        // Also update the user's householdIds
        try await userService.removeUserFromHousehold(userId: userId, householdId: householdId)
    }

    /// Update a household's name
    /// - Parameters:
    ///   - householdId: Household ID
    ///   - newName: New household name
    func updateHouseholdName(householdId: String, newName: String) async throws {
        let householdRef = householdsCollection.document(householdId)
        try await householdRef.updateData(["name": newName])
    }
    
    /// Delete a household. This is a destructive operation.
    /// - Parameters:
    ///   - householdId: The ID of the household to delete.
    ///   - userId: The ID of the user attempting the deletion (must be the owner).
    func deleteHousehold(householdId: String, userId: String) async throws {
        let householdRef = householdsCollection.document(householdId)
        
        // Start a batch to perform multiple operations atomically
        let batch = db.batch()
        
        // 1. Verify the user is the owner
        let householdDoc = try await householdRef.getDocument()
        let household = try householdDoc.data(as: Household.self)
        
        guard household.ownerUserId == userId else {
            throw NSError(domain: "HouseholdService", code: 3, userInfo: [NSLocalizedDescriptionKey: "Only the household owner can delete the household."])
        }
        
        // 2. Remove householdId from all member users' householdIds array
        for memberId in household.memberUserIds {
            // This assumes userService.removeUserFromHousehold only updates the user side.
            // If it also tries to modify household, it might conflict or be redundant.
            // For simplicity, let's assume we directly update user documents here or ensure userService method is safe.
            let userRef = db.collection("users").document(memberId)
            batch.updateData(["householdIds": FieldValue.arrayRemove([householdId])], forDocument: userRef)
        }
        
        // 3. Delete all chores associated with this household
        // This requires ChoreService to have a method like deleteAllChores(forHouseholdId: String, batch: WriteBatch)
        // Or query and delete them here.
        let choresQuery = db.collection("chores").whereField("householdId", isEqualTo: householdId)
        let choreDocs = try await choresQuery.getDocuments()
        for choreDoc in choreDocs.documents {
            batch.deleteDocument(choreDoc.reference)
        }
        
        // 4. Delete all household rules associated with this household (if rules are a subcollection)
        let rulesQuery = householdRulesCollection(forHouseholdId: householdId)
        let ruleDocs = try await rulesQuery.getDocuments()
        for ruleDoc in ruleDocs.documents {
            batch.deleteDocument(ruleDoc.reference)
        }

        // 5. Delete the household document itself
        batch.deleteDocument(householdRef)
        
        // Commit the batch
        try await batch.commit()
    }

    // MARK: - Household Rules Implementation
    
    func createHouseholdRule(householdId: String, ruleText: String, createdByUserId: String) async throws -> HouseholdRule {
        let newRule = HouseholdRule(
            householdId: householdId,
            ruleText: ruleText,
            createdByUserId: createdByUserId,
            createdAt: Date(),
            lastUpdatedAt: nil,
            displayOrder: nil // Or calculate next displayOrder
        )
        
        let ruleRef = householdRulesCollection(forHouseholdId: householdId).document()
        try ruleRef.setData(from: newRule)
        
        // Return the rule with its generated ID
        var createdRule = newRule
        createdRule.id = ruleRef.documentID
        return createdRule
    }
    
    func fetchHouseholdRules(forHouseholdId householdId: String) async throws -> [HouseholdRule] {
        let snapshot = try await householdRulesCollection(forHouseholdId: householdId)
            .order(by: "displayOrder", descending: false) // Or by "createdAt"
            .getDocuments()
        
        return snapshot.documents.compactMap { document in
            try? document.data(as: HouseholdRule.self)
        }
    }
    
    func updateHouseholdRule(_ rule: HouseholdRule) async throws -> HouseholdRule {
        guard let ruleId = rule.id else {
            throw NSError(domain: "HouseholdService", code: 4, userInfo: [NSLocalizedDescriptionKey: "Rule ID is missing."])
        }
        
        var mutableRule = rule
        mutableRule.lastUpdatedAt = Date()
        
        let ruleRef = householdRulesCollection(forHouseholdId: rule.householdId).document(ruleId)
        try ruleRef.setData(from: mutableRule, merge: true)
        return mutableRule
    }
    
    func deleteHouseholdRule(ruleId: String) async throws {
        // To delete a rule, we need its householdId to construct the path.
        // This implies that deleteHouseholdRule should perhaps take householdId as a parameter,
        // or the ruleId itself should be structured to contain householdId, or we fetch the rule first.
        // For now, assuming ruleId is just the document ID within a known household's subcollection.
        // This function will need to be called from a context where householdId is known.
        // Let's adjust the signature or make an assumption.
        // Assuming this is called from HouseholdViewModel where selectedHousehold.id is available.
        // This method signature is problematic if householdId is not passed.
        // For a generic service, it's better to require householdId.
        // Let's assume for now the caller (ViewModel) will construct the correct reference.
        // This is a placeholder for how it might be called if householdId was available:
        // try await householdRulesCollection(forHouseholdId: "SOME_HOUSEHOLD_ID").document(ruleId).delete()
        //
        // A better approach for the service:
        // func deleteHouseholdRule(ruleId: String, inHouseholdId householdId: String) async throws
        // For now, we'll leave it as is, but this is a design consideration.
        // This function cannot be implemented correctly without householdId.
        // Let's throw an error to indicate this.
        throw NSError(domain: "HouseholdService", code: 5, userInfo: [NSLocalizedDescriptionKey: "deleteHouseholdRule requires householdId to locate the rule. Please refactor."])
    }
    
    // Helper to delete a rule when householdId is known
    // This is a more robust signature.
    func deleteHouseholdRule(ruleId: String, inHouseholdId householdId: String) async throws {
        try await householdRulesCollection(forHouseholdId: householdId).document(ruleId).delete()
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
