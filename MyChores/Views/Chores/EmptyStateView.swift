// EmptyStateView.swift
// MyChores
//
// Created on 2025-05-02.
//

import SwiftUI

/// Empty state view for ChoresView when no chores match the current filter
struct EmptyStateView: View {
    let filterMode: ChoreViewModel.FilterMode
    let onAddTapped: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            Spacer()
            
            Image(systemName: "checkmark.circle")
                .font(.system(size: 60))
                .foregroundColor(Theme.Colors.primary.opacity(0.5))
            
            Text(emptyStateTitle)
                .font(Theme.Typography.subheadingFontSystem)
                .foregroundColor(Theme.Colors.text)
                .multilineTextAlignment(.center)
            
            Text(emptyStateMessage)
                .font(Theme.Typography.captionFontSystem)
                .foregroundColor(Theme.Colors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            
            if shouldShowAddButton {
                Button {
                    onAddTapped()
                } label: {
                    Text("Add a Chore")
                        .font(Theme.Typography.bodyFontSystem.bold())
                        .foregroundColor(.white)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(Theme.Colors.primary)
                        .cornerRadius(Theme.Dimensions.cornerRadiusMedium)
                }
                .padding(.top, 8)
            }
            
            Spacer()
        }
        .padding()
    }
    
    // MARK: - Helper Properties
    
    private var emptyStateTitle: String {
        switch filterMode {
        case .all:
            return "No Chores Yet"
        case .mine:
            return "No Chores Assigned to You"
        case .pending:
            return "No Pending Chores"
        case .overdue:
            return "No Overdue Chores"
        case .completed:
            return "No Completed Chores"
        }
    }
    
    private var emptyStateMessage: String {
        switch filterMode {
        case .all:
            return "Get started by adding your first household chore"
        case .mine:
            return "You don't have any chores assigned to you at the moment"
        case .pending:
            return "There are no pending chores in your household"
        case .overdue:
            return "Great job! There are no overdue chores"
        case .completed:
            return "Complete some chores to see them here"
        }
    }
    
    private var shouldShowAddButton: Bool {
        // Show the add button for all filter modes except 'completed'
        // This allows users to add chores from any empty state view
        return filterMode != .completed
    }
}
