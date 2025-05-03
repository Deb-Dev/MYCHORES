// MyChoresApp.swift
// MyChores
//
// Created by Debasish Chowdhury on 2025-05-02.
//

import SwiftUI
import FirebaseCore

@main
struct MyChoresApp: App {
    // Use the App Delegate for Firebase setup
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    
    // Auth view model to track authentication state
    @StateObject private var authViewModel = AuthViewModel()
    
    var body: some Scene {
        WindowGroup {
            MainView()
                .environmentObject(authViewModel)
        }
    }
}
