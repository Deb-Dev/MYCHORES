// ChoreRowView.swift
// MyChores
//
// Created on 2025-05-02.
// Updated on 2025-05-03.
//

import SwiftUI

// Import Theme and animated view modifiers
import SwiftUI

/// Row view for a single chore in the list
struct ChoreRowView: View {
    // MARK: - Properties
    
    let chore: Chore
    
    // MARK: - Body
    
    var body: some View {
        HStack(spacing: 16) {
            // Status indicator with smooth animation
            ZStack {
                // Background circle with smooth gradient animation
                Circle()
                    .fill(Color.white) // Base fill for consistent appearance
                    .frame(width: 44, height: 44)
                    .overlay(
                        Circle()
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        statusColor.opacity(0.8),
                                        statusColor.opacity(0.5)
                                    ]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    )
                    .shadow(color: statusColor.opacity(0.3), radius: 3, x: 0, y: 2)
                    .modifier(AnimatedViewModifiers.AnimatedGradient(
                        colors: [
                            statusColor.opacity(0.8), 
                            statusColor.opacity(0.5)
                        ], 
                        duration: 5.0
                    ))
                
                // Status icon with appropriate animation
                Group {
                    if chore.isCompleted {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 26, weight: .semibold))
                            .foregroundColor(.white)
                    } else if chore.isOverdue {
                        Image(systemName: "exclamationmark.circle.fill")
                            .font(.system(size: 26, weight: .semibold))
                            .foregroundColor(.white)
                            .modifier(AnimatedViewModifiers.PulseEffect(
                                minScale: 0.95,
                                maxScale: 1.05,
                                duration: 1.2
                            ))
                    } else {
                        Image(systemName: "circle")
                            .font(.system(size: 26, weight: .semibold))
                            .foregroundColor(.white)
                    }
                }
            }
            
            // Chore details with enhanced styling
            VStack(alignment: .leading, spacing: 6) {
                Text(chore.title)
                    .font(Theme.Typography.bodyFontSystem.weight(.semibold))
                    .foregroundColor(chore.isCompleted ? Theme.Colors.textSecondary : Theme.Colors.text)
                    .strikethrough(chore.isCompleted)
                    .lineLimit(1)
                
                HStack(spacing: 12) {
                    // Due date with enhanced styling
                    if let dueDate = chore.dueDate {
                        HStack(spacing: 4) {
                            Image(systemName: "calendar")
                                .font(.system(size: 12, weight: .medium))
                            
                            Text(formatDate(dueDate))
                                .font(Theme.Typography.captionFontSystem.weight(.medium))
                        }
                        .foregroundColor(dueDateColor)
                        .padding(.vertical, 3)
                        .padding(.horizontal, 6)
                        .background(dueDateColor.opacity(0.1))
                        .cornerRadius(4)
                    }
                    
                    // Points
                    HStack(spacing: 4) {
                        Image(systemName: "star.fill")
                            .font(.system(size: 12))
                        
                        Text("\(chore.points) pts") // MODIFIED: Use chore.points
                            .font(Theme.Typography.captionFontSystem)
                    }
                    .foregroundColor(Theme.Colors.accent)
                    
                    // Recurring indicator
                    // MODIFIED: Use chore.recurrenceRule
                    if chore.recurrenceRule != nil && chore.recurrenceRule?.type != .none {
                        HStack(spacing: 4) {
                            Image(systemName: "arrow.clockwise")
                                .font(.system(size: 12))
                            
                            Text(recurrenceText)
                                .font(Theme.Typography.captionFontSystem)
                        }
                        .foregroundColor(Theme.Colors.textSecondary)
                    }
                }
            }
            
            Spacer()
            
            // Assigned user initials
            if let assignedToUserId = chore.assignedToUserId {
                Text(getUserInitials(assignedToUserId))
                    .font(Theme.Typography.captionFontSystem.bold())
                    .foregroundColor(.white)
                    .frame(width: 30, height: 30)
                    .background(Theme.Colors.secondary)
                    .clipShape(Circle())
            }
        }
        .padding(.vertical, 8)
    }
    
    // MARK: - Helper Properties
    
    private var statusColor: Color {
        if chore.isCompleted {
            return Theme.Colors.success
        } else if chore.isOverdue {
            return Theme.Colors.error
        } else {
            return Theme.Colors.primary
        }
    }
    
    private var dueDateColor: Color {
        if chore.isOverdue {
            return Theme.Colors.error
        } else {
            return Theme.Colors.textSecondary
        }
    }
    
    private var recurrenceText: String {
        // MODIFIED: Use chore.recurrenceRule
        guard let rule = chore.recurrenceRule, rule.type != .none else {
            return "Recurring" // Default or consider if it should be empty
        }
        
        let interval = rule.interval ?? 1 // Default to 1 if nil for simplicity in row view

        switch rule.type {
        case .daily, .everyXDays:
            return interval == 1 ? "Daily" : "Every \(interval) days"
        case .weekly, .everyXWeeks:
            // For a more detailed row, you could add "on Mon, Wed" etc.
            return interval == 1 ? "Weekly" : "Every \(interval) weeks"
        case .monthly, .specificDayOfMonth, .specificWeekdayOfMonth:
            // Monthly recurrences can be complex; keep it simple for the row view
            // Or use a more generic term like "Monthly"
            // For specific day/weekday, you might want more detail if space allows
            let monthInterval = rule.monthInterval ?? 1
            return monthInterval == 1 ? "Monthly" : "Every \(monthInterval) months"
        case .none:
            return "" // Should not happen due to guard
        }
    }
    
    // MARK: - Helper Methods
    
    private func formatDate(_ date: Date) -> String {
        let now = Date()
        let calendar = Calendar.current
        
        // If it's today
        if calendar.isDateInToday(date) {
            let formatter = DateFormatter()
            formatter.dateFormat = "h:mm a"
            return "Today, \(formatter.string(from: date))"
        }
        
        // If it's tomorrow
        if calendar.isDateInTomorrow(date) {
            let formatter = DateFormatter()
            formatter.dateFormat = "h:mm a"
            return "Tomorrow, \(formatter.string(from: date))"
        }
        
        // If it's within the week
        if let diff = calendar.dateComponents([.day], from: now, to: date).day, diff < 7, diff > 0 {
            let formatter = DateFormatter()
            formatter.dateFormat = "EEEE"
            return formatter.string(from: date)
        }
        
        // Otherwise, use standard date format
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    private func getUserInitials(_ userId: String) -> String {
        // This is a placeholder - in a real implementation, we would look up the user's name
        // For now, just return a placeholder based on the user ID
        let firstChar = userId.first?.uppercased() ?? "U"
        return firstChar
    }
}
