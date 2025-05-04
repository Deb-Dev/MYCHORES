// ChoresView.swift
// MyChores
//
// Created on 2025-05-02.
// Updated on 2025-05-03.
//

import SwiftUI
import Combine

/// Main view for managing household chores
struct ChoresView: View {
    // MARK: - Properties
    
    @StateObject private var toastManager = ToastManager()
    @StateObject private var viewModel: ChoreViewModel
    @State private var showingAddChore = false
    @State private var showingChoreDetail: Chore?
    @State private var isRefreshing = false
    
    // MARK: - Initialization
    
    init(householdId: String) {
        // Use _StateObject to initialize the StateObject property
        self._viewModel = StateObject(wrappedValue: ChoreViewModel(householdId: householdId))
    }
    
    // MARK: - Body
    
    var body: some View {
        ZStack {
            Theme.Colors.background.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Filter controls
                FilterControlsView(viewModel: viewModel)
                
                // Chore content
                choreContent
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
            .sheet(isPresented: $showingAddChore, onDismiss: {
                // Refresh chores when sheet is dismissed
                viewModel.loadChores()
            }) {
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
        }
        .modifier(ToastViewModifier(toastManager: toastManager))
        .refreshable {
            await refreshChores()
        }
        .onChange(of: viewModel.pointsEarnedMessage) { newValue in
            if let message = newValue {
                toastManager.show(ToastManager.ToastType.points(message))
                viewModel.pointsEarnedMessage = nil
            }
        }
        .onChange(of: viewModel.badgeEarnedMessage) { newValue in
            if let message = newValue {
                toastManager.show(ToastManager.ToastType.badge(message))
                viewModel.badgeEarnedMessage = nil
            }
        }
        .onChange(of: viewModel.errorMessage) { newValue in
            if let message = newValue {
                toastManager.show(ToastManager.ToastType.error(message))
                viewModel.errorMessage = nil
            }
        }
    }
    
    // MARK: - Computed Properties
    
    @ViewBuilder
    private var choreContent: some View {
        if viewModel.isLoading && viewModel.chores.isEmpty {
            loadingView
        } else if viewModel.filteredChores.isEmpty {
            EmptyStateFactory.forChoresFilter(filterMode: filterModeString, onAddTapped: {
                showingAddChore = true
            })
        } else {
            ChoreListView(viewModel: viewModel) { chore in
                showingChoreDetail = chore
            }
        }
    }
    
    // Convert the filter mode to a string for the EmptyStateFactory
    private var filterModeString: String {
        return viewModel.filterMode.rawValue
    }
    
    // MARK: - UI Components
    
    private var loadingView: some View {
        ProgressView()
            .progressViewStyle(CircularProgressViewStyle())
            .scaleEffect(1.5)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Methods
    
    /// Refreshes the chore list asynchronously
    private func refreshChores() async {
        isRefreshing = true
        
        // Use Swift concurrency with Task to wait for loadChores
        await viewModel.loadChoresAsync()
        
        isRefreshing = false
    }
}
// MARK: - Date Extension


#Preview {
    ChoresView(householdId: "sample_household_id")
}
