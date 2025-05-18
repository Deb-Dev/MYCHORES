// Chore.swift
// MyChores
//
// Created on 2025-05-02.
//

import Foundation
import FirebaseFirestore
/// Types of recurrence patterns
public enum RecurrenceType: String, Codable {
    case daily
    case weekly
    case monthly
}

/// Represents a chore task within a household
struct Chore: Identifiable, Codable, Equatable {
    /// Unique identifier for the chore
    @DocumentID var id: String?
    
    /// Title of the chore
    var title: String
    
    /// Detailed description of what the chore involves
    var description: String
    
    /// ID of the household this chore belongs to
    var householdId: String
    
    /// ID of the user assigned to complete this chore (optional)
    var assignedToUserId: String?
    
    /// ID of the user who created the chore
    var createdByUserId: String?
    
    /// Due date for the chore to be completed
    var dueDate: Date?
    
    /// Whether the chore is completed
    var isCompleted: Bool = false
    
    /// Date when the chore was created
    var createdAt: Date
    
    /// Date when the chore was completed (nil if not completed)
    var completedAt: Date?
    
    /// ID of the user who completed the chore (nil if not completed)
    var completedByUserId: String?
    
    /// Point value awarded for completing this chore
    var pointValue: Int
    
    /// Whether this is a recurring chore
    var isRecurring: Bool = false
    
    /// How often the chore recurs (daily, weekly, monthly)
    var recurrenceType: RecurrenceType?
    
    /// Number of days/weeks/months between recurrences
    var recurrenceInterval: Int?
    
    /// For weekly recurrence, which days of the week (0 = Sunday, 6 = Saturday)
    var recurrenceDaysOfWeek: [Int]?
    
    /// For monthly recurrence, which day of the month
    var recurrenceDayOfMonth: Int?
    
    /// End date for recurring chores (nil for indefinite)
    var recurrenceEndDate: Date?
    
    /// Date of the next occurrence for a recurring chore
    var nextOccurrenceDate: Date?
    
    /// Custom CodingKeys to match Firestore field names
    enum CodingKeys: String, CodingKey {
        case id
        case title
        case description
        case householdId
        case assignedToUserId
        case createdByUserId
        case dueDate
        case isCompleted
        case createdAt
        case completedAt
        case completedByUserId
        case pointValue
        case isRecurring
        case recurrenceType
        case recurrenceInterval
        case recurrenceDaysOfWeek
        case recurrenceDayOfMonth
        case recurrenceEndDate
        case nextOccurrenceDate
    }
    
    /// Check if the chore is overdue
    var isOverdue: Bool {
        guard let dueDate = dueDate else { return false }
        return !isCompleted && dueDate < Date()
    }
    
    /// Create next occurrence of a recurring chore
    func createNextOccurrence() -> Chore? {
        guard isRecurring, 
              let recurrenceType = recurrenceType,
              let interval = recurrenceInterval else { return nil }
        
        let calendar = Calendar.current
        var nextDate: Date?
        
        if let occurrenceDate = self.nextOccurrenceDate ?? dueDate {
            switch recurrenceType {
            case .daily:
                nextDate = calendar.date(byAdding: .day, value: interval, to: occurrenceDate)
                
            case .weekly:
                if let daysOfWeek = recurrenceDaysOfWeek, !daysOfWeek.isEmpty {
                    // Calculate next occurrence based on days of week
                    var candidateDate = calendar.date(byAdding: .day, value: 1, to: occurrenceDate)!
                    
                    // Find the next day that matches our recurrence pattern
                    for _ in 0..<7*interval {
                        let weekday = calendar.component(.weekday, from: candidateDate) - 1 // 0-indexed
                        if daysOfWeek.contains(weekday) {
                            nextDate = candidateDate
                            break
                        }
                        candidateDate = calendar.date(byAdding: .day, value: 1, to: candidateDate)!
                    }
                } else {
                    // Simple weekly recurrence
                    nextDate = calendar.date(byAdding: .weekOfYear, value: interval, to: occurrenceDate)
                }
                
            case .monthly:
                if let dayOfMonth = recurrenceDayOfMonth {
                    // Get the base next month date
                    let nextMonth = calendar.date(byAdding: .month, value: interval, to: occurrenceDate)!
                    
                    // Set to the specified day of month
                    var components = calendar.dateComponents([.year, .month], from: nextMonth)
                    components.day = min(dayOfMonth, calendar.range(of: .day, in: .month, for: nextMonth)?.count ?? 28)
                    nextDate = calendar.date(from: components)
                } else {
                    // Just use same day next month
                    nextDate = calendar.date(byAdding: .month, value: interval, to: occurrenceDate)
                }
            }
        }
        
        // Check if we've passed the end date
        if let endDate = recurrenceEndDate, let nextDate = nextDate, nextDate > endDate {
            return nil
        }
        
        // Create the next occurrence
        guard let nextDueDate = nextDate else { return nil }
        
        var newChore = self
        newChore.id = nil
        newChore.isCompleted = false
        newChore.completedAt = nil
        newChore.completedByUserId = nil
        newChore.dueDate = nextDueDate
        newChore.nextOccurrenceDate = nextDueDate
        newChore.createdAt = Date()
        
        return newChore
    }
    
    // MARK: - Equatable
    
    static func == (lhs: Chore, rhs: Chore) -> Bool {
        // If both have IDs, compare IDs
        if let lhsId = lhs.id, let rhsId = rhs.id {
            return lhsId == rhsId
        }
        
        // Otherwise compare critical properties
        return lhs.title == rhs.title &&
            lhs.householdId == rhs.householdId &&
            lhs.assignedToUserId == rhs.assignedToUserId &&
            lhs.dueDate == rhs.dueDate &&
            lhs.isCompleted == rhs.isCompleted
    }
}

// MARK: - Sample Data

extension Chore {
    static let samples: [Chore] = [
        Chore(
            id: "sample_chore_1",
            title: "Clean kitchen",
            description: "Wash dishes, wipe counters, and mop floor",
            householdId: "sample_household_id",
            assignedToUserId: "sample_user_id",
            dueDate: Calendar.current.date(byAdding: .day, value: 1, to: Date()),
            isCompleted: false,
            createdAt: Date(),
            pointValue: 3
        ),
        Chore(
            id: "sample_chore_2",
            title: "Take out trash",
            description: "Don't forget to separate recycling",
            householdId: "sample_household_id",
            assignedToUserId: "sample_user_id_2",
            dueDate: Calendar.current.date(byAdding: .hour, value: -3, to: Date()),
            isCompleted: true,
            createdAt: Date().addingTimeInterval(-86400),
            completedAt: Calendar.current.date(byAdding: .hour, value: -1, to: Date()),
            completedByUserId: "sample_user_id_2",
            pointValue: 1
        ),
        Chore(
            id: "sample_chore_3",
            title: "Mow the lawn",
            description: "Cut the grass in the front and back yard",
            householdId: "sample_household_id",
            assignedToUserId: "sample_user_id",
            dueDate: Calendar.current.date(byAdding: .day, value: 2, to: Date()),
            isCompleted: false,
            createdAt: Date().addingTimeInterval(-86400 * 2),
            pointValue: 5,
            isRecurring: true,
            recurrenceType: .weekly,
            recurrenceInterval: 2,
            recurrenceDaysOfWeek: [6] // Saturday
        ),
        Chore(
            id: "sample_chore_4",
            title: "Buy groceries", 
            description: "Milk, eggs, bread, fruits, and vegetables",
            householdId: "sample_household_id",
            dueDate: Calendar.current.date(byAdding: .day, value: -1, to: Date()),
            isCompleted: false,
            createdAt: Date().addingTimeInterval(-86400 * 3),
            pointValue: 2
        )
    ]
}
