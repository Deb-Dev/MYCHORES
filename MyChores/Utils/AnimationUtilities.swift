// 
// AnimationUtilities.swift
// MyChores
//
// Created on 2025-05-17.
//

import SwiftUI

/// Utility struct for common animations used throughout the app
public struct AnimationUtilities {
    
    /// Creates a staggered appearance animation
    /// - Parameters:
    ///   - duration: Animation duration
    ///   - delay: Delay before animation starts
    ///   - dampingFraction: Spring animation damping fraction (0 to 1)
    /// - Returns: An Animation that can be used with SwiftUI views
    public static func staggeredAppearance(
        duration: Double = 0.6, 
        delay: Double = 0.0, 
        dampingFraction: Double = 0.7
    ) -> Animation {
        return .spring(response: duration, dampingFraction: dampingFraction)
            .delay(delay)
    }
    
    /// Creates a fade-in animation
    /// - Parameters:
    ///   - duration: Animation duration
    ///   - delay: Delay before animation starts
    /// - Returns: An Animation that can be used with SwiftUI views
    public static func fadeIn(
        duration: Double = 0.5, 
        delay: Double = 0.0
    ) -> Animation {
        return .easeOut(duration: duration)
            .delay(delay)
    }
    
    /// Creates a continuous rotation animation
    /// - Parameters:
    ///   - duration: Time for one complete rotation
    ///   - clockwise: Rotation direction
    /// - Returns: An Animation that can be used with SwiftUI views
    public static func continuousRotation(
        duration: Double = 20.0, 
        clockwise: Bool = true
    ) -> Animation {
        return .linear(duration: duration)
            .repeatForever(autoreverses: false)
    }
    
    /// Creates a pulsing animation
    /// - Parameters:
    ///   - duration: Time for one pulse cycle
    ///   - minScale: Minimum scale factor
    ///   - maxScale: Maximum scale factor
    /// - Returns: An Animation that can be used with SwiftUI views
    public static func pulsing(
        duration: Double = 1.5, 
        minScale: Double = 0.8, 
        maxScale: Double = 1.2
    ) -> Animation {
        return .easeInOut(duration: duration)
            .repeatForever(autoreverses: true)
    }
    
    /// Creates a shimmering effect animation
    /// - Parameters:
    ///   - duration: Time for one shimmer pass
    ///   - delay: Delay before animation starts
    /// - Returns: An Animation that can be used with SwiftUI views
    public static func shimmer(
        duration: Double = 1.5, 
        delay: Double = 0.0
    ) -> Animation {
        return .easeInOut(duration: duration)
            .delay(delay)
            .repeatForever(autoreverses: false)
    }
    
    /// Extension to stagger animations in a collection
    /// - Parameters:
    ///   - index: Current index in the collection
    ///   - baseDelay: Base delay before any animation starts
    ///   - staggerAmount: Time between each item's animation start
    /// - Returns: Calculated delay for this specific index
    public static func staggeredDelay(
        for index: Int, 
        baseDelay: Double = 0.0, 
        staggerAmount: Double = 0.05
    ) -> Double {
        return baseDelay + (Double(index) * staggerAmount)
    }
}

// View extension for common animation modifiers
public extension View {
    
    /// Adds a staggered appearance animation to a view
    /// - Parameters:
    ///   - value: The value to animate
    ///   - delay: Animation delay
    ///   - duration: Animation duration
    /// - Returns: A view with the animation applied
    func staggeredAppearance<V: Equatable>(
        value: V,
        delay: Double = 0.0,
        duration: Double = 0.6
    ) -> some View {
        self.animation(
            AnimationUtilities.staggeredAppearance(
                duration: duration,
                delay: delay
            ),
            value: value
        )
    }
    
    /// Adds a continuous rotation animation to a view
    /// - Parameter value: The value to animate
    /// - Returns: A view with the rotation animation applied
    func continuousRotation<V: Equatable>(value: V) -> some View {
        self.animation(
            AnimationUtilities.continuousRotation(),
            value: value
        )
    }
}
