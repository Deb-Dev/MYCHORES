// MainView.swift
// MyChores
//
// Created on 2025-05-02.
//

import SwiftUI

/// Main view that handles authentication state and navigation
struct MainView: View {
    @EnvironmentObject private var authViewModel: AuthViewModel
    
    var body: some View {
        Group {
            switch authViewModel.authState {
            case .initializing:
                LoadingView()
                
            case .unauthenticated:
                AuthView()
                
            case .authenticatedButProfileIncomplete:
                LoadingView()
                
            case .authenticated:
                HomeView()
            }
        }
        .animation(.easeInOut, value: authViewModel.authState)
    }
}

/// Loading screen shown during authentication state changes
struct LoadingView: View {
    @State private var isTimedOut = false
    @State private var dots = ""
    
    let timer = Timer.publish(every: 0.5, on: .main, in: .common).autoconnect()
    let timeoutTimer = Timer.publish(every: 15, on: .main, in: .common).autoconnect()
    
    var body: some View {
        VStack(spacing: 24) {
            if isTimedOut {
                VStack(spacing: 16) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 50))
                        .foregroundColor(Theme.Colors.error)
                    
                    Text("Loading timed out")
                        .font(Theme.Typography.headingFontSystem)
                    
                    Text("Please check your internet connection or try again later.")
                        .font(Theme.Typography.bodyFontSystem)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    
                    Button(action: {
                        // Force refresh
                        isTimedOut = false
                        dots = ""
                    }) {
                        Text("Try Again")
                            .padding()
                            .foregroundColor(.white)
                            .background(Theme.Colors.primary)
                            .cornerRadius(8)
                    }
                    .padding(.top)
                }
            } else {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle())
                    .scaleEffect(1.5)
                
                Text("Loading\(dots)")
                    .font(Theme.Typography.headingFontSystem)
            }
        }
        .onReceive(timer) { _ in
            if dots.count < 3 {
                dots.append(".")
            } else {
                dots = ""
            }
        }
        .onReceive(timeoutTimer) { _ in
            isTimedOut = true
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Theme.Colors.background)
    }
}

#Preview {
    MainView()
        .environmentObject(AuthViewModel())
}
