// ChoresView.swift
// MyChores
//
// Created on 2025-05-02.
// Enhanced on 2025-05-14.
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
    @State private var appearAnimation = false
    
    // MARK: - Initialization
    
    init(householdId: String) {
        // Use _StateObject to initialize the StateObject property
        self._viewModel = StateObject(wrappedValue: ChoreViewModel(householdId: householdId))
    }
    
    // MARK: - Body
    
    var body: some View {
        ZStack {
            Theme.Colors.background.ignoresSafeArea()
            mainChoresContent
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
        .onAppear {
            withAnimation(.easeOut(duration: 0.6)) {
                appearAnimation = true
            }
        }
    }
    
    // Extracted main content view
    private var mainChoresContent: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Metrics header
                if !viewModel.isLoading && !viewModel.chores.isEmpty {
                    ChoreMetricsCard(
                        completedCount: viewModel.chores.filter(\.isCompleted).count,
                        totalCount: viewModel.chores.count,
                        overdueCount: viewModel.chores.filter(\.isOverdue).count
                    )
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .transition(.opacity.combined(with: .move(edge: .top)))
                    .scaleEffect(appearAnimation ? 1.0 : 0.95)
                    .opacity(appearAnimation ? 1.0 : 0)
                    .animation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.1), value: appearAnimation)
                }
                
                // Filter controls with improved styling
                FilterControlsView(viewModel: viewModel)
                    .padding(.top, 4)
                    .opacity(appearAnimation ? 1.0 : 0)
                    .offset(y: appearAnimation ? 0 : 10)
                    .animation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.2), value: appearAnimation)
                
                // Chore content
                choreContent
                    .opacity(appearAnimation ? 1.0 : 0)
                    .animation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.3), value: appearAnimation)
                
                // Add some bottom padding for better scrolling experience
                Spacer().frame(height: 30)
            }
        }
        .refreshable {
            await refreshChores()
        }
        .navigationTitle("Chores")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showingAddChore = true
                } label: {
                    Label("Add Chore", systemImage: "plus.circle.fill")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(Theme.Colors.primary)
                }
                .scaleEffect(appearAnimation ? 1.0 : 0.8)
                .opacity(appearAnimation ? 1.0 : 0)
                .animation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.4), value: appearAnimation)
            }
            
            ToolbarItem(placement: .navigationBarLeading) {
                if viewModel.isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                        .scaleEffect(0.8)
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
        .animation(.easeInOut, value: viewModel.chores.count)
        .animation(.easeInOut, value: viewModel.filteredChores.count)
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
        VStack {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle())
                .scaleEffect(1.5)
                .padding(.bottom, 20)
            
            Text("Loading your chores...")
                .font(Theme.Typography.bodyFontSystem)
                .foregroundColor(Theme.Colors.textSecondary)
        }
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

#Preview {
    ChoresView(householdId: "sample_household_id")
}
