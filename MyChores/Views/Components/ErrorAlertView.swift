// ErrorAlertView.swift
// MyChores
//
// Created on 2025-05-03.
//

import SwiftUI

/// A nicely styled error alert view for a consistent look and feel across the app
struct ErrorAlertView: View {
    let title: String
    let message: String
    let onDismiss: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            VStack(spacing: 12) {
                // Error icon
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 32))
                    .foregroundColor(Theme.Colors.error)
                    .padding(.top, 24)
                
                // Title
                Text(title)
                    .font(Theme.Typography.subheadingFontSystem.bold())
                    .foregroundColor(Theme.Colors.text)
                    .multilineTextAlignment(.center)
                
                // Message
                Text(message)
                    .font(Theme.Typography.bodyFontSystem)
                    .foregroundColor(Theme.Colors.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
                    .padding(.bottom, 8)
            }
            
            // Dismiss button
            Button {
                onDismiss()
            } label: {
                Text("OK")
                    .font(Theme.Typography.bodyFontSystem.bold())
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Theme.Colors.primary)
                    .cornerRadius(Theme.Dimensions.cornerRadiusMedium)
                    .padding(.horizontal, 24)
            }
            .padding(.bottom, 24)
        }
        .background(Theme.Colors.cardBackground)
        .cornerRadius(Theme.Dimensions.cornerRadiusLarge)
        .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 4)
        .padding(.horizontal, 40)
    }
}

/// Extension to SwiftUI.View that adds a custom error alert modifier
extension View {
    func customErrorAlert(isPresented: Binding<Bool>, title: String, message: String) -> some View {
        ZStack {
            self
            
            if isPresented.wrappedValue {
                Color.black.opacity(0.4)
                    .edgesIgnoringSafeArea(.all)
                    .animation(.easeInOut, value: isPresented.wrappedValue)
                
                ErrorAlertView(
                    title: title,
                    message: message,
                    onDismiss: {
                        isPresented.wrappedValue = false
                    }
                )
                .transition(.scale.combined(with: .opacity))
                .animation(.spring(), value: isPresented.wrappedValue)
            }
        }
    }
}

#Preview {
    VStack {
        Text("Background Content")
    }
    .customErrorAlert(
        isPresented: .constant(true),
        title: "Something Went Wrong",
        message: "We couldn't complete your request. Please check your connection and try again."
    )
}
