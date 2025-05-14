// ChoreDetailView.swift
// MyChores
//
// Created on 2025-05-02.
//

import SwiftUI
import FirebaseFirestore
import FirebaseAuth

/// Detail view for a chore
struct ChoreDetailView: View {
    @Environment(\.dismiss) private var dismiss
    
    let chore: Chore
    let onComplete: () -> Void
    let onDelete: () -> Void
    
    @State private var showingDeleteConfirmation = false
    
    /// Dictionary to store user names keyed by user ID
    @State private var userNames: [String: String] = [:]
    
    var body: some View {
        NavigationStack {
            ZStack {
                Theme.Colors.background.ignoresSafeArea()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        // Status banner
                        statusBanner
                        
                        // Content sections
                        basicInfoSection
                        infoCardsSection
                        actionButtonsSection
                    }
                }
            }
            .navigationTitle("Chore Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .alert("Delete Chore", isPresented: $showingDeleteConfirmation) {
                Button("Cancel", role: .cancel) {}
                Button("Delete", role: .destructive) {
                    onDelete()
                    dismiss()
                }
            } message: {
                Text("Are you sure you want to delete this chore? This action cannot be undone.")
            }
            .onAppear {
                // Load user information for display
                loadUserInformation()
            }
        }
    }
    
    // MARK: - UI Sections
    
    private var basicInfoSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(chore.title)
                .font(Theme.Typography.titleFontSystem)
                .foregroundColor(Theme.Colors.text)
            
            if !chore.description.isEmpty {
                Text(chore.description)
                    .font(Theme.Typography.bodyFontSystem)
                    .foregroundColor(Theme.Colors.textSecondary)
                    .padding(.top, 4)
            }
        }
        .padding(.horizontal, 16)
    }
    
    private var infoCardsSection: some View {
        VStack(spacing: 16) {
            // Due date
            if let dueDate = chore.dueDate {
                infoCard(
                    title: "Due Date",
                    value: formatDate(dueDate),
                    icon: "calendar",
                    color: chore.isOverdue ? Theme.Colors.error : Theme.Colors.primary
                )
            }
            
            // Assigned to
            if let assignedToUserId = chore.assignedToUserId {
                infoCard(
                    title: "Assigned To",
                    value: userNames[assignedToUserId] ?? "Loading...",
                    icon: "person.fill",
                    color: Theme.Colors.secondary
                )
            }
            
            // Points
            infoCard(
                title: "Points",
                value: "\(chore.points) point\(chore.points > 1 ? "s" : "")", // Corrected to chore.points
                icon: "star.fill",
                color: Theme.Colors.accent
            )
            
            // Recurrence
            if chore.recurrenceRule != nil && chore.recurrenceRule?.type != .none {
                infoCard(
                    title: "Recurrence",
                    value: getRecurrenceText(),
                    icon: "arrow.clockwise",
                    color: Theme.Colors.secondary
                )
            }
            
            // Completion status
            if chore.isCompleted, let completedAt = chore.completedAt {
                infoCard(
                    title: "Completed",
                    value: formatDate(completedAt),
                    icon: "checkmark.circle.fill",
                    color: Theme.Colors.success
                )
            }
        }
        .padding(.horizontal, 16)
    }
    
    private var actionButtonsSection: some View {
        VStack(spacing: 12) {
            // Complete button (only if not already completed)
            if !chore.isCompleted {
                completeButton
            }
            
            // Delete button
            deleteButton
        }
        .padding(.horizontal, 16)
        .padding(.top, 24)
        .padding(.bottom, 16)
    }
    
    // MARK: - UI Components
    
    private var statusBanner: some View {
        HStack {
            Image(systemName: statusIcon)
                .font(.system(size: 24))
            
            Text(statusText)
                .font(Theme.Typography.subheadingFontSystem)
            
            Spacer()
        }
        .padding()
        .foregroundColor(.white)
        .background(statusColor)
    }
    
    private var completeButton: some View {
        Button {
            onComplete()
            dismiss()
        } label: {
            HStack {
                Image(systemName: "checkmark.circle.fill")
                Text("Mark as Completed")
            }
            .font(Theme.Typography.bodyFontSystem.bold())
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding()
            .background(Theme.Colors.success)
            .cornerRadius(Theme.Dimensions.cornerRadiusMedium)
        }
    }
    
    private var deleteButton: some View {
        Button {
            showingDeleteConfirmation = true
        } label: {
            HStack {
                Image(systemName: "trash.fill")
                Text("Delete Chore")
            }
            .font(Theme.Typography.bodyFontSystem.bold())
            .foregroundColor(Theme.Colors.error)
            .frame(maxWidth: .infinity)
            .padding()
            .background(Theme.Colors.error.opacity(0.1))
            .cornerRadius(Theme.Dimensions.cornerRadiusMedium)
        }
    }
    
    private func infoCard(title: String, value: String, icon: String, color: Color) -> some View {
        HStack {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(color)
                .frame(width: 32)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(Theme.Typography.captionFontSystem)
                    .foregroundColor(Theme.Colors.textSecondary)
                
                Text(value)
                    .font(Theme.Typography.bodyFontSystem)
                    .foregroundColor(Theme.Colors.text)
            }
            
            Spacer()
        }
        .padding()
        .background(Theme.Colors.cardBackground)
        .cornerRadius(Theme.Dimensions.cornerRadiusMedium)
        .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
    
    // MARK: - Helper Properties
    
    private var statusIcon: String {
        if chore.isCompleted {
            return "checkmark.circle.fill"
        } else if chore.isOverdue {
            return "exclamationmark.circle.fill"
        } else {
            return "circle"
        }
    }
    
    private var statusText: String {
        if chore.isCompleted {
            return "Completed"
        } else if chore.isOverdue {
            return "Overdue"
        } else {
            return "Pending"
        }
    }
    
    private var statusColor: Color {
        if chore.isCompleted {
            return Theme.Colors.success
        } else if chore.isOverdue {
            return Theme.Colors.error
        } else {
            return Theme.Colors.primary
        }
    }
    
    // MARK: - Helper Methods
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    /// Load user information for display
    private func loadUserInformation() {
        // Load the assigned user's name if there is one
        if let userId = chore.assignedToUserId {
            loadUserName(userId)
        }
        
        // Also load the creator if available
        if let creatorId = chore.createdByUserId {
            loadUserName(creatorId)
        }
        
        // And the completer
        if let completerId = chore.completedByUserId {
            loadUserName(completerId)
        }
    }
    
    /// Loads a user's name by their ID
    private func loadUserName(_ userId: String) {
        Task {
            do {
                if let user = try await UserService.shared.fetchUser(withId: userId) {
                    await MainActor.run {
                        userNames[userId] = user.name
                    }
                }
            } catch {
                print("Error fetching user name for ID \(userId): \(error.localizedDescription)")
            }
        }
    }
    
    private func getRecurrenceText() -> String {
        guard let rule = chore.recurrenceRule, rule.type != .none else {
            return "Does not repeat"
        }
        
        var text = ""
        
        switch rule.type {
        case .daily:
            text = rule.interval == 1 ? "Daily" : "Every \\\\(rule.interval ?? 1) days"
        case .weekly:
            let base = rule.interval == 1 ? "Weekly" : "Every \\\\(rule.interval ?? 1) weeks"
            if let days = rule.daysOfWeek, !days.isEmpty {
                let dayNames = days.compactMap { DayOfWeek(rawValue: $0)?.shortName }.joined(separator: ", ")
                text = "\\\\(base) on \\\\(dayNames)"
            } else {
                text = base
            }
        case .monthly:
            var monthText = "Monthly"
            if let dayOfMonth = rule.dayOfMonth, dayOfMonth > 0 {
                monthText += " on day \\\\(dayOfMonth)"
            }
            
            // Add month interval text only if it's greater than 1,
            // or if there's no specific day of month (meaning it's just "Monthly, every X months")
            if let monthInterval = rule.monthInterval, monthInterval > 1 {
                if rule.dayOfMonth != nil {
                     monthText += "," // Add comma if dayOfMonth was specified
                }
                monthText += " every \\\\(monthInterval) months"
            } else if rule.dayOfMonth == nil && rule.monthInterval == 1 {
                // This is just "Monthly", already handled by initialization of monthText
            }
            text = monthText
        case .everyXDays:
            text = "Every \\\\(rule.interval ?? 1) days"
        case .everyXWeeks:
            let base = "Every \\\\(rule.interval ?? 1) weeks"
            if let days = rule.daysOfWeek, !days.isEmpty {
                let dayNames = days.compactMap { DayOfWeek(rawValue: $0)?.shortName }.joined(separator: ", ")
                text = "\\\\(base) on \\\\(dayNames)"
            } else {
                text = base
            }
        case .specificDayOfMonth:
            var specificDayText = "On the "
            if let day = rule.dayOfMonth {
                if day == -1 { // Assuming -1 means last day
                    specificDayText += "last day"
                } else {
                    specificDayText += "\\\\(day)\\\\(ordinalSuffix(day)) day"
                }
            }
            specificDayText += " of the month"
            if let monthInterval = rule.monthInterval, monthInterval > 1 {
                specificDayText += ", every \\\\(monthInterval) months"
            }
            text = specificDayText
        case .specificWeekdayOfMonth:
            var specificWeekdayText = "On the "
            if let weekOrdinal = rule.weekOfMonth, let dayOfWeekValue = rule.daysOfWeek?.first,
               let weekDesc = WeekOfMonthOption(rawValue: weekOrdinal)?.displayName,
               let dayName = DayOfWeek(rawValue: dayOfWeekValue)?.shortName {
                specificWeekdayText += "\\\\(weekDesc) \\\\(dayName)"
            }
            specificWeekdayText += " of the month"
            if let monthInterval = rule.monthInterval, monthInterval > 1 {
                specificWeekdayText += ", every \\\\(monthInterval) months"
            }
            text = specificWeekdayText
        case .none:
            return "Does not repeat"
        }
        
        if let endDate = rule.endDate {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            text += ", until \\\\(formatter.string(from: endDate))"
        }
        
        return text
    }

    private func ordinalSuffix(_ number: Int) -> String {
        let suffixes = ["th", "st", "nd", "rd"]
        let v = number % 100
        if v >= 11 && v <= 13 {
            return "th"
        }
        return suffixes[min(number % 10, 4)]
    }
    
    private func getDayName(_ dayIndex: Int) -> String {
        let days = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]
        return days[dayIndex % 7]
    }
}
