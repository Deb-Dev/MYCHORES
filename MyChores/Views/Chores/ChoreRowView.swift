// ChoreRowView.swift
// MyChores
//
// Created on 2025-05-02.
//

import SwiftUI

/// Row view for a single chore in the list
struct ChoreRowView: View {
    let chore: Chore
    
    var body: some View {
        HStack(spacing: 16) {
            // Status indicator
            ZStack {
                Circle()
                    .fill(statusColor.opacity(0.2))
                    .frame(width: 40, height: 40)
                
                if chore.isCompleted {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(Theme.Colors.success)
                } else if chore.isOverdue {
                    Image(systemName: "exclamationmark.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(Theme.Colors.error)
                } else {
                    Image(systemName: "circle")
                        .font(.system(size: 24))
                        .foregroundColor(statusColor)
                }
            }
            
            // Chore details
            VStack(alignment: .leading, spacing: 4) {
                Text(chore.title)
                    .font(Theme.Typography.bodyFontSystem.bold())
                    .foregroundColor(chore.isCompleted ? Theme.Colors.textSecondary : Theme.Colors.text)
                    .strikethrough(chore.isCompleted)
                
                HStack(spacing: 12) {
                    // Due date
                    if let dueDate = chore.dueDate {
                        HStack(spacing: 4) {
                            Image(systemName: "calendar")
                                .font(.system(size: 12))
                            
                            Text(formatDate(dueDate))
                                .font(Theme.Typography.captionFontSystem)
                        }
                        .foregroundColor(dueDateColor)
                    }
                    
                    // Points
                    HStack(spacing: 4) {
                        Image(systemName: "star.fill")
                            .font(.system(size: 12))
                        
                        Text("\(chore.pointValue) pts")
                            .font(Theme.Typography.captionFontSystem)
                    }
                    .foregroundColor(Theme.Colors.accent)
                    
                    // Recurring indicator
                    if chore.isRecurring {
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
        guard let type = chore.recurrenceType, let interval = chore.recurrenceInterval else {
            return "Recurring"
        }
        
        switch type {
        case .daily:
            return interval == 1 ? "Daily" : "Every \(interval) days"
        case .weekly:
            return interval == 1 ? "Weekly" : "Every \(interval) weeks"
        case .monthly:
            return interval == 1 ? "Monthly" : "Every \(interval) months"
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
