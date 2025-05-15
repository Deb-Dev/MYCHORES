// ChoreProgressView.swift
// MyChores
//
// Created on 2025-05-14.
//

import SwiftUI

/// A circular progress view showing chore completion progress
struct ChoreProgressView: View {
    let completedCount: Int
    let totalCount: Int
    let size: CGFloat
    
    @State private var animateProgress = false
    
    private var progress: CGFloat {
        if totalCount == 0 {
            return 1.0 // Show full circle when no chores
        }
        return CGFloat(completedCount) / CGFloat(totalCount)
    }
    
    var body: some View {
        ZStack {
            // Track Circle
            Circle()
                .stroke(
                    Theme.Colors.primary.opacity(0.2),
                    lineWidth: size / 15
                )
            
            // Progress Circle
            Circle()
                .trim(from: 0, to: animateProgress ? progress : 0)
                .stroke(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Theme.Colors.primary,
                            Theme.Colors.primary.opacity(0.7)
                        ]),
                        startPoint: .leading,
                        endPoint: .trailing
                    ),
                    style: StrokeStyle(
                        lineWidth: size / 15,
                        lineCap: .round
                    )
                )
                .rotationEffect(.degrees(-90))
                .animation(.easeOut(duration: 1.0), value: animateProgress)
            
            // Percentage Text
            VStack(spacing: 0) {
                Text("\(Int(progress * 100))%")
                    .font(.system(size: size / 4, weight: .bold, design: .rounded))
                    .foregroundColor(Theme.Colors.text)
                
                Text("\(completedCount)/\(totalCount)")
                    .font(.system(size: size / 8, weight: .medium, design: .rounded))
                    .foregroundColor(Theme.Colors.textSecondary)
            }
        }
        .frame(width: size, height: size)
        .onAppear {
            // Animate after a slight delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                animateProgress = true
            }
        }
    }
}

/// A combined info card showing chore metrics and progress
struct ChoreMetricsCard: View {
    let completedCount: Int
    let totalCount: Int
    let overdueCount: Int
    
    @State private var animateIn = false
    
    var body: some View {
        ZStack {
            // Card background with gradient
            RoundedRectangle(cornerRadius: Theme.Dimensions.cornerRadiusMedium)
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Theme.Colors.cardBackground,
                            Theme.Colors.cardBackground.opacity(0.95)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
            
            // Decorative elements
            Circle()
                .fill(Theme.Colors.primary.opacity(0.07))
                .frame(width: 100, height: 100)
                .offset(x: -120, y: -60)
            
            Circle()
                .fill(Theme.Colors.secondary.opacity(0.07))
                .frame(width: 80, height: 80)
                .offset(x: 140, y: 60)
            
            // Content
            HStack(spacing: 16) {
                // Progress circle
                ChoreProgressView(
                    completedCount: completedCount,
                    totalCount: totalCount,
                    size: 100
                )
                .scaleEffect(animateIn ? 1.0 : 0.7)
                .opacity(animateIn ? 1.0 : 0.0)
                .padding(.leading, 20)
                
                // Statistics
                VStack(alignment: .leading, spacing: 12) {
                    // Total chores
                    HStack(spacing: 8) {
                        ZStack {
                            Circle()
                                .fill(Theme.Colors.primary.opacity(0.15))
                                .frame(width: 32, height: 32)
                            
                            Image(systemName: "checklist")
                                .foregroundColor(Theme.Colors.primary)
                                .font(.system(size: 16, weight: .semibold))
                        }
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Total")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(Theme.Colors.textSecondary)
                            
                            Text("\(totalCount) chores")
                                .font(.system(size: 16, weight: .bold, design: .rounded))
                                .foregroundColor(Theme.Colors.text)
                        }
                    }
                    .offset(x: animateIn ? 0 : 50)
                    .opacity(animateIn ? 1.0 : 0.0)
                    
                    // Completed chores
                    HStack(spacing: 8) {
                        ZStack {
                            Circle()
                                .fill(Theme.Colors.success.opacity(0.15))
                                .frame(width: 32, height: 32)
                            
                            Image(systemName: "checkmark.circle")
                                .foregroundColor(Theme.Colors.success)
                                .font(.system(size: 16, weight: .semibold))
                        }
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Completed")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(Theme.Colors.textSecondary)
                            
                            Text("\(completedCount) chores")
                                .font(.system(size: 16, weight: .bold, design: .rounded))
                                .foregroundColor(Theme.Colors.text)
                        }
                    }
                    .offset(x: animateIn ? 0 : 50)
                    .opacity(animateIn ? 1.0 : 0.0)
                    
                    // Overdue chores
                    if overdueCount > 0 {
                        HStack(spacing: 8) {
                            ZStack {
                                Circle()
                                    .fill(Theme.Colors.error.opacity(0.15))
                                    .frame(width: 32, height: 32)
                                
                                Image(systemName: "exclamationmark.circle")
                                    .foregroundColor(Theme.Colors.error)
                                    .font(.system(size: 16, weight: .semibold))
                            }
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Overdue")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(Theme.Colors.textSecondary)
                                
                                Text("\(overdueCount) chores")
                                    .font(.system(size: 16, weight: .bold, design: .rounded))
                                    .foregroundColor(Theme.Colors.text)
                            }
                        }
                        .offset(x: animateIn ? 0 : 50)
                        .opacity(animateIn ? 1.0 : 0.0)
                    }
                }
                .padding(.trailing, 20)
                
                Spacer()
            }
            .padding(.vertical, 16)
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.1)) {
                animateIn = true
            }
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        ChoreProgressView(
            completedCount: 7,
            totalCount: 10,
            size: 150
        )
        
        ChoreMetricsCard(
            completedCount: 7,
            totalCount: 10,
            overdueCount: 2
        )
        .padding(.horizontal, 16)
    }
    .padding(.vertical, 50)
    .background(Theme.Colors.background)
}
