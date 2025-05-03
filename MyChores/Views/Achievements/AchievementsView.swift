// AchievementsView.swift
// MyChores
//
// Created on 2025-05-02.
//

import SwiftUI

/// View for displaying user's achievements and badges
struct AchievementsView: View {
    @StateObject private var viewModel: AchievementsViewModel
    @State private var showingBadgeDetail: Badge?
    @State private var isRefreshing = false
    
    init(userId: String? = nil) {
        let userId = userId ?? AuthService.shared.getCurrentUserId() ?? ""
        self._viewModel = StateObject(wrappedValue: AchievementsViewModel(userId: userId))
    }
    
    var body: some View {
        ZStack {
            Theme.Colors.background.ignoresSafeArea()
            
            if viewModel.isLoading {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle())
                    .scaleEffect(1.5)
            } else {
                ScrollView {
                    VStack(spacing: 24) {
                        // Stats summary
                        statsSection
                            .padding(.top, 16)
                        
                        // Badges grid
                        badgesSection
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 24)
                }
                .refreshable {
                    isRefreshing = true
                    viewModel.loadBadges()
                    isRefreshing = false
                }
            }
        }
        .navigationTitle("Achievements")
        .sheet(item: $showingBadgeDetail) { badge in
            BadgeDetailView(badge: badge)
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
    
    // MARK: - Stats Section
    
    private var statsSection: some View {
        VStack(spacing: 16) {
            Text("Your Stats")
                .font(Theme.Typography.subheadingFontSystem)
                .foregroundColor(Theme.Colors.text)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                statCard(
                    value: "\(viewModel.totalCompletedTasks)",
                    label: "Tasks Completed",
                    icon: "checkmark.circle.fill",
                    color: Theme.Colors.success
                )
                
                statCard(
                    value: "\(viewModel.totalEarnedBadges)",
                    label: "Badges Earned",
                    icon: "rosette",
                    color: Theme.Colors.accent
                )
                
                statCard(
                    value: "\(viewModel.totalPoints)",
                    label: "Total Points",
                    icon: "star.fill",
                    color: Theme.Colors.primary
                )
            }
        }
        .padding()
        .background(Theme.Colors.cardBackground)
        .cornerRadius(Theme.Dimensions.cornerRadiusMedium)
        .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
    
    private func statCard(value: String, label: String, icon: String, color: Color) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(color)
            
            Text(value)
                .font(Theme.Typography.titleFontSystem)
                .foregroundColor(Theme.Colors.text)
                .fontWeight(.bold)
            
            Text(label)
                .font(Theme.Typography.captionFontSystem)
                .foregroundColor(Theme.Colors.textSecondary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
    }
    
    // MARK: - Badges Section
    
    private var badgesSection: some View {
        VStack(spacing: 16) {
            Text("Your Badges")
                .font(Theme.Typography.subheadingFontSystem)
                .foregroundColor(Theme.Colors.text)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                // Earned badges
                ForEach(viewModel.earnedBadges) { badge in
                    BadgeCardView(
                        badge: badge,
                        isEarned: true,
                        progress: 1.0
                    )
                    .onTapGesture {
                        showingBadgeDetail = badge
                    }
                }
                
                // Upcoming badges
                ForEach(viewModel.unearnedBadges) { badge in
                    BadgeCardView(
                        badge: badge,
                        isEarned: false,
                        progress: viewModel.getBadgeProgress(for: badge)
                    )
                    .onTapGesture {
                        showingBadgeDetail = badge
                    }
                }
            }
            
            if viewModel.earnedBadges.isEmpty && viewModel.unearnedBadges.isEmpty {
                emptyBadgesView
            }
        }
        .padding()
        .background(Theme.Colors.cardBackground)
        .cornerRadius(Theme.Dimensions.cornerRadiusMedium)
        .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
    
    private var emptyBadgesView: some View {
        VStack(spacing: 16) {
            Image(systemName: "rosette")
                .font(.system(size: 60))
                .foregroundColor(Theme.Colors.textSecondary.opacity(0.5))
            
            Text("No badges yet")
                .font(Theme.Typography.subheadingFontSystem)
                .foregroundColor(Theme.Colors.text)
            
            Text("Complete chores to earn badges and reach new achievements!")
                .font(Theme.Typography.bodyFontSystem)
                .foregroundColor(Theme.Colors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 16)
        }
        .padding()
    }
}

/// Card view for displaying a badge
struct BadgeCardView: View {
    let badge: Badge
    let isEarned: Bool
    let progress: Double
    
    var body: some View {
        VStack(spacing: 12) {
            // Badge icon
            ZStack {
                Circle()
                    .fill(
                        isEarned ? 
                        Theme.Colors.accent.opacity(0.2) : 
                        Theme.Colors.textSecondary.opacity(0.1)
                    )
                    .frame(width: 80, height: 80)
                
                Image(systemName: badge.iconName)
                    .font(.system(size: 36))
                    .foregroundColor(
                        isEarned ? 
                        Theme.Colors.accent : 
                        Theme.Colors.textSecondary.opacity(0.5)
                    )
                
                // Progress circle for upcoming badges
                if !isEarned && progress > 0 {
                    Circle()
                        .trim(from: 0, to: CGFloat(progress))
                        .stroke(
                            Theme.Colors.primary.opacity(0.7),
                            style: StrokeStyle(lineWidth: 4, lineCap: .round)
                        )
                        .rotationEffect(.degrees(-90))
                        .frame(width: 90, height: 90)
                }
            }
            
            Text(badge.name)
                .font(Theme.Typography.bodyFontSystem.bold())
                .foregroundColor(isEarned ? Theme.Colors.text : Theme.Colors.textSecondary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
            
            if !isEarned && progress > 0 {
                Text("\(Int(progress * 100))% complete")
                    .font(Theme.Typography.captionFontSystem)
                    .foregroundColor(Theme.Colors.primary)
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(
            isEarned ? 
            Theme.Colors.cardBackground : 
            Theme.Colors.cardBackground.opacity(0.7)
        )
        .cornerRadius(Theme.Dimensions.cornerRadiusMedium)
        .overlay(
            RoundedRectangle(cornerRadius: Theme.Dimensions.cornerRadiusMedium)
                .stroke(
                    isEarned ? 
                    Theme.Colors.accent.opacity(0.5) : 
                    Color.gray.opacity(0.2),
                    lineWidth: 1
                )
        )
    }
}

/// Detailed view for a single badge
struct BadgeDetailView: View {
    @Environment(\.dismiss) private var dismiss
    
    let badge: Badge
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 32) {
                // Badge icon
                VStack(spacing: 24) {
                    Image(systemName: badge.iconName)
                        .font(.system(size: 80))
                        .foregroundColor(Theme.Colors.accent)
                        .padding()
                        .background(
                            Circle()
                                .fill(Theme.Colors.accent.opacity(0.2))
                                .frame(width: 160, height: 160)
                        )
                    
                    Text(badge.name)
                        .font(Theme.Typography.titleFontSystem)
                        .foregroundColor(Theme.Colors.text)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 24)
                
                // Badge description
                Text(badge.description)
                    .font(Theme.Typography.bodyFontSystem)
                    .foregroundColor(Theme.Colors.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
                
                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Theme.Colors.background)
            .navigationTitle("Badge Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    AchievementsView(userId: "preview_user_id")
}
