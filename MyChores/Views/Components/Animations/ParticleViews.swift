// 
// ParticleViews.swift
// MyChores
//
// Created on 2025-05-17.
// Moved to Components/Animations on 2025-05-17.
//

import SwiftUI

/// A view that displays subtle floating particles in the background
public struct ParticleBackgroundView: View {
    let particleCount: Int
    
    public init(particleCount: Int = 15) {
        self.particleCount = particleCount
    }
    
    public var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(0..<particleCount, id: \.self) { index in
                    ParticleView(
                        size: CGFloat.random(in: 4...12),
                        position: randomPosition(in: geometry.size),
                        color: randomColor(),
                        animationDuration: Double.random(in: 20...40)
                    )
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
    
    private func randomPosition(in size: CGSize) -> CGPoint {
        return CGPoint(
            x: CGFloat.random(in: 0...size.width),
            y: CGFloat.random(in: 0...size.height)
        )
    }
    
    private func randomColor() -> Color {
        let colors = [
            Theme.Colors.primary,
            Theme.Colors.secondary,
            Theme.Colors.accent
        ]
        return colors.randomElement()!.opacity(0.3)
    }
}

/// A single floating particle view
struct ParticleView: View {
    let size: CGFloat
    let position: CGPoint
    let color: Color
    let animationDuration: Double
    
    @State private var isAnimating = false
    
    var body: some View {
        Circle()
            .fill(color)
            .frame(width: size, height: size)
            .position(x: position.x, y: position.y)
            .offset(
                x: isAnimating ? CGFloat.random(in: -50...50) : 0,
                y: isAnimating ? CGFloat.random(in: -50...50) : 0
            )
            .animation(
                Animation.easeInOut(duration: animationDuration)
                    .repeatForever(autoreverses: true),
                value: isAnimating
            )
            .onAppear {
                isAnimating = true
            }
    }
}

#Preview {
    ZStack {
        Color.black.opacity(0.1)
        ParticleBackgroundView()
    }
}
