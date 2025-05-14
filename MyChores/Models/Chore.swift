// Chore.swift
// MyChores
//
// Created on 2025-05-02.
//

import Foundation
import FirebaseFirestore

/// Types of recurrence patterns for a chore
public enum RecurrenceRuleType: String, Codable, Equatable {
    case none // For chores that do not repeat
    case daily
    case weekly
    case monthly // Simple monthly, e.g., on the same day number
    case everyXDays
    case everyXWeeks
    case specificDayOfMonth // E.g., the 15th of every X months, or the last day
    case specificWeekdayOfMonth // E.g., the second Tuesday of every X months
}

/// Defines the recurrence rule for a chore
public struct RecurrenceRule: Codable, Equatable {
    /// The basic type of recurrence
    var type: RecurrenceRuleType

    /// The interval for the recurrence type.
    /// For `.everyXDays`, this is the number of days.
    /// For `.everyXWeeks`, this is the number of weeks.
    /// For `.daily`, `.weekly`, `.monthly` if they need an interval (e.g. every 2nd day for daily type if we extend it)
    var interval: Int?

    /// Specifies the days of the week for weekly recurrence.
    /// Array of integers, e.g., [1, 3, 5] for Sunday, Tuesday, Thursday (1=Sun, 7=Sat).
    /// Used with `.weekly` and `.everyXWeeks`.
    var daysOfWeek: [Int]?

    /// Specifies the day of the month (e.g., 15 for the 15th).
    /// Can be negative, e.g., -1 for the last day of the month.
    /// Used with `.specificDayOfMonth` and potentially `.monthly` if it means "on the Nth day".
    var dayOfMonth: Int?
    
    /// Specifies the week of the month (e.g., 1 for first, 2 for second, -1 for last).
    /// Used with `.specificWeekdayOfMonth`.
    var weekOfMonth: Int?

    /// Specifies the interval in months for monthly types of recurrence.
    /// E.g., if `monthInterval` is 2, it means every other month. Defaults to 1 if not set for relevant types.
    /// Used with `.monthly`, `.specificDayOfMonth`, `.specificWeekdayOfMonth`.
    var monthInterval: Int?

    /// The date when the recurrence should end. If nil, it recurs indefinitely.
    var endDate: Date?
    
    // Initializer
    public init(type: RecurrenceRuleType, interval: Int? = nil, daysOfWeek: [Int]? = nil, dayOfMonth: Int? = nil, weekOfMonth: Int? = nil, monthInterval: Int? = nil, endDate: Date? = nil) {
        self.type = type
        self.interval = interval
        self.daysOfWeek = daysOfWeek
        self.dayOfMonth = dayOfMonth
        self.weekOfMonth = weekOfMonth
        self.monthInterval = monthInterval
        self.endDate = endDate
    }
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
    var points: Int
    
    /// Recurrence rule for the chore
    var recurrenceRule: RecurrenceRule?
    
    /// Timestamp of the last update to the chore
    var updatedAt: Date?
    
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
        case points
        case recurrenceRule
        case updatedAt
    }
    
    /// Check if the chore is overdue
    var isOverdue: Bool {
        guard let dueDate = dueDate else { return false }
        return !isCompleted && dueDate < Date()
    }
    
    /// Create next occurrence of a recurring chore
    func createNextOccurrence() -> Chore? {
        guard let recurrenceRule = recurrenceRule, recurrenceRule.type != .none, let currentDueDate = self.dueDate else { return nil }
        
        let calendar = Calendar.current
        var nextDueDateCandidate: Date?
        
        // Always calculate from the current chore's due date
        let baseDateForCalculation = currentDueDate

        switch recurrenceRule.type {
        case .daily:
            nextDueDateCandidate = calendar.date(byAdding: .day, value: recurrenceRule.interval ?? 1, to: baseDateForCalculation)
            
        case .weekly:
            let weekInterval = recurrenceRule.interval ?? 1
            if let daysOfWeek = recurrenceRule.daysOfWeek, !daysOfWeek.isEmpty {
                // Sort days of week to find the next one logically
                let sortedDaysOfWeek = daysOfWeek.map { $0 == 0 ? 7 : $0 }.sorted() // Convert Sunday from 0 to 7 for sorting, then map back if necessary for Calendar
                
                var searchDate = baseDateForCalculation
                if weekInterval > 1 {
                     // If it's every X weeks, first advance to the week before the target week, then find the day.
                     // Or, more simply, find the next valid day, and if it's not in the correct week interval, keep searching.
                     // For now, let's find the next valid day from baseDateForCalculation and then check if it fits the interval.
                }

                // Find the next occurrence day
                var foundNextDate = false
                for i in 0..<(7 * weekInterval + 7) { // Search a bit beyond the current week(s)
                    searchDate = calendar.date(byAdding: .day, value: 1, to: searchDate)!
                    let searchWeekday = calendar.component(.weekday, from: searchDate) // 1=Sun, 2=Mon, ..., 7=Sat
                    
                    if sortedDaysOfWeek.contains(searchWeekday) {
                        // Check if this date is in the correct week interval if interval > 1
                        if weekInterval > 1 {
                            let weeksBetween = calendar.dateComponents([.weekOfYear], from: baseDateForCalculation, to: searchDate).weekOfYear ?? 0
                            if weeksBetween >= weekInterval || (weeksBetween == (weekInterval - 1) && calendar.component(.weekday, from: baseDateForCalculation) > searchWeekday) {
                                // This logic needs refinement for "every X weeks"
                                // A simpler approach for "every X weeks":
                                // 1. Find the first occurrence *after* baseDateForCalculation that matches a day in daysOfWeek.
                                // 2. If this date is not at least X weeks after baseDateForCalculation, repeat step 1 starting from X weeks after baseDateForCalculation.
                                // This is complex. Let's use a simpler model for now: advance by X weeks, then find the *first* matching day of week.
                                // This might skip occurrences if baseDateForCalculation is, e.g., a Monday, rule is every 2 weeks on Wed,
                                // and next Wed is in the same week.
                                // Correct approach:
                                // Start from baseDateForCalculation. Iterate day by day.
                                // If a day matches daysOfWeek:
                                //   Calculate week difference from original baseDateForCalculation.
                                //   If week difference % interval == 0, then it's a candidate.
                                // This still feels off.
                                // Let's try:
                                // Add `weekInterval` weeks to `baseDateForCalculation`. Then find the *first* day in `daysOfWeek` on or after that date.
                                // This is not quite right if `daysOfWeek` has multiple values.
                                
                                // Simpler: Add 1 day at a time. If day matches, check if it's been at least `interval` weeks.
                                // This is what the original loop was trying.
                                // The issue is how to anchor the "every X weeks".
                                // Let's assume the `baseDateForCalculation` is a valid anchor.
                                // We need to find the next date that is on a `daysOfWeek` AND is part of a week that is `interval` weeks after `baseDateForCalculation`'s week.

                                // Alternative for everyXWeeks:
                                // 1. Identify the week of baseDateForCalculation.
                                // 2. Target week = week of baseDateForCalculation + interval.
                                // 3. Find the first day in daysOfWeek that falls in this target week.

                                // Let's refine the .everyXWeeks logic separately if this doesn't work.
                                // For now, the existing loop structure for .weekly might be okay if interval is handled by advancing the start date.
                                // The current loop for .weekly finds the *next* available slot.
                                // For .everyXWeeks, we need to ensure it's in the *correct* week.

                                // Let's try advancing the base date first for everyXWeeks
                                var effectiveBaseDate = baseDateForCalculation
                                if recurrenceRule.type == .everyXWeeks {
                                    effectiveBaseDate = calendar.date(byAdding: .weekOfYear, value: weekInterval, to: baseDateForCalculation)!
                                    // Now find the first day in daysOfWeek on or after this effectiveBaseDate
                                    // We might need to adjust effectiveBaseDate to the start of its week for consistent results.
                                    let startOfWeekOfEffectiveBase = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: effectiveBaseDate))!
                                    searchDate = calendar.date(byAdding: .day, value: -1, to: startOfWeekOfEffectiveBase)! // Start searching from day before.
                                } else { // .weekly
                                     searchDate = baseDateForCalculation // Start search from current due date for simple weekly
                                }
                                
                                // Find the next matching day of week
                                for _ in 0..<14 { // Search up to 2 weeks out
                                    searchDate = calendar.date(byAdding: .day, value: 1, to: searchDate)!
                                    let searchWeekdayComponent = calendar.component(.weekday, from: searchDate) // 1=Sun, ..., 7=Sat
                                    if sortedDaysOfWeek.contains(searchWeekdayComponent) {
                                        // Ensure this date is after the original baseDateForCalculation
                                        if searchDate > baseDateForCalculation {
                                            nextDueDateCandidate = searchDate
                                            foundNextDate = true
                                            break
                                        }
                                    }
                                }
                                if foundNextDate { break }


                            } else { // Simple .weekly, interval = 1
                                nextDueDateCandidate = searchDate
                                foundNextDate = true
                                break;
                            }
                        }
                         if foundNextDate { break }
                    }
                }
                if !foundNextDate && recurrenceRule.type == .everyXWeeks { // Fallback for everyXWeeks if not found by targeted search
                     // Advance by interval weeks from the original due date, then find the first matching day.
                    var advancedWeekDate = calendar.date(byAdding: .weekOfYear, value: weekInterval, to: baseDateForCalculation)!
                    advancedWeekDate = calendar.date(byAdding: .day, value: -1, to: advancedWeekDate)! // Start search from day before
                    for _ in 0..<7 {
                        advancedWeekDate = calendar.date(byAdding: .day, value: 1, to: advancedWeekDate)!
                        let advancedWeekday = calendar.component(.weekday, from: advancedWeekDate)
                        if sortedDaysOfWeek.contains(advancedWeekday) {
                            if advancedWeekDate > baseDateForCalculation { // Ensure it's in the future
                                nextDueDateCandidate = advancedWeekDate
                                break
                            }
                        }
                    }
                }


            } else { // Simple weekly or everyXWeeks without specific days (behaves like every X weeks on same weekday)
                nextDueDateCandidate = calendar.date(byAdding: .weekOfYear, value: weekInterval, to: baseDateForCalculation)
            }
            
        case .monthly: // This is simple monthly on the same day number, with monthInterval
            let monthInt = recurrenceRule.monthInterval ?? 1
            var nextMonthDate = calendar.date(byAdding: .month, value: monthInt, to: baseDateForCalculation)!
            
            // Ensure day is valid for that month (e.g. if original was Jan 31, next is Feb 28/29)
            let originalDay = calendar.component(.day, from: baseDateForCalculation)
            var nextMonthComponents = calendar.dateComponents([.year, .month], from: nextMonthDate)
            nextMonthComponents.day = originalDay
            
            if let date = calendar.date(from: nextMonthComponents), calendar.component(.month, from: date) == nextMonthComponents.month {
                nextDueDateCandidate = date
            } else { // Day doesn't exist (e.g. 31st in Feb), so take last day of that month
                var lastDayComponents = calendar.dateComponents([.year, .month], from: nextMonthDate)
                lastDayComponents.month = (lastDayComponents.month ?? 0) + 1
                lastDayComponents.day = 0
                nextDueDateCandidate = calendar.date(from: lastDayComponents)
            }

        case .everyXDays:
            nextDueDateCandidate = calendar.date(byAdding: .day, value: recurrenceRule.interval ?? 1, to: baseDateForCalculation)
            
        case .everyXWeeks: // This logic is now combined with .weekly, using interval.
                           // Specific handling if daysOfWeek is nil or empty.
            let weekInt = recurrenceRule.interval ?? 1
            if let daysOfWeek = recurrenceRule.daysOfWeek, !daysOfWeek.isEmpty {
                 // This was attempted above. The logic for everyXWeeks with specific days is complex.
                 // Let's use the refined logic from .weekly case, ensuring it correctly uses weekInterval.
                 // The .weekly case needs to be robust for this.
                 // Simplified: Advance X weeks, then find the first available day from daysOfWeek.
                var searchStartDate = calendar.date(byAdding: .weekOfYear, value: weekInt, to: baseDateForCalculation)!
                // Ensure searchStartDate is at the beginning of that target week for consistent day finding.
                let components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: searchStartDate)
                searchStartDate = calendar.date(from: components)!
                searchStartDate = calendar.date(byAdding: .day, value: -1, to: searchStartDate)! // Start search from day before

                let sortedDaysOfWeek = daysOfWeek.map { $0 == 0 ? 7 : $0 }.sorted() // 1=Sun .. 7=Sat

                for _ in 0..<7 { // Check all days in that target week
                    searchStartDate = calendar.date(byAdding: .day, value: 1, to: searchStartDate)!
                    let currentWeekday = calendar.component(.weekday, from: searchStartDate)
                    if sortedDaysOfWeek.contains(currentWeekday) {
                        if searchStartDate > baseDateForCalculation { // Must be in the future
                           nextDueDateCandidate = searchStartDate
                           break
                        }
                    }
                }
                // If multiple days in daysOfWeek, this picks the earliest in the target week.
                // If no day in that week matches (e.g. rule is for Mon, target week starts on Tue), it might fail.
                // This needs to find the *first* day that is in `daysOfWeek` AND is in a week `interval` weeks after `baseDateForCalculation`'s week.

            } else { // No specific days of week, just advance by X weeks (same day of week as original)
                nextDueDateCandidate = calendar.date(byAdding: .weekOfYear, value: weekInt, to: baseDateForCalculation)
            }

        case .specificDayOfMonth:
            let monthInt = recurrenceRule.monthInterval ?? 1
            guard let dayOfMonth = recurrenceRule.dayOfMonth else { break }
            
            var components = calendar.dateComponents([.year, .month], from: baseDateForCalculation)
            components.month = (components.month ?? 0) + monthInt
            components.day = 1 // Start with first day of target month to calculate accurately

            var targetMonthDate = calendar.date(from: components)!
            
            if dayOfMonth > 0 {
                components.day = dayOfMonth
                if let date = calendar.date(from: components), calendar.component(.month, from: date) == components.month {
                    nextDueDateCandidate = date
                } else { // Day is invalid (e.g. 31st for Feb), take last day of month
                    nextDueDateCandidate = targetMonthDate.lastDayOfMonth()
                }
            } else { // Negative dayOfMonth, e.g., -1 for last day
                if let lastDay = targetMonthDate.lastDayOfMonth() {
                    if dayOfMonth == -1 {
                        nextDueDateCandidate = lastDay
                    } else {
                        // For -2 (second to last), etc.
                        nextDueDateCandidate = calendar.date(byAdding: .day, value: dayOfMonth + 1, to: lastDay)
                    }
                }
            }
            // Ensure the calculated date is after the current due date. If it's same month due to short interval, recalculate for next period.
            if let candidate = nextDueDateCandidate, candidate <= baseDateForCalculation {
                 components.month = (components.month ?? 0) + monthInt // Add interval again
                 targetMonthDate = calendar.date(from: components)!
                 if dayOfMonth > 0 {
                    components.day = dayOfMonth
                    if let date = calendar.date(from: components), calendar.component(.month, from: date) == components.month {
                        nextDueDateCandidate = date
                    } else {
                        nextDueDateCandidate = targetMonthDate.lastDayOfMonth()
                    }
                } else {
                    if let lastDay = targetMonthDate.lastDayOfMonth() {
                        nextDueDateCandidate = calendar.date(byAdding: .day, value: dayOfMonth + 1, to: lastDay)
                    }
                }
            }

        case .specificWeekdayOfMonth:
            let monthInt = recurrenceRule.monthInterval ?? 1
            guard let weekOfMonth = recurrenceRule.weekOfMonth, // e.g., 1, 2, -1
                  let daysOfWeek = recurrenceRule.daysOfWeek, !daysOfWeek.isEmpty else { break }
            
            // Assuming daysOfWeek contains the target weekday(s) (e.g., [2] for Monday)
            // For simplicity, let's assume daysOfWeek[0] is the target weekday.
            // The UI should perhaps enforce a single selection for this type or we pick the first.
            let targetWeekday = daysOfWeek[0] // Calendar's 1=Sun, ..., 7=Sat

            var components = calendar.dateComponents([.year, .month], from: baseDateForCalculation)
            components.day = 1 // Start with a known day in the month for calculation base
            
            var searchDate = baseDateForCalculation
            var attempts = 0
            
            // Loop to find the correct month first, then the day
            while attempts < 12 { // Try for up to 12 monthly intervals
                components.month = (calendar.component(.month, from: searchDate)) + monthInt
                components.year = calendar.component(.year, from: searchDate)
                if components.month! > 12 { // Adjust year if month wraps around
                    components.year! += (components.month! - 1) / 12
                    components.month = (components.month! - 1) % 12 + 1
                }

                let firstDayOfTargetMonthComponents = DateComponents(year: components.year, month: components.month, day: 1)
                guard let firstDayOfTargetMonth = calendar.date(from: firstDayOfTargetMonthComponents) else {
                    searchDate = calendar.date(byAdding: .month, value: monthInt, to: searchDate)! // Advance search and retry
                    attempts += 1
                    continue
                }

                if let nthDate = Date.nthWeekday(weekOfMonth, weekday: targetWeekday, ofMonth: calendar.component(.month, from: firstDayOfTargetMonth), year: calendar.component(.year, from: firstDayOfTargetMonth)) {
                    if nthDate > baseDateForCalculation {
                        nextDueDateCandidate = nthDate
                        break
                    }
                }
                // If not found or not in future, advance searchDate to the beginning of the *next* interval period
                // This ensures we are looking in the correct future month.
                var tempComp = calendar.dateComponents([.year, .month, .day], from: searchDate)
                tempComp.month! += monthInt
                searchDate = calendar.date(from: tempComp)!
                attempts += 1
            }
            
        case .none:
            break
        }
        
        // Check if we've passed the end date
        if let endDate = recurrenceRule.endDate, let candidate = nextDueDateCandidate, candidate > endDate {
            return nil
        }
        
        // Create the next occurrence
        guard let finalNextDueDate = nextDueDateCandidate else { return nil }
        
        var newChore = self
        newChore.id = nil // Firestore will generate a new ID
        newChore.isCompleted = false
        newChore.completedAt = nil
        newChore.completedByUserId = nil
        newChore.dueDate = finalNextDueDate
        // newChore.nextOccurrenceDate = finalNextDueDate // nextOccurrenceDate is not a field in Chore model
        newChore.createdAt = Date() // New chore instance gets a new creation date
        newChore.updatedAt = Date()
        
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
            points: 3
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
            points: 1
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
            points: 5,
            recurrenceRule: RecurrenceRule(
                type: .weekly,
                interval: 2,
                daysOfWeek: [6] // Saturday
            )
        ),
        Chore(
            id: "sample_chore_4",
            title: "Buy groceries", 
            description: "Milk, eggs, bread, fruits, and vegetables",
            householdId: "sample_household_id",
            dueDate: Calendar.current.date(byAdding: .day, value: -1, to: Date()),
            isCompleted: false,
            createdAt: Date().addingTimeInterval(-86400 * 3),
            points: 2
        )
    ]
}
