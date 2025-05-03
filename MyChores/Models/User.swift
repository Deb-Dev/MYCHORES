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
    
    /// Week start date for tracking weekly points
    var currentWeekStartDate: Date?
    
    /// Month start date for tracking monthly points
    var currentMonthStartDate: Date?
    
    /// List of badges earned by the user
    var earnedBadges: [String] = []
    
    /// Custom CodingKeys to match Firestore field names
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
        case currentWeekStartDate
        case currentMonthStartDate
        case earnedBadges
    }
}

// MARK: - Sample Data

extension User {
    static let sample = User(
        id: "sample_user_id",
        name: "John Doe",
        email: "john@example.com",
        photoURL: nil,
        householdIds: ["sample_household_id"],
        fcmToken: "sample_fcm_token",
        createdAt: Date(),
        totalPoints: 120,
        weeklyPoints: 25,
        monthlyPoints: 75,
        currentWeekStartDate: Calendar.current.date(from: Calendar.current.dateComponents([.yearForWeekOfYear, .weekOfYear], from: Date())),
        currentMonthStartDate: Calendar.current.date(from: Calendar.current.dateComponents([.year, .month], from: Date())),
        earnedBadges: ["first_chore", "ten_chores"]
    )
}
