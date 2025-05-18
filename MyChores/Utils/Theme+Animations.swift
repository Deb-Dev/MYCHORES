// 
// Theme+Animations.swift
// MyChores
//
// Created on 2025-05-17.
//

import SwiftUI

/// Theme extensions for animation-related styling
extension Theme {
    
    /// Animation durations for consistent timing throughout the app
    struct AnimationDurations {
        /// Very quick animations (0.15s)
        public static let veryShort: Double = 0.15
        
        /// Quick animations for small UI elements (0.25s)
        public static let short: Double = 0.25
        
        /// Standard animations for most UI changes (0.35s)
        public static let standard: Double = 0.35
        
        /// Longer animations for more emphasis (0.5s)
        public static let medium: Double = 0.5
        
        /// Extended animations for major transitions (0.75s)
        public static let long: Double = 0.75
        
        /// Very long animations for dramatic effects (1.0s+)
        public static let veryLong: Double = 1.0
    }
    
    /// Animation curves for consistent easing throughout the app
    struct AnimationCurves {
        /// Standard ease-in-out for most animations
        public static func standard<V: Equatable>(value: V) -> Animation {
            return .easeInOut(duration: AnimationDurations.standard)
        }
        
        /// Spring animation for bouncy, energetic effects
        public static func spring<V: Equatable>(value: V) -> Animation {
            return .spring(response: 0.4, dampingFraction: 0.7)
        }
        
        /// Gentle spring with less bounce
        public static func gentleSpring<V: Equatable>(value: V) -> Animation {
            return .spring(response: 0.5, dampingFraction: 0.8)
        }
        
        /// Emphasized spring for attention-grabbing elements
        public static func emphasizedSpring<V: Equatable>(value: V) -> Animation {
            return .spring(response: 0.6, dampingFraction: 0.6)
        }
        
        /// Linear animation for continuous effects like rotation
        public static func linear<V: Equatable>(duration: Double, value: V) -> Animation {
            return .linear(duration: duration)
        }
    }
    
    /// Animation delays for staggered animations
    struct AnimationDelays {
        /// No delay
        public static let none: Double = 0.0
        
        /// Minimal delay for subtle staggering (0.05s)
        public static let minimal: Double = 0.05
        
        /// Short delay for noticeable staggering (0.1s)
        public static let short: Double = 0.1
        
        /// Medium delay for emphasized staggering (0.2s)
        public static let medium: Double = 0.2
        
        /// Long delay for dramatic staggering (0.3s+)
        public static let long: Double = 0.3
        
        /// Helper to calculate staggered delay based on index
        public static func staggered(index: Int, baseDelay: Double = 0.0, staggerAmount: Double = minimal) -> Double {
            return baseDelay + (Double(index) * staggerAmount)
        }
    }
}

// Extension to make animations more readable in view code
public extension View {
    
    /// Apply a standard animation with optional delay
    func withStandardAnimation<V: Equatable>(value: V, delay: Double = 0) -> some View {
        self.animation(
            .easeInOut(duration: Theme.AnimationDurations.standard).delay(delay),
            value: value
        )
    }
    
    /// Apply a spring animation with optional delay
    func withSpringAnimation<V: Equatable>(value: V, delay: Double = 0) -> some View {
        self.animation(
            .spring(response: 0.4, dampingFraction: 0.7).delay(delay),
            value: value
        )
    }
    
    /// Apply a staggered appearance animation
    func withStaggeredAppearance<V: Equatable>(value: V, index: Int, baseDelay: Double = 0) -> some View {
        let delay = Theme.AnimationDelays.staggered(index: index, baseDelay: baseDelay)
        return self.animation(
            .spring(response: 0.4, dampingFraction: 0.7).delay(delay),
            value: value
        )
    }
}
