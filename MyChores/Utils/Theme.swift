// Theme.swift
// MyChores
//
// Created on 2025-05-02.
//

import SwiftUI

/// Theme defines the app's color palette and typography
struct Theme {
    // MARK: - Colors
    
    struct Colors {
        static let primary = Color("Primary") // Teal: #2A9D8F
        static let secondary = Color("Secondary") // Coral: #E76F51
        static let accent = Color("Accent") // Yellow: #E9C46A
        static let background = Color("Background") // Off-white: #F8F9FA
        static let cardBackground = Color("CardBackground") // White: #FFFFFF
        static let text = Color("Text") // Dark gray: #264653
        static let textSecondary = Color("TextSecondary") // Medium gray: #6C757D
        static let success = Color("Success") // Green: #43AA8B
        static let error = Color("Error") // Red: #F94144
    }
    
    // MARK: - Typography
    
    struct Typography {
        static let titleFont = Font.custom("Montserrat-Bold", size: 28)
        static let headingFont = Font.custom("Montserrat-SemiBold", size: 22)
        static let subheadingFont = Font.custom("Montserrat-Medium", size: 18)
        static let bodyFont = Font.custom("Montserrat-Regular", size: 16)
        static let captionFont = Font.custom("Montserrat-Regular", size: 14)
        
        // Fallback system fonts if custom fonts are not available
        static let titleFontSystem = Font.system(.largeTitle, design: .rounded).weight(.bold)
        static let headingFontSystem = Font.system(.title2, design: .rounded).weight(.semibold)
        static let subheadingFontSystem = Font.system(.title3, design: .rounded).weight(.medium)
        static let bodyFontSystem = Font.system(.body, design: .rounded)
        static let captionFontSystem = Font.system(.subheadline, design: .rounded)
    }
    
    // MARK: - Dimensions
    
    struct Dimensions {
        static let paddingSmall: CGFloat = 8
        static let paddingMedium: CGFloat = 16
        static let paddingLarge: CGFloat = 24
        
        static let cornerRadiusSmall: CGFloat = 8
        static let cornerRadiusMedium: CGFloat = 12
        static let cornerRadiusLarge: CGFloat = 16
        
        static let iconSizeSmall: CGFloat = 20
        static let iconSizeMedium: CGFloat = 24
        static let iconSizeLarge: CGFloat = 32
    }
    
    // MARK: - Animations
    
    struct Animations {
        static let defaultAnimation = Animation.easeInOut(duration: 0.3)
        static let springAnimation = Animation.spring(response: 0.5, dampingFraction: 0.7)
    }
}
