// HouseholdView.swift
// MyChores
//
// Created on 2025-05-02.
//

import SwiftUI

struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed)
    }
}
/// View for managing household settings and members
struct HouseholdView: View {
    @Binding var selectedHouseholdId: String?
    @StateObject private var viewModel = HouseholdViewModel()
    @State private var showingInviteSheet = false
    @State private var showingLeaveAlert = false
    @State private var showingCreateHousehold = false
    @State private var showingJoinHousehold = false
    
    // Animation states
    @State private var headerAppeared = false
    @State private var cardsAppeared = false
    @State private var buttonsAppeared = false
    
    var onCreateNewHousehold: (() -> Void)? = nil
    
    var body: some View {
        ZStack {
            Theme.Colors.background.ignoresSafeArea()
            
            // Background decoration
            VStack {
                Circle()
                    .fill(Theme.Colors.primary.opacity(0.05))
                    .frame(width: 300, height: 300)
                    .offset(x: 150, y: -150)
                    .blur(radius: 50)
                
                Circle()
                    .fill(Theme.Colors.secondary.opacity(0.05))
                    .frame(width: 200, height: 200)
                    .offset(x: -150, y: 100)
                    .blur(radius: 40)
                
                Spacer()
            }
            .ignoresSafeArea()
            
            if viewModel.isLoading {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle())
                    .scaleEffect(1.5)
            } else {
                ScrollView {
                    VStack(spacing: 24) {
                        // Household picker (if user belongs to multiple households)
                        if let user = viewModel.currentUser, user.householdIds.count > 1 {
                            householdPicker(user: user)
                                .transition(.move(edge: .top).combined(with: .opacity))
                                .animation(.easeInOut(duration: 0.5).delay(0.1), value: headerAppeared)
                                .opacity(headerAppeared ? 1 : 0)
                        }
                        
                        // Current household info
                        if let household = viewModel.selectedHousehold {
                            currentHouseholdSection(household: household)
                                .transition(.scale.combined(with: .opacity))
                                .animation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.2), value: cardsAppeared)
                                .opacity(cardsAppeared ? 1 : 0)
                                .offset(y: cardsAppeared ? 0 : 20)
                        }
                        
                        // Members section
                        if !viewModel.householdMembers.isEmpty {
                            membersSection(members: viewModel.householdMembers)
                                .transition(.move(edge: .bottom).combined(with: .opacity))
                                .animation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.3), value: cardsAppeared)
                                .opacity(cardsAppeared ? 1 : 0)
                                .offset(y: cardsAppeared ? 0 : 20)
                        }
                        
                        // Actions section
                        actionsSection
                            .transition(.scale.combined(with: .opacity))
                            .animation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.4), value: buttonsAppeared)
                            .opacity(buttonsAppeared ? 1 : 0)
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 24)
                }
            }
        }
        .sheet(isPresented: $showingInviteSheet) {
            if let household = viewModel.selectedHousehold {
                InviteCodeView(inviteCode: household.inviteCode)
            }
        }
        .sheet(isPresented: $showingCreateHousehold) {
            CreateHouseholdView()
                .environmentObject(viewModel)
        }
        .sheet(isPresented: $showingJoinHousehold) {
            JoinHouseholdView()
                .environmentObject(viewModel)
        }
        .alert("Leave Household", isPresented: $showingLeaveAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Leave", role: .destructive) {
                leaveCurrentHousehold()
            }
        } message: {
            Text("Are you sure you want to leave this household? You will need to be invited again to rejoin.")
        }
        .alert(
            "Error",
            isPresented: .init(
                get: { viewModel.errorMessage != nil },
                set: { if !$0 { viewModel.errorMessage = nil } }
            ),
            actions: { Button("OK", role: .cancel) {} },
            message: { Text(viewModel.errorMessage ?? "") }
        )
        .onChange(of: selectedHouseholdId) { newValue in
            if let id = newValue {
                viewModel.fetchHousehold(id: id)
            }
        }
        .onChange(of: viewModel.selectedHousehold) { newValue in
            if let household = newValue {
                selectedHouseholdId = household.id
            }
        }
        .onAppear {
            if let id = selectedHouseholdId {
                viewModel.fetchHousehold(id: id)
            }
            
            // Trigger animations
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation {
                    headerAppeared = true
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    withAnimation {
                        cardsAppeared = true
                    }
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        withAnimation {
                            buttonsAppeared = true
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - UI Components
    
    private func householdPicker(user: User) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Select Household")
                .font(Theme.Typography.captionFontSystem)
                .foregroundColor(Theme.Colors.textSecondary)
                .padding(.leading, 4)
            
            Menu {
                ForEach(user.householdIds, id: \.self) { householdId in
                    Button {
                        selectedHouseholdId = householdId
                    } label: {
                        if householdId == selectedHouseholdId {
                            Label(getHouseholdName(id: householdId) ?? "Household", systemImage: "checkmark")
                                .foregroundColor(Theme.Colors.primary)
                        } else {
                            Text(getHouseholdName(id: householdId) ?? "Household")
                        }
                    }
                }
                
                Divider()
                
                Button {
                    showingCreateHousehold = true
                    onCreateNewHousehold?()
                } label: {
                    Label("Create New Household", systemImage: "plus")
                }
                
                Button {
                    showingJoinHousehold = true
                } label: {
                    Label("Join Household", systemImage: "person.badge.plus")
                }
            } label: {
                HStack {
                    HStack(spacing: 12) {
                        // House icon with color based on selected household
                        ZStack {
                            Circle()
                                .fill(Theme.Colors.primary.opacity(0.15))
                                .frame(width: 36, height: 36)
                            
                            Image(systemName: "house.fill")
                                .font(.system(size: 16))
                                .foregroundColor(Theme.Colors.primary)
                        }
                        
                        Text(getHouseholdName(id: selectedHouseholdId) ?? "Select Household")
                            .font(Theme.Typography.bodyFontSystem.bold())
                            .foregroundColor(Theme.Colors.text)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.down")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(Theme.Colors.textSecondary)
                        .padding(8)
                        .background(Color.black.opacity(0.03))
                        .clipShape(Circle())
                }
                .padding(.vertical, 12)
                .padding(.horizontal, 16)
                .background(
                    RoundedRectangle(cornerRadius: Theme.Dimensions.cornerRadiusMedium)
                        .fill(Theme.Colors.cardBackground)
                        .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: Theme.Dimensions.cornerRadiusMedium)
                        .stroke(
                            LinearGradient(
                                colors: [Theme.Colors.primary.opacity(0.3), Theme.Colors.primary.opacity(0.1)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
                .contentShape(Rectangle())
            }
        }
        .padding(.top, 16)
    }
    
    private func currentHouseholdSection(household: Household) -> some View {
        VStack(spacing: 20) {
            // Household icon and name with shimmer effect
            VStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(Theme.Colors.primary.opacity(0.15))
                        .frame(width: 90, height: 90)
                    
                    Circle()
                        .fill(Theme.Colors.cardBackground)
                        .frame(width: 80, height: 80)
                        .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
                    
                    Image(systemName: "house.fill")
                        .font(.system(size: 40))
                        .foregroundColor(Theme.Colors.primary)
                        .shadow(color: Theme.Colors.primary.opacity(0.3), radius: 2, x: 0, y: 1)
                }
                .overlay(
                    Circle()
                        .stroke(
                            LinearGradient(
                                gradient: Gradient(colors: [Theme.Colors.primary.opacity(0.7), Theme.Colors.primary.opacity(0.1)]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 2
                        )
                        .rotationEffect(Angle(degrees: headerAppeared ? 360 : 0))
                        .animation(
                            Animation.linear(duration: 10).repeatForever(autoreverses: false),
                            value: headerAppeared
                        )
                )
                
                Text(household.name)
                    .font(Theme.Typography.titleFontSystem)
                    .foregroundColor(Theme.Colors.text)
                    .multilineTextAlignment(.center)
            }
            
            // Household stats with improved visual styling
            HStack(spacing: 32) {
                VStack(spacing: 6) {
                    Text("\(viewModel.householdMembers.count)")
                        .font(Theme.Typography.headingFontSystem.bold())
                        .foregroundColor(Theme.Colors.primary)
                    
                    Text("Members")
                        .font(Theme.Typography.captionFontSystem)
                        .foregroundColor(Theme.Colors.textSecondary)
                        .padding(.top, 2)
                }
                .frame(width: 100)
                
                VStack(spacing: 6) {
                    Text(household.createdAt.formatted(date: .abbreviated, time: .omitted))
                        .font(Theme.Typography.headingFontSystem.bold())
                        .foregroundColor(Theme.Colors.secondary)
                    
                    Text("Created")
                        .font(Theme.Typography.captionFontSystem)
                        .foregroundColor(Theme.Colors.textSecondary)
                        .padding(.top, 2)
                }
                .frame(width: 100)
            }
            .padding(.vertical, 10)
            .background(Theme.Colors.cardBackground.opacity(0.6))
            .cornerRadius(Theme.Dimensions.cornerRadiusMedium)
            
            // Invite code card with animated effects
            Button {
                showingInviteSheet = true
            } label: {
                HStack {
                    Image(systemName: "person.badge.plus")
                        .font(.system(size: 20))
                        .symbolEffect(.pulse, options: .repeating, value: cardsAppeared)
                    
                    Text("Share Invite Code")
                        .font(Theme.Typography.bodyFontSystem.bold())
                }
                .foregroundColor(Theme.Colors.primary)
                .padding(.vertical, 12)
                .padding(.horizontal, 16)
                .frame(maxWidth: .infinity)
                .background(
                    LinearGradient(
                        colors: [
                            Theme.Colors.primary.opacity(0.12),
                            Theme.Colors.primary.opacity(0.08)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: Theme.Dimensions.cornerRadiusMedium)
                        .stroke(Theme.Colors.primary.opacity(0.3), lineWidth: 1)
                )
                .cornerRadius(Theme.Dimensions.cornerRadiusMedium)
                .shadow(color: Theme.Colors.primary.opacity(0.2), radius: 2, x: 0, y: 2)
            }
        }
        .padding()
        .background(Theme.Colors.cardBackground)
        .cornerRadius(Theme.Dimensions.cornerRadiusMedium)
        .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
    
    private func membersSection(members: [User]) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Members")
                .font(Theme.Typography.subheadingFontSystem)
                .foregroundColor(Theme.Colors.text)
                .padding(.horizontal, 16)
            
            ForEach(Array(members.enumerated()), id: \.element.stableId) { index, member in
                memberRow(member: member, index: index)
            }
        }
        .padding(.vertical, 16)
        .background(Theme.Colors.cardBackground)
        .cornerRadius(Theme.Dimensions.cornerRadiusMedium)
        .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
    
    private func memberRow(member: User, index: Int) -> some View {
        // Animation state to stagger the appearance of members
        let isLast = index == viewModel.householdMembers.count - 1
        let animationDelay = 0.2 + (Double(index) * 0.1)
        
        return HStack(spacing: 16) {
            // Enhanced avatar
            ZStack {
                Circle()
                    .fill(getMemberColor(member))
                    .frame(width: 50, height: 50)
                    .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
                
                // White inner circle
                Circle()
                    .fill(Color.white.opacity(0.9))
                    .frame(width: 42, height: 42)
                
                // Initials
                Text(getInitials(from: member.name))
                    .font(Theme.Typography.bodyFontSystem.bold())
                    .foregroundColor(getMemberColor(member))
            }
            .drawingGroup() // Use Metal rendering for better performance
            
            // Name and email with improved styling
            VStack(alignment: .leading, spacing: 4) {
                Text(member.name)
                    .font(Theme.Typography.bodyFontSystem.bold())
                    .foregroundColor(Theme.Colors.text)
                
                Text(member.email)
                    .font(Theme.Typography.captionFontSystem)
                    .foregroundColor(Theme.Colors.textSecondary)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }
            
            Spacer()
            
            // Enhanced badges
            if isCreator(member) {
                HStack(spacing: 4) {
                    Image(systemName: "crown.fill")
                        .font(.system(size: 12))
                    
                    Text("Creator")
                        .font(Theme.Typography.captionFontSystem.bold())
                }
                .foregroundColor(.white)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(
                    LinearGradient(
                        colors: [Theme.Colors.accent, Theme.Colors.accent.opacity(0.8)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .cornerRadius(12)
                .shadow(color: Theme.Colors.accent.opacity(0.3), radius: 2, x: 0, y: 1)
            } else if isCurrentUser(member) {
                Text("You")
                    .font(Theme.Typography.captionFontSystem.bold())
                    .foregroundColor(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(
                        LinearGradient(
                            colors: [Theme.Colors.primary, Theme.Colors.primary.opacity(0.8)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .cornerRadius(12)
                    .shadow(color: Theme.Colors.primary.opacity(0.3), radius: 2, x: 0, y: 1)
            }
        }
        .padding(16)
        .background(isCurrentUser(member) ? Theme.Colors.primary.opacity(0.05) : Color.clear)
        .cornerRadius(Theme.Dimensions.cornerRadiusSmall)
        .padding(.horizontal, 8)
        // Add staggered animations for each member row
        .opacity(cardsAppeared ? 1 : 0)
        .offset(y: cardsAppeared ? 0 : 20)
        .animation(.spring(response: 0.4, dampingFraction: 0.8).delay(animationDelay), value: cardsAppeared)
        // Add divider after all but last member
        .overlay(alignment: .bottom) {
            if !isLast {
                Divider()
                    .padding(.horizontal, 16)
                    .opacity(0.5)
            }
        }
    }
    
    private var actionsSection: some View {
        VStack(spacing: 16) {
            // Join or create household buttons (if no household selected)
            if viewModel.selectedHousehold == nil {
                Button {
                    showingCreateHousehold = true
                    onCreateNewHousehold?()
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 20))
                            .symbolRenderingMode(.hierarchical)
                            .symbolEffect(.bounce, options: .repeat(2), value: buttonsAppeared)
                        
                        Text("Create New Household")
                            .fontWeight(.bold)
                    }
                    .font(Theme.Typography.bodyFontSystem)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        LinearGradient(
                            colors: [Theme.Colors.primary, Theme.Colors.primary.opacity(0.8)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: Theme.Dimensions.cornerRadiusMedium))
                    .shadow(color: Theme.Colors.primary.opacity(0.3), radius: 5, x: 0, y: 3)
                }
                .buttonStyle(ScaleButtonStyle())
                
                Button {
                    showingJoinHousehold = true
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "person.badge.plus")
                            .font(.system(size: 20))
                            .symbolRenderingMode(.hierarchical)
                        
                        Text("Join Household")
                            .fontWeight(.bold)
                    }
                    .font(Theme.Typography.bodyFontSystem)
                    .foregroundColor(Theme.Colors.primary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Theme.Colors.primary.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: Theme.Dimensions.cornerRadiusMedium)
                            .stroke(Theme.Colors.primary.opacity(0.3), lineWidth: 1)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: Theme.Dimensions.cornerRadiusMedium))
                }
                .buttonStyle(ScaleButtonStyle())
            } else {
                // Leave current household
                Button {
                    showingLeaveAlert = true
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "rectangle.portrait.and.arrow.right")
                            .font(.system(size: 20))
                            .symbolRenderingMode(.hierarchical)
                        
                        Text("Leave Household")
                            .fontWeight(.bold)
                    }
                    .font(Theme.Typography.bodyFontSystem)
                    .foregroundColor(Theme.Colors.error)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Theme.Colors.error.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: Theme.Dimensions.cornerRadiusMedium)
                            .stroke(Theme.Colors.error.opacity(0.3), lineWidth: 1)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: Theme.Dimensions.cornerRadiusMedium))
                }
                .buttonStyle(ScaleButtonStyle())
            }
        }
        .padding(.top, 8)
    }
    
    // MARK: - Button Styles
    
    /// Custom button style that scales when pressed
    
    // MARK: - Helper Methods
    
    private func getHouseholdName(id: String?) -> String? {
        guard let id = id else { return nil }
        
        if let household = viewModel.households.first(where: { $0.id == id }) {
            return household.name
        }
        
        return "Household"
    }
    
    private func getInitials(from name: String) -> String {
        let components = name.components(separatedBy: " ")
        if components.count > 1, let first = components.first?.first, let last = components.last?.first {
            return "\(first)\(last)"
        } else if let first = name.first {
            return String(first)
        } else {
            return "?"
        }
    }
    
    /// Gets a consistent color for a user based on their ID
    private func getMemberColor(_ user: User) -> Color {
        // This allows us to have consistent colors for specific users
        if let userId = user.id, let firstChar = userId.first {
            let value = Int(firstChar.asciiValue ?? 0) % 5
            switch value {
            case 0: return Theme.Colors.secondary
            case 1: return Theme.Colors.accent 
            case 2: return Theme.Colors.primary
            case 3: return Color(red: 0.4, green: 0.6, blue: 0.9) // Light blue
            default: return Color(red: 0.8, green: 0.4, blue: 0.7) // Purple
            }
        }
        return Theme.Colors.secondary
    }
    
    private func isCreator(_ user: User) -> Bool {
        guard let household = viewModel.selectedHousehold else { return false }
        return user.id == household.ownerUserId
    }
    
    private func isCurrentUser(_ user: User) -> Bool {
        return user.id == AuthService.shared.getCurrentUserId()
    }
    
    private func leaveCurrentHousehold() {
        guard let householdId = selectedHouseholdId else { return }
        
        viewModel.leaveHousehold(householdId: householdId) { success in
            if success {
                // Find another household to select, or set to nil
                if let user = viewModel.currentUser {
                    let remainingHouseholds = user.householdIds.filter { $0 != householdId }
                    selectedHouseholdId = remainingHouseholds.first
                } else {
                    selectedHouseholdId = nil
                }
            }
        }
    }
}

/// View for displaying a household invite code
struct InviteCodeView: View {
    @Environment(\.dismiss) private var dismiss
    let inviteCode: String
    @State private var copiedToClipboard = false
    
    // Animation states
    @State private var showContent = false
    @State private var pulseEffect = false
    @State private var rotateEffect = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Animated background elements
                Color(UIColor.systemGroupedBackground).ignoresSafeArea()
                
                // Background decorative elements
                Circle()
                    .fill(Theme.Colors.primary.opacity(0.07))
                    .frame(width: 220, height: 220)
                    .offset(x: 150, y: -150)
                    .blur(radius: 60)
                
                Circle()
                    .fill(Theme.Colors.accent.opacity(0.07))
                    .frame(width: 180, height: 180)
                    .offset(x: -150, y: 100)
                    .blur(radius: 50)
                
                VStack(spacing: 32) {
                    // Animated icon
                    ZStack {
                        Circle()
                            .fill(Theme.Colors.primary.opacity(0.1))
                            .frame(width: 120, height: 120)
                            .scaleEffect(pulseEffect ? 1.15 : 0.95)
                            .animation(
                                Animation.easeInOut(duration: 1.5)
                                    .repeatForever(autoreverses: true),
                                value: pulseEffect
                            )
                        
                        Circle()
                            .strokeBorder(
                                AngularGradient(
                                    gradient: Gradient(colors: [
                                        Theme.Colors.primary.opacity(0.8),
                                        Theme.Colors.primary.opacity(0.2),
                                        Theme.Colors.primary.opacity(0.8)
                                    ]),
                                    center: .center
                                ),
                                lineWidth: 4
                            )
                            .frame(width: 110, height: 110)
                            .rotationEffect(Angle(degrees: rotateEffect ? 360 : 0))
                            .animation(
                                Animation.linear(duration: 8)
                                    .repeatForever(autoreverses: false),
                                value: rotateEffect
                            )
                        
                        Image(systemName: "person.badge.plus")
                            .font(.system(size: 50, weight: .light))
                            .symbolRenderingMode(.hierarchical)
                            .foregroundColor(Theme.Colors.primary)
                    }
                    .padding(.top, 20)
                    .opacity(showContent ? 1 : 0)
                    .offset(y: showContent ? 0 : 20)
                    .animation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.1), value: showContent)
                    
                    // Title and Description
                    VStack(spacing: 16) {
                        Text("Invite Others")
                            .font(Theme.Typography.titleFontSystem)
                            .foregroundColor(Theme.Colors.text)
                        
                        Text("Share this code with others to invite them to your household")
                            .font(Theme.Typography.bodyFontSystem)
                            .foregroundColor(Theme.Colors.textSecondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                    }
                    .opacity(showContent ? 1 : 0)
                    .offset(y: showContent ? 0 : 20)
                    .animation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.2), value: showContent)
                    
                    // Invite code display with fancy styling
                    VStack(spacing: 12) {
                        Text("Invite Code")
                            .font(Theme.Typography.captionFontSystem)
                            .foregroundColor(Theme.Colors.textSecondary)
                        
                        Text(inviteCode)
                            .font(.system(size: 36, weight: .bold, design: .monospaced))
                            .kerning(3)
                            .tracking(2)
                            .foregroundColor(Theme.Colors.primary)
                            .padding(.vertical, 20)
                            .padding(.horizontal, 32)
                            .background(
                                ZStack {
                                    RoundedRectangle(cornerRadius: Theme.Dimensions.cornerRadiusMedium)
                                        .fill(Color.white)
                                    
                                    RoundedRectangle(cornerRadius: Theme.Dimensions.cornerRadiusMedium)
                                        .stroke(
                                            LinearGradient(
                                                gradient: Gradient(colors: [
                                                    Theme.Colors.primary.opacity(0.6),
                                                    Theme.Colors.primary.opacity(0.2)
                                                ]),
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            ),
                                            lineWidth: 2
                                        )
                                }
                            )
                            .shadow(color: Theme.Colors.primary.opacity(0.1), radius: 8, x: 0, y: 4)
                    }
                    .opacity(showContent ? 1 : 0)
                    .scaleEffect(showContent ? 1 : 0.9)
                    .animation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.3), value: showContent)
                    
                    // Copy button with enhanced animation
                    Button {
                        UIPasteboard.general.string = inviteCode
                        withAnimation(.spring()) {
                            copiedToClipboard = true
                        }
                        
                        // Hide the "Copied" message after a delay
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            withAnimation(.spring()) {
                                copiedToClipboard = false
                            }
                        }
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: copiedToClipboard ? "checkmark" : "doc.on.doc")
                                .font(.system(size: 18))
                                .symbolEffect(
                                    copiedToClipboard ? .bounce.down : .bounce.up,
                                    options: .speed(1.5),
                                    value: copiedToClipboard
                                )
                            
                            Text(copiedToClipboard ? "Copied to Clipboard!" : "Copy to Clipboard")
                                .fontWeight(.bold)
                        }
                        .font(Theme.Typography.bodyFontSystem)
                        .foregroundColor(.white)
                        .frame(height: 50)
                        .frame(width: 260)
                        .background(
                            RoundedRectangle(cornerRadius: Theme.Dimensions.cornerRadiusMedium)
                                .fill(
                                    copiedToClipboard ? 
                                    LinearGradient(
                                        colors: [Theme.Colors.success, Theme.Colors.success.opacity(0.8)],
                                        startPoint: .topLeading, 
                                        endPoint: .bottomTrailing
                                    ) :
                                    LinearGradient(
                                        colors: [Theme.Colors.primary, Theme.Colors.primary.opacity(0.8)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .shadow(color: copiedToClipboard ? 
                                        Theme.Colors.success.opacity(0.4) : 
                                        Theme.Colors.primary.opacity(0.4),
                                        radius: 8, x: 0, y: 4)
                        )
                    }
                    .opacity(showContent ? 1 : 0)
                    .offset(y: showContent ? 0 : 20)
                    .animation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.4), value: showContent)
                    .buttonStyle(ScaleButtonStyle()) // Reusing the scale button style
                    
                    Spacer()
                }
                .padding(.horizontal, 24)
            }
            .navigationTitle("Invite Code")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                // Start animations
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    showContent = true
                    pulseEffect = true
                    rotateEffect = true
                }
            }
        }
    }
}

#Preview {
    HouseholdView(selectedHouseholdId: .constant("preview_household_id"))
}
