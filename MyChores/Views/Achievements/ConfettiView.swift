// 
// ConfettiView.swift
// MyChores
//
// Created on 2025-05-17.
//

import SwiftUI

/// A view that displays a confetti celebration animation
struct ConfettiCelebrationView: View {
    @State private var isAnimating = false
    let count: Int
    
    var body: some View {
        ZStack {
            ForEach(0..<count, id: \.self) { index in
                ConfettiPiece(color: confettiColor(for: index), rotation: Double.random(in: 0...360))
                    .offset(x: isAnimating ? randomOffset() : 0, y: isAnimating ? 500 : -100)
                    .opacity(isAnimating ? 0 : 1)
                    .animation(
                        Animation.timingCurve(0.05, 0.7, 0.3, 1, duration: Double.random(in: 1.0...3.0))
                            .delay(Double.random(in: 0...0.5)),
                        value: isAnimating
                    )
            }
        }
        .onAppear {
            isAnimating = true
        }
    }
    
    private func randomOffset() -> CGFloat {
        return CGFloat.random(in: -150...150)
    }
    
    private func confettiColor(for index: Int) -> Color {
        let colors: [Color] = [
            Theme.Colors.primary,
            Theme.Colors.secondary,
            Theme.Colors.accent,
            Theme.Colors.success
        ]
        return colors[index % colors.count]
    }
}

/// A single piece of confetti
struct ConfettiPiece: View {
    let color: Color
    let rotation: Double
    
    var body: some View {
        Rectangle()
            .fill(color)
            .frame(width: 10, height: 10)
            .rotationEffect(.degrees(rotation))
    }
}

#Preview {
    ZStack {
        Color.black.opacity(0.1)
        ConfettiCelebrationView(count: 50)
    }
}
