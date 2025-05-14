// DateExtensions.swift
// MyChores
//
// Created on 2025-05-03.
//

import Foundation

/// Extensions to the Date class for convenience methods
extension Date {
    /// Returns the next date with the specified weekday
    /// - Parameters:
    ///   - weekday: The weekday to find (1 = Sunday, 2 = Monday, etc.)
    ///   - considerToday: If true and today is the specified weekday, returns today
    /// - Returns: The date of the next specified weekday
    func next(_ weekday: Int, considerToday: Bool = false) -> Date {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.weekday], from: self)
        let currentWeekday = components.weekday!
        
        var daysToAdd: Int
        if currentWeekday == weekday && considerToday {
            daysToAdd = 0
        } else if currentWeekday < weekday {
            daysToAdd = weekday - currentWeekday
        } else {
            daysToAdd = 7 - (currentWeekday - weekday)
        }
        
        return calendar.date(byAdding: .day, value: daysToAdd, to: self)!
    }
    
    /// Returns a formatted string for the date in a relative format
    /// For example: "Today", "Tomorrow", "Yesterday", or "Mon, May 3"
    func relativeFormatted() -> String {
        let calendar = Calendar.current
        let now = Date()
        
        if calendar.isDateInToday(self) {
            return "Today"
        } else if calendar.isDateInTomorrow(self) {
            return "Tomorrow"
        } else if calendar.isDateInYesterday(self) {
            return "Yesterday"
        }
        
        // For dates within a week, show day of week
        let formatter = DateFormatter()
        
        if let diff = calendar.dateComponents([.day], from: now, to: self).day, abs(diff) < 7 {
            formatter.dateFormat = "EEE, MMM d"
        } else {
            formatter.dateFormat = "MMM d, yyyy"
        }
        
        return formatter.string(from: self)
    }
    
    /// Returns a time-relative string for due dates (e.g., "Due in 2 days", "Due today", "Overdue by 3 days")
    /// - Returns: A formatted string representing the due date status
    func dueDateStatus() -> String {
        let calendar = Calendar.current
        let now = Date()
        
        // Normalize dates to the start of the day for accurate day difference calculation
        let startOfSelf = calendar.startOfDay(for: self)
        let startOfNow = calendar.startOfDay(for: now)
        
        if calendar.isDateInToday(startOfSelf) {
            return "Due today"
        }
        
        let components = calendar.dateComponents([.day], from: startOfNow, to: startOfSelf)
        
        if let days = components.day {
            if days == 1 {
                return "Due tomorrow"
            } else if days > 1 {
                return "Due in \(days) days"
            } else if days == -1 {
                 return "Overdue by 1 day"
            } else if days < -1 { // Overdue
                return "Overdue by \(abs(days)) days"
            }
        }
        
        // Fallback format if components calculation fails or for same day but different times (already handled by isDateInToday)
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy"
        return "Due \(formatter.string(from: self))"
    }

    /// Calculates the Nth weekday of a given month and year.
    /// - Parameters:
    ///   - ordinal: The ordinal number (1 for first, 2 for second, -1 for last).
    ///   - weekday: The desired weekday (1 for Sunday, 2 for Monday, ..., 7 for Saturday).
    ///   - month: The month.
    ///   - year: The year.
    /// - Returns: The Date of the Nth weekday, or nil if not found.
    static func nthWeekday(_ ordinal: Int, weekday: Int, ofMonth month: Int, year: Int) -> Date? {
        let calendar = Calendar.current
        var components = DateComponents()
        components.year = year
        components.month = month
        components.weekday = weekday
        
        if ordinal == -1 { // Last occurrence of the weekday
            components.weekdayOrdinal = -1 // This directly asks for the last one
        } else {
            components.weekdayOrdinal = ordinal
        }
        
        return calendar.date(from: components)
    }

    /// Returns the date for the last day of the current month.
    func lastDayOfMonth() -> Date? {
        let calendar = Calendar.current
        guard let range = calendar.range(of: .day, in: .month, for: self) else { return nil }
        var components = calendar.dateComponents([.year, .month], from: self)
        components.day = range.upperBound - 1
        return calendar.date(from: components)
    }
}
