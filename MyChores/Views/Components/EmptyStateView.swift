// EmptyStateView.swift
// MyChores
//
// Created on 2025-05-03.
//

import SwiftUI

/// Reusable empty state view component for when content is not available
struct EmptyStateView: View {
    // MARK: - Properties
    
    /// The icon to show in the empty state
    let icon: String
    
    /// Main title text
    let title: String
    
    /// Optional secondary message
    let message: String
    
    /// Whether to show an action button
    let showActionButton: Bool
    
    /// Text for the action button
    let actionButtonText: String
    
    /// Action to perform when the button is tapped
    let onActionTapped: () -> Void
    
    // MARK: - Initialization
    
    /// Initialize with custom parameters (for any view)
    /// - Parameters:
    ///   - icon: System image name for the icon
    ///   - title: Main title text
    ///   - message: Secondary message
    ///   - showActionButton: Whether to show an action button
    ///   - actionButtonText: Text for the action button
    ///   - onActionTapped: Action to perform when button is tapped
    init(
        icon: String,
        title: String,
        message: String,
        showActionButton: Bool = false,
        actionButtonText: String = "Add Item",
        onActionTapped: @escaping () -> Void = {}
    ) {
        self.icon = icon
        self.title = title
        self.message = message
        self.showActionButton = showActionButton
        self.actionButtonText = actionButtonText
        self.onActionTapped = onActionTapped
    }
    
    // MARK: - Body
    
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            
            // Icon with animated gradient background
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Theme.Colors.primary.opacity(0.1),
                                Theme.Colors.primary.opacity(0.2)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 110, height: 110)
                
                Image(systemName: icon)
                    .font(.system(size: 48, weight: .medium))
                    .foregroundColor(Theme.Colors.primary)
            }
            
            VStack(spacing: 12) {
                Text(title)
                    .font(Theme.Typography.headingFontSystem)
                    .foregroundColor(Theme.Colors.text)
                    .multilineTextAlignment(.center)
                
                Text(message)
                    .font(Theme.Typography.bodyFontSystem)
                    .foregroundColor(Theme.Colors.textSecondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, 32)
            }
            
            if showActionButton {
                Button {
                    onActionTapped()
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "plus.circle.fill")
                        Text(actionButtonText)
                    }
                    .font(Theme.Typography.bodyFontSystem.bold())
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 14)
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [Theme.Colors.primary, Theme.Colors.primary.opacity(0.8)]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(Theme.Dimensions.cornerRadiusMedium)
                    .shadow(color: Theme.Colors.primary.opacity(0.3), radius: 4, x: 0, y: 2)
                }
                .padding(.top, 16)
            }
            
            Spacer()
        }
        .padding()
    }
}

/// Factory for creating common empty state views
struct EmptyStateFactory {
    /// Create an empty state for the chores filter mode
    /// - Parameters:
    ///   - filterMode: String representation of the filter mode
    ///   - onAddTapped: Action to perform when add button is tapped
    /// - Returns: An EmptyStateView configured for the specified filter mode
    static func forChoresFilter(filterMode: String, onAddTapped: @escaping () -> Void) -> EmptyStateView {
        switch filterMode {
        case "All":
            return EmptyStateView(
                icon: "list.clipboard",
                title: "No Chores Yet",
                message: "You don't have any chores in this household. Tap the button below to add your first chore!",
                showActionButton: true,
                actionButtonText: "Add a Chore",
                onActionTapped: onAddTapped
            )
            
        case "Assigned to Me":
            return EmptyStateView(
                icon: "person.crop.circle.badge.checkmark",
                title: "No Assigned Chores",
                message: "You don't have any chores assigned to you. You can relax or help others with their chores!",
                showActionButton: true,
                actionButtonText: "Add a Chore",
                onActionTapped: onAddTapped
            )
            
        case "Pending":
            return EmptyStateView(
                icon: "checkmark.circle",
                title: "All Chores Completed",
                message: "Great job! All your chores are completed. Add more chores if needed.",
                showActionButton: true,
                actionButtonText: "Add a Chore",
                onActionTapped: onAddTapped
            )
            
        case "Overdue":
            return EmptyStateView(
                icon: "calendar.badge.exclamationmark",
                title: "No Overdue Chores",
                message: "You're all caught up! There are no overdue chores at the moment.",
                showActionButton: false
            )
            
        case "Completed":
            return EmptyStateView(
                icon: "star.circle",
                title: "No Completed Chores Yet",
                message: "Complete some chores to see them here!",
                showActionButton: true,
                actionButtonText: "Go to Pending Chores",
                onActionTapped: onAddTapped
            )
            
        default:
            return EmptyStateView(
                icon: "questionmark.circle",
                title: "No Items Available",
                message: "There are no items to display at the moment.",
                showActionButton: false
            )
        }
    }
    
    /// Create an empty state for the leaderboard
    /// - Returns: An EmptyStateView configured for the leaderboard
    static func forLeaderboard() -> EmptyStateView {
        return EmptyStateView(
            icon: "trophy",
            title: "No Leaderboard Data",
            message: "Complete some chores to start earning points and appear on the leaderboard!",
            showActionButton: false
        )
    }
    
    /// Create an empty state for achievements
    /// - Returns: An EmptyStateView configured for achievements
    static func forAchievements() -> EmptyStateView {
        return EmptyStateView(
            icon: "rosette",
            title: "No Badges Yet",
            message: "Complete chores to earn badges and see them displayed here!",
            showActionButton: false
        )
    }
    
    /// Create an empty state for household members
    /// - Returns: An EmptyStateView configured for household members
    static func forHouseholdMembers(onInvite: @escaping () -> Void) -> EmptyStateView {
        return EmptyStateView(
            icon: "person.3",
            title: "No Other Members",
            message: "You're the only member of this household. Invite others to join you!",
            showActionButton: true,
            actionButtonText: "Invite Members",
            onActionTapped: onInvite
        )
    }
}

// MARK: - Preview

struct EmptyStateView_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Theme.Colors.background.ignoresSafeArea()
            
            EmptyStateFactory.forChoresFilter(filterMode: "All", onAddTapped: {})
        }
    }
}
