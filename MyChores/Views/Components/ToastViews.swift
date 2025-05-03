// ToastViews.swift
// MyChores
//
// Created on 2025-05-02.
//

import SwiftUI

/// Displays a toast message when points are earned
struct PointsEarnedToastView: View {
    let message: String
    let onDismiss: () -> Void
    
    var body: some View {
        VStack {
            Spacer()
            
            Text(message)
                .font(Theme.Typography.bodyFontSystem.bold())
                .padding()
                .background(Theme.Colors.success)
                .foregroundColor(.white)
                .cornerRadius(Theme.Dimensions.cornerRadiusMedium)
                .padding(.bottom, 16)
                .transition(.move(edge: .bottom).combined(with: .opacity))
        }
        .zIndex(100)
        .animation(.spring(), value: message)
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                onDismiss()
            }
        }
    }
}

/// Displays a toast message when a badge is earned
struct BadgeEarnedToastView: View {
    let message: String
    let onDismiss: () -> Void
    
    var body: some View {
        VStack {
            Text(message)
                .font(Theme.Typography.bodyFontSystem.bold())
                .padding()
                .background(Theme.Colors.accent)
                .foregroundColor(.white)
                .cornerRadius(Theme.Dimensions.cornerRadiusMedium)
                .padding(.top, 16)
                .transition(.move(edge: .top).combined(with: .opacity))
            
            Spacer()
        }
        .zIndex(100)
        .animation(.spring(), value: message)
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                onDismiss()
            }
        }
    }
}
