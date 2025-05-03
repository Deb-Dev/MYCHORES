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
                value: "\(chore.pointValue) point\(chore.pointValue > 1 ? "s" : "")",
                icon: "star.fill",
                color: Theme.Colors.accent
            )
            
            // Recurrence
            if chore.isRecurring {
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
        guard let type = chore.recurrenceType, let interval = chore.recurrenceInterval else {
            return "Recurring"
        }
        
        var baseText: String
        
        switch type {
        case .daily:
            baseText = interval == 1 ? "Daily" : "Every \(interval) days"
        case .weekly:
            baseText = interval == 1 ? "Weekly" : "Every \(interval) weeks"
            
            if let days = chore.recurrenceDaysOfWeek, !days.isEmpty {
                let dayNames = days.map { getDayName($0) }.joined(separator: ", ")
                baseText += " on \(dayNames)"
            }
        case .monthly:
            baseText = interval == 1 ? "Monthly" : "Every \(interval) months"
            
            if let dayOfMonth = chore.recurrenceDayOfMonth {
                baseText += " on day \(dayOfMonth)"
            }
        }
        
        if let endDate = chore.recurrenceEndDate {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            baseText += " until \(formatter.string(from: endDate))"
        }
        
        return baseText
    }
    
    private func getDayName(_ dayIndex: Int) -> String {
        let days = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]
        return days[dayIndex % 7]
    }
}
