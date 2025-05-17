// AchievementsView.swift
// MyChores
//
// Created on 2025-05-02.
// Enhanced on 2025-05-15.
// Refactored on 2025-05-17.
//

import SwiftUI
import Combine

// Import local components
// These imports are not actually necessary in Swift
// as all files in the same module are automatically accessible
// This is just for clarity

/// View for displaying user's achievements and badges
struct AchievementsView: View {
    @StateObject private var viewModel: AchievementsViewModel
    @State private var showingBadgeDetail: Badge?
    
    // Animation states
    @State private var headerAppeared = false
    @State private var statsAppeared = false
    @State private var badgesAppeared = false
    
    // Celebration effects
    @State private var showCelebration = false
    @State private var recentlyEarnedBadgeId: String? = nil
    @State private var isRotating3D = false
    
    init(userId: String? = nil) {
        let id = userId ?? AuthService.shared.getCurrentUserId() ?? ""
        self._viewModel = StateObject(wrappedValue: AchievementsViewModel(userId: id))
    }

    var body: some View {
        ZStack {
            // Background with subtle pattern
            backgroundView
                .ignoresSafeArea()

            if viewModel.isLoading {
                loadingView
                    .accessibilityIdentifier("Achievements_Loading")
            } else {
                // Main content
                ScrollView {
                    VStack(spacing: 24) {
                        // Achievement progress header
                        achievementProgressHeader
                            .scaleEffect(headerAppeared ? 1.0 : 0.95)
                            .opacity(headerAppeared ? 1.0 : 0)
                            .offset(y: headerAppeared ? 0 : -20)
                        
                        // Stats section with cards
                        enhancedStatsSection
                            .scaleEffect(statsAppeared ? 1.0 : 0.95)
                            .opacity(statsAppeared ? 1.0 : 0)
                            .offset(y: statsAppeared ? 0 : -10)
                        
                        // Badges display section
                        enhancedBadgesSection
                            .scaleEffect(badgesAppeared ? 1.0 : 0.95)
                            .opacity(badgesAppeared ? 1.0 : 0)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
                    .padding(.bottom, 20)
                }
                .refreshable {
                    refreshData()
                }
                .accessibilityIdentifier("Achievements_ScrollView")
                
                // Celebration animation overlay
                if showCelebration {
                    ConfettiCelebrationView(count: 50)
                        .allowsHitTesting(false)
                        .onAppear {
                            // Hide celebration after 3 seconds
                            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                                withAnimation {
                                    showCelebration = false
                                }
                            }
                        }
                }
            }
        }
        .navigationTitle("Achievements")
        .onAppear {
            Task {
                await loadInitialData()
            }
        }
        .onDisappear {
            // Reset animation states for next appearance
            resetAnimationStates()
        }
        .sheet(item: $showingBadgeDetail) { badge in
            BadgeDetailView(badge: badge)
                .accessibilityIdentifier("BadgeDetailView")
        }
        .alert(
            LocalizedStringKey("Error"),
            isPresented: .init(
                get: { viewModel.errorMessage != nil },
                set: { if !$0 { viewModel.errorMessage = nil } }
            ),
            actions: { Button(LocalizedStringKey("OK"), role: .cancel) {} },
            message: { Text(viewModel.errorMessage ?? "") }
        )
    }
    
    // Load initial data and trigger animations
    private func loadInitialData() async {
        // Check for newly earned badges
        let previouslyEarnedCount = UserDefaults.standard.integer(forKey: "previouslyEarnedBadgesCount")
        
        // Load badges
        viewModel.loadBadges()
        
        // Animate the UI elements
        animateUIElements()
        
        // After a brief delay, check if we should celebrate a new badge
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            let currentEarnedCount = viewModel.earnedBadges.count
            
            if currentEarnedCount > previouslyEarnedCount && !viewModel.earnedBadges.isEmpty {
                // Found a newly earned badge!
                if let mostRecent = viewModel.earnedBadges.first {
                    self.recentlyEarnedBadgeId = mostRecent.id
                    // Save to UserDefaults
                    UserDefaults.standard.set(mostRecent.id, forKey: "recentlyEarnedBadgeId")
                    // Show celebration
                    self.showCelebration = true
                }
            }
            
            // Save the current count for next time
            UserDefaults.standard.set(currentEarnedCount, forKey: "previouslyEarnedBadgesCount")
        }
    }
    
    // Refresh data
    private func refreshData() {
        viewModel.loadBadges()
    }
    
    // Animate UI elements with staggered timing
    private func animateUIElements() {
        withAnimation(.easeOut(duration: 0.6)) {
            headerAppeared = true
        }
        
        withAnimation(.easeOut(duration: 0.7).delay(0.2)) {
            statsAppeared = true
        }
        
        withAnimation(.easeOut(duration: 0.7).delay(0.4)) {
            badgesAppeared = true
        }
        
        // Start 3D rotation for badge cards
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            self.isRotating3D = true
        }
    }
    
    // Reset all animation states
    private func resetAnimationStates() {
        headerAppeared = false
        statsAppeared = false
        badgesAppeared = false
        isRotating3D = false
        showCelebration = false
    }
    
    // MARK: - Background View
    private var backgroundView: some View {
        ZStack {
            Theme.Colors.background
            
            // Particle effects
            ParticleBackgroundView()
                .opacity(0.2)
            
            // Subtle decorative pattern
            VStack(spacing: 60) {
                ForEach(0..<6) { i in
                    HStack(spacing: 60) {
                        ForEach(0..<4) { j in
                            Image(systemName: "rosette")
                                .font(.system(size: 20))
                                .foregroundColor(Theme.Colors.primary.opacity(0.03))
                                .rotationEffect(.degrees(Double((i + j) * 15)))
                        }
                    }
                }
            }
            .offset(y: -100)
        }
    }
    
    // MARK: - Loading View
    private var loadingView: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .stroke(Theme.Colors.primary.opacity(0.2), lineWidth: 8)
                    .frame(width: 80, height: 80)
                
                Circle()
                    .trim(from: 0, to: 0.7)
                    .stroke(
                        LinearGradient(
                            gradient: Gradient(colors: [Theme.Colors.primary, Theme.Colors.accent]),
                            startPoint: .leading,
                            endPoint: .trailing
                        ),
                        style: StrokeStyle(lineWidth: 8, lineCap: .round)
                    )
                    .frame(width: 80, height: 80)
                    .rotationEffect(.degrees(Double.random(in: 0...360)))
                    .animation(Animation.linear(duration: 1.5).repeatForever(autoreverses: false), value: UUID())
            }
            
            Text("Loading achievements...")
                .font(Theme.Typography.bodyFontSystem)
                .foregroundColor(Theme.Colors.textSecondary)
        }
    }
    
    // MARK: - Achievement Progress Header
    private var achievementProgressHeader: some View {
        let totalBadges = Double(viewModel.allBadges.count)
        let earned = Double(viewModel.earnedBadges.count)
        let progress = totalBadges > 0 ? earned / totalBadges : 0
        
        return ZStack {
            // Background with gradient
            RoundedRectangle(cornerRadius: Theme.Dimensions.cornerRadiusMedium)
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Theme.Colors.primary.opacity(0.9),
                            Theme.Colors.primary.opacity(0.7)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    // Add decorative elements
                    ZStack {
                        // Small decorative circles - animated
                        ForEach(0..<5) { i in
                            Circle()
                                .fill(Color.white.opacity(0.1))
                                .frame(width: CGFloat.random(in: 60...100))
                                .offset(
                                    x: [-120, -80, -20, 40, 100][i],
                                    y: [30, -40, 20, -30, 40][i]
                                )
                                .scaleEffect(headerAppeared ? 1.0 : 0.5)
                                .opacity(headerAppeared ? 1.0 : 0)
                                .animation(
                                    .spring(response: 0.8, dampingFraction: 0.7)
                                    .delay(Double(i) * 0.1),
                                    value: headerAppeared
                                )
                        }
                        
                        // Pattern overlay
                        HStack(spacing: 20) {
                            ForEach(0..<10) { _ in
                                RoundedRectangle(cornerRadius: 1)
                                    .fill(Color.white.opacity(0.03))
                                    .frame(width: 2, height: 100)
                            }
                        }
                        .rotationEffect(.degrees(45))
                    }
                )
            
            HStack(spacing: 20) {
                // Enhanced progress circle with animated components
                ZStack {
                    // Background track
                    Circle()
                        .stroke(Color.white.opacity(0.2), lineWidth: 8)
                        .frame(width: 90, height: 90)
                    
                    // Progress indicator
                    Circle()
                        .trim(from: 0, to: progress)
                        .stroke(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color.white.opacity(0.8),
                                    Color.white
                                ]),
                                startPoint: .leading,
                                endPoint: .trailing
                            ),
                            style: StrokeStyle(lineWidth: 8, lineCap: .round)
                        )
                        .frame(width: 90, height: 90)
                        .rotationEffect(.degrees(-90))
                        .animation(.spring(response: 1.5, dampingFraction: 0.8), value: progress)
                    
                    // Progress marks
                    ForEach(0..<8) { i in
                        Rectangle()
                            .fill(Color.white.opacity(0.3))
                            .frame(width: 2, height: 5)
                            .offset(y: -45)
                            .rotationEffect(.degrees(Double(i) * 45))
                    }
                    
                    // Center content
                    VStack(spacing: 0) {
                        Text("\(Int(progress * 100))%")
                            .font(.system(size: 22, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                        
                        Text("Complete")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.white.opacity(0.9))
                    }
                }
                .scaleEffect(headerAppeared ? 1.0 : 0.8)
                .opacity(headerAppeared ? 1.0 : 0)
                .animation(.spring(response: 0.8, dampingFraction: 0.7).delay(0.2), value: headerAppeared)
                
                VStack(alignment: .leading, spacing: 5) {
                    Text("Achievement Progress")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text("\(viewModel.earnedBadges.count) of \(viewModel.allBadges.count) badges earned")
                        .font(.system(size: 16))
                        .foregroundColor(.white.opacity(0.9))
                    
                    // Progress bar with animated indicator
                    ZStack(alignment: .leading) {
                        // Background track
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.white.opacity(0.2))
                            .frame(height: 8)
                        
                        // Progress fill
                        RoundedRectangle(cornerRadius: 4)
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        Color.white.opacity(0.9),
                                        Color.white
                                    ]),
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: max(5, CGFloat(progress) * UIScreen.main.bounds.width * 0.55), height: 8)
                            .animation(.spring(response: 1.0, dampingFraction: 0.7), value: progress)
                        
                        // Glowing dot at the end
                        if progress > 0 {
                            Circle()
                                .fill(Color.white)
                                .frame(width: 12, height: 12)
                                .shadow(color: Color.white.opacity(0.7), radius: 4, x: 0, y: 0)
                                .offset(x: max(0, CGFloat(progress) * UIScreen.main.bounds.width * 0.55 - 6), y: 0)
                                .animation(.spring(response: 1.0, dampingFraction: 0.7), value: progress)
                        }
                    }
                }
                .offset(x: headerAppeared ? 0 : -20, y: 0)
                .opacity(headerAppeared ? 1.0 : 0)
                .animation(.spring(response: 0.8, dampingFraction: 0.7).delay(0.3), value: headerAppeared)
            }
            .padding(20)
        }
        .shadow(color: Theme.Colors.primary.opacity(0.3), radius: 10, x: 0, y: 4)
    }
    
    // MARK: - Enhanced Stats Section
    private var enhancedStatsSection: some View {
        VStack(spacing: 16) {
            HStack {
                Text(LocalizedStringKey("Your Stats"))
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(Theme.Colors.text)
                
                Spacer()
                
                Image(systemName: "chart.bar.fill")
                    .foregroundColor(Theme.Colors.primary)
                    .font(.system(size: 18))
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)

            LazyVGrid(columns: Array(repeating: .init(.flexible()), count: 3), spacing: 16) {
                animatedStatCard(
                    value: "\(viewModel.totalCompletedTasks)",
                    label: ("Tasks Completed"),
                    icon: "checkmark.circle.fill",
                    color: Theme.Colors.success,
                    delay: 0.1
                )
                animatedStatCard(
                    value: "\(viewModel.totalEarnedBadges)",
                    label: ("Badges Earned"),
                    icon: "rosette",
                    color: Theme.Colors.accent,
                    delay: 0.2
                )
                animatedStatCard(
                    value: "\(viewModel.totalPoints)",
                    label: ("Total Points"),
                    icon: "star.fill",
                    color: Theme.Colors.primary,
                    delay: 0.3
                )
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
        }
        .background(Theme.Colors.cardBackground)
        .cornerRadius(Theme.Dimensions.cornerRadiusMedium)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
        .accessibilityIdentifier("Achievements_StatsSection")
    }

    private func animatedStatCard(value: String, label: String, icon: String, color: Color, delay: Double) -> some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.1))
                    .frame(width: 56, height: 56)
                
                Image(systemName: icon)
                    .font(.system(size: 24))
                    .foregroundColor(color)
            }
            .scaleEffect(statsAppeared ? 1.0 : 0.5)
            .opacity(statsAppeared ? 1.0 : 0)
            .animation(.spring(response: 0.6, dampingFraction: 0.7).delay(delay), value: statsAppeared)

            Text(value)
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundColor(Theme.Colors.text)
                .opacity(statsAppeared ? 1.0 : 0)
                .animation(.easeOut(duration: 0.5).delay(delay + 0.2), value: statsAppeared)

            Text(label)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(Theme.Colors.textSecondary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
                .opacity(statsAppeared ? 1.0 : 0)
                .animation(.easeOut(duration: 0.5).delay(delay + 0.3), value: statsAppeared)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label), \(value)")
    }

    // MARK: - Enhanced Badges Section
    private var enhancedBadgesSection: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Your Badges")
                    .font(Theme.Typography.titleFont)
                    .foregroundColor(Theme.Colors.text)
                Spacer()
                Text("View All") // Placeholder for potential future action
                    .font(Theme.Typography.bodyFont)
                    .foregroundColor(Theme.Colors.primary)
            }
            .padding(.horizontal, 20)

            if viewModel.unearnedBadges.isEmpty && viewModel.earnedBadges.isEmpty {
                enhancedEmptyBadgesView
            } else {
                // Display earned badges first, then unearned
                let allDisplayBadges = viewModel.earnedBadges + viewModel.unearnedBadges
                
                LazyVGrid(columns: Array(repeating: .init(.flexible(), spacing: 16), count: 2), spacing: 16) {
                    ForEach(allDisplayBadges.indices, id: \.self) { index in
                        let badge = allDisplayBadges[index]
                        let isEarned = viewModel.earnedBadges.contains(where: { $0.id == badge.id })
                        
                        EnhancedBadgeCardView(
                            badge: badge,
                            isEarned: isEarned,
                            viewModel: viewModel, // Pass the viewModel
                            delay: Double(index) * 0.05 + 0.3
                        )
                        .onTapGesture {
                            showingBadgeDetail = badge
                        }
                        .accessibilityElement(children: .combine)
                        .accessibilityLabel(isEarned ? "Earned badge: \\(badge.name)" : "Unearned badge: \\(badge.name)")
                        .accessibilityHint("Tap to see details for badge \\(badge.name)")
                    }
                }
            }
        }
        .padding(.bottom, 16)
        .background(Theme.Colors.cardBackground)
        .cornerRadius(Theme.Dimensions.cornerRadiusMedium)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
        .accessibilityIdentifier("Achievements_BadgesSection")
    }

    private var enhancedEmptyBadgesView: some View {
        VStack(spacing: 30) {
            // Animated badge placeholder
            ZStack {
                // Background decorative elements
                Circle()
                    .fill(Theme.Colors.accent.opacity(0.1))
                    .frame(width: 120, height: 120)
                
                Circle()
                    .stroke(
                        AngularGradient(
                            gradient: Gradient(colors: [
                                Theme.Colors.accent.opacity(0.1),
                                Theme.Colors.accent.opacity(0.3),
                                Theme.Colors.accent.opacity(0.1)
                            ]),
                            center: .center
                        ),
                        lineWidth: 3
                    )
                    .frame(width: 140, height: 140)
                    .rotationEffect(.degrees(badgesAppeared ? 360 : 0))
                    .animation(
                        Animation.linear(duration: 15)
                            .repeatForever(autoreverses: false),
                        value: badgesAppeared
                    )
                
                Image(systemName: "rosette")
                    .font(.system(size: 60))
                    .foregroundColor(Theme.Colors.textSecondary.opacity(0.6))
                    .shadow(color: Theme.Colors.accent.opacity(0.2), radius: 5, x: 0, y: 2)
                    .overlay(
                        // Subtle shimmering effect
                        Rectangle()
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        Color.white.opacity(0),
                                        Color.white.opacity(0.2),
                                        Color.white.opacity(0)
                                    ]),
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .offset(x: badgesAppeared ? 60 : -60)
                            .animation(
                                Animation.easeInOut(duration: 1.5)
                                    .repeatForever(autoreverses: false)
                                    .delay(1.0),
                                value: badgesAppeared
                            )
                    )
                    .mask(
                        Image(systemName: "rosette")
                            .font(.system(size: 60))
                    )
            }
            .padding(.top, 30)
            .scaleEffect(badgesAppeared ? 1.0 : 0.8)
            .opacity(badgesAppeared ? 1.0 : 0)
            .animation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.3), value: badgesAppeared)

            VStack(spacing: 10) {
                Text(LocalizedStringKey("No badges yet"))
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(Theme.Colors.text)
                
                Text(LocalizedStringKey("Complete chores to earn badges and reach new achievements!"))
                    .font(.system(size: 16))
                    .foregroundColor(Theme.Colors.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
            }
            .opacity(badgesAppeared ? 1.0 : 0)
            .offset(y: badgesAppeared ? 0 : 20)
            .animation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.5), value: badgesAppeared)
            
            // Motivational button
            Button(action: {
                // Navigate to chores view or other relevant action
            }) {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 18))
                    
                    Text("View Available Chores")
                        .font(.system(size: 16, weight: .semibold))
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(Theme.Colors.primary)
                .foregroundColor(.white)
                .cornerRadius(Theme.Dimensions.cornerRadiusMedium)
                .shadow(color: Theme.Colors.primary.opacity(0.3), radius: 5, x: 0, y: 2)
            }
            .opacity(badgesAppeared ? 1.0 : 0)
            .offset(y: badgesAppeared ? 0 : 20)
            .animation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.7), value: badgesAppeared)
            .padding(.bottom, 30)
        }
        .padding()
    }
}

// Particle Views have been moved to ParticleViews.swift

// Badge Card View has been moved to BadgeCardView.swift

// Badge Detail View has been moved to BadgeDetailView.swift

#Preview {
    NavigationStack {
        AchievementsView(userId: "preview_user_id")
    }
}

// Component files reference:
// ParticleViews.swift - Contains ParticleBackgroundView and ParticleView
// BadgeCardView.swift - Contains EnhancedBadgeCardView 
// BadgeDetailView.swift - Contains BadgeDetailView
// ConfettiView.swift - Contains ConfettiCelebrationView and ConfettiPiece

// Confetti Animation has been moved to ConfettiView.swift
