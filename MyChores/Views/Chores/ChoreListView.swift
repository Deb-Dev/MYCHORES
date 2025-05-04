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
        List {
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
                                viewModel.completeChore(choreId: chore.id ?? "")
                            } label: {
                                Label("Complete", systemImage: "checkmark.circle")
                            }
                            .tint(Theme.Colors.success)
                        }
                        
                        // Delete action for all chores
                        Button(role: .destructive) {
                            viewModel.deleteChore(choreId: chore.id ?? "")
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
            }
        }
        .listStyle(InsetGroupedListStyle())
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
