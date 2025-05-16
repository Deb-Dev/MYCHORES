// User+BadgeTracking.swift
// MyChores
//
// Created on 2025-05-16.
//

import Foundation

// Extension to add badge tracking functionality to User model
extension User {
    /// Update the custom decoder to handle the new badge tracking fields
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // In Swift, all stored properties must be initialized before accessing 'self'
        // Initialize everything with placeholders first, then we'll populate correctly from Firestore
        // Required fields
        let decodedId = try container.decodeIfPresent(String.self, forKey: .id)
        let decodedName = try container.decode(String.self, forKey: .name)
        let decodedEmail = try container.decode(String.self, forKey: .email)
        let decodedPhotoURL = try container.decodeIfPresent(String.self, forKey: .photoURL)
        let decodedCreatedAt = try container.decodeIfPresent(Date.self, forKey: .createdAt) ?? Date()
        
        // Initialize with required minimum values first to avoid 'self used before all stored properties are initialized'
        self.init(
            id: decodedId,
            name: decodedName,
            email: decodedEmail,
            photoURL: decodedPhotoURL
        )
        
        // Now we can safely set additional properties
        self.createdAt = decodedCreatedAt
        
        // Fulfill optional fields after initialization
        self.fcmToken = try container.decodeIfPresent(String.self, forKey: .fcmToken)
        self.currentWeekStartDate = try container.decodeIfPresent(Date.self, forKey: .currentWeekStartDate)
        self.currentMonthStartDate = try container.decodeIfPresent(Date.self, forKey: .currentMonthStartDate)
        self.lastChoreCompletionDate = try container.decodeIfPresent(Date.self, forKey: .lastChoreCompletionDate)
        
        // Arrays with defaults
        do {
            self.householdIds = try container.decode([String].self, forKey: .householdIds)
        } catch {
            self.householdIds = []
            print("Warning: householdIds not found, defaulting to empty array")
        }
        
        do {
            self.earnedBadges = try container.decode([String].self, forKey: .earnedBadges)
        } catch {
            self.earnedBadges = []
            print("Warning: earnedBadges not found, defaulting to empty array")
        }
        
        // Numeric values with defaults
        do {
            self.totalPoints = try container.decode(Int.self, forKey: .totalPoints)
        } catch {
            self.totalPoints = 0
            print("Warning: totalPoints not found, defaulting to 0")
        }
        
        do {
            self.weeklyPoints = try container.decode(Int.self, forKey: .weeklyPoints)
        } catch {
            self.weeklyPoints = 0
            print("Warning: weeklyPoints not found, defaulting to 0")
        }
        
        do {
            self.monthlyPoints = try container.decode(Int.self, forKey: .monthlyPoints)
        } catch {
            self.monthlyPoints = 0
            print("Warning: monthlyPoints not found, defaulting to 0")
        }
        
        // New badge tracking fields
        do {
            self.earlyCompletionCount = try container.decode(Int.self, forKey: .earlyCompletionCount)
        } catch {
            self.earlyCompletionCount = 0
            print("Warning: earlyCompletionCount not found, defaulting to 0")
        }
        
        do {
            self.currentStreakDays = try container.decode(Int.self, forKey: .currentStreakDays)
        } catch {
            self.currentStreakDays = 0
            print("Warning: currentStreakDays not found, defaulting to 0")
        }
        
        do {
            self.highestStreakDays = try container.decode(Int.self, forKey: .highestStreakDays)
        } catch {
            self.highestStreakDays = 0
            print("Warning: highestStreakDays not found, defaulting to 0")
        }
        
        // Privacy settings
        do {
            self.privacySettings = try container.decode(UserPrivacySettings.self, forKey: .privacySettings)
        } catch {
            self.privacySettings = UserPrivacySettings()
            print("Warning: privacySettings not found, defaulting to default settings")
        }
    }
    
    /// Update streak information when a chore is completed
    /// - Parameter completionDate: The date the chore was completed
    mutating func updateStreakInfo(completionDate: Date) {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: completionDate)
        
        // If we have a previous completion date
        if let lastDate = lastChoreCompletionDate {
            let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!
            let lastCompletionDay = calendar.startOfDay(for: lastDate)
            
            if calendar.isDate(lastCompletionDay, inSameDayAs: yesterday) {
                // Consecutive day, increment streak
                currentStreakDays += 1
                highestStreakDays = max(currentStreakDays, highestStreakDays)
            } else if !calendar.isDate(lastCompletionDay, inSameDayAs: today) {
                // Not consecutive and not same day, reset streak
                currentStreakDays = 1
            }
            // If same day, keep streak the same
        } else {
            // First completion ever
            currentStreakDays = 1
            highestStreakDays = 1
        }
        
        // Update last completion date
        lastChoreCompletionDate = today
    }
    
    /// Check if a chore was completed early and update count if needed
    /// - Parameters:
    ///   - completionDate: The date the chore was completed
    ///   - dueDate: The due date of the chore
    mutating func checkAndUpdateEarlyCompletion(completionDate: Date, dueDate: Date) {
        if completionDate < dueDate {
            earlyCompletionCount += 1
        }
    }
}
