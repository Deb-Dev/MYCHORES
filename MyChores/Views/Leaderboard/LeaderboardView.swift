// LeaderboardView.swift
// MyChores
//
// Created on 2025-05-02.
//

import SwiftUI

/// View displaying the household leaderboard of points
struct LeaderboardView: View {
    @StateObject private var viewModel: LeaderboardViewModel
    @State private var isRefreshing = false
    
    init(householdId: String) {
        self._viewModel = StateObject(wrappedValue: LeaderboardViewModel(householdId: householdId))
    }
    
    var body: some View {
        ZStack {
            Theme.Colors.background.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Period selector
                periodSelector
                
                if viewModel.isLoading && viewModel.currentLeaderboard.isEmpty {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                        .scaleEffect(1.5)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if viewModel.currentLeaderboard.isEmpty {
                    emptyStateView
                } else {
                    ScrollView {
                        VStack(spacing: 24) {
                            // Top performers podium (only if there are at least 2 users)
                            if viewModel.currentLeaderboard.count >= 2 {
                                topPerformersPodium
                                    .padding(.top, 20)
                                    .padding(.bottom, 16)
                            }
                            
                            // Leaderboard list
                            leaderboardList
                                .padding(.bottom, 16)
                        }
                    }
                }
            }
            .navigationTitle("Leaderboard")
            .refreshable {
                isRefreshing = true
                viewModel.loadLeaderboards()
                isRefreshing = false
            }
            .alert(
                "Error",
                isPresented: .init(
                    get: { viewModel.errorMessage != nil },
                    set: { if !$0 { viewModel.errorMessage = nil } }
                ),
                actions: { Button("OK", role: .cancel) {} },
                message: { Text(viewModel.errorMessage ?? "") }
            )
        }
    }
    
    // MARK: - Period Selector
    
    private var periodSelector: some View {
        Picker("Period", selection: $viewModel.selectedPeriod) {
            ForEach(LeaderboardViewModel.LeaderboardPeriod.allCases) { period in
                Text(period.rawValue).tag(period)
            }
        }
        .pickerStyle(SegmentedPickerStyle())
        .padding()
        .background(Theme.Colors.cardBackground)
    }
    
    // MARK: - Empty State
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "trophy")
                .font(.system(size: 60))
                .foregroundColor(Theme.Colors.textSecondary.opacity(0.5))
            
            Text("No leaderboard data")
                .font(Theme.Typography.subheadingFontSystem)
                .foregroundColor(Theme.Colors.text)
            
            Text("Complete some chores to start earning points and appear on the leaderboard!")
                .font(Theme.Typography.bodyFontSystem)
                .foregroundColor(Theme.Colors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Top Performers Podium
    
    private var topPerformersPodium: some View {
        let leaderboard = viewModel.currentLeaderboard
        
        return HStack(alignment: .bottom, spacing: 0) {
            // Second place (if exists)
            if leaderboard.count >= 2 {
                VStack(spacing: 8) {
                    UserAvatarView(user: leaderboard[1], size: 70)
                        .overlay(
                            Circle()
                                .stroke(Theme.Colors.secondary, lineWidth: 3)
                        )
                    
                    Text(leaderboard[1].name)
                        .font(Theme.Typography.bodyFontSystem.bold())
                        .foregroundColor(Theme.Colors.text)
                        .lineLimit(1)
                    
                    Text("\(leaderboard[1].getPointsForCurrentPeriod(in: viewModel.selectedPeriod)) pts")
                        .font(Theme.Typography.captionFontSystem)
                        .foregroundColor(Theme.Colors.textSecondary)
                    
                    ZStack {
                        Rectangle()
                            .fill(Theme.Colors.secondary)
                            .frame(width: 80, height: 70)
                        
                        Text("2")
                            .font(Theme.Typography.titleFontSystem)
                            .foregroundColor(.white)
                    }
                }
                .frame(maxWidth: .infinity)
            }
            
            // First place
            VStack(spacing: 8) {
                Image(systemName: "crown.fill")
                    .font(.system(size: 24))
                    .foregroundColor(Theme.Colors.accent)
                
                UserAvatarView(user: leaderboard[0], size: 90)
                    .overlay(
                        Circle()
                            .stroke(Theme.Colors.accent, lineWidth: 4)
                    )
                
                Text(leaderboard[0].name)
                    .font(Theme.Typography.subheadingFontSystem.bold())
                    .foregroundColor(Theme.Colors.text)
                    .lineLimit(1)
                
                Text("\(leaderboard[0].getPointsForCurrentPeriod(in: viewModel.selectedPeriod)) pts")
                    .font(Theme.Typography.bodyFontSystem.bold())
                    .foregroundColor(Theme.Colors.primary)
                
                ZStack {
                    Rectangle()
                        .fill(Theme.Colors.accent)
                        .frame(width: 80, height: 90)
                    
                    Text("1")
                        .font(Theme.Typography.titleFontSystem)
                        .foregroundColor(.white)
                }
            }
            .frame(maxWidth: .infinity)
            
            // Third place (if exists)
            if leaderboard.count >= 3 {
                VStack(spacing: 8) {
                    UserAvatarView(user: leaderboard[2], size: 60)
                        .overlay(
                            Circle()
                                .stroke(Theme.Colors.primary, lineWidth: 3)
                        )
                    
                    Text(leaderboard[2].name)
                        .font(Theme.Typography.bodyFontSystem.bold())
                        .foregroundColor(Theme.Colors.text)
                        .lineLimit(1)
                    
                    Text("\(leaderboard[2].getPointsForCurrentPeriod(in: viewModel.selectedPeriod)) pts")
                        .font(Theme.Typography.captionFontSystem)
                        .foregroundColor(Theme.Colors.textSecondary)
                    
                    ZStack {
                        Rectangle()
                            .fill(Theme.Colors.primary)
                            .frame(width: 80, height: 50)
                        
                        Text("3")
                            .font(Theme.Typography.titleFontSystem)
                            .foregroundColor(.white)
                    }
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding(.horizontal, 16)
    }
    
    // MARK: - Leaderboard List
    
    private var leaderboardList: some View {
        VStack(spacing: 0) {
            // Skip the top 3 if we're displaying the podium
            let startIndex = viewModel.currentLeaderboard.count >= 3 ? 3 : 0
            
            ForEach(startIndex..<viewModel.currentLeaderboard.count, id: \.self) { index in
                let user = viewModel.currentLeaderboard[index]
                
                HStack(spacing: 16) {
                    // Rank
                    Text("\(index + 1)")
                        .font(Theme.Typography.bodyFontSystem.bold())
                        .foregroundColor(Theme.Colors.textSecondary)
                        .frame(width: 30, alignment: .center)
                    
                    // User avatar
                    UserAvatarView(user: user, size: 50)
                    
                    // User info
                    VStack(alignment: .leading, spacing: 4) {
                        Text(user.name)
                            .font(Theme.Typography.bodyFontSystem.bold())
                            .foregroundColor(Theme.Colors.text)
                        
                        if let userId = AuthService.shared.getCurrentUserId(), userId == user.id {
                            Text("You")
                                .font(Theme.Typography.captionFontSystem)
                                .foregroundColor(Theme.Colors.primary)
                        }
                    }
                    
                    Spacer()
                    
                    // Points
                    HStack(spacing: 4) {
                        Text("\(user.getPointsForCurrentPeriod(in: viewModel.selectedPeriod))")
                            .font(Theme.Typography.bodyFontSystem.bold())
                            .foregroundColor(Theme.Colors.primary)
                        
                        Text("pts")
                            .font(Theme.Typography.captionFontSystem)
                            .foregroundColor(Theme.Colors.textSecondary)
                    }
                }
                .padding()
                .background(index % 2 == 0 ? Theme.Colors.cardBackground : Theme.Colors.background)
                .cornerRadius(Theme.Dimensions.cornerRadiusMedium)
                .padding(.horizontal, 16)
            }
        }
    }
}

/// User avatar view
//struct UserAvatarView: View {
//    let user: User
//    let size: CGFloat
//    
//    var body: some View {
//        Group {
//            if let photoURL = user.photoURL, !photoURL.isEmpty {
//                // In a real app, we would load the image from the URL
//                // For now, just show a placeholder with the user's initials
//                Circle()
//                    .fill(Theme.Colors.secondary)
//                    .overlay(
//                        Text(getInitials())
//                            .font(.system(size: size * 0.4, weight: .bold))
//                            .foregroundColor(.white)
//                    )
//            } else {
//                Circle()
//                    .fill(Theme.Colors.secondary)
//                    .overlay(
//                        Text(getInitials())
//                            .font(.system(size: size * 0.4, weight: .bold))
//                            .foregroundColor(.white)
//                    )
//            }
//        }
//        .frame(width: size, height: size)
//    }
//    
//    private func getInitials() -> String {
//        let components = user.name.components(separatedBy: " ")
//        if components.count > 1, let first = components.first?.first, let last = components.last?.first {
//            return "\(first)\(last)"
//        } else if let first = user.name.first {
//            return String(first)
//        } else {
//            return "?"
//        }
//    }
//}

// MARK: - Extensions

//extension User {
//    func getPointsForCurrentPeriod(in period: LeaderboardViewModel.LeaderboardPeriod) -> Int {
//        switch period {
//        case .weekly:
//            return weeklyPoints
//        case .monthly:
//            return monthlyPoints
//        }
//    }
//}

#Preview {
    LeaderboardView(householdId: "sample_household_id")
}
