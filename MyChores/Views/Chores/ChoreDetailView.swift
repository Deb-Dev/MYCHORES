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
    @State private var appearAnimation = false
    
    /// Dictionary to store user names keyed by user ID
    @State private var userNames: [String: String] = [:]
    
    var body: some View {
        NavigationStack {
            ZStack {
                Theme.Colors.background.ignoresSafeArea()
                
                // Decorative background elements
                VStack {
                    HStack {
                        Circle()
                            .fill(Theme.Colors.primary.opacity(0.1))
                            .frame(width: 150, height: 150)
                            .offset(x: -40, y: -30)
                            .blur(radius: 30)
                        
                        Spacer()
                    }
                    
                    Spacer()
                    
                    HStack {
                        Spacer()
                        
                        Circle()
                            .fill(Theme.Colors.secondary.opacity(0.1))
                            .frame(width: 180, height: 180)
                            .offset(x: 50, y: 50)
                            .blur(radius: 30)
                    }
                }
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        // Status banner
                        statusBanner
                            .opacity(appearAnimation ? 1 : 0)
                            .offset(y: appearAnimation ? 0 : -20)
                        
                        // Content sections
                        basicInfoSection
                            .opacity(appearAnimation ? 1 : 0)
                            .offset(y: appearAnimation ? 0 : -15)
                        
                        infoCardsSection
                            .opacity(appearAnimation ? 1 : 0)
                            .offset(y: appearAnimation ? 0 : -10)
                        
                        actionButtonsSection
                            .opacity(appearAnimation ? 1 : 0)
                            .offset(y: appearAnimation ? 0 : -5)
                    }
                    .padding(.bottom, 32)
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
                
                // Trigger animations with slight delay
                withAnimation(Theme.Animations.springAnimation.delay(0.2)) {
                    appearAnimation = true
                }
            }
        }
    }
    
    // MARK: - UI Sections
    
    private var basicInfoSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(chore.title)
                .font(Theme.Typography.titleFontSystem)
                .foregroundColor(Theme.Colors.text)
                .padding(.bottom, 2)
            
            if !chore.description.isEmpty {
                Text(chore.description)
                    .font(Theme.Typography.bodyFontSystem)
                    .foregroundColor(Theme.Colors.textSecondary)
                    .padding(.top, 4)
                    .padding(.bottom, 8)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            // Creation info with subtle styling
            if let createdByUserId = chore.createdByUserId {
                HStack(spacing: 6) {
                    Image(systemName: "person.crop.circle")
                        .font(.system(size: 14))
                        .foregroundColor(Theme.Colors.primary)
                    
                    Text("Created by \(userNames[createdByUserId] ?? "Unknown") · \(relativeDateFormatter(chore.createdAt))")
                        .font(Theme.Typography.captionFontSystem)
                        .foregroundColor(Theme.Colors.textSecondary)
                }
                .padding(.top, 4)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: Theme.Dimensions.cornerRadiusLarge)
                .fill(Theme.Colors.cardBackground)
                .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
        )
        .padding(.horizontal, 16)
    }
    
    private var infoCardsSection: some View {
        VStack(spacing: 16) {
            // Section title
            HStack {
                Text("Details")
                    .font(Theme.Typography.subheadingFontSystem.bold())
                    .foregroundColor(Theme.Colors.text)
                
                Spacer()
            }
            .padding(.horizontal, 16)
            
            // Cards grid for better layout on larger screens
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                // Due date
                if let dueDate = chore.dueDate {
                    infoCard(
                        title: "Due Date",
                        value: formatDateForDisplay(dueDate),
                        icon: "calendar",
                        color: chore.isOverdue ? Theme.Colors.error : Theme.Colors.primary
                    )
                    .transition(.scale(scale: 0.9).combined(with: .opacity))
                }
                
                // Assigned to
                if let assignedToUserId = chore.assignedToUserId {
                    infoCard(
                        title: "Assigned To",
                        value: userNames[assignedToUserId] ?? "Loading...",
                        icon: "person.fill",
                        color: Theme.Colors.secondary
                    )
                    .transition(.scale(scale: 0.9).combined(with: .opacity))
                }
                
                // Points
                infoCard(
                    title: "Points",
                    value: "\(chore.pointValue) point\(chore.pointValue > 1 ? "s" : "")",
                    icon: "star.fill",
                    color: Theme.Colors.accent
                )
                .transition(.scale(scale: 0.9).combined(with: .opacity))
                
                // Recurrence
                if chore.isRecurring {
                    infoCard(
                        title: "Recurrence",
                        value: getRecurrenceText(),
                        icon: "arrow.clockwise",
                        color: Theme.Colors.secondary
                    )
                    .transition(.scale(scale: 0.9).combined(with: .opacity))
                }
                
                // Completion status
                if chore.isCompleted, let completedAt = chore.completedAt, let completedByUserId = chore.completedByUserId {
                    infoCard(
                        title: "Completed",
                        value: formatCompletionInfo(date: completedAt, userId: completedByUserId),
                        icon: "checkmark.circle.fill",
                        color: Theme.Colors.success
                    )
                    .gridCellColumns(2)
                    .transition(.scale(scale: 0.9).combined(with: .opacity))
                }
            }
            .padding(.horizontal, 16)
        }
    }
    
    private var actionButtonsSection: some View {
        VStack(spacing: 16) {
            // Section title
            HStack {
                Text("Actions")
                    .font(Theme.Typography.subheadingFontSystem.bold())
                    .foregroundColor(Theme.Colors.text)
                
                Spacer()
            }
            .padding(.horizontal, 16)
            
            // Action buttons
            VStack(spacing: 16) {
                // Complete button (only if not already completed)
                if !chore.isCompleted {
                    completeButton
                        .transition(.scale(scale: 0.9).combined(with: .opacity))
                }
                
                // Delete button
                deleteButton
                    .transition(.scale(scale: 0.9).combined(with: .opacity))
            }
            .padding(.horizontal, 16)
        }
        .padding(.top, 8)
        .padding(.bottom, 16)
    }
    
    // MARK: - UI Components
    
    private var statusBanner: some View {
        HStack {
            Image(systemName: statusIcon)
                .font(.system(size: 28, weight: .semibold))
                .foregroundColor(.white)
                .frame(width: 50, height: 50)
                .background(
                    Circle()
                        .fill(statusColor)
                        .shadow(color: statusColor.opacity(0.5), radius: 5, x: 0, y: 3)
                )
                .overlay(
                    Circle()
                        .stroke(Color.white.opacity(0.3), lineWidth: 2)
                )
                .padding(.trailing, 8)
                // Only apply scale animation during initial appearance
                .scaleEffect(appearAnimation ? 1.0 : 0.8)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(statusText)
                    .font(Theme.Typography.subheadingFontSystem.weight(.bold))
                    .foregroundColor(Theme.Colors.text)
                
                Text(statusDescription)
                    .font(Theme.Typography.captionFontSystem)
                    .foregroundColor(Theme.Colors.textSecondary)
            }
            
            Spacer()
        }
        .padding(EdgeInsets(top: 16, leading: 16, bottom: 16, trailing: 16))
        .background(
            RoundedRectangle(cornerRadius: Theme.Dimensions.cornerRadiusLarge)
                .fill(Theme.Colors.cardBackground)
                .shadow(color: statusColor.opacity(0.2), radius: 8, x: 0, y: 4)
        )
        .overlay(
            RoundedRectangle(cornerRadius: Theme.Dimensions.cornerRadiusLarge)
                .stroke(statusColor.opacity(0.3), lineWidth: 1)
        )
        .padding(.horizontal, 16)
    }
    
    private var completeButton: some View {
        Button {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                onComplete()
                dismiss()
            }
        } label: {
            HStack {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 20, weight: .semibold))
                
                Text("Mark as Completed")
                    .fontWeight(.semibold)
            }
            .font(Theme.Typography.bodyFontSystem)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [
                        Theme.Colors.success.opacity(0.9),
                        Theme.Colors.success
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .cornerRadius(Theme.Dimensions.cornerRadiusLarge)
            .shadow(color: Theme.Colors.success.opacity(0.4), radius: 8, x: 0, y: 4)
            .overlay(
                RoundedRectangle(cornerRadius: Theme.Dimensions.cornerRadiusLarge)
                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
            )
        }
        .buttonStyle(ScaleButtonStyle())
    }
    
    private var deleteButton: some View {
        Button {
            showingDeleteConfirmation = true
        } label: {
            HStack {
                Image(systemName: "trash.fill")
                    .font(.system(size: 18, weight: .semibold))
                
                Text("Delete Chore")
                    .fontWeight(.semibold)
            }
            .font(Theme.Typography.bodyFontSystem)
            .foregroundColor(Theme.Colors.error)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(Theme.Colors.error.opacity(0.1))
            .cornerRadius(Theme.Dimensions.cornerRadiusLarge)
            .overlay(
                RoundedRectangle(cornerRadius: Theme.Dimensions.cornerRadiusLarge)
                    .stroke(Theme.Colors.error.opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(ScaleButtonStyle())
    }
    
    private func infoCard(title: String, value: String, icon: String, color: Color) -> some View {
        HStack(alignment: .top, spacing: 14) {
            // Icon with background
            ZStack {
                Circle()
                    .fill(color.opacity(0.15))
                    .frame(width: 44, height: 44)
                
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(color)
            }
            
            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(Theme.Typography.captionFontSystem.weight(.semibold))
                    .foregroundColor(Theme.Colors.textSecondary)
                
                Text(value)
                    .font(Theme.Typography.bodyFontSystem)
                    .foregroundColor(Theme.Colors.text)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            Spacer()
        }
        .padding(.vertical, 16)
        .padding(.horizontal, 14)
        .background(
            RoundedRectangle(cornerRadius: Theme.Dimensions.cornerRadiusLarge)
                .fill(Theme.Colors.cardBackground)
                .shadow(color: Color.black.opacity(0.05), radius: 6, x: 0, y: 3)
        )
        .overlay(
            RoundedRectangle(cornerRadius: Theme.Dimensions.cornerRadiusLarge)
                .stroke(color.opacity(0.15), lineWidth: 1)
        )
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
    
    private var statusDescription: String {
        if chore.isCompleted, let completedAt = chore.completedAt {
            return "Finished \(formatDateForDisplay(completedAt))"
        } else if chore.isOverdue, let dueDate = chore.dueDate {
            return "Was due \(formatDateForDisplay(dueDate))"
        } else if let dueDate = chore.dueDate {
            return "Due \(formatDateForDisplay(dueDate))"
        } else {
            return "No due date set"
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
        // For more readable date presentation
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMM d, yyyy"
        let dateString = dateFormatter.string(from: date)
        
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "h:mm a"
        let timeString = timeFormatter.string(from: date)
        
        return "\(dateString) at \(timeString)"
    }
    
    private func relativeDateFormatter(_ date: Date) -> String {
        // For dates within a week, show relative dates
        let calendar = Calendar.current
        if calendar.isDateInToday(date) {
            return "Today"
        } else if calendar.isDateInYesterday(date) {
            return "Yesterday"
        } else if let days = calendar.dateComponents([.day], from: date, to: Date()).day, days < 7 {
            let formatter = DateFormatter()
            formatter.dateFormat = "EEEE"
            return formatter.string(from: date)
        } else {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            formatter.timeStyle = .none
            return formatter.string(from: date)
        }
    }
    
    /// Formats a date in a more readable, user-friendly way for card displays
    private func formatDateForDisplay(_ date: Date) -> String {
        let calendar = Calendar.current
        let now = Date()
        
        // Use a friendly format for dates
        if calendar.isDateInToday(date) {
            return "Today at \(formatTime(date))"
        } else if calendar.isDateInTomorrow(date) {
            return "Tomorrow at \(formatTime(date))"
        } else if let days = calendar.dateComponents([.day], from: now, to: date).day, days > 0 && days < 7 {
            let dayName = getDayName(from: date)
            return "\(dayName) at \(formatTime(date))"
        } else {
            // More distant date
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "MMM d"
            
            // Add year only if it's different from current year
            if !calendar.isDate(date, equalTo: now, toGranularity: .year) {
                dateFormatter.dateFormat = "MMM d, yyyy"
            }
            
            return "\(dateFormatter.string(from: date)) at \(formatTime(date))"
        }
    }
    
    /// Format just the time portion of a date
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: date)
    }
    
    /// Get day name from a date
    private func getDayName(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE" // Full day name
        return formatter.string(from: date)
    }
    
    /// Format completion information in a readable way
    private func formatCompletionInfo(date: Date, userId: String) -> String {
        let userName = userNames[userId] ?? "Unknown"
        let dateInfo = formatDateForDisplay(date)
        
        return "Completed \(dateInfo) by \(userName)"
    }
    
    /// Load user information for display
    private func loadUserInformation() {
        // Collect unique user IDs that need to be loaded
        var userIds = Set<String>()
        
        if let userId = chore.assignedToUserId {
            userIds.insert(userId)
        }
        
        if let creatorId = chore.createdByUserId {
            userIds.insert(creatorId)
        }
        
        if let completerId = chore.completedByUserId {
            userIds.insert(completerId)
        }
        
        // Only fetch each user once
        for userId in userIds {
            loadUserName(userId)
        }
    }
    
    /// Loads a user's name by their ID
    private func loadUserName(_ userId: String) {
        #if DEBUG
        // For preview, just use mock data
        DispatchQueue.main.async {
            // Sample user names for preview
            let mockNames = [
                "user1": "John Doe",
                "user2": "Jane Smith",
                "user3": "Alex Johnson",
                "user4": "Sam Wilson"
            ]
            self.userNames[userId] = mockNames[userId] ?? "User \(userId.prefix(4))"
        }
        #else
        // In real app, fetch from UserService
        Task {
            do {
                if let user = try await UserService.shared.getUser(withId: userId) {
                    await MainActor.run {
                        self.userNames[userId] = user.name
                    }
                }
            } catch {
                print("Error fetching user name for ID \(userId): \(error.localizedDescription)")
                
                // Set a fallback name if fetch fails
                await MainActor.run {
                    // Only set fallback if not already set
                    if self.userNames[userId] == nil {
                        self.userNames[userId] = "User \(userId.prefix(4))..."
                    }
                }
            }
        }
        #endif
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
