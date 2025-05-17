// 
// BadgeCardView.swift
// MyChores
//
// Created on 2025-05-17.
//

import SwiftUI

/// Enhanced card view for displaying a badge
struct EnhancedBadgeCardView: View {
    let badge: Badge
    let isEarned: Bool
    let viewModel: AchievementsViewModel
    let delay: Double

    @State private var progress: Double = 0.0
    @State private var appeared = false
    @State private var rotationX: CGFloat = 0
    @State private var rotationY: CGFloat = 0
    @State private var isRecentlyEarned = false
    
    // For 3D effect
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        VStack(spacing: 16) {
            // Badge icon with animated container
            ZStack {
                // Background glow
                Circle()
                    .fill(
                        isEarned ?
                        Theme.Colors.accent.opacity(0.15) :
                        Theme.Colors.textSecondary.opacity(0.05)
                    )
                    .frame(width: 80, height: 80)
                
                // Animated outer ring for earned badges
                if isEarned {
                    Circle()
                        .stroke(
                            AngularGradient(
                                gradient: Gradient(colors: [
                                    Theme.Colors.accent.opacity(0.2),
                                    Theme.Colors.accent.opacity(0.6),
                                    Theme.Colors.accent.opacity(0.2)
                                ]),
                                center: .center
                            ),
                            lineWidth: 3
                        )
                        .frame(width: 90, height: 90)
                        .rotationEffect(.degrees(appeared ? 360 : 0))
                        .animation(
                            Animation.linear(duration: 20)
                                .repeatForever(autoreverses: false),
                            value: appeared
                        )
                }
                
                // Pulsing effect for recently earned badges
                if isRecentlyEarned {
                    Circle()
                        .fill(Theme.Colors.accent.opacity(0))
                        .frame(width: 100, height: 100)
                        .overlay(
                            Circle()
                                .stroke(Theme.Colors.accent.opacity(0.7), lineWidth: 2)
                        )
                        .scaleEffect(appeared ? 1.2 : 0.8)
                        .opacity(appeared ? 0 : 0.8)
                        .animation(
                            Animation.easeInOut(duration: 1.5)
                                .repeatForever(autoreverses: true),
                            value: appeared
                        )
                }

                // Icon
                Image(systemName: badge.iconName)
                    .font(.system(size: 36))
                    .foregroundColor(
                        isEarned ?
                        Theme.Colors.accent :
                        Theme.Colors.textSecondary.opacity(0.5)
                    )
                    .offset(x: rotationX * 5, y: rotationY * 5) // Parallax effect

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
                        .animation(.spring(response: 1.0, dampingFraction: 0.7), value: progress)
                }
            }
            .scaleEffect(appeared ? 1.0 : 0.7)
            .opacity(appeared ? 1.0 : 0)
            .offset(x: rotationX * 2, y: rotationY * 2) // Subtle parallax effect

            // Badge name
            Text(badge.name)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(isEarned ? Theme.Colors.text : Theme.Colors.textSecondary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
                .opacity(appeared ? 1.0 : 0)
                .offset(x: rotationX * -1, y: rotationY * -1) // Inverse parallax for depth

            // Progress percentage for unearned badges
            if !isEarned && progress > 0 {
                Text("\(Int(progress * 100))% complete")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(Theme.Colors.primary)
                    .opacity(appeared ? 1.0 : 0)
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
        .shadow(
            color: isRecentlyEarned ? Theme.Colors.accent.opacity(0.4) :
                   (isEarned ? Theme.Colors.accent.opacity(0.2) : Color.clear),
            radius: isRecentlyEarned ? 12 : 8,
            x: 0,
            y: 4
        )
        .overlay(
            RoundedRectangle(cornerRadius: Theme.Dimensions.cornerRadiusMedium)
                .stroke(
                    isRecentlyEarned ? Theme.Colors.accent :
                    (isEarned ? Theme.Colors.accent.opacity(0.5) : Color.gray.opacity(0.2)),
                    lineWidth: isRecentlyEarned ? 2 : 1
                )
        )
        .rotation3DEffect(
            .degrees(rotationY * 10),
            axis: (x: 1, y: 0, z: 0)
        )
        .rotation3DEffect(
            .degrees(rotationX * 10),
            axis: (x: 0, y: 1, z: 0)
        )
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { value in
                    // Calculate rotation based on drag gesture
                    // Adjust sensitivity as needed
                    rotationY = value.translation.width * 0.1
                    rotationX = -value.translation.height * 0.1
                }
                .onEnded { _ in
                    // Spring back to original position
                    withAnimation(.spring()) {
                        rotationX = 0
                        rotationY = 0
                    }
                }
        )
        .onAppear {
            // Animate appearance
            withAnimation(.easeOut(duration: 0.5).delay(delay)) {
                appeared = true
            }
            // Fetch progress on appear
            Task {
                self.progress = await viewModel.getBadgeProgress(for: badge)
            }
            
            // Check if this badge was recently earned
            if UserDefaults.standard.string(forKey: "recentlyEarnedBadgeId") == badge.id {
                isRecentlyEarned = true
                // Clear the flag after a delay
                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                    UserDefaults.standard.removeObject(forKey: "recentlyEarnedBadgeId")
                    isRecentlyEarned = false
                }
            }
        }
    }
}

//#Preview {
//    let previewBadge = Badge(id: "preview", name: "Task Master", description: "Complete 10 tasks", iconName: "star.fill", requiredTaskCount: 10)
//    EnhancedBadgeCardView(badge: previewBadge, isEarned: true, viewModel: AchievementsViewModel(userId: "preview"), delay: 0.0)
//}
