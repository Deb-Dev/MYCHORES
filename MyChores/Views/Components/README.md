# UI Components

This directory contains reusable UI components that can be used throughout the MyChores application. The components are organized by category to make them easy to find and use.

## Directory Structure

- **Animations/** - Animation-related components
  - `ConfettiView.swift` - Celebration animations for achievements and milestones
  - `ParticleViews.swift` - Background particle effects for visual interest

- **Badges/** - Badge-related components
  - `BadgeCardView.swift` - Card display for individual badges
  - `BadgeDetailView.swift` - Detailed view for inspecting badges

## Usage Guidelines

### Animation Components

Animation components should be used consistently across the app to maintain a unified look and feel. For custom animations, consider using the `AnimationUtilities.swift` helpers in the Utils directory.

Example usage:

```swift
// Using particle background
ZStack {
    ParticleBackgroundView(particleCount: 15)
        .opacity(0.2)
    
    // Your content here
}

// Using confetti celebration
if showCelebration {
    ConfettiCelebrationView(count: 50)
}
```

### Badge Components

Badge components provide a consistent way to display achievements throughout the app. They support:

- Earned vs. unearned states
- Progress indicators
- 3D interactive effects
- Celebration effects for newly earned badges

Example usage:

```swift
BadgeCardView(
    badge: badge,
    isEarned: isEarned,
    progress: progressValue,
    delay: animationDelay,
    isRecentlyEarned: isRecentlyEarned,
    onAppear: {
        // Custom actions when the badge appears
    }
)
.onTapGesture {
    showingBadgeDetail = badge
}

// For detailed view
BadgeDetailView(badge: badge)
```

## Adding New Components

When adding new components:

1. Place them in the appropriate category folder
2. Make the component as reusable as possible with customizable parameters
3. Add proper documentation comments
4. Include a preview for visual testing
5. Consider making the component public for easier access
