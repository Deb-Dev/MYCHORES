// Badge.swift
// MyChores
//
// Created on 2025-05-02.
//

import Foundation
import FirebaseFirestore

/// Represents an achievement badge that users can earn
struct Badge: Identifiable, Codable {
    /// Unique identifier for the badge
    @DocumentID var id: String?
    
    /// String identifier used as a key to reference this badge (e.g., "first_chore")
    var badgeKey: String
    
    /// Human-readable name of the badge
    var name: String
    
    /// Detailed description of how to earn the badge
    var description: String
    
    /// Name of the SF Symbol icon used for this badge
    var iconName: String
    
    /// Color name from the asset catalog for this badge
    var colorName: String
    
    /// Number of tasks required to earn this badge (if applicable)
    var requiredTaskCount: Int?
    
    /// Custom CodingKeys to match Firestore field names
    enum CodingKeys: String, CodingKey {
        case id
        case badgeKey
        case name
        case description
        case iconName
        case colorName
        case requiredTaskCount
    }
}

// MARK: - Predefined Badges

extension Badge {
    /// Standard badges available in the app
    static let predefinedBadges: [Badge] = [
        Badge(
            badgeKey: "first_chore",
            name: "First Step",
            description: "Completed your first chore",
            iconName: "1.circle.fill",
            colorName: "Primary",
            requiredTaskCount: 1
        ),
        Badge(
            badgeKey: "ten_chores",
            name: "Getting Things Done",
            description: "Completed 10 chores",
            iconName: "10.circle.fill",
            colorName: "Secondary",
            requiredTaskCount: 10
        ),
        Badge(
            badgeKey: "fifty_chores",
            name: "Task Master",
            description: "Completed 50 chores",
            iconName: "50.circle.fill",
            colorName: "Accent",
            requiredTaskCount: 50
        ),
        Badge(
            badgeKey: "hundred_chores",
            name: "Century Club",
            description: "Completed 100 chores",
            iconName: "100.circle.fill",
            colorName: "Success",
            requiredTaskCount: 100
        ),
        Badge(
            badgeKey: "daily_streak",
            name: "Consistency Champion",
            description: "Completed chores for 7 consecutive days",
            iconName: "flame.fill",
            colorName: "Error",
            requiredTaskCount: nil
        ),
        Badge(
            badgeKey: "household_helper",
            name: "Team Player",
            description: "Completed chores in multiple households",
            iconName: "person.3.fill",
            colorName: "Secondary",
            requiredTaskCount: nil
        ),
        Badge(
            badgeKey: "early_bird", 
            name: "Early Bird",
            description: "Completed 5 chores before their due date",
            iconName: "alarm.fill",
            colorName: "Primary",
            requiredTaskCount: nil
        )
    ]
    
    /// Get a predefined badge by its key
    static func getBadge(byKey key: String) -> Badge? {
        return predefinedBadges.first { $0.badgeKey == key }
    }
}
