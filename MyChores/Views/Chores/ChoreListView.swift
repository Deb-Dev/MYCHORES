// ChoreListView.swift
// MyChores
//
// Created on 2025-05-03.
//

import SwiftUI

/// A dedicated list view for chores with swipe actions
struct ChoreListView: View {
    // MARK: - Properties
    
    @ObservedObject var viewModel: ChoreViewModel
    let onTapChore: (Chore) -> Void
    
    // MARK: - Body
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 4) { // Added 8 points of spacing between each chore
                ForEach(viewModel.filteredChores) { chore in
                    ChoreRowView(chore: chore)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            onTapChore(chore)
                        }
                        .swipeActions(edge: .trailing) {
                            // Complete action for incomplete chores
                            if !chore.isCompleted {
                                Button {
                                    // Get the current user ID from the viewModel's authService
                                    if (viewModel.authService.getCurrentUserId()) != nil {
                                        Task{
                                            viewModel.completeChore(choreId: chore.id ?? "")
                                        }
                                    } else {
                                        // Handle the case where the user ID is not available (e.g., show an error)
                                        print("Error: Could not get current user ID to complete chore.")
                                        // Optionally, you could set an error message on the viewModel to display to the user
                                    }
                                } label: {
                                    Label("Complete", systemImage: "checkmark.circle")
                                }
                                .tint(Theme.Colors.success)
                            }
                            
                            // Delete action for all chores
                            Button(role: .destructive) {
                                Task{
                                    viewModel.deleteChore(choreId: chore.id ?? "")
                                }
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                }
            }
            .padding(.horizontal, 8) // Thin side margins
        }
        .background(Theme.Colors.background)
        .animation(.default, value: viewModel.filteredChores)
        .accessibilityLabel("Chores list")
    }
}

#Preview {
    ChoreListView(
        viewModel: ChoreViewModel(householdId: "sample_household_id"),
        onTapChore: { _ in }
    )
}
