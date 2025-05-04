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
        
        if calendar.isDateInToday(self) {
            return "Due today"
        }
        
        let components = calendar.dateComponents([.day], from: now, to: self)
        
        if let days = components.day {
            if days > 0 {
                return "Due in \(days) \(days == 1 ? "day" : "days")"
            } else {
                return "Overdue by \(abs(days)) \(abs(days) == 1 ? "day" : "days")"
            }
        }
        
        // Fallback format if components calculation fails
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy"
        return "Due \(formatter.string(from: self))"
    }
}
