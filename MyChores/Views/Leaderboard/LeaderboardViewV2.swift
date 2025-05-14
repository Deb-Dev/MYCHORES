// LeaderboardViewV2.swift
// MyChores
//
// Created on 2025-05-14.
//

import SwiftUI
import FirebaseFirestore

/// View displaying the household leaderboard of points in a modern podium style
struct LeaderboardViewV2: View {
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
                        VStack(spacing: 0) {
                            // Modern podium design
                            if viewModel.currentLeaderboard.count >= 2 {
                                modernPodiumView
                                    .padding(.top, 24)
                            }
                            
                            // Rest of the leaderboard
                            leaderboardList
                                .padding(.top, 24)
                                .padding(.bottom, 16)
                                .padding(.horizontal, 16)
                        }
                    }
                }
            }
            .padding(.horizontal, 16)
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
            .onAppear {
                viewModel.loadLeaderboards()
            }
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
    
    // MARK: - Modern Podium View
    private var modernPodiumView: some View {
        // Extract fixed values to constants to simplify the view
        let leaderboard = viewModel.currentLeaderboard
        let maxUsers = min(3, leaderboard.count)
        
        // Podium heights and sizes
        let firstPlaceHeight: CGFloat = 110
        let secondPlaceHeight: CGFloat = 80
        let thirdPlaceHeight: CGFloat = 60
        
        // Avatar sizes
        let firstPlaceSize: CGFloat = 110
        let otherPlaceSize: CGFloat = 90
        
        return VStack(spacing: 0) {
            // Extra padding to avoid crown getting cut off
            Color.clear.frame(height: 25)
            
            ZStack(alignment: .bottom) {
                // Subtle background decoration
                RoundedRectangle(cornerRadius: 20)
                    .fill(Theme.Colors.background.opacity(0.8))
                    .frame(height: 300)
                    .padding(.horizontal, 5)
            
                HStack(alignment: .bottom, spacing: 0) {
                    // Second place - LEFT
                    ZStack(alignment: .bottom) {
                        if maxUsers >= 2 {
                            UserPodiumItem(
                                user: leaderboard[1],
                                rank: 2,
                                size: otherPlaceSize,
                                color: Theme.Colors.secondary,
                                podiumColor: Theme.Colors.secondary,
                                podiumHeight: secondPlaceHeight,
                                showCrown: false
                            )
                        }
                    }
                    .frame(width: UIScreen.main.bounds.width / 3)
                    
                    // First place - CENTER (taller than others)
                    ZStack(alignment: .bottom) {
                        if maxUsers >= 1 {
                            UserPodiumItem(
                                user: leaderboard[0],
                                rank: 1,
                                size: firstPlaceSize,
                                color: Theme.Colors.accent,
                                podiumColor: Theme.Colors.accent,
                                podiumHeight: firstPlaceHeight,
                                showCrown: true
                            )
                        }
                    }
                    .frame(width: UIScreen.main.bounds.width / 3)
                    // Make it taller so the crown doesn't get cut off
                    .padding(.bottom, -20)
                    
                    // Third place - RIGHT
                    ZStack(alignment: .bottom) {
                        if maxUsers >= 3 {
                            UserPodiumItem(
                                user: leaderboard[2],
                                rank: 3,
                                size: otherPlaceSize,
                                color: Theme.Colors.primary,
                                podiumColor: Theme.Colors.primary,
                                podiumHeight: thirdPlaceHeight,
                                showCrown: false
                            )
                        }
                    }
                    .frame(width: UIScreen.main.bounds.width / 3)
                }
                .background(
                    // Invisible rectangle to ensure bottom alignment
                    Rectangle()
                        .fill(Color.clear)
                        .frame(height: 1)
                        .alignmentGuide(.bottom) { _ in 0 }
                )
            }
            .frame(height: 320)
            .padding(.bottom, 20)
        }
    }
    
    // MARK: - Leaderboard List
    private var leaderboardList: some View {
        // Skip the top 3 if we're displaying the podium
        let startIndex = viewModel.currentLeaderboard.count >= 3 ? 3 : 0
        
        // Create a simple array of remaining users
        let remainingUsers = viewModel.currentLeaderboard.count > startIndex
            ? Array(viewModel.currentLeaderboard[startIndex..<viewModel.currentLeaderboard.count])
            : []
        
        return VStack(spacing: 12) {
            // Show title for the rest of the leaderboard if there are remaining users
            if !remainingUsers.isEmpty {
                Text("Leaderboard")
                    .font(Theme.Typography.subheadingFontSystem)
                    .foregroundColor(Theme.Colors.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.bottom, 4)
            }
            
            ForEach(remainingUsers, id: \.stableId) { user in
                let rank = (remainingUsers.firstIndex(where: { $0.id == user.id }) ?? 0) + startIndex + 1
                
                LeaderboardRowItem(
                    user: user,
                    rank: rank,
                    period: viewModel.selectedPeriod,
                    currentUserId: viewModel.currentUserId
                )
            }
        }
        // Padding handled by parent VStack
    }
}

// MARK: - User Podium Item

struct UserPodiumItem: View {
    let user: User
    let rank: Int
    let size: CGFloat
    let color: Color
    let podiumColor: Color
    let podiumHeight: CGFloat
    let showCrown: Bool
    
    // Animation states
    @State private var animateAvatar = false
    @State private var animateCrown = false
    @State private var animatePodium = false
    
    var body: some View {
        VStack(spacing: 8) {
            // User avatar with crown if winner
            ZStack(alignment: .top) {
                UserAvatarView(
                    user: user,
                    size: size,
                    backgroundColor: color,
                    showCrown: false // We'll handle crown separately
                )
                .scaleEffect(animateAvatar ? 1.0 : 0.8)
                .animation(.spring(response: 0.5, dampingFraction: 0.6), value: animateAvatar)
                
                // Show crown on top if this is the winner
                if showCrown {
                    Image(systemName: "crown.fill")
                        .font(.system(size: size * 0.45))
                        .foregroundColor(Theme.Colors.accent)
                        .offset(y: -size * 0.45)
                        .shadow(color: Color.black.opacity(0.2), radius: 2, x: 0, y: 1)
                        .zIndex(2)
                        .scaleEffect(animateCrown ? 1.0 : 0.1)
                        .rotationEffect(Angle(degrees: animateCrown ? 0 : -30))
                        .animation(.spring(response: 0.5, dampingFraction: 0.6).delay(0.3), value: animateCrown)
                }
            }
            .padding(.bottom, 4)
            
            // User name
            Text(user.name)
                .font(Theme.Typography.bodyFontSystem.weight(.semibold))
                .foregroundColor(Theme.Colors.text)
                .lineLimit(1)
                .frame(width: size + 20) // Ensure consistent name width
                .multilineTextAlignment(.center)
                .opacity(animateAvatar ? 1.0 : 0.0)
                .animation(.easeIn.delay(0.2), value: animateAvatar)
            
            // Points
            Text("\(user.getPointsForCurrentPeriod(in: .weekly)) pts")
                .font(Theme.Typography.bodyFontSystem.weight(rank == 1 ? .bold : .medium))
                .foregroundColor(color)
                .padding(.bottom, 4)
                .opacity(animateAvatar ? 1.0 : 0.0)
                .animation(.easeIn.delay(0.3), value: animateAvatar)
            
            // Podium stand
            ZStack {
                Rectangle()
                    .fill(podiumColor)
                    .frame(width: 80, height: podiumHeight)
                    .cornerRadius(8, corners: [.topLeft, .topRight])
                    .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
                    .scaleEffect(y: animatePodium ? 1.0 : 0.1, anchor: .bottom)
                    .animation(.spring(response: 0.4, dampingFraction: 0.7).delay(0.1 * Double(rank)), value: animatePodium)
                
                Text("\(rank)")
                    .font(Theme.Typography.headingFontSystem.weight(.bold))
                    .foregroundColor(.white)
                    .opacity(animatePodium ? 1.0 : 0.0)
                    .animation(.easeIn.delay(0.2 + 0.1 * Double(rank)), value: animatePodium)
            }
        }
        .onAppear {
            // Trigger animations when view appears
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                animateAvatar = true
                animateCrown = true
                animatePodium = true
            }
        }
    }
}

// MARK: - User Avatar View

struct UserAvatarView: View {
    let user: User
    let size: CGFloat
    let backgroundColor: Color?
    let showCrown: Bool
    
    init(user: User, size: CGFloat, backgroundColor: Color? = nil, showCrown: Bool = false) {
        self.user = user
        self.size = size
        self.backgroundColor = backgroundColor
        self.showCrown = showCrown
    }
    
    var body: some View {
        ZStack {
            // Outer colored circle
            Circle()
                .fill(backgroundColor ?? getDefaultColor())
                .frame(width: size, height: size)
                .shadow(color: Color.black.opacity(0.15), radius: 4, x: 0, y: 2)
            
            // White inner circle with slight padding
            Circle()
                .fill(Color.white.opacity(0.9))
                .frame(width: size * 0.85, height: size * 0.85)
            
            // Initials
            Text(getInitials())
                .font(.system(size: size * 0.45, weight: .bold))
                .foregroundColor(backgroundColor ?? getDefaultColor())
            
            // Crown if this is the winner (now handled in UserPodiumItem)
            if showCrown {
                Image(systemName: "crown.fill")
                    .font(.system(size: size * 0.35))
                    .foregroundColor(Theme.Colors.accent)
                    .offset(y: -size * 0.65)
                    .zIndex(2)
            }
        }
        .drawingGroup() // Use Metal rendering for better performance
    }
    
    // MARK: - Helper Methods
    
    private func getDefaultColor() -> Color {
        // This allows us to have consistent colors for specific users
        if let userId = user.id, let firstChar = userId.first {
            let value = Int(firstChar.asciiValue ?? 0) % 3
            switch value {
                case 0: return Theme.Colors.secondary
                case 1: return Theme.Colors.accent
                default: return Theme.Colors.primary
            }
        }
        return Theme.Colors.secondary
    }
    
    private func getInitials() -> String {
        let components = user.name.components(separatedBy: " ")
        if components.count > 1, let first = components.first?.first, let last = components.last?.first {
            return "\(first)\(last)"
        } else if let first = user.name.first {
            return String(first)
        } else {
            return "?"
        }
    }
}

// MARK: - Extensions

extension User {
    func getPointsForCurrentPeriod(in period: LeaderboardViewModel.LeaderboardPeriod) -> Int {
        switch period {
        case .weekly:
            return weeklyPoints
        case .monthly:
            return monthlyPoints
        }
    }
}

// MARK: - Helper Extensions

extension LeaderboardViewModel {
    var currentUserId: String? {
        return AuthService.shared.getCurrentUserId()
    }
}

// MARK: - Round Specific Corners

extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

// MARK: - Preview

struct LeaderboardViewV2_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            LeaderboardViewV2(householdId: "sample_household_id")
        }
    }
}

// MARK: - User Row Item

/// Individual row for displaying a user in the leaderboard list
private struct LeaderboardRowItem: View {
    let user: User
    let rank: Int
    let period: LeaderboardViewModel.LeaderboardPeriod
    let currentUserId: String?
    
    // Animation state
    @State private var appearAnimation = false
    
    // Computed property to check if this is the current user
    private var isCurrentUser: Bool {
        guard let userId = currentUserId else { return false }
        return userId == user.id
    }
    
    var body: some View {
        HStack(spacing: 16) {
            // Rank
            Text("\(rank)")
                .font(Theme.Typography.bodyFontSystem.bold())
                .foregroundColor(Theme.Colors.textSecondary)
                .frame(width: 30, alignment: .center)
            
            // User avatar (smaller for list items)
            UserAvatarView(user: user, size: 40)
            
            // User info
            VStack(alignment: .leading, spacing: 4) {
                Text(user.name)
                    .font(Theme.Typography.bodyFontSystem.bold())
                    .foregroundColor(Theme.Colors.text)
                
                if isCurrentUser {
                    Text("You")
                        .font(Theme.Typography.captionFontSystem)
                        .foregroundColor(Theme.Colors.primary)
                }
            }
            
            Spacer()
            
            // Points
            HStack(spacing: 4) {
                Text("\(user.getPointsForCurrentPeriod(in: period))")
                    .font(Theme.Typography.bodyFontSystem.bold())
                    .foregroundColor(Theme.Colors.primary)
                
                Text("pts")
                    .font(Theme.Typography.captionFontSystem)
                    .foregroundColor(Theme.Colors.textSecondary)
            }
        }
        .padding()
        .background(isCurrentUser ? Theme.Colors.cardBackground.opacity(0.95) : Theme.Colors.cardBackground)
        .cornerRadius(Theme.Dimensions.cornerRadiusMedium)
        .shadow(color: Color.black.opacity(isCurrentUser ? 0.1 : 0.05), radius: isCurrentUser ? 4 : 2, x: 0, y: isCurrentUser ? 2 : 1)
        .scaleEffect(isCurrentUser ? (appearAnimation ? 1.01 : 1.0) : 1.0)
        .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: appearAnimation)
        .opacity(appearAnimation ? 1.0 : 0.0)
        .offset(x: appearAnimation ? 0 : 20)
        .animation(.spring(response: 0.4, dampingFraction: 0.8).delay(0.1 * Double(rank - 3)), value: appearAnimation)
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                appearAnimation = true
            }
        }
    }
}
