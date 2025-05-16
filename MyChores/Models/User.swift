// User.swift
// MyChores
//
// Created on 2025-05-02.
//

import Foundation
import FirebaseFirestore

/// Represents a user in the app
struct User: Identifiable, Codable {
    /// Unique identifier, matches Firebase Auth UID
    @DocumentID var id: String?
    
    /// Stable ID for view identification when DocumentID might be nil
    var stableId: String {
        return id ?? UUID().uuidString
    }
    
    /// User's display name 
    var name: String
    
    /// User's email address
    var email: String
    
    /// URL for user's profile photo
    var photoURL: String?
    
    /// List of household IDs the user belongs to
    var householdIds: [String] = []
    
    /// FCM token for push notifications
    var fcmToken: String?
    
    /// Date user was created
    var createdAt: Date
    
    /// User's all-time points from completing chores
    var totalPoints: Int = 0
    
    /// User's points in the current week (resets weekly)
    var weeklyPoints: Int = 0
    
    /// User's points in the current month (resets monthly)
    var monthlyPoints: Int = 0
    
    /// Count of chores completed early (before due date)
    var earlyCompletionCount: Int = 0
    
    /// Current streak of days with completed chores
    var currentStreakDays: Int = 0
    
    /// Highest streak of days with completed chores
    var highestStreakDays: Int = 0
    
    /// Date of the last chore completion (for streak calculation)
    var lastChoreCompletionDate: Date?
    
    /// Week start date for tracking weekly points
    var currentWeekStartDate: Date?
    
    /// Month start date for tracking monthly points
    var currentMonthStartDate: Date?
    
    /// Array of badge keys that the user has earned
    var earnedBadges: [String] = []
    
    /// User's privacy settings
    var privacySettings: UserPrivacySettings = UserPrivacySettings()
    
    /// Terms and privacy policy acceptance information
    var termsAcceptance: TermsAcceptance = TermsAcceptance()
    
    /// Initialize a new user with default values
    init(id: String? = nil, name: String, email: String, photoURL: String? = nil) {
        self.id = id
        self.name = name
        self.email = email
        self.photoURL = photoURL
        self.createdAt = Date()
        self.householdIds = []
        self.earnedBadges = []
        self.totalPoints = 0
        self.weeklyPoints = 0
        self.monthlyPoints = 0
        self.earlyCompletionCount = 0
        self.currentStreakDays = 0
        self.highestStreakDays = 0
    }
    
    /// Encode the user to Firestore-compatible format
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encodeIfPresent(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(email, forKey: .email)
        try container.encodeIfPresent(photoURL, forKey: .photoURL)
        try container.encode(householdIds, forKey: .householdIds)
        try container.encodeIfPresent(fcmToken, forKey: .fcmToken)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encode(totalPoints, forKey: .totalPoints)
        try container.encode(weeklyPoints, forKey: .weeklyPoints)
        try container.encode(monthlyPoints, forKey: .monthlyPoints)
        try container.encode(earnedBadges, forKey: .earnedBadges)
        try container.encode(earlyCompletionCount, forKey: .earlyCompletionCount)
        try container.encode(currentStreakDays, forKey: .currentStreakDays)
        try container.encode(highestStreakDays, forKey: .highestStreakDays)
        try container.encodeIfPresent(lastChoreCompletionDate, forKey: .lastChoreCompletionDate)
        try container.encodeIfPresent(currentWeekStartDate, forKey: .currentWeekStartDate)
        try container.encodeIfPresent(currentMonthStartDate, forKey: .currentMonthStartDate)
        try container.encode(privacySettings, forKey: .privacySettings)
        try container.encode(termsAcceptance, forKey: .termsAcceptance)
    }
    
    /// Check if user has earned a specific badge
    func hasBadge(withKey badgeKey: String) -> Bool {
        return earnedBadges.contains(badgeKey)
    }
    
    /// Generate a display-friendly string of the user's points
    var pointsDisplay: String {
        return "\(totalPoints) \(totalPoints == 1 ? "pt" : "pts")"
    }
    
    /// Calculate the user's current level based on total points
    var level: Int {
        // Simple level calculation: 1 level per 100 points, minimum level 1
        return max(1, Int(totalPoints / 100) + 1)
    }
}

/// User privacy settings for controlling what information is shared
struct UserPrivacySettings: Codable {
    /// Whether the user's profile is visible to others
    var showProfile: Bool = true
    
    /// Whether the user's achievements are visible to others
    var showAchievements: Bool = true
    
    /// Whether to share the user's activity with household members
    var shareActivity: Bool = true
}

/// Represents user's terms and privacy policy acceptance
struct TermsAcceptance: Codable, Equatable {
    /// Whether the user has accepted the terms of service
    var termsAccepted: Bool = false
    
    /// Whether the user has accepted the privacy policy
    var privacyAccepted: Bool = false
    
    /// Date when the user accepted the terms and privacy policy
    var acceptanceDate: Date?
    
    /// Version of the terms that were accepted
    var termsVersion: String = "1.0"
}

// MARK: - Coding Keys
extension User {
    /// Coding keys for Firestore encoding/decoding
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case email
        case photoURL
        case householdIds
        case fcmToken
        case createdAt
        case totalPoints
        case weeklyPoints
        case monthlyPoints
        case earnedBadges
        case earlyCompletionCount
        case currentStreakDays
        case highestStreakDays
        case lastChoreCompletionDate
        case currentWeekStartDate
        case currentMonthStartDate
        case privacySettings
        case termsAcceptance
    }
}
