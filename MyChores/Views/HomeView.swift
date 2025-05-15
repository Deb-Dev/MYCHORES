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
                    LeaderboardViewV2(householdId: householdId)
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

// MARK: - Settings Views

/// Notification settings view
struct NotificationSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var dueRemindersEnabled = UserDefaults.standard.bool(forKey: "dueRemindersEnabled") 
    @State private var assignmentRemindersEnabled = UserDefaults.standard.bool(forKey: "assignmentRemindersEnabled")
    @State private var achievementRemindersEnabled = UserDefaults.standard.bool(forKey: "achievementRemindersEnabled")
    @State private var reminderLeadTime = UserDefaults.standard.integer(forKey: "reminderLeadTime")
    
    init() {
        // Set defaults if no values are in UserDefaults
        if !UserDefaults.standard.contains(key: "dueRemindersEnabled") {
            _dueRemindersEnabled = State(initialValue: true)
        }
        
        if !UserDefaults.standard.contains(key: "assignmentRemindersEnabled") {
            _assignmentRemindersEnabled = State(initialValue: true)
        }
        
        if !UserDefaults.standard.contains(key: "achievementRemindersEnabled") {
            _achievementRemindersEnabled = State(initialValue: true)
        }
        
        if !UserDefaults.standard.contains(key: "reminderLeadTime") {
            _reminderLeadTime = State(initialValue: 1)
        }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Theme.Colors.background.ignoresSafeArea()
                
                List {
                    Section {
                        Toggle("Due Date Reminders", isOn: $dueRemindersEnabled)
                            .tint(Theme.Colors.primary)
                        
                        if dueRemindersEnabled {
                            Picker("Remind Me", selection: $reminderLeadTime) {
                                Text("At Due Time").tag(0)
                                Text("1 Hour Before").tag(1)
                                Text("3 Hours Before").tag(3)
                                Text("1 Day Before").tag(24)
                            }
                        }
                    } header: {
                        Text("Chore Reminders")
                    } footer: {
                        Text("Receive notifications when your chores are approaching their due date.")
                    }
                    
                    Section {
                        Toggle("Assignment Notifications", isOn: $assignmentRemindersEnabled)
                            .tint(Theme.Colors.primary)
                        
                        Toggle("Achievement Notifications", isOn: $achievementRemindersEnabled)
                            .tint(Theme.Colors.primary)
                    } header: {
                        Text("Other Notifications")
                    } footer: {
                        Text("Get notified when you're assigned new chores or earn achievements.")
                    }
                    
                    Section {
                        Button {
                            if let appSettings = URL(string: UIApplication.openSettingsURLString) {
                                UIApplication.shared.open(appSettings)
                            }
                        } label: {
                            HStack {
                                Text("iOS Notification Settings")
                                    .foregroundStyle(.red)
                                Spacer()
                                Image(systemName: "arrow.up.forward.app")
                                    .foregroundStyle(.red)
                            }
                        }
                    } footer: {
                        Text("Manage all app permissions in iOS Settings.")
                    }
                }
                .navigationTitle("Notifications")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Done") {
                            saveNotificationSettings()
                            dismiss()
                        }
                    }
                }
                .onAppear {
                    loadNotificationSettings()
                }
            }
        }
    }
    
    private func saveNotificationSettings() {
        // Save notification settings to UserDefaults
        UserDefaults.standard.set(dueRemindersEnabled, forKey: "dueRemindersEnabled")
        UserDefaults.standard.set(assignmentRemindersEnabled, forKey: "assignmentRemindersEnabled")
        UserDefaults.standard.set(achievementRemindersEnabled, forKey: "achievementRemindersEnabled")
        UserDefaults.standard.set(reminderLeadTime, forKey: "reminderLeadTime")
        
        // Here we would also update notification permissions and scheduling logic
        NotificationService.shared.updateNotificationSettings(
            dueReminders: dueRemindersEnabled,
            assignmentReminders: assignmentRemindersEnabled,
            achievementReminders: achievementRemindersEnabled,
            reminderLeadTime: reminderLeadTime
        )
    }
    
    private func loadNotificationSettings() {
        // Load notification settings from UserDefaults
        dueRemindersEnabled = UserDefaults.standard.bool(forKey: "dueRemindersEnabled")
        assignmentRemindersEnabled = UserDefaults.standard.bool(forKey: "assignmentRemindersEnabled")
        achievementRemindersEnabled = UserDefaults.standard.bool(forKey: "achievementRemindersEnabled")
        reminderLeadTime = UserDefaults.standard.integer(forKey: "reminderLeadTime")
    }
}

/// Privacy settings view
struct PrivacySettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var authViewModel: AuthViewModel // Ensure AuthViewModel is available

    @State private var showProfileToOthers = UserDefaults.standard.bool(forKey: "showProfileToOthers")
    @State private var showAchievementsToOthers = UserDefaults.standard.bool(forKey: "showAchievementsToOthers")
    @State private var shareActivityWithHousehold = UserDefaults.standard.bool(forKey: "shareActivityWithHousehold")
    
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
                            // Deep link to privacy policy
                        } label: {
                            HStack {
                                Text("Privacy Policy")
                                Spacer()
                                Image(systemName: "arrow.up.right")
                            }
                        }
                        
                        Button {
                            // Action to delete account
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
}

/// Help and support view
struct HelpSupportView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var showingFAQ = false
    @State private var selectedQuestion: FAQItem?
    @State private var feedbackText = ""
    @State private var showingFeedbackSent = false
    
    // Sample FAQ items
    private let faqItems = [
        FAQItem(
            question: "How do I create a new chore?",
            answer: "To create a new chore, tap the + button at the top right of the Chores tab. Fill in the details like title, description, due date, and assigned person. Tap Save to create the chore."
        ),
        FAQItem(
            question: "How do points work?",
            answer: "Each chore has a point value associated with it. When you complete a chore, you earn those points. Points are tracked weekly and monthly on the leaderboard. Higher point values typically indicate more complex or time-consuming chores."
        ),
        FAQItem(
            question: "How do I invite others to my household?",
            answer: "In the Household tab, tap 'Invite Member' and share the generated invitation code with others. They can enter this code when joining a household to become members of your group."
        ),
        FAQItem(
            question: "How do badges work?",
            answer: "Badges are earned by completing achievements, such as completing a certain number of chores or maintaining a streak. You can view your earned badges in the Achievements tab."
        ),
        FAQItem(
            question: "Can I edit or delete a chore?",
            answer: "Yes! Tap on a chore to view its details. From there, you can tap the Edit button to modify it or the trash icon to delete it. Only the creator or the assignee can edit or delete a chore."
        )
    ]
    
    var body: some View {
        NavigationStack {
            ZStack {
                Theme.Colors.background.ignoresSafeArea()
                
                List {
                    Section {
                        ForEach(faqItems) { item in
                            Button {
                                selectedQuestion = item
                                showingFAQ = true
                            } label: {
                                HStack {
                                    Text(item.question)
                                        .foregroundStyle(Theme.Colors.text)
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .foregroundStyle(Theme.Colors.textSecondary)
                                        .font(.caption)
                                }
                            }
                        }
                    } header: {
                        Text("Frequently Asked Questions")
                    }
                    
                    Section {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Send us Feedback")
                                .font(Theme.Typography.bodyFontSystem.bold())
                            
                            TextEditor(text: $feedbackText)
                                .frame(minHeight: 120)
                                .padding(4)
                                .background(
                                    RoundedRectangle(cornerRadius: Theme.Dimensions.cornerRadiusSmall)
                                        .stroke(Theme.Colors.textSecondary.opacity(0.3), lineWidth: 1)
                                )
                            
                            Button {
                                sendFeedback()
                            } label: {
                                Text("Send Feedback")
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(Theme.Colors.primary)
                            .disabled(feedbackText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                        }
                    } header: {
                        Text("Contact Support")
                    } footer: {
                        Text("We'll respond to your feedback as soon as possible.")
                    }
                }
                .navigationTitle("Help & Support")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Done") {
                            dismiss()
                        }
                    }
                }
                .sheet(isPresented: $showingFAQ) {
                    if let question = selectedQuestion {
                        faqDetailView(faq: question)
                    }
                }
                .alert("Feedback Sent", isPresented: $showingFeedbackSent) {
                    Button("OK", role: .cancel) { }
                } message: {
                    Text("Thank you for your feedback! We'll review it as soon as possible.")
                }
            }
        }
    }
    
    private func faqDetailView(faq: FAQItem) -> some View {
        NavigationStack {
            ZStack {
                Theme.Colors.background.ignoresSafeArea()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        Text(faq.question)
                            .font(Theme.Typography.headingFontSystem)
                            .foregroundStyle(Theme.Colors.text)
                        
                        Text(faq.answer)
                            .font(Theme.Typography.bodyFontSystem)
                            .foregroundStyle(Theme.Colors.text)
                    }
                    .padding()
                }
            }
            .navigationTitle("FAQ")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        showingFAQ = false
                    }
                }
            }
        }
    }
    
    private func sendFeedback() {
        // Here we would send the feedback to the support team
        // For now, we'll just show a success alert
        feedbackText = ""
        showingFeedbackSent = true
    }
}

/// About view showing app information
struct AboutView: View {
    @Environment(\.dismiss) private var dismiss
    let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
    let buildNumber = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    
    var body: some View {
        NavigationStack {
            ZStack {
                Theme.Colors.background.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 30) {
                        // App icon and name
                        VStack(spacing: 16) {
                            Image(uiImage: UIImage(named: "AppIcon60x60") ?? UIImage())
                                .resizable()
                                .frame(width: 80, height: 80)
                                .cornerRadius(16)
                            
                            Text("MyChores")
                                .font(Theme.Typography.titleFontSystem.bold())
                                .foregroundStyle(Theme.Colors.text)
                            
                            Text("Version \(appVersion) (\(buildNumber))")
                                .font(Theme.Typography.captionFontSystem)
                                .foregroundStyle(Theme.Colors.textSecondary)
                        }
                        .padding(.bottom, 20)
                        
                        // App information
                        CardView {
                            VStack(alignment: .leading, spacing: 16) {
                                infoRow(title: "Developed By", value: "MyChores Team")
                                infoRow(title: "Contact", value: "support@mychores.app")
                                infoRow(title: "Website", value: "www.mychores.app")
                            }
                        }
                        
                        // Legal information
                        CardView {
                            VStack(alignment: .leading, spacing: 12) {
                                Button {
                                    // Open terms of service
                                } label: {
                                    Text("Terms of Service")
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .foregroundStyle(Theme.Colors.primary)
                                }
                                
                                Divider()
                                
                                Button {
                                    // Open privacy policy
                                } label: {
                                    Text("Privacy Policy")
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .foregroundStyle(Theme.Colors.primary)
                                }
                                
                                Divider()
                                
                                Button {
                                    // Open licenses
                                } label: {
                                    Text("Third-Party Licenses")
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .foregroundStyle(Theme.Colors.primary)
                                }
                            }
                        }
                        
                        // Credits
                        Text("© 2025 MyChores. All rights reserved.")
                            .font(Theme.Typography.captionFontSystem)
                            .foregroundStyle(Theme.Colors.textSecondary)
                            .padding(.top, 20)
                    }
                    .padding()
                }
            }
            .navigationTitle("About")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func infoRow(title: String, value: String) -> some View {
        HStack(alignment: .top) {
            Text(title)
                .font(Theme.Typography.bodyFontSystem)
                .foregroundStyle(Theme.Colors.textSecondary)
                .frame(width: 100, alignment: .leading)
            
            Text(value)
                .font(Theme.Typography.bodyFontSystem)
                .foregroundStyle(Theme.Colors.text)
            
            Spacer()
        }
    }
}

// MARK: - UserDefaults Extension

extension UserDefaults {
    /// Check if a key exists in UserDefaults
    /// - Parameter key: The key to check
    /// - Returns: True if the key exists, false otherwise
    func contains(key: String) -> Bool {
        return object(forKey: key) != nil
    }
}

// Helper types
struct FAQItem: Identifiable {
    var id = UUID()
    let question: String
    let answer: String
}

#Preview {
    HomeView()
        .environmentObject(AuthViewModel())
}
