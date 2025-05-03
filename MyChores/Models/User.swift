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
    
    /// Custom initializer to handle potential issues with missing data
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // Required fields
        id = try container.decodeIfPresent(String.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        email = try container.decode(String.self, forKey: .email)
        
        // Optional fields with defaults
        photoURL = try container.decodeIfPresent(String.self, forKey: .photoURL)
        fcmToken = try container.decodeIfPresent(String.self, forKey: .fcmToken)
        
        // Arrays with defaults
        do {
            householdIds = try container.decode([String].self, forKey: .householdIds)
        } catch {
            householdIds = []
            print("Warning: householdIds not found, defaulting to empty array")
        }
        
        do {
            earnedBadges = try container.decode([String].self, forKey: .earnedBadges)
        } catch {
            earnedBadges = []
            print("Warning: earnedBadges not found, defaulting to empty array")
        }
        
        // Dates
        do {
            createdAt = try container.decode(Date.self, forKey: .createdAt)
        } catch {
            createdAt = Date()
            print("Warning: createdAt not found, defaulting to current date")
        }
        
        currentWeekStartDate = try container.decodeIfPresent(Date.self, forKey: .currentWeekStartDate)
        currentMonthStartDate = try container.decodeIfPresent(Date.self, forKey: .currentMonthStartDate)
        
        // Numeric values with defaults
        do {
            totalPoints = try container.decode(Int.self, forKey: .totalPoints)
        } catch {
            totalPoints = 0
            print("Warning: totalPoints not found, defaulting to 0")
        }
        
        do {
            weeklyPoints = try container.decode(Int.self, forKey: .weeklyPoints)
        } catch {
            weeklyPoints = 0
            print("Warning: weeklyPoints not found, defaulting to 0")
        }
        
        do {
            monthlyPoints = try container.decode(Int.self, forKey: .monthlyPoints)
        } catch {
            monthlyPoints = 0
            print("Warning: monthlyPoints not found, defaulting to 0")
        }
    }
    
    /// Standard initializer
    init(
        id: String? = nil,
        name: String,
        email: String,
        photoURL: String? = nil,
        householdIds: [String] = [],
        fcmToken: String? = nil,
        createdAt: Date = Date(),
        totalPoints: Int = 0,
        weeklyPoints: Int = 0,
        monthlyPoints: Int = 0,
        currentWeekStartDate: Date? = nil,
        currentMonthStartDate: Date? = nil,
        earnedBadges: [String] = []
    ) {
        self.id = id
        self.name = name
        self.email = email
        self.photoURL = photoURL
        self.householdIds = householdIds
        self.fcmToken = fcmToken
        self.createdAt = createdAt
        self.totalPoints = totalPoints
        self.weeklyPoints = weeklyPoints
        self.monthlyPoints = monthlyPoints
        self.currentWeekStartDate = currentWeekStartDate
        self.currentMonthStartDate = currentMonthStartDate
        self.earnedBadges = earnedBadges
    }
    
    /// Force set the ID when it's missing
    /// This is needed because DocumentID can't be set directly
    /// - Parameter newId: The ID to set
    mutating func forceSetId(_ newId: String) {
        self.id = newId
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
