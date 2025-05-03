// Household.swift
// MyChores
//
// Created on 2025-05-02.
//

import Foundation
import FirebaseFirestore

/// Represents a household group of users sharing chores
struct Household: Identifiable, Codable, Equatable {
    /// Unique identifier for the household
    @DocumentID var id: String?
    
    /// Name of the household
    var name: String
    
    /// ID of the user who created the household
    var ownerUserId: String
    
    /// List of user IDs who are members of this household
    var memberUserIds: [String]
    
    /// Unique invite code that others can use to join this household
    var inviteCode: String
    
    /// Date household was created
    var createdAt: Date
    
    /// Custom CodingKeys to match Firestore field names
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case ownerUserId
        case memberUserIds
        case inviteCode
        case createdAt
    }
}

// MARK: - Sample Data

extension Household {
    static let sample = Household(
        id: "sample_household_id",
        name: "Smith Family",
        ownerUserId: "sample_user_id",
        memberUserIds: ["sample_user_id", "sample_user_id_2"],
        inviteCode: "SMITH123",
        createdAt: Date()
    )
    
    // MARK: - Equatable Implementation
    
    static func == (lhs: Household, rhs: Household) -> Bool {
        // Two households are considered equal if they have the same ID
        return lhs.id == rhs.id
    }
}
