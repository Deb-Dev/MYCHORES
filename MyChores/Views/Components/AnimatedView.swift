// AnimatedView.swift
// MyChores
//
// Created on 2025-05-03.
//

import SwiftUI

/// A collection of animated view modifiers to add delight to the UI
struct AnimatedViewModifiers {
    
    // MARK: - Pulse Animation
    
    /// Applies a pulsing animation to a view
    struct PulseEffect: ViewModifier {
        @State private var isPulsing = false
        
        /// The scale to pulse between
        let minScale: CGFloat
        
        /// The maximum scale to reach
        let maxScale: CGFloat
        
        /// The duration of one pulse cycle
        let duration: Double
        
        /// Initialize with custom parameters
        init(minScale: CGFloat = 0.95, maxScale: CGFloat = 1.05, duration: Double = 1.5) {
            self.minScale = minScale
            self.maxScale = maxScale
            self.duration = duration
        }
        
        func body(content: Content) -> some View {
            content
                .scaleEffect(isPulsing ? maxScale : minScale)
                .animation(Animation.easeInOut(duration: duration).repeatForever(autoreverses: true), value: isPulsing)
                .onAppear {
                    isPulsing = true
                }
        }
    }
    
    // MARK: - Shimmer Animation
    
    /// Applies a shimmering effect to a view
    struct ShimmerEffect: ViewModifier {
        @State private var isAnimating = false
        
        func body(content: Content) -> some View {
            content
                .overlay(
                    GeometryReader { geometry in
                        ZStack {
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    .clear,
                                    Color.white.opacity(0.2),
                                    .clear
                                ]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                            .frame(width: geometry.size.width * 3)
                            .offset(x: isAnimating ? geometry.size.width : -geometry.size.width)
                        }
                        .mask(Rectangle().fill(LinearGradient(
                            gradient: Gradient(colors: [.clear, .black, .clear]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )))
                    }
                )
                .onAppear {
                    withAnimation(Animation.linear(duration: 2.0).repeatForever(autoreverses: false)) {
                        isAnimating = true
                    }
                }
        }
    }
    
    // MARK: - Floating Animation
    
    /// Makes a view float up and down subtly
    struct FloatingEffect: ViewModifier {
        @State private var isFloating = false
        
        /// The distance to float up and down
        let distance: CGFloat
        
        /// The duration of one float cycle
        let duration: Double
        
        /// Initialize with custom parameters
        init(distance: CGFloat = 5, duration: Double = 2.5) {
            self.distance = distance
            self.duration = duration
        }
        
        func body(content: Content) -> some View {
            content
                .offset(y: isFloating ? -distance : distance)
                .animation(Animation.easeInOut(duration: duration).repeatForever(autoreverses: true), value: isFloating)
                .onAppear {
                    isFloating = true
                }
        }
    }
    
    // MARK: - Badge Bounce Animation
    
    /// Applies a bounce animation when a view appears
    struct BadgeBounce: ViewModifier {
        @State private var animate = false
        
        func body(content: Content) -> some View {
            content
                .scaleEffect(animate ? 1.0 : 0.5)
                .opacity(animate ? 1.0 : 0.0)
                .animation(.spring(response: 0.5, dampingFraction: 0.6), value: animate)
                .onAppear {
                    animate = true
                }
        }
    }
    
    // MARK: - Slide In Animation
    
    /// Direction for slide in animation
    enum SlideDirection {
        case left, right, top, bottom
    }
    
    /// Slides a view in from a specified direction
    struct SlideIn: ViewModifier {
        @State private var hasSlid = false
        
        /// The direction to slide from
        let direction: SlideDirection
        
        /// The distance to slide
        let distance: CGFloat
        
        /// Initialize with custom parameters
        init(direction: SlideDirection, distance: CGFloat = 50) {
            self.direction = direction
            self.distance = distance
        }
        
        func body(content: Content) -> some View {
            content
                .offset(
                    x: slideXOffset,
                    y: slideYOffset
                )
                .opacity(hasSlid ? 1.0 : 0.0)
                .animation(.spring(response: 0.4, dampingFraction: 0.7), value: hasSlid)
                .onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        hasSlid = true
                    }
                }
        }
        
        private var slideXOffset: CGFloat {
            if !hasSlid {
                switch direction {
                case .left: return -distance
                case .right: return distance
                default: return 0
                }
            }
            return 0
        }
        
        private var slideYOffset: CGFloat {
            if !hasSlid {
                switch direction {
                case .top: return -distance
                case .bottom: return distance
                default: return 0
                }
            }
            return 0
        }
    }
    
    // MARK: - Gradient Animation
    
    /// Animates the colors of a gradient
    struct AnimatedGradient: ViewModifier {
        @State private var animate = false
        
        /// The gradient colors to animate between
        let colors: [Color]
        
        /// The duration of the animation cycle
        let duration: Double
        
        /// Initialize with custom parameters
        init(colors: [Color], duration: Double = 3.0) {
            self.colors = colors
            self.duration = duration
        }
        
        func body(content: Content) -> some View {
            content
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: colors),
                        startPoint: animate ? .topLeading : .bottomTrailing,
                        endPoint: animate ? .bottomTrailing : .topLeading
                    )
                )
                .animation(Animation.easeInOut(duration: duration).repeatForever(autoreverses: true), value: animate)
                .onAppear {
                    animate = true
                }
        }
    }
}

// MARK: - View Extensions

extension View {
    /// Adds a pulsing animation to the view
    func pulsingAnimation(minScale: CGFloat = 0.95, maxScale: CGFloat = 1.05, duration: Double = 1.5) -> some View {
        self.modifier(AnimatedViewModifiers.PulseEffect(minScale: minScale, maxScale: maxScale, duration: duration))
    }
    
    /// Adds a shimmer effect to the view
    func shimmerEffect() -> some View {
        self.modifier(AnimatedViewModifiers.ShimmerEffect())
    }
    
    /// Makes the view float up and down subtly
    func floatingAnimation(distance: CGFloat = 5, duration: Double = 2.5) -> some View {
        self.modifier(AnimatedViewModifiers.FloatingEffect(distance: distance, duration: duration))
    }
    
    /// Applies a bounce animation when the view appears
    func badgeBounceEffect() -> some View {
        self.modifier(AnimatedViewModifiers.BadgeBounce())
    }
    
    /// Slides the view in from a specified direction
    func slideInAnimation(from direction: AnimatedViewModifiers.SlideDirection, distance: CGFloat = 50) -> some View {
        self.modifier(AnimatedViewModifiers.SlideIn(direction: direction, distance: distance))
    }
    
    /// Animates the gradient background of the view
    func animatedGradient(colors: [Color], duration: Double = 3.0) -> some View {
        self.modifier(AnimatedViewModifiers.AnimatedGradient(colors: colors, duration: duration))
    }
}

// MARK: - Preview

struct AnimatedView_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Theme.Colors.background.ignoresSafeArea()
            
            VStack(spacing: 30) {
                Text("Pulse Animation")
                    .font(Theme.Typography.bodyFontSystem)
                    .padding()
                    .background(Theme.Colors.primary.opacity(0.2))
                    .cornerRadius(10)
                    .pulsingAnimation()
                
                Text("Shimmer Effect")
                    .font(Theme.Typography.bodyFontSystem)
                    .padding()
                    .background(Theme.Colors.primary)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                    .shimmerEffect()
                
                Text("Floating Animation")
                    .font(Theme.Typography.bodyFontSystem)
                    .padding()
                    .background(Theme.Colors.accent)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                    .floatingAnimation()
                
                Text("Badge Bounce Effect")
                    .font(Theme.Typography.bodyFontSystem)
                    .padding()
                    .background(Theme.Colors.secondary)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                    .badgeBounceEffect()
                
                HStack(spacing: 20) {
                    Text("Slide Left")
                        .font(Theme.Typography.bodyFontSystem)
                        .padding()
                        .background(Theme.Colors.success)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                        .slideInAnimation(from: .left)
                    
                    Text("Slide Right")
                        .font(Theme.Typography.bodyFontSystem)
                        .padding()
                        .background(Theme.Colors.success)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                        .slideInAnimation(from: .right)
                }
                
                Text("Animated Gradient")
                    .font(Theme.Typography.bodyFontSystem)
                    .padding()
                    .foregroundColor(.white)
                    .cornerRadius(10)
                    .animatedGradient(colors: [
                        Theme.Colors.primary,
                        Theme.Colors.secondary,
                        Theme.Colors.accent
                    ])
            }
            .padding()
        }
    }
}
