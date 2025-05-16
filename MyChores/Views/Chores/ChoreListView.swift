// ChoreListView.swift
// MyChores
//
// Created on 2025-05-03.
// Enhanced on 2025-05-14
//

import SwiftUI
import _Concurrency

/// A dedicated list view for chores with swipe actions
struct ChoreListView: View {
    // MARK: - Properties
    
    @ObservedObject var viewModel: ChoreViewModel
    let onTapChore: (Chore) -> Void
    
    // Animation states
    @State private var listAppeared = false
    @State private var selectedChoreId: String? = nil
    @State private var headerOffset: CGFloat = -50
    
    // MARK: - Body
    
    var body: some View {
        mainContentView
            .animation(.default, value: viewModel.filteredChores)
            .accessibilityLabel("Chores list")
            .onAppear {
                withAnimation(.easeOut(duration: 0.6).delay(0.2)) {
                    listAppeared = true
                }
            }
    }
    
    // MARK: - Main Content Components
    
    // Main content container view
    private var mainContentView: some View {
        VStack(spacing: 0) {
            // Decorative header
            headerView
            
            // Main content - either empty state or chore list
            if viewModel.filteredChores.isEmpty {
                emptyStateView
                    .transition(.opacity)
                    .animation(.easeInOut(duration: 0.5), value: viewModel.filteredChores.isEmpty)
            } else {
                // Now we'll put the chore items directly into this container without ScrollView
                fullChoreListContent
            }
        }
        .background(backgroundPatternView)
    }
    
    // Header with animation
    private var headerView: some View {
        header
            .offset(y: headerOffset)
            .onAppear {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.2)) {
                    headerOffset = 0
                }
            }
    }
    
    // Background pattern view
    private var backgroundPatternView: some View {
        ZStack {
            // Main background
            Theme.Colors.background
            
            // Subtle pattern for visual interest
            patternDotsView
        }
        .ignoresSafeArea()
    }
    
    // Pattern of dots for background visual interest
    private var patternDotsView: some View {
        VStack {
            ForEach(0..<10) { i in
                HStack(spacing: 40) {
                    ForEach(0..<5) { j in
                        Circle()
                            .fill(Theme.Colors.primary.opacity(0.03))
                            .frame(width: 10, height: 10)
                            .offset(x: CGFloat((i + j) % 2) * 20)
                    }
                }
            }
        }
        .rotationEffect(.degrees(15))
        .offset(x: 20, y: -100)
    }
    
    // Full chore list content without its own ScrollView
    private var fullChoreListContent: some View {
        LazyVStack(spacing: 12) {
            choreListItemsView
            
            // Add some bottom padding for better scrolling experience
            Spacer().frame(height: 20)
        }
        .padding(.top, 8)
        .transition(.opacity)
        .animation(.easeInOut(duration: 0.5), value: viewModel.filteredChores.isEmpty)
    }
    
    // The actual list of chore items
    private var choreListItemsView: some View {
        ForEach(Array(viewModel.filteredChores.enumerated()), id: \.element.id) { index, chore in
            choreCard(for: chore, index: index)
                .padding(.horizontal, 16)
                .scaleEffect(listAppeared ? 1.0 : 0.95)
                .opacity(listAppeared ? 1.0 : 0)
                .offset(y: listAppeared ? 0 : 20)
                .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(Double(index) * 0.05), value: listAppeared)
                .onTapGesture {
                    handleChoreTap(chore)
                }
        }
    }
    
    // Handle tap on a chore item
    private func handleChoreTap(_ chore: Chore) {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            // Add a little tap animation
            selectedChoreId = chore.id
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                selectedChoreId = nil
                onTapChore(chore)
            }
        }
    }
    
    // MARK: - Helper Views
    
    private var header: some View {
        VStack(spacing: 0) {
            ZStack {
                // Header decorative background
                RoundedRectangle(cornerRadius: 0)
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Theme.Colors.primary.opacity(0.05),
                                Theme.Colors.background
                            ]),
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(height: 12)
                
                // Decorative elements
                HStack(spacing: 16) {
                    ForEach(0..<3) { index in
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Theme.Colors.primary.opacity(0.2))
                            .frame(width: 40, height: 4)
                    }
                }
            }
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "checklist")
                .font(.system(size: 70))
                .foregroundColor(Theme.Colors.primary.opacity(0.7))
                .padding()
                .background(
                    Circle()
                        .fill(Theme.Colors.primary.opacity(0.1))
                        .frame(width: 150, height: 150)
                )
            
            Text("No chores found")
                .font(Theme.Typography.subheadingFontSystem)
                .foregroundColor(Theme.Colors.text)
            
            Text("Add your first chore to get started or adjust your filters")
                .font(Theme.Typography.bodyFontSystem)
                .foregroundColor(Theme.Colors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
        .padding(.top, 80)
    }
    
    private func choreCard(for chore: Chore, index: Int) -> some View {
        ChoreRowView(chore: chore)
            .contentShape(Rectangle())
            .background(Theme.Colors.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: Theme.Dimensions.cornerRadiusMedium))
            .overlay(
                RoundedRectangle(cornerRadius: Theme.Dimensions.cornerRadiusMedium)
                    .stroke(
                        selectedChoreId == chore.id ? 
                            Theme.Colors.primary :
                            Color.gray.opacity(0.05),
                        lineWidth: selectedChoreId == chore.id ? 2 : 1
                    )
            )
            .shadow(
                color: chore.isCompleted ? 
                    Theme.Colors.success.opacity(0.1) : 
                    (chore.isOverdue ? Theme.Colors.error.opacity(0.1) : Color.black.opacity(0.05)),
                radius: 8,
                x: 0,
                y: 2
            )
            // Add custom swipe actions
            .swipeActions(edge: .trailing) {
                // Complete action for incomplete chores
                if !chore.isCompleted {
                    Button {
                        if (viewModel.authService.getCurrentUserId()) != nil {
                            Task {
                                viewModel.completeChore(choreId: chore.id ?? "")
                            }
                        } else {
                            print("Error: Could not get current user ID to complete chore.")
                        }
                    } label: {
                        Label("Complete", systemImage: "checkmark.circle.fill")
                            .font(.system(size: 16, weight: .semibold))
                    }
                    .tint(Theme.Colors.success)
                }
                
                // Delete action for all chores
                Button(role: .destructive) {
                    
                        Task {
                            viewModel.deleteChore(choreId: chore.id ?? "")
                        }
                } label: {
                    Label("Delete", systemImage: "trash.fill")
                        .font(.system(size: 16, weight: .semibold))
                }
            }
    }
}

#Preview {
    ChoreListView(
        viewModel: ChoreViewModel(householdId: "sample_household_id"),
        onTapChore: { _ in }
    )
}
