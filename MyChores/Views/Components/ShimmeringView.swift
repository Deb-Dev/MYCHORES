// ShimmeringView.swift
// MyChores
//
// Created on 2025-05-03.
//

import SwiftUI

/// A view modifier that adds a shimmering effect to any view
/// Used for loading states to indicate content is being fetched
struct Shimmering: ViewModifier {
    let active: Bool
    let duration: Double
    let bounce: Bool
    
    func body(content: Content) -> some View {
        content
            .overlay(
                Group {
                    if active {
                        ShimmeringView(duration: duration, bounce: bounce)
                    }
                }
            )
    }
}

/// The actual view that implements the shimmer effect
private struct ShimmeringView: View {
    let duration: Double
    let bounce: Bool
    
    @State private var offset: CGFloat = -0.7
    
    var body: some View {
        GeometryReader { geo in
            LinearGradient(
                stops: [
                    .init(color: .clear, location: offset - 0.7),
                    .init(color: .white.opacity(0.5), location: offset - 0.4),
                    .init(color: .white.opacity(0.7), location: offset),
                    .init(color: .white.opacity(0.5), location: offset + 0.4),
                    .init(color: .clear, location: offset + 0.7)
                ],
                startPoint: .leading,
                endPoint: .trailing
            )
            .blendMode(.screen)
            .onAppear {
                withAnimation(
                    Animation.linear(duration: duration)
                    .repeatForever(autoreverses: bounce)
                ) {
                    offset = 1.7
                }
            }
        }
        .mask(
            Rectangle()
        )
    }
}

extension View {
    /// Apply a shimmering effect to the view
    /// - Parameters:
    ///   - active: Whether the shimmer is active
    ///   - duration: Duration of the animation
    ///   - bounce: Whether the animation bounces back and forth
    /// - Returns: The view with the shimmer effect applied
    func shimmering(
        active: Bool = true,
        duration: Double = 1.5,
        bounce: Bool = false
    ) -> some View {
        modifier(Shimmering(active: active, duration: duration, bounce: bounce))
    }
}
