// 
// BadgeDetailView.swift
// MyChores
//
// Created on 2025-05-17.
//

import SwiftUI

/// Enhanced detailed view for a single badge
struct BadgeDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var animateDetail = false
    @State private var showShine = false

    let badge: Badge

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 32) {
                    // Badge icon with animated effect
                    VStack(spacing: 24) {
                        ZStack {
                            // Outer glow
                            Circle()
                                .fill(Theme.Colors.accent.opacity(0.15))
                                .frame(width: 180, height: 180)
                            
                            // Middle ring
                            Circle()
                                .stroke(Theme.Colors.accent.opacity(0.3), lineWidth: 3)
                                .frame(width: 160, height: 160)
                            
                            // Animated shine effect that passes across the badge
                            if showShine {
                                Rectangle()
                                    .fill(
                                        LinearGradient(
                                            gradient: Gradient(colors: [
                                                Color.white.opacity(0)
                                            ]),
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .frame(width: 30, height: 200)
                                    .rotationEffect(.degrees(45))
                                    .offset(x: animateDetail ? 100 : -100)
                                    .animation(
                                        Animation.easeOut(duration: 1.5)
                                            .repeatForever(autoreverses: false)
                                            .delay(1.5),
                                        value: animateDetail
                                    )
                                    .mask(
                                        Circle()
                                            .frame(width: 160, height: 160)
                                    )
                                    .blendMode(.screen)
                            }
                            
                            // Badge icon
                            Image(systemName: badge.iconName)
                                .font(.system(size: 80))
                                .foregroundColor(Theme.Colors.accent)
                                .scaleEffect(animateDetail ? 1.0 : 0.8)
                                .opacity(animateDetail ? 1.0 : 0)
                                .animation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.1), value: animateDetail)
                            
                            // Animated particles - staggered circles
                            ForEach(0..<12) { i in
                                let radius = 90.0
                                let angle = Double(i) * .pi / 6
                                
                                Circle()
                                    .fill(Theme.Colors.accent.opacity(0.3))
                                    .frame(width: i % 2 == 0 ? 12 : 8, height: i % 2 == 0 ? 12 : 8)
                                    .offset(
                                        x: animateDetail ? radius * cos(angle) : 0,
                                        y: animateDetail ? radius * sin(angle) : 0
                                    )
                                    .scaleEffect(animateDetail ? 1.0 : 0)
                                    .opacity(animateDetail ? 1.0 : 0)
                                    .animation(
                                        .spring(response: 0.8, dampingFraction: 0.6)
                                        .delay(0.2 + Double(i) * 0.03),
                                        value: animateDetail
                                    )
                            }
                        }

                        Text(badge.name)
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(Theme.Colors.text)
                            .multilineTextAlignment(.center)
                            .opacity(animateDetail ? 1.0 : 0)
                            .offset(y: animateDetail ? 0 : 20)
                            .animation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.3), value: animateDetail)
                    }
                    .padding(.top, 24)

                    // Badge description with background card
                    VStack(spacing: 16) {
                        Text("Description")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(Theme.Colors.text)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        Text(badge.description)
                            .font(.system(size: 16))
                            .foregroundColor(Theme.Colors.textSecondary)
                            .multilineTextAlignment(.leading)
                            .padding(.bottom, 8)
                            .lineSpacing(4)
                    }
                    .padding(24)
                    .background(Theme.Colors.cardBackground)
                    .cornerRadius(Theme.Dimensions.cornerRadiusMedium)
                    .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                    .padding(.horizontal, 20)
                    .opacity(animateDetail ? 1.0 : 0)
                    .offset(y: animateDetail ? 0 : 20)
                    .animation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.4), value: animateDetail)
                    
                    // Requirements section (if applicable)
                    if let requiredTasks = badge.requiredTaskCount {
                        VStack(spacing: 16) {
                            Text("Requirements")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(Theme.Colors.text)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            
                            HStack(spacing: 16) {
                                ZStack {
                                    Circle()
                                        .fill(Theme.Colors.primary.opacity(0.1))
                                        .frame(width: 40, height: 40)
                                    
                                    Image(systemName: "checklist")
                                        .font(.system(size: 18))
                                        .foregroundColor(Theme.Colors.primary)
                                }
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Complete \(requiredTasks) tasks")
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(Theme.Colors.text)
                                    
                                    Text("Keep completing chores to earn this badge")
                                        .font(.system(size: 14))
                                        .foregroundColor(Theme.Colors.textSecondary)
                                }
                                
                                Spacer()
                            }
                            .padding(16)
                            .background(Theme.Colors.primary.opacity(0.05))
                            .cornerRadius(12)
                        }
                        .padding(24)
                        .background(Theme.Colors.cardBackground)
                        .cornerRadius(Theme.Dimensions.cornerRadiusMedium)
                        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                        .padding(.horizontal, 20)
                        .opacity(animateDetail ? 1.0 : 0)
                        .offset(y: animateDetail ? 0 : 20)
                        .animation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.5), value: animateDetail)
                    }

                    Spacer()
                }
                .padding(.bottom, 32)
            }
            .background(
                ZStack {
                    Theme.Colors.background
                    
                    // Subtle background decoration
                    ForEach(0..<20) { i in
                        Image(systemName: "rosette")
                            .font(.system(size: 40))
                            .foregroundColor(Theme.Colors.primary.opacity(0.02))
                            .position(
                                x: CGFloat.random(in: 0...UIScreen.main.bounds.width),
                                y: CGFloat.random(in: 0...UIScreen.main.bounds.height)
                            )
                            .rotationEffect(.degrees(Double.random(in: 0...360)))
                    }
                }
                .ignoresSafeArea()
            )
            .navigationTitle("Badge Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("Done") {
                        withAnimation {
                            dismiss()
                        }
                    }
                }
            }
            .onAppear {
                animateDetail = true
                showShine = true
                
                // Play haptic feedback when viewing a badge
                let generator = UINotificationFeedbackGenerator()
                generator.notificationOccurred(.success)
            }
            .onDisappear {
                animateDetail = false
                showShine = false
            }
        }
    }
}

//#Preview {
//    let previewBadge = Badge(id: "preview", name: "Task Master", description: "Complete 10 tasks", iconName: "star.fill", requiredTaskCount: 10)
//    BadgeDetailView(badge: previewBadge)
//}
