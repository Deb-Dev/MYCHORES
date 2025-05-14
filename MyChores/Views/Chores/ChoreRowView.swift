// ChoreRowView.swift
// MyChores
//
// Created on 2025-05-02.
// Updated on 2025-05-14.
//

import SwiftUI
import FirebaseFirestore

/// Row view for a single chore in the list
struct ChoreRowView: View {
    // MARK: - Properties
    
    let chore: Chore
    @Environment(\.colorScheme) private var colorScheme
    @State private var assignedUserName: String = "Loading..."
    
    // MARK: - Body
    
    var body: some View {
        ZStack {
            // Card background
            RoundedRectangle(cornerRadius: Theme.Dimensions.cornerRadiusSmall)
                .fill(Theme.Colors.cardBackground)
                .shadow(
                    color: colorScheme == .dark 
                        ? Color.black.opacity(0.2) 
                        : Color.black.opacity(0.05),
                    radius: 2, 
                    x: 0, 
                    y: 1
                )
            
            // Content
            VStack(spacing: 0) {
                // Title row with status circle
                HStack(alignment: .center, spacing: 12) {
                    // Status circle
                    Circle()
                        .fill(statusColor)
                        .frame(width: 24, height: 24)
                        .overlay {
                            if chore.isCompleted {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(.white)
                            }
                        }
                        .animation(.easeInOut, value: chore.isCompleted)
                    
                    // Title
                    Text(chore.title)
                        .font(Theme.Typography.bodyFontSystem.weight(.medium))
                        .foregroundColor(Theme.Colors.text)
                        .lineLimit(1)
                        .strikethrough(chore.isCompleted)
                    
                    Spacer()
                    
                    // Points
                    HStack(spacing: 4) {
                        Image(systemName: "star.fill")
                            .foregroundColor(Theme.Colors.accent)
                            .font(.system(size: 14))
                        
                        Text("\(chore.pointValue) pts")
                            .font(Theme.Typography.captionFontSystem.weight(.medium))
                            .foregroundColor(Theme.Colors.accent)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .padding(.bottom, 4)
                
                // Assignment information
                if let assignedToUserId = chore.assignedToUserId {
                    HStack(spacing: 4) {
                        Text("Assigned to: \(getUserName(assignedToUserId))")
                            .font(Theme.Typography.captionFontSystem)
                            .foregroundColor(Theme.Colors.textSecondary)
                        Spacer()
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 4)
                    .padding(.leading, 36) // Align with title text
                }
                
                // Schedule information
                HStack(spacing: 14) {
                    // Due date
                    if let dueDate = chore.dueDate {
                        HStack(spacing: 6) {
                            Image(systemName: "calendar")
                                .foregroundColor(dueDateColor)
                                .font(.system(size: 14))
                            
                            Text(formatDate(dueDate))
                                .font(Theme.Typography.captionFontSystem)
                                .foregroundColor(dueDateColor)
                        }
                    }
                    
                    // Recurrence
                    if chore.isRecurring {
                        HStack(spacing: 6) {
                            Image(systemName: "arrow.clockwise")
                                .foregroundColor(Theme.Colors.textSecondary)
                                .font(.system(size: 14))
                            
                            Text(recurrenceText)
                                .font(Theme.Typography.captionFontSystem)
                                .foregroundColor(Theme.Colors.textSecondary)
                        }
                    }
                    
                    Spacer()
                }
                .padding(.horizontal, Theme.Dimensions.paddingMedium)
                .padding(.bottom, Theme.Dimensions.paddingMedium)
            }
        }
        .padding(.vertical, 2)
        .padding(.horizontal, 4) // Thinner side margins
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
    
    private func getUserName(_ userId: String) -> String {
        Task {
            do {
                if let user = try await UserService.shared.fetchUser(withId: userId) {
                    DispatchQueue.main.async {
                        self.assignedUserName = user.name
                    }
                } else {
                    DispatchQueue.main.async {
                        self.assignedUserName = "Unknown User"
                    }
                }
            } catch {
                print("Error fetching user: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    self.assignedUserName = "User \(userId.prefix(4))"
                }
            }
        }
        return assignedUserName
    }
}
