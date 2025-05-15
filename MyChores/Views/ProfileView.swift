//
//  ProfileView.swift
//  MyChores
//
//  Created by Debasish Chowdhury on 2025-05-14.
//
import SwiftUI
import UIKit

struct ProfileView: View {
    @EnvironmentObject private var authViewModel: AuthViewModel
    @State private var showingSignOutConfirmation = false
    @State private var isEditingProfile = false
    @State private var editedName = ""
    
    // Settings navigation state
    @State private var showingNotificationSettings = false
    @State private var showingPrivacySettings = false
    @State private var showingHelpSupport = false
    @State private var showingAbout = false
    
    // Animation states
    @State private var profileAppeared = false
    @State private var selectedTab = 0
    @State private var showingBadges = false
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                gradient: Gradient(colors: [
                    Theme.Colors.background,
                    Theme.Colors.primary.opacity(0.05)
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            // Decorative elements
            ZStack {
                Circle()
                    .fill(Theme.Colors.primary.opacity(0.1))
                    .frame(width: 250, height: 250)
                    .offset(x: -100, y: -180)
                    .blur(radius: 30)
                
                Circle()
                    .fill(Theme.Colors.accent.opacity(0.08))
                    .frame(width: 200, height: 200)
                    .offset(x: 150, y: 300)
                    .blur(radius: 20)
            }
            .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 24) {
                    // Profile header with avatar and name
                    profileHeader
                        .opacity(profileAppeared ? 1 : 0)
                        .offset(y: profileAppeared ? 0 : -20)
                    
                    // Segmented control for stats and achievements
                    segmentedControl
                        .padding(.horizontal, 16)
                        .opacity(profileAppeared ? 1 : 0)
                    
                    // Content based on selected tab
                    if selectedTab == 0 {
                        // Stats section
                        statsSection
                            .padding(.horizontal, 16)
                            .transition(.opacity.combined(with: .move(edge: .leading)))
                    } else {
                        // Badges section
                        badgesSection
                            .padding(.horizontal, 16)
                            .transition(.opacity.combined(with: .move(edge: .trailing)))
                    }
                    
                    // Settings section with improved design
                    settingsSection
                        .padding(.horizontal, 16)
                        .opacity(profileAppeared ? 1 : 0)
                        .offset(y: profileAppeared ? 0 : 20)
                    
                    // Sign out button
                    signOutButton
                        .padding(.horizontal, 16)
                        .padding(.top, 8)
                        .padding(.bottom, 32)
                        .opacity(profileAppeared ? 1 : 0)
                }
                .padding(.top, 24)
            }
        }
        .sheet(isPresented: $isEditingProfile) {
            editProfileView
        }
        .sheet(isPresented: $showingNotificationSettings) {
            NotificationSettingsView()
        }
        .sheet(isPresented: $showingPrivacySettings) {
            PrivacySettingsView()
        }
        .sheet(isPresented: $showingHelpSupport) {
            HelpSupportView()
        }
        .sheet(isPresented: $showingAbout) {
            AboutView()
        }
        .alert("Sign Out", isPresented: $showingSignOutConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Sign Out", role: .destructive) {
                signOut()
            }
        } message: {
            Text("Are you sure you want to sign out?")
        }
        .onAppear {
            // Start the appearance animations as soon as the view appears
            withAnimation(.spring(response: 0.7, dampingFraction: 0.9)) {
                profileAppeared = true
            }
            
            // Fetch user data
            Task {
                // Ensure user data is fresh when the view appears
                _ = await authViewModel.refreshCurrentUser()
                // Now load settings from the potentially updated currentUser in authViewModel
                loadUserSettings()
            }
        }
        .onDisappear {
            // Reset animation states when view disappears
            profileAppeared = false
            showingBadges = false
        }
    }
    
    // MARK: - User Settings
    
    private func loadUserSettings() {
        // This method loads user settings from the currentUser in AuthViewModel into UserDefaults
        guard let user = authViewModel.currentUser else {
            print("ProfileView: Cannot load user settings, currentUser is nil.")
            return
        }
        
        print("ProfileView: Loading user settings into UserDefaults from authViewModel.currentUser")
        // Assuming user.privacySettings is a non-optional struct or has default values.
        // If privacySettings itself can be nil, add appropriate optional chaining or guarding.
        UserDefaults.standard.set(user.privacySettings.showProfile,
                                 forKey: "showProfileToOthers")
        UserDefaults.standard.set(user.privacySettings.showAchievements,
                                 forKey: "showAchievementsToOthers")
        UserDefaults.standard.set(user.privacySettings.shareActivity,
                                 forKey: "shareActivityWithHousehold")
    }
    
    // MARK: - Profile Header
    
    private var profileHeader: some View {
        VStack(spacing: 0) {
            // Enhanced background gradient arc with animated pattern
            ZStack(alignment: .top) {
                // Main gradient background
                Rectangle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Theme.Colors.primary,
                                Theme.Colors.primary.opacity(0.8)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(height: 130)
                    .cornerRadius(Theme.Dimensions.cornerRadiusLarge, corners: [.bottomLeft, .bottomRight])
                
                // Animated decorative elements
                HStack {
                    ForEach(0..<5) { i in
                        Circle()
                            .fill(Color.white.opacity(0.15 - Double(i) * 0.02))
                            .frame(width: 30 + CGFloat(i * 15), height: 30 + CGFloat(i * 15))
                            .offset(x: -60 + CGFloat(i * 40), y: CGFloat(10 + (i % 3) * 10))
                            .blur(radius: 8)
                            .rotation3DEffect(
                                .degrees(profileAppeared ? Double((i % 2 == 0) ? 10 : -10) : 0),
                                axis: (x: 0, y: 1, z: 0)
                            )
                            .animation(
                                Animation.easeInOut(duration: 3 + Double(i) * 0.5)
                                    .repeatCount(2, autoreverses: true)
                                    .delay(Double(i) * 0.2),
                                value: profileAppeared
                            )
                    }
                }
                .mask(
                    Rectangle()
                        .frame(height: 130)
                )
                
                // Animated shine effect
                GeometryReader { geometry in
                    Color.white.opacity(0.2)
                        .mask(
                            Rectangle()
                                .fill(
                                    LinearGradient(
                                        gradient: Gradient(stops: [
                                            .init(color: .clear, location: 0),
                                            .init(color: .white.opacity(0.5), location: 0.4),
                                            .init(color: .white, location: 0.5),
                                            .init(color: .white.opacity(0.5), location: 0.6),
                                            .init(color: .clear, location: 1)
                                        ]),
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .rotationEffect(.degrees(45))
                                .offset(x: profileAppeared ? geometry.size.width : -geometry.size.width)
                        )
                        .animation(
                            Animation.easeInOut(duration: 4)
                                .repeatCount(2, autoreverses: false)
                                .delay(1),
                            value: profileAppeared
                        )
                }
                .frame(height: 130)
                
                // User avatar positioned to overlap the gradient background
                ZStack {
                    // Avatar shadow with subtle animation
                    Circle()
                        .fill(Color.black.opacity(0.25))
                        .frame(width: 110, height: 110)
                        .blur(radius: 8)
                        .offset(y: 4)
                        .scaleEffect(profileAppeared ? 1 : 0.9)
                        .animation(.spring(response: 1, dampingFraction: 0.8), value: profileAppeared)
                    
                    // Avatar background with pulse effect
                    Circle()
                        .fill(Color.white)
                        .frame(width: 108, height: 108)
                        .shadow(color: Color.black.opacity(0.2), radius: 10, x: 0, y: 5)
                        .overlay(
                            Circle()
                                .stroke(Color.white.opacity(0.8), lineWidth: 3)
                                .scaleEffect(profileAppeared ? 1.1 : 1)
                                .opacity(profileAppeared ? 0 : 0.6)
                                .animation(
                                    Animation.easeOut(duration: 1.5),
                                    value: profileAppeared
                                )
                        )
                    
                    // User photo or initials with reveal animation
                    if let photoURL = authViewModel.currentUser?.photoURL, !photoURL.isEmpty {
                        AsyncImage(url: URL(string: photoURL)) { phase in
                            switch phase {
                            case .success(let image):
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: 100, height: 100)
                                    .clipShape(Circle())
                                    .scaleEffect(profileAppeared ? 1 : 0.8)
                                    .animation(.spring(response: 0.6, dampingFraction: 0.8), value: profileAppeared)
                            default:
                                initialsView
                            }
                        }
                    } else {
                        initialsView
                            .scaleEffect(profileAppeared ? 1 : 0.8)
                            .animation(.spring(response: 0.6, dampingFraction: 0.8), value: profileAppeared)
                    }
                }
                .offset(y: 65)
            }
            
            // User information with ample padding to account for the overlapping avatar
            VStack(spacing: 4) {
                Spacer().frame(height: 60)
                
                // User name and email with staggered reveal animations
                if let user = authViewModel.currentUser {
                    Text(user.name)
                        .font(Theme.Typography.headingFontSystem)
                        .fontWeight(.bold)
                        .foregroundColor(Theme.Colors.text)
                        .opacity(profileAppeared ? 1 : 0)
                        .offset(y: profileAppeared ? 0 : 10)
                        .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.1), value: profileAppeared)
                    
                    Text(user.email)
                        .font(Theme.Typography.bodyFontSystem)
                        .foregroundColor(Theme.Colors.textSecondary)
                        .opacity(profileAppeared ? 1 : 0)
                        .offset(y: profileAppeared ? 0 : 10)
                        .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.2), value: profileAppeared)
                    
                    HStack(spacing: 8) {
                        // Member since badge with subtle hover effect
                        HStack(spacing: 4) {
                            Image(systemName: "calendar")
                                .font(.system(size: 12))
                                .foregroundColor(Theme.Colors.primary.opacity(0.8))
                            
                            Text("Member since \(calculateMemberSinceShort())")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(Theme.Colors.primary.opacity(0.8))
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(
                            Capsule()
                                .fill(Theme.Colors.primary.opacity(0.1))
                                .shadow(color: Theme.Colors.primary.opacity(0.1), radius: 3, x: 0, y: 2)
                        )
                    }
                    .padding(.top, 8)
                    .opacity(profileAppeared ? 1 : 0)
                    .offset(y: profileAppeared ? 0 : 10)
                    .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.3), value: profileAppeared)
                }
                
                // Edit profile button
                modernEditProfileButton()
            }
            .padding(.bottom, 20)
            .padding(.horizontal, 20)
        }
        .background(Theme.Colors.cardBackground)
        .cornerRadius(Theme.Dimensions.cornerRadiusLarge)
        .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
        .padding(.horizontal, 16)
    }
    
    private var initialsView: some View {
        ZStack {
            Circle()
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Theme.Colors.primary.opacity(0.7),
                            Theme.Colors.primary
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 100, height: 100)
            
            Text(getInitials())
                .font(.system(size: 36, weight: .semibold, design: .rounded))
                .foregroundColor(.white)
        }
    }
    
    // MARK: - Stats Section
    
    private var statsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Your Statistics")
                    .font(Theme.Typography.subheadingFontSystem)
                    .foregroundColor(Theme.Colors.text)
                
                Spacer()
                
                // Small visual indicator showing this is the active tab
                Capsule()
                    .fill(Theme.Colors.primary)
                    .frame(width: 30, height: 4)
                    .padding(.trailing, 4)
                    .opacity(selectedTab == 0 ? 1 : 0)
                    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: selectedTab)
            }
            
            if let user = authViewModel.currentUser {
                // Progress overview
                progressOverview(points: user.totalPoints)
                    .padding(.bottom, 8)
            }
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                if let user = authViewModel.currentUser {
                    // Animate each stat card with a staggered delay
                    Group {
                        statCard(
                            value: "\(user.totalPoints)",
                            label: "Total Points",
                            icon: "star.fill",
                            color: Theme.Colors.primary
                        )
                        .transition(.scale.combined(with: .opacity))
                        
                        statCard(
                            value: "\(user.earnedBadges.count)",
                            label: "Badges Earned",
                            icon: "rosette",
                            color: Theme.Colors.accent
                        )
                        .transition(.scale.combined(with: .opacity))
                        
                        statCard(
                            value: "\(user.householdIds.count)",
                            label: "Households",
                            icon: "house.fill",
                            color: Theme.Colors.secondary
                        )
                        .transition(.scale.combined(with: .opacity))
                        
                        statCard(
                            value: calculateMemberSince(),
                            label: "Member Since",
                            icon: "calendar",
                            color: Theme.Colors.success
                        )
                        .transition(.scale.combined(with: .opacity))
                    }
                    .animation(Animation.spring(response: 0.5, dampingFraction: 0.7).delay(0.1), value: profileAppeared)
                }
            }
        }
        .padding(20)
        .background(Theme.Colors.cardBackground)
        .cornerRadius(Theme.Dimensions.cornerRadiusMedium)
        .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 4)
    }
    
    // Custom progress chart for total points
    private func progressOverview(points: Int) -> some View {
        HStack(alignment: .top, spacing: 20) {
            // Circular progress indicator
            ZStack {
                Circle()
                    .stroke(Theme.Colors.primary.opacity(0.2), lineWidth: 8)
                
                Circle()
                    .trim(from: 0, to: min(CGFloat(points) / 1000, 1.0))
                    .stroke(
                        AngularGradient(
                            gradient: Gradient(colors: [Theme.Colors.primary.opacity(0.7), Theme.Colors.primary]),
                            center: .center
                        ),
                        style: StrokeStyle(lineWidth: 8, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                
                VStack(spacing: 3) {
                    Text("\(points)")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(Theme.Colors.text)
                    
                    Text("points")
                        .font(.system(size: 12))
                        .foregroundColor(Theme.Colors.textSecondary)
                }
            }
            .frame(width: 100, height: 100)
            
            // Progress details
            VStack(alignment: .leading, spacing: 10) {
                // Current level
                VStack(alignment: .leading, spacing: 5) {
                    Text("Current Level")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(Theme.Colors.textSecondary)
                    
                    Text("Level \(points / 100 + 1)")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(Theme.Colors.text)
                }
                
                // Progress to next level
                VStack(alignment: .leading, spacing: 5) {
                    HStack {
                        Text("Progress to next level")
                            .font(.system(size: 12))
                            .foregroundColor(Theme.Colors.textSecondary)
                        
                        Spacer()
                        
                        Text("\(points % 100)/100")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(Theme.Colors.primary)
                    }
                    
                    // Progress bar
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            Rectangle()
                                .frame(width: geometry.size.width, height: 8)
                                .foregroundColor(Theme.Colors.primary.opacity(0.2))
                                .cornerRadius(4)
                            
                            Rectangle()
                                .frame(width: min(CGFloat(points % 100) / 100 * geometry.size.width, geometry.size.width), height: 8)
                                .foregroundColor(Theme.Colors.primary)
                                .cornerRadius(4)
                        }
                    }
                    .frame(height: 8)
                }
            }
            .frame(maxWidth: .infinity)
        }
        .padding(15)
        .background(Theme.Colors.cardBackground.opacity(0.5))
        .cornerRadius(Theme.Dimensions.cornerRadiusSmall)
        .shadow(color: Color.black.opacity(0.03), radius: 5, x: 0, y: 2)
    }
    
    // MARK: - Settings Section
    
    private var settingsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Settings")
                .font(Theme.Typography.subheadingFontSystem)
                .foregroundColor(Theme.Colors.text)
            
            VStack(spacing: 0) {
                settingRow(icon: "bell.fill", title: "Notifications", action: {
                    // Open notification settings
                    showingNotificationSettings = true
                })
                
                Divider()
                    .padding(.leading, 56)
                
                settingRow(icon: "lock.fill", title: "Privacy", action: {
                    // Open privacy settings
                    showingPrivacySettings = true
                })
                
                Divider()
                    .padding(.leading, 56)
                
                settingRow(icon: "questionmark.circle.fill", title: "Help & Support", action: {
                    // Open help
                    showingHelpSupport = true
                })
                
                Divider()
                    .padding(.leading, 56)
                
                settingRow(icon: "info.circle.fill", title: "About", action: {
                    // Show about info
                    showingAbout = true
                })
            }
        }
        .padding(20)
        .background(Theme.Colors.cardBackground)
        .cornerRadius(Theme.Dimensions.cornerRadiusMedium)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
        .sheet(isPresented: $showingNotificationSettings) {
            NotificationSettingsView()
        }
        .sheet(isPresented: $showingPrivacySettings) {
            PrivacySettingsView()
        }
        .sheet(isPresented: $showingHelpSupport) {
            HelpSupportView()
        }
        .sheet(isPresented: $showingAbout) {
            AboutView()
        }
    }
    
    // MARK: - Sign Out Button
    
    private var signOutButton: some View {
        Button {
            showingSignOutConfirmation = true
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "arrow.right.circle")
                    .font(.system(size: 18))
                Text("Sign Out")
                    .font(.system(size: 16, weight: .semibold))
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [
                        Theme.Colors.error,
                        Theme.Colors.error.opacity(0.8)
                    ]),
                    startPoint: .leading, 
                    endPoint: .trailing
                )
            )
            .cornerRadius(Theme.Dimensions.cornerRadiusMedium)
            .shadow(color: Theme.Colors.error.opacity(0.4), radius: 8, x: 0, y: 4)
        }
        .buttonStyle(ScaleButtonStyle())
    }
    
    // MARK: - Edit Profile View
    
    private var editProfileView: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header with subtle decoration
                ZStack(alignment: .top) {
                    // Decorative background
                    Rectangle()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Theme.Colors.primary.opacity(0.1),
                                    Theme.Colors.background
                                ]),
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(height: 160)
                    
                    // Profile image/initials
                    VStack {
                        if let user = authViewModel.currentUser {
                            if let photoURL = user.photoURL, !photoURL.isEmpty {
                                AsyncImage(url: URL(string: photoURL)) { phase in
                                    switch phase {
                                    case .success(let image):
                                        image
                                            .resizable()
                                            .aspectRatio(contentMode: .fill)
                                            .frame(width: 120, height: 120)
                                            .clipShape(Circle())
                                            .shadow(color: Color.black.opacity(0.2), radius: 8, x: 0, y: 4)
                                    default:
                                        largeInitialsView
                                    }
                                }
                            } else {
                                largeInitialsView
                            }
                        }
                        
                        Text("Edit Your Profile")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundColor(Theme.Colors.text)
                            .padding(.top, 16)
                    }
                    .padding(.top, 24)
                }
                
                // Form fields
                Form {
                    Section {
                        TextField("Name", text: $editedName)
                            .font(.system(size: 16))
                            .padding(.vertical, 10)
                    } header: {
                        Text("Personal Information")
                            .foregroundColor(Theme.Colors.primary)
                            .font(.system(size: 14, weight: .medium))
                    }
                    
                    // Future fields can be added here
                    // Section {
                    //     Toggle("Make profile public", isOn: $isPublic)
                    // } header: {
                    //     Text("Privacy")
                    // }
                }
                
                // Save button
                VStack {
                    Button("Save Changes") {
                        saveProfile()
                        isEditingProfile = false
                    }
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        editedName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                        ? Theme.Colors.primary.opacity(0.4)
                        : Theme.Colors.primary
                    )
                    .cornerRadius(10)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .disabled(editedName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
                .background(Color(UIColor.systemGroupedBackground))
                .cornerRadius(10, corners: [.topLeft, .topRight])
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        isEditingProfile = false
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(Theme.Colors.textSecondary)
                            .font(.system(size: 20))
                    }
                }
            }
            .background(Color(UIColor.systemGroupedBackground))
            .edgesIgnoringSafeArea(.bottom)
        }
    }
    
    // Larger initials view for edit profile screen
    private var largeInitialsView: some View {
        ZStack {
            Circle()
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Theme.Colors.primary.opacity(0.7),
                            Theme.Colors.primary
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 120, height: 120)
                .shadow(color: Color.black.opacity(0.2), radius: 8, x: 0, y: 4)
            
            Text(getInitials())
                .font(.system(size: 48, weight: .semibold, design: .rounded))
                .foregroundColor(.white)
        }
    }
    
    // MARK: - Segmented Control
    
    private var segmentedControl: some View {
        HStack(spacing: 0) {
            // Stats Tab
            Button {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                    selectedTab = 0
                }
            } label: {
                VStack(spacing: 8) {
                    Text("Stats")
                        .font(.system(size: 16, weight: selectedTab == 0 ? .semibold : .medium))
                        .foregroundColor(selectedTab == 0 ? Theme.Colors.primary : Theme.Colors.textSecondary)
                    
                    // Indicator
                    Capsule()
                        .fill(Theme.Colors.primary)
                        .frame(height: 3)
                        .opacity(selectedTab == 0 ? 1 : 0)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 40)
            }
            
            // Badges Tab
            Button {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                    selectedTab = 1
                    // Trigger badges to show with a slight delay
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        self.showingBadges = true
                    }
                }
            } label: {
                VStack(spacing: 8) {
                    Text("Badges")
                        .font(.system(size: 16, weight: selectedTab == 1 ? .semibold : .medium))
                        .foregroundColor(selectedTab == 1 ? Theme.Colors.primary : Theme.Colors.textSecondary)
                    
                    // Indicator
                    Capsule()
                        .fill(Theme.Colors.primary)
                        .frame(height: 3)
                        .opacity(selectedTab == 1 ? 1 : 0)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 40)
            }
        }
        .background(
            RoundedRectangle(cornerRadius: Theme.Dimensions.cornerRadiusMedium)
                .fill(Theme.Colors.cardBackground)
                .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
        )
    }
    
    // MARK: - Badges Section
    
    private var badgesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Your Badges")
                    .font(Theme.Typography.subheadingFontSystem)
                    .foregroundColor(Theme.Colors.text)
                
                Spacer()
                
                // Small visual indicator showing this is the active tab
                Capsule()
                    .fill(Theme.Colors.primary)
                    .frame(width: 30, height: 4)
                    .padding(.trailing, 4)
                    .opacity(selectedTab == 1 ? 1 : 0)
                    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: selectedTab)
            }
            
            // Badges grid
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 16), count: 3), spacing: 16) {
                if let user = authViewModel.currentUser {
                    ForEach(user.earnedBadges.isEmpty ? Badge.predefinedBadges : Badge.predefinedBadges) { badge in
                        let isEarned = user.earnedBadges.contains(badge.badgeKey)
                        
                        badgeCard(badge: badge, isEarned: isEarned)
                            .scaleEffect(showingBadges ? 1 : 0.5)
                            .opacity(showingBadges ? 1 : 0)
                            .animation(
                                Animation.spring(response: 0.5, dampingFraction: 0.7)
                                    .delay(0.1 + Double(Badge.predefinedBadges.firstIndex(where: { $0.badgeKey == badge.badgeKey }) ?? 0) * 0.1),
                                value: showingBadges
                            )
                    }
                } else {
                    // Placeholder badges if user data is not available
                    ForEach(Badge.predefinedBadges.prefix(3)) { badge in
                        badgeCard(badge: badge, isEarned: false)
                            .opacity(0.5)
                    }
                }
            }
            
            // Show badge status message
            if let user = authViewModel.currentUser {
                let earnedCount = user.earnedBadges.count
                let totalBadges = Badge.predefinedBadges.count
                
                HStack {
                    Spacer()
                    
                    Text("You've earned \(earnedCount) of \(totalBadges) badges")
                        .font(.system(size: 14))
                        .foregroundColor(Theme.Colors.textSecondary)
                    
                    Spacer()
                }
                .padding(.top, 8)
            }
        }
        .padding(20)
        .background(Theme.Colors.cardBackground)
        .cornerRadius(Theme.Dimensions.cornerRadiusMedium)
        .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 4)
        .onAppear {
            if selectedTab == 1 {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    self.showingBadges = true
                }
            }
        }
        .onDisappear {
            self.showingBadges = false
        }
    }
    
    // Individual badge card
    private func badgeCard(badge: Badge, isEarned: Bool) -> some View {
        VStack(spacing: 10) {
            // Badge icon with gradient background
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color(badge.colorName).opacity(isEarned ? 0.9 : 0.3),
                                Color(badge.colorName).opacity(isEarned ? 1.0 : 0.4)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 60, height: 60)
                    .shadow(color: isEarned ? Color(badge.colorName).opacity(0.5) : Color.clear, radius: 8, x: 0, y: 4)
                
                Image(systemName: badge.iconName)
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundColor(isEarned ? .white : .gray.opacity(0.6))
            }
            
            // Badge name and lock status
            VStack(spacing: 2) {
                Text(badge.name)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(isEarned ? Theme.Colors.text : Theme.Colors.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
                
                if !isEarned {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 10))
                        .foregroundColor(.gray.opacity(0.6))
                }
            }
        }
        .frame(height: 110)
        .padding(.vertical, 8)
        .padding(.horizontal, 4)
        .background(
            RoundedRectangle(cornerRadius: Theme.Dimensions.cornerRadiusSmall)
                .fill(Theme.Colors.cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: Theme.Dimensions.cornerRadiusSmall)
                        .stroke(Color.gray.opacity(0.1), lineWidth: 1)
                )
        )
    }
    
    // MARK: - Helper Methods
    
    private func getInitials() -> String {
        guard let name = authViewModel.currentUser?.name else { return "" }
        return name.components(separatedBy: " ")
            .reduce("") { ($0 == "" ? "" : "\($0.first!)") + "\($1.first!)" }
            .uppercased()
    }
    
    private func calculateMemberSince() -> String {
        guard let createdAt = authViewModel.currentUser?.createdAt else { return "N/A" }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: createdAt)
    }
    
    private func signOut() {
        Task {
            do {
                try await authViewModel.signOut()
                // Navigation to login screen will be handled by MainView based on auth state
            } catch {
                // Handle error (e.g., show an alert)
                print("Error signing out: \\(error.localizedDescription)")
            }
        }
    }
    
    private func saveProfile() {
        // TODO: Move this logic to AuthViewModel and then to AuthService
        // For now, directly updating Firestore for simplicity
        guard let userId = authViewModel.currentUser?.id else { return }
        let newName = editedName.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if newName.isEmpty {
            // Optionally, show an alert to the user that name cannot be empty
            return
        }
        
        Task {
            await authViewModel.updateUserName(newName: newName)
            // Optionally, refresh user data or rely on existing listeners
            // _ = await authViewModel.refreshCurrentUser() // This might be redundant if listeners are robust
        }
    }
    
    // MARK: - UI Components
    
    @ViewBuilder
    private func statCard(value: String, label: String, icon: String, color: Color) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(color)
                .frame(width: 40, height: 40)
                .background(color.opacity(0.2))
                .clipShape(RoundedRectangle(cornerRadius: Theme.Dimensions.cornerRadiusSmall))
            
            VStack(alignment: .leading, spacing: 4) {
                Text(value)
                    .font(Theme.Typography.subheadingFontSystem)
                    .foregroundColor(Theme.Colors.text)
                
                Text(label)
                    .font(Theme.Typography.captionFontSystem)
                    .foregroundColor(Theme.Colors.textSecondary)
            }
            
            Spacer()
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(Theme.Colors.cardBackground)
        .cornerRadius(Theme.Dimensions.cornerRadiusSmall)
        .overlay(
            RoundedRectangle(cornerRadius: Theme.Dimensions.cornerRadiusSmall)
                .stroke(Color.gray.opacity(0.1), lineWidth: 1)
        )
    }
    
    private func settingRow(icon: String, title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(Theme.Colors.primary)
                    .frame(width: 40)
                
                Text(title)
                    .font(Theme.Typography.bodyFontSystem)
                    .foregroundColor(Theme.Colors.text)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Theme.Colors.textSecondary)
            }
            .padding(.vertical, 16)
        }
    }
    
    // Enhanced Edit Profile button
    func modernEditProfileButton() -> some View {
        Button {
            if let user = authViewModel.currentUser {
                editedName = user.name
            }
            isEditingProfile = true
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "pencil")
                    .font(.system(size: 14))
                Text("Edit Profile")
                    .font(.system(size: 14, weight: .medium))
            }
            .foregroundColor(Theme.Colors.primary)
            .padding(.vertical, 8)
            .padding(.horizontal, 16)
            .background(
                Capsule()
                    .fill(Theme.Colors.primary.opacity(0.05))
                    .overlay(
                        Capsule()
                            .stroke(Theme.Colors.primary.opacity(0.7), lineWidth: 1.5)
                    )
                    .shadow(color: Theme.Colors.primary.opacity(0.2), radius: 3, x: 0, y: 2)
            )
        }
        .buttonStyle(ScaleButtonStyle()) // Apply scale animation on press
        .padding(.top, 12)
        .opacity(profileAppeared ? 1 : 0)
        .offset(y: profileAppeared ? 0 : 10)
        .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.4), value: profileAppeared)
    }

    // Calculate member since for short format
    private func calculateMemberSinceShort() -> String {
        guard let createdAt = authViewModel.currentUser?.createdAt else { return "N/A" }
        
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM yyyy"
        return formatter.string(from: createdAt)
    }
}

// MARK: - Extension for rounded corners

extension View {
    /// Apply rounded corners to specific corners of a view
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape( RoundedCornerShape(radius: radius, corners: corners) )
    }
}

/// Custom shape for applying rounded corners to specific sides
struct RoundedCornerShape: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect, 
            byRoundingCorners: corners, 
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}
