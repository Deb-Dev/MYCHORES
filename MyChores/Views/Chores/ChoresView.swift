// ChoresView.swift
// MyChores
//
// Created on 2025-05-02.
//

import SwiftUI
import Combine
import FirebaseFirestore
import Foundation



// Extensions for Theme to make the code simpler and help with type checking
extension Theme.Colors {
    static var systemBackground: Color { Color(UIColor.systemBackground) }
    static var systemFill: Color { Color(UIColor.systemFill) }
    static var label: Color { Color(UIColor.label) }
    static var secondaryLabel: Color { Color(UIColor.secondaryLabel) }
}

/// Main view for managing household chores
struct ChoresView: View {
    @ObservedObject private var viewModel: ChoreViewModel
    @State private var showingAddChore = false
    @State private var showingChoreDetail: Chore?
    @State private var isRefreshing = false
    
    init(householdId: String) {
        self.viewModel = ChoreViewModel(householdId: householdId)
    }
    
    var body: some View {
        ZStack {
            Theme.Colors.background.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Filter controls
                FilterControlsView(viewModel: viewModel)
                
                // Chore content
                if viewModel.isLoading && viewModel.chores.isEmpty {
                    loadingView
                } else if viewModel.filteredChores.isEmpty {
                    EmptyStateView(filterMode: viewModel.filterMode, onAddTapped: {
                        showingAddChore = true
                    })
                } else {
                    choreListView
                }
            }
            .navigationTitle("Chores")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingAddChore = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddChore) {
                AddChoreView(householdId: viewModel.householdId)
            }
            .sheet(item: $showingChoreDetail) { chore in
                ChoreDetailView(
                    chore: chore,
                    onComplete: {
                        viewModel.completeChore(choreId: chore.id ?? "")
                    },
                    onDelete: {
                        viewModel.deleteChore(choreId: chore.id ?? "")
                    }
                )
            }
            
            // Points earned toast
            if let pointsMessage = viewModel.pointsEarnedMessage {
                PointsEarnedToastView(message: pointsMessage) {
                    viewModel.pointsEarnedMessage = nil
                }
            }
            
            // Badge earned toast
            if let badgeMessage = viewModel.badgeEarnedMessage {
                BadgeEarnedToastView(message: badgeMessage) {
                    viewModel.badgeEarnedMessage = nil
                }
            }
        }
        .refreshable {
            isRefreshing = true
            viewModel.loadChores()
            isRefreshing = false
        }
        .alert(
            "Error",
            isPresented: Binding<Bool>(
                get: { viewModel.errorMessage != nil },
                set: { if !$0 { viewModel.errorMessage = nil } }
            ),
            actions: { Button("OK", role: .cancel) {} },
            message: { Text(viewModel.errorMessage ?? "") }
        )
    }
    
    // MARK: - UI Components
    
    private var loadingView: some View {
        ProgressView()
            .progressViewStyle(CircularProgressViewStyle())
            .scaleEffect(1.5)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var choreListView: some View {
        List {
            ForEach(viewModel.filteredChores) { chore in
                ChoreRowView(chore: chore)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        showingChoreDetail = chore
                    }
                    .swipeActions(edge: .trailing) {
                        if !chore.isCompleted {
                            Button {
                                viewModel.completeChore(choreId: chore.id ?? "")
                            } label: {
                                Label("Complete", systemImage: "checkmark.circle")
                            }
                            .tint(Theme.Colors.success)
                        }
                        
                        Button(role: .destructive) {
                            viewModel.deleteChore(choreId: chore.id ?? "")
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
            }
        }
        .listStyle(InsetGroupedListStyle())
    }
}

// MARK: - Date Extension

extension Date {
    func next(_ weekday: Int, considerToday: Bool = false) -> Date {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.weekday], from: self)
        let currentWeekday = components.weekday!
        
        var daysToAdd: Int
        if currentWeekday == weekday && considerToday {
            daysToAdd = 0
        } else if currentWeekday < weekday {
            daysToAdd = weekday - currentWeekday
        } else {
            daysToAdd = 7 - (currentWeekday - weekday)
        }
        
        return calendar.date(byAdding: .day, value: daysToAdd, to: self)!
    }
}

#Preview {
    ChoresView(householdId: "sample_household_id")
}
