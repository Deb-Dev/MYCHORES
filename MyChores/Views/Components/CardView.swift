// CardView.swift
// MyChores
//
// Created on 2025-05-03.
//

import SwiftUI

/// A reusable card view component for consistent styling across the app
struct CardView<Content: View>: View {
    // MARK: - Properties
    
    /// The content inside the card
    let content: Content
    
    /// Optional icon to display in the header (if title is provided)
    let icon: String?
    
    /// Optional title for the card
    let title: String?
    
    /// Whether to apply a shadow to the card
    let withShadow: Bool
    
    /// Background color of the card, defaults to card background color
    let backgroundColor: Color
    
    /// Padding around the content
    let padding: EdgeInsets
    
    /// Whether to add a colored accent border on the leading edge
    let showLeadingAccent: Bool
    
    /// Color for the leading accent if enabled
    let accentColor: Color
    
    /// Whether to animate the card with subtle effects
    let animated: Bool
    
    // MARK: - Initialization
    
    /// Initialize a card with content
    /// - Parameters:
    ///   - icon: Optional icon to display in the header
    ///   - title: Optional title for the card
    ///   - withShadow: Whether to apply a shadow (defaults to true)
    ///   - backgroundColor: Background color (defaults to cardBackground)
    ///   - padding: Padding around the content (defaults to medium on all sides)
    ///   - showLeadingAccent: Whether to show a colored accent on the leading edge
    ///   - accentColor: Color for the accent if enabled
    ///   - animated: Whether to add subtle animations to the card
    ///   - content: The content to display inside the card
    init(
        icon: String? = nil,
        title: String? = nil,
        withShadow: Bool = true,
        backgroundColor: Color = Theme.Colors.cardBackground,
        padding: EdgeInsets = EdgeInsets(
            top: Theme.Dimensions.paddingMedium,
            leading: Theme.Dimensions.paddingMedium,
            bottom: Theme.Dimensions.paddingMedium,
            trailing: Theme.Dimensions.paddingMedium
        ),
        showLeadingAccent: Bool = false,
        accentColor: Color = Theme.Colors.primary,
        animated: Bool = false,
        @ViewBuilder content: () -> Content
    ) {
        self.icon = icon
        self.title = title
        self.withShadow = withShadow
        self.backgroundColor = backgroundColor
        self.padding = padding
        self.showLeadingAccent = showLeadingAccent
        self.accentColor = accentColor
        self.animated = animated
        self.content = content()
    }
    
    // MARK: - Body
    
    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Dimensions.paddingMedium) {
            // Header if title exists
            if let title = title {
                HStack(spacing: Theme.Dimensions.paddingSmall) {
                    if let icon = icon {
                        Image(systemName: icon)
                            .font(.system(size: Theme.Dimensions.iconSizeMedium, weight: .semibold))
                            .foregroundColor(accentColor)
                    }
                    
                    Text(title)
                        .font(Theme.Typography.subheadingFontSystem.weight(.semibold))
                        .foregroundColor(Theme.Colors.text)
                }
            }
            
            // Content
            content
        }
        .padding(padding)
        .background(
            ZStack {
                // Main background
                RoundedRectangle(cornerRadius: Theme.Dimensions.cornerRadiusMedium)
                    .fill(backgroundColor)
                
                // Leading accent if enabled
                if showLeadingAccent {
                    HStack {
                        Rectangle()
                            .fill(accentColor)
                            .frame(width: 4)
                        
                        Spacer()
                    }
                    .mask(
                        RoundedRectangle(cornerRadius: Theme.Dimensions.cornerRadiusMedium)
                    )
                }
            }
        )
        .cornerRadius(Theme.Dimensions.cornerRadiusMedium)
        .if(withShadow) { view in
            view.shadow(
                color: Color.black.opacity(0.1),
                radius: 8,
                x: 0,
                y: 3
            )
        }
        .if(animated) { view in
            view.modifier(AnimatedViewModifiers.PulseEffect(minScale: 0.98, maxScale: 1.0, duration: 2.0))
        }
    }
}

// MARK: - Conditional Modifier

extension View {
    /// Apply a modifier conditionally
    /// - Parameters:
    ///   - condition: The condition to check
    ///   - transform: The transform to apply if condition is true
    /// - Returns: Modified view if condition is true, otherwise the original view
    @ViewBuilder func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
}

// MARK: - Preview

struct CardView_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Theme.Colors.background.ignoresSafeArea()
            
            VStack(spacing: 20) {
                // Standard card
                CardView {
                    Text("Simple card with content")
                        .font(Theme.Typography.bodyFontSystem)
                        .foregroundColor(Theme.Colors.text)
                }
                
                // Card with title
                CardView(title: "Card With Title") {
                    Text("This card has a title")
                        .font(Theme.Typography.bodyFontSystem)
                        .foregroundColor(Theme.Colors.text)
                }
                
                // Card with title and icon
                CardView(icon: "star.fill", title: "Featured Card") {
                    Text("This card has a title and icon")
                        .font(Theme.Typography.bodyFontSystem)
                        .foregroundColor(Theme.Colors.text)
                }
                
                // Card without shadow
                CardView(withShadow: false) {
                    Text("Card without shadow")
                        .font(Theme.Typography.bodyFontSystem)
                        .foregroundColor(Theme.Colors.text)
                }
                
                // Card with custom background
                CardView(backgroundColor: Theme.Colors.primary.opacity(0.1)) {
                    Text("Card with custom background")
                        .font(Theme.Typography.bodyFontSystem)
                        .foregroundColor(Theme.Colors.text)
                }
            }
            .padding()
        }
    }
}
