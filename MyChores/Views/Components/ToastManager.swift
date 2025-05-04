// ToastManager.swift
// MyChores
//
// Created on 2025-05-03.
//

import SwiftUI
import Combine

/// A centralized manager for displaying toast messages in the app
@MainActor
class ToastManager: ObservableObject {
    // MARK: - Toast Types
    
    enum ToastType {
        case points(String)
        case badge(String)
        case error(String)
        
        var duration: TimeInterval {
            switch self {
            case .points: return 2.0
            case .badge: return 3.0
            case .error: return 4.0
            }
        }
    }
    
    // MARK: - Published Properties
    
    @Published private(set) var activeToast: ToastType?
    private var toastCancellable: AnyCancellable?
    
    // MARK: - Public Methods
    
    /// Show a toast message
    /// - Parameter toast: The type of toast to show
    func show(_ toast: ToastType) {
        // Cancel any existing toast timer
        toastCancellable?.cancel()
        
        // Show the new toast
        activeToast = toast
        
        // Set up automatic dismissal
        toastCancellable = Just(())
            .delay(for: .seconds(toast.duration), scheduler: RunLoop.main)
            .sink { [weak self] _ in
                self?.activeToast = nil
            }
    }
    
    /// Manually dismiss the current toast
    func dismiss() {
        toastCancellable?.cancel()
        activeToast = nil
    }
}

// MARK: - Toast View Modifier

struct ToastViewModifier: ViewModifier {
    @ObservedObject var toastManager: ToastManager
    
    func body(content: Content) -> some View {
        content
            .overlay(
                ZStack {
                    if let toast = toastManager.activeToast {
                        Group {
                            switch toast {
                            case .points(let message):
                                PointsEarnedToastView(message: message) {
                                    toastManager.dismiss()
                                }
                            case .badge(let message):
                                BadgeEarnedToastView(message: message) {
                                    toastManager.dismiss()
                                }
                            case .error(let message):
                                ErrorToastView(message: message) {
                                    toastManager.dismiss()
                                }
                            }
                        }
                        .transition(.opacity)
                        .animation(.easeInOut, value: toastManager.activeToast != nil)
                    }
                }
            )
    }
}

/// New ErrorToastView for displaying error messages
struct ErrorToastView: View {
    let message: String
    let onDismiss: () -> Void
    
    var body: some View {
        VStack {
            HStack(spacing: 12) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.white)
                
                Text(message)
                    .font(Theme.Typography.bodyFontSystem)
                    .foregroundColor(.white)
                
                Spacer()
                
                Button {
                    onDismiss()
                } label: {
                    Image(systemName: "xmark")
                        .foregroundColor(.white.opacity(0.7))
                }
            }
            .padding()
            .background(Theme.Colors.error)
            .cornerRadius(Theme.Dimensions.cornerRadiusMedium)
            .padding(.horizontal)
            .padding(.top, 16)
            
            Spacer()
        }
        .zIndex(100)
    }
}

// MARK: - View Extension

extension View {
    func toastManager(_ manager: ToastManager) -> some View {
        self.modifier(ToastViewModifier(toastManager: manager))
    }
}
