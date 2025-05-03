// HomeView.swift
// MyChores
//
// Created on 2025-05-02.
//

import SwiftUI
import Foundation
import Combine

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
                        if selectedHouseholdId == nil, let firstHouseholdId = user.householdIds.first {
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
        Group {
            if let householdId = selectedHouseholdId {
                ChoresView(householdId: householdId)
            } else {
                Text("Select a household")
                    .font(Theme.Typography.subheadingFontSystem)
                    .foregroundColor(Theme.Colors.textSecondary)
            }
        }
        .navigationTitle("Chores")
    }
    
    private var leaderboardTabView: some View {
        Group {
            if let householdId = selectedHouseholdId {
                LeaderboardView(householdId: householdId)
            } else {
                Text("Select a household")
                    .font(Theme.Typography.subheadingFontSystem)
                    .foregroundColor(Theme.Colors.textSecondary)
            }
        }
        .navigationTitle("Leaderboard")
    }
    
    private var achievementsTabView: some View {
        AchievementsView()
            .navigationTitle("Achievements")
    }
    
    private var householdTabView: some View {
        HouseholdView(
            selectedHouseholdId: $selectedHouseholdId,
            onCreateNewHousehold: {
                // Reset tab to chores when creating a new household
                selectedTab = 0
            }
        )
        .navigationTitle("Household")
    }
    
    private var profileTabView: some View {
        ProfileView()
            .navigationTitle("Profile")
    }
}

/// Onboarding view for users who don't belong to any household yet
struct HouseholdOnboardingView: View {
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
        .sheet(isPresented: $showingCreateHousehold) {
            CreateHouseholdView()
        }
        .sheet(isPresented: $showingJoinHousehold) {
            JoinHouseholdView()
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
                try? authViewModel.signOut()
            }
            .padding()
            .background(Theme.Colors.error)
            .foregroundColor(.white)
            .cornerRadius(Theme.Dimensions.cornerRadiusMedium)
        }
        .padding()
    }
}

/// Placeholder for CreateHouseholdView implementation
struct CreateHouseholdView: View {
    @Environment(\.dismiss) private var dismiss
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
                // Dismiss the sheet once the household is created
                dismiss()
            }
        }
    }
}

/// Placeholder for JoinHouseholdView implementation
struct JoinHouseholdView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = HouseholdViewModel()
    @State private var inviteCode = ""
    
    var body: some View {
        NavigationStack {
            ZStack {
                Theme.Colors.background.ignoresSafeArea()
                
                VStack(spacing: 24) {
                    Text("Join a Household")
                        .font(Theme.Typography.headingFont)
                        .padding(.top, 16)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Invite Code")
                            .font(Theme.Typography.captionFontSystem)
                            .foregroundColor(Theme.Colors.textSecondary)
                        
                        TextField("Enter the household invite code", text: $inviteCode)
                            .padding()
//                            .textInputAutocapitalization(.allCharacters)
                            .background(Theme.Colors.cardBackground)
                            .cornerRadius(Theme.Dimensions.cornerRadiusMedium)
                            .overlay(
                                RoundedRectangle(cornerRadius: Theme.Dimensions.cornerRadiusMedium)
                                    .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                            )
                    }
                    .padding(.horizontal, 24)
                    
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
                    .background(Theme.Colors.primary)
                    .cornerRadius(Theme.Dimensions.cornerRadiusMedium)
                    .disabled(inviteCode.isEmpty || viewModel.isLoading)
                    .opacity(inviteCode.isEmpty || viewModel.isLoading ? 0.7 : 1.0)
                    .padding(.horizontal, 24)
                    
                    Spacer()
                }
            }
            .alert(
                "Join Household Failed",
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
    
    private func joinHousehold() {
        guard !inviteCode.isEmpty else { return }
        
        viewModel.joinHousehold(inviteCode: inviteCode) { success in
            if success {
                // Dismiss the sheet once the household is joined
                dismiss()
            }
        }
    }
}

#Preview {
    HomeView()
        .environmentObject(AuthViewModel())
}
