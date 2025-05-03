// HomeView.swift
// MyChores
//
// Created on 2025-05-02.
//

import SwiftUI
import Foundation
import Combine
import FirebaseFirestore
import FirebaseAuth
import Foundation

// Import necessary ViewModels and utilities
struct HomeView: View {
    @EnvironmentObject private var authViewModel: AuthViewModel
    @State private var selectedTab = 0
    @State private var selectedHouseholdId: String?
    
    var body: some View {
        ZStack {
            Theme.Colors.background.ignoresSafeArea()
            
            if let user = authViewModel.currentUser {
                if user.householdIds.isEmpty {
                    // If user doesn't belong to any household, show the household creation/join screen
                    HouseholdOnboardingView()
                } else {
                    // If user has households, show the main tabbed interface
                    TabView(selection: $selectedTab) {
                        // Chores tab
                        choresTabView
                            .tabItem {
                                Label("Chores", systemImage: "checklist")
                            }
                            .tag(0)
                        
                        // Leaderboard tab
                        leaderboardTabView
                            .tabItem {
                                Label("Leaderboard", systemImage: "trophy")
                            }
                            .tag(1)
                        
                        // Achievements tab
                        achievementsTabView
                            .tabItem {
                                Label("Achievements", systemImage: "star.fill")
                            }
                            .tag(2)
                        
                        // Household settings tab
                        householdTabView
                            .tabItem {
                                Label("Household", systemImage: "house")
                            }
                            .tag(3)
                        
                        // Profile/settings tab
                        profileTabView
                            .tabItem {
                                Label("Profile", systemImage: "person")
                            }
                            .tag(4)
                    }
                    .tint(Theme.Colors.primary)
                    .onAppear {
                        // When first showing the tabbed interface, set the selectedHouseholdId to the first one
                        if selectedHouseholdId == nil, 
                           let firstHouseholdId = user.householdIds.first,
                           !firstHouseholdId.isEmpty {
                            selectedHouseholdId = firstHouseholdId
                        }
                    }
                }
            } else {
                // Show loading view while user data is being fetched
                LoadingView()
            }
        }
    }
    
    // MARK: - Tab Views
    
    private var choresTabView: some View {
        NavigationStack {
            Group {
                if let householdId = selectedHouseholdId, !householdId.isEmpty {
                    ChoresView(householdId: householdId)
                } else {
                    Text("Select a household")
                        .font(Theme.Typography.subheadingFontSystem)
                        .foregroundColor(Theme.Colors.textSecondary)
                }
            }
            .navigationTitle("Chores")
        }
    }
    
    private var leaderboardTabView: some View {
        NavigationStack {
            Group {
                if let householdId = selectedHouseholdId, !householdId.isEmpty {
                    LeaderboardView(householdId: householdId)
                } else {
                    Text("Select a household")
                        .font(Theme.Typography.subheadingFontSystem)
                        .foregroundColor(Theme.Colors.textSecondary)
                }
            }
            .navigationTitle("Leaderboard")
        }
    }
    
    private var achievementsTabView: some View {
        NavigationStack {
            AchievementsView()
                .navigationTitle("Achievements")
        }
    }
    
    private var householdTabView: some View {
        NavigationStack {
            HouseholdView(
                selectedHouseholdId: $selectedHouseholdId,
                onCreateNewHousehold: {
                    // Reset tab to chores when creating a new household
                    selectedTab = 0
                }
            )
            .navigationTitle("Household")
        }
    }
    
    private var profileTabView: some View {
        NavigationStack {
            ProfileView()
                .navigationTitle("Profile")
        }
    }
}

/// Onboarding view for users who don't belong to any household yet
struct HouseholdOnboardingView: View {
    @EnvironmentObject private var authViewModel: AuthViewModel
    @State private var showingCreateHousehold = false
    @State private var showingJoinHousehold = false
    
    var body: some View {
        VStack(spacing: 32) {
            // Header
            VStack(spacing: 16) {
                Image(systemName: "house.fill")
                    .font(.system(size: 60))
                    .foregroundColor(Theme.Colors.primary)
                
                Text("Welcome to MyChores!")
                    .font(Theme.Typography.titleFontSystem)
                    .foregroundColor(Theme.Colors.text)
                
                Text("Let's set up your household")
                    .font(Theme.Typography.bodyFontSystem)
                    .foregroundColor(Theme.Colors.textSecondary)
                    .multilineTextAlignment(.center)
            }
            
            // Options
            VStack(spacing: 16) {
                Button {
                    showingCreateHousehold = true
                } label: {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 24))
                        
                        Text("Create a Household")
                            .font(Theme.Typography.bodyFontSystem.bold())
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                    }
                    .padding()
                    .foregroundColor(.white)
                    .background(Theme.Colors.primary)
                    .cornerRadius(Theme.Dimensions.cornerRadiusMedium)
                }
                
                Button {
                    showingJoinHousehold = true
                } label: {
                    HStack {
                        Image(systemName: "person.2.fill")
                            .font(.system(size: 24))
                        
                        Text("Join a Household")
                            .font(Theme.Typography.bodyFontSystem.bold())
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                    }
                    .padding()
                    .foregroundColor(Theme.Colors.primary)
                    .background(Theme.Colors.cardBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: Theme.Dimensions.cornerRadiusMedium)
                            .stroke(Theme.Colors.primary, lineWidth: 2)
                    )
                    .cornerRadius(Theme.Dimensions.cornerRadiusMedium)
                }
            }
            .padding(.horizontal, 24)
        }
        .padding(.horizontal, 16)
        .sheet(isPresented: $showingCreateHousehold, onDismiss: refreshUserData) {
            CreateHouseholdView()
        }
        .sheet(isPresented: $showingJoinHousehold, onDismiss: refreshUserData) {
            JoinHouseholdView()
        }
    }
    
    private func refreshUserData() {
        Task {
            await authViewModel.refreshCurrentUser()
        }
    }
}


/// Placeholder for ProfileView implementation
struct ProfileView: View {
    @EnvironmentObject private var authViewModel: AuthViewModel
    
    var body: some View {
        VStack(spacing: 24) {
            Text("Profile View")
                .font(Theme.Typography.headingFont)
            
            if let user = authViewModel.currentUser {
                Text("Welcome, \(user.name)")
                    .font(Theme.Typography.subheadingFontSystem)
            }
            
            Button("Sign Out") {
                Task {
                    await authViewModel.signOut { success, error in
                        if !success {
                            print("Sign out failed: \(error?.localizedDescription ?? "Unknown error")")
                        }
                    }
                }
            }
            .padding()
            .background(Theme.Colors.error)
            .foregroundColor(.white)
            .cornerRadius(Theme.Dimensions.cornerRadiusMedium)
        }
        .padding()
    }
}

/// View for creating a new household
struct CreateHouseholdView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var authViewModel: AuthViewModel
    @StateObject private var viewModel = HouseholdViewModel()
    @State private var householdName = ""
    
    var body: some View {
        NavigationStack {
            ZStack {
                Theme.Colors.background.ignoresSafeArea()
                
                VStack(spacing: 24) {
                    Text("Create a New Household")
                        .font(Theme.Typography.headingFont)
                        .padding(.top, 16)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Household Name")
                            .font(Theme.Typography.captionFontSystem)
                            .foregroundColor(Theme.Colors.textSecondary)
                        
                        TextField("Enter a name for your household", text: $householdName)
                            .padding()
                            .background(Theme.Colors.cardBackground)
                            .cornerRadius(Theme.Dimensions.cornerRadiusMedium)
                            .overlay(
                                RoundedRectangle(cornerRadius: Theme.Dimensions.cornerRadiusMedium)
                                    .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                            )
                    }
                    .padding(.horizontal, 24)
                    
                    Button {
                        createHousehold()
                    } label: {
                        if viewModel.isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle())
                                .tint(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                        } else {
                            Text("Create Household")
                                .font(Theme.Typography.bodyFontSystem.bold())
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                        }
                    }
                    .background(Theme.Colors.primary)
                    .cornerRadius(Theme.Dimensions.cornerRadiusMedium)
                    .disabled(householdName.isEmpty || viewModel.isLoading)
                    .opacity(householdName.isEmpty || viewModel.isLoading ? 0.7 : 1.0)
                    .padding(.horizontal, 24)
                    
                    Spacer()
                }
            }
            .alert(
                "Create Household Failed",
                isPresented: .init(
                    get: { viewModel.errorMessage != nil },
                    set: { if !$0 { viewModel.errorMessage = nil } }
                ),
                actions: { Button("OK", role: .cancel) {} },
                message: { Text(viewModel.errorMessage ?? "") }
            )
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func createHousehold() {
        guard !householdName.isEmpty else { return }
        
        viewModel.createHousehold(name: householdName) { success in
            if success {
                // Refresh the user data to update the householdIds array
                Task {
                    await authViewModel.refreshCurrentUser()
                    
                    // Dismiss the sheet once the household is created and user is refreshed
                    DispatchQueue.main.async {
                        dismiss()
                    }
                }
            }
        }
    }
}

/// View for joining an existing household
struct JoinHouseholdView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var authViewModel: AuthViewModel
    @StateObject private var viewModel = HouseholdViewModel()
    @State private var inviteCode = ""
    @State private var isShowingInformation = false
    @State private var isShowingErrorAlert = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                Theme.Colors.background.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Header section
                        VStack(spacing: 16) {
                            Image(systemName: "house.fill")
                                .font(.system(size: 48))
                                .foregroundColor(Theme.Colors.primary)
                                .padding(.top, 16)
                            
                            Text("Join a Household")
                                .font(Theme.Typography.headingFontSystem)
                                .foregroundColor(Theme.Colors.text)
                            
                            Text("Enter the invite code shared by the household owner")
                                .font(Theme.Typography.bodyFontSystem)
                                .foregroundColor(Theme.Colors.textSecondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 24)
                        }
                        .padding(.bottom, 16)
                        
                        // Invite code input section
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Invite Code")
                                    .font(Theme.Typography.captionFontSystem)
                                    .foregroundColor(Theme.Colors.textSecondary)
                                
                                Button {
                                    isShowingInformation = true
                                } label: {
                                    Image(systemName: "info.circle")
                                        .foregroundColor(Theme.Colors.textSecondary)
                                }
                                .alert("About Invite Codes", isPresented: $isShowingInformation) {
                                    Button("OK", role: .cancel) {}
                                } message: {
                                    Text("Invite codes are 6-character alphanumeric codes that can be shared by the household owner. Ask them to share this code with you.")
                                }
                            }
                            
                            TextField("EXAMPLE: ABC123", text: $inviteCode)
                                .padding()
                                .disableAutocorrection(true)
                                .font(.system(size: 18, weight: .medium, design: .monospaced))
                                .background(Theme.Colors.cardBackground)
                                .cornerRadius(Theme.Dimensions.cornerRadiusMedium)
                                .overlay(
                                    RoundedRectangle(cornerRadius: Theme.Dimensions.cornerRadiusMedium)
                                        .stroke(inviteCode.isEmpty ? Color.gray.opacity(0.2) : Theme.Colors.primary, lineWidth: 1)
                                )
                                .onChange(of: inviteCode) { oldValue, newValue in
                                    // Break this into smaller statements to avoid compiler issues
                                    formatInviteCode(newValue)
                                }
                        }
                        .padding(.horizontal, 24)
                        
                        // Join button
                        Button {
                            joinHousehold()
                        } label: {
                            if viewModel.isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle())
                                    .tint(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                            } else {
                                Text("Join Household")
                                    .font(Theme.Typography.bodyFontSystem.bold())
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                            }
                        }
                        .background(inviteCode.isEmpty || viewModel.isLoading ? Theme.Colors.primary.opacity(0.6) : Theme.Colors.primary)
                        .cornerRadius(Theme.Dimensions.cornerRadiusMedium)
                        .disabled(inviteCode.isEmpty || viewModel.isLoading)
                        .padding(.horizontal, 24)
                        
                        // Additional instructions
                        if !viewModel.isLoading {
                            VStack(spacing: 12) {
                                Text("Don't have an invite code?")
                                    .font(Theme.Typography.captionFontSystem)
                                    .foregroundColor(Theme.Colors.textSecondary)
                                
                                Text("Ask the household owner to share their invite code with you, or create your own household.")
                                    .font(Theme.Typography.captionFontSystem)
                                    .foregroundColor(Theme.Colors.textSecondary)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal, 24)
                            }
                            .padding(.top, 16)
                        }
                        
                        Spacer()
                    }
                    .padding(.vertical, 8)
                }
            }
            .alert(
                "About Invite Codes",
                isPresented: $isShowingInformation
            ) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("Invite codes are 6-character alphanumeric codes that can be shared by the household owner. Ask them to share this code with you.")
            }
            .customErrorAlert(
                isPresented: $isShowingErrorAlert,
                title: "Join Household Failed",
                message: viewModel.errorMessage ?? "An unknown error occurred"
            )
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func joinHousehold() {
        guard !inviteCode.isEmpty else { return }
        
        // Trim whitespace from invite code to prevent common user input error
        let trimmedCode = inviteCode.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        
        viewModel.joinHousehold(inviteCode: trimmedCode) { success in
            if success {
                // After joining household, refresh the user data in AuthViewModel
                Task {
                    // Give Firestore a moment to update
                    try? await Task.sleep(nanoseconds: 1_500_000_000) // 1.5 second delay
                    
                    // Attempt to refresh the user up to 3 times if needed
                    var refreshSuccess = false
                    var attempts = 0
                    
                    while !refreshSuccess && attempts < 3 {
                        attempts += 1
                        refreshSuccess = await self.authViewModel.refreshCurrentUser() ?? false
                        
                        if !refreshSuccess && attempts < 3 {
                            try? await Task.sleep(nanoseconds: 1_000_000_000) // Wait 1 second before retrying
                        }
                    }
                    
                    // Dismiss the sheet once the household is joined and user is refreshed
                    DispatchQueue.main.async {
                        self.dismiss()
                    }
                }
            } else {
                // Show error alert
                DispatchQueue.main.async {
                    self.isShowingErrorAlert = true
                }
            }
        }
    }
    
    /// Formats the invite code to be uppercase and contain only letters and numbers
    private func formatInviteCode(_ value: String) {
        // Automatically uppercase the invite code and filter out invalid characters
        let filtered = value.filter { $0.isLetter || $0.isNumber }
        
        if filtered != value {
            inviteCode = filtered.uppercased()
        } else {
            inviteCode = value.uppercased()
        }
    }
}

#Preview {
    HomeView()
        .environmentObject(AuthViewModel())
}
