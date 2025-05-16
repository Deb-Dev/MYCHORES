// PrivacySettingsView.swift
// MyChores
//
// Created on 2025-05-16.
//

import SwiftUI
import Foundation

/// Privacy settings view
struct PrivacySettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var authViewModel: AuthViewModel // Ensure AuthViewModel is available

    @State private var showProfileToOthers = UserDefaults.standard.bool(forKey: "showProfileToOthers")
    @State private var showAchievementsToOthers = UserDefaults.standard.bool(forKey: "showAchievementsToOthers")
    @State private var shareActivityWithHousehold = UserDefaults.standard.bool(forKey: "shareActivityWithHousehold")
    @State private var showingPrivacyTerms = false
    @State private var showingDeleteConfirmation = false
    
    init() {
        // Set defaults if no values are in UserDefaults
        if !UserDefaults.standard.contains(key: "showProfileToOthers") {
            _showProfileToOthers = State(initialValue: true)
        }
        
        if !UserDefaults.standard.contains(key: "showAchievementsToOthers") {
            _showAchievementsToOthers = State(initialValue: true)
        }
        
        if !UserDefaults.standard.contains(key: "shareActivityWithHousehold") {
            _shareActivityWithHousehold = State(initialValue: true)
        }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Theme.Colors.background.ignoresSafeArea()
                
                List {
                    Section {
                        Toggle("Share Profile with Household", isOn: $showProfileToOthers)
                            .tint(Theme.Colors.primary)
                        
                        Toggle("Display Achievements", isOn: $showAchievementsToOthers)
                            .tint(Theme.Colors.primary)
                        
                        Toggle("Share Activity History", isOn: $shareActivityWithHousehold)
                            .tint(Theme.Colors.primary)
                    } header: {
                        Text("Visibility Settings")
                    } footer: {
                        Text("Control what information is visible to other members of your household.")
                    }
                    
                    Section {
                        Button {
                            // Present the privacy policy view
                            showPrivacyTerms()
                        } label: {
                            HStack {
                                Text("Privacy Policy & Terms")
                                Spacer()
                                Image(systemName: "arrow.up.right")
                            }
                        }
                        
                        Button {
                            // Action to delete account
                            showDeleteAccountConfirmation()
                        } label: {
                            Text("Delete My Account")
                                .foregroundStyle(.red)
                        }
                    } header: {
                        Text("Data & Privacy")
                    } footer: {
                        Text("View our privacy policy or request account deletion. Account deletion will permanently remove all your data.")
                    }
                }
                .navigationTitle("Privacy")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Done") {
                            Task {
                                await savePrivacySettings()
                                dismiss()
                            }
                        }
                    }
                }
                .onAppear {
                    loadPrivacySettings()
                }
                .sheet(isPresented: $showingPrivacyTerms) {
                    PrivacyTermsView()
                }
                .alert("Delete Account", isPresented: $showingDeleteConfirmation) {
                    Button("Cancel", role: .cancel) {}
                    Button("Delete", role: .destructive) {
                        Task {
                            // Implement account deletion logic
                            // await authViewModel.deleteAccount()
                        }
                    }
                } message: {
                    Text("Are you sure you want to delete your account? This action cannot be undone and will permanently remove all your data from our servers.")
                }
            }
        }
    }
    
    private func savePrivacySettings() async { // Make async
        // Save privacy settings to UserDefaults (local cache/UI responsiveness)
        UserDefaults.standard.set(showProfileToOthers, forKey: "showProfileToOthers")
        UserDefaults.standard.set(showAchievementsToOthers, forKey: "showAchievementsToOthers")
        UserDefaults.standard.set(shareActivityWithHousehold, forKey: "shareActivityWithHousehold")
        
        // Update server-side privacy settings via AuthViewModel
        print("PrivacySettingsView: Calling authViewModel.updateUserPrivacySettings")
        await authViewModel.updateUserPrivacySettings(
            showProfile: showProfileToOthers,
            showAchievements: showAchievementsToOthers,
            shareActivity: shareActivityWithHousehold
        )
        // After this, AuthViewModel will get updated currentUser from AuthService if successful,
        // which should then reflect in ProfileView if it re-evaluates its onAppear or observes currentUser directly.
    }
    
    private func loadPrivacySettings() {
        // Load from AuthViewModel's currentUser first if available, then UserDefaults as fallback or initial state.
        if let user = authViewModel.currentUser {
            print("PrivacySettingsView: Loading privacy settings from authViewModel.currentUser")
            showProfileToOthers = user.privacySettings.showProfile
            showAchievementsToOthers = user.privacySettings.showAchievements
            shareActivityWithHousehold = user.privacySettings.shareActivity
        } else {
            // Fallback to UserDefaults if currentUser is not yet available (should be rare if ProfileView ensures refresh)
            print("PrivacySettingsView: authViewModel.currentUser is nil, loading from UserDefaults as fallback.")
            showProfileToOthers = UserDefaults.standard.bool(forKey: "showProfileToOthers")
            showAchievementsToOthers = UserDefaults.standard.bool(forKey: "showAchievementsToOthers")
            shareActivityWithHousehold = UserDefaults.standard.bool(forKey: "shareActivityWithHousehold")
        }
    }
    
    private func showPrivacyTerms() {
        showingPrivacyTerms = true
    }
    
    private func showDeleteAccountConfirmation() {
        showingDeleteConfirmation = true
    }
}

#Preview {
    PrivacySettingsView()
        .environmentObject(AuthViewModel())
}

#Preview("Privacy Terms") {
    PrivacyTermsView()
}
