// HouseholdView.swift
// MyChores
//
// Created on 2025-05-02.
//

import SwiftUI

/// View for managing household settings and members
struct HouseholdView: View {
    @Binding var selectedHouseholdId: String?
    @StateObject private var viewModel = HouseholdViewModel()
    @State private var showingInviteSheet = false
    @State private var showingLeaveAlert = false
    @State private var showingCreateHousehold = false
    @State private var showingJoinHousehold = false
    
    var onCreateNewHousehold: (() -> Void)? = nil
    
    var body: some View {
        ZStack {
            Theme.Colors.background.ignoresSafeArea()
            
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
                        }
                        
                        // Current household info
                        if let household = viewModel.selectedHousehold {
                            currentHouseholdSection(household: household)
                        }
                        
                        // Members section
                        if !viewModel.householdMembers.isEmpty {
                            membersSection(members: viewModel.householdMembers)
                        }
                        
                        // Actions section
                        actionsSection
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
        }
    }
    
    // MARK: - UI Components
    
    private func householdPicker(user: User) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Select Household")
                .font(Theme.Typography.captionFontSystem)
                .foregroundColor(Theme.Colors.textSecondary)
            
            Menu {
                ForEach(user.householdIds, id: \.self) { householdId in
                    Button {
                        selectedHouseholdId = householdId
                    } label: {
                        if householdId == selectedHouseholdId {
                            Label(getHouseholdName(id: householdId) ?? "Household", systemImage: "checkmark")
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
                    Text(getHouseholdName(id: selectedHouseholdId) ?? "Select Household")
                        .font(Theme.Typography.bodyFontSystem)
                        .foregroundColor(Theme.Colors.text)
                    
                    Spacer()
                    
                    Image(systemName: "chevron.down")
                        .font(.system(size: 14))
                        .foregroundColor(Theme.Colors.textSecondary)
                }
                .padding()
                .background(Theme.Colors.cardBackground)
                .cornerRadius(Theme.Dimensions.cornerRadiusMedium)
                .overlay(
                    RoundedRectangle(cornerRadius: Theme.Dimensions.cornerRadiusMedium)
                        .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                )
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 16)
    }
    
    private func currentHouseholdSection(household: Household) -> some View {
        VStack(spacing: 16) {
            // Household icon and name
            VStack(spacing: 8) {
                Image(systemName: "house.fill")
                    .font(.system(size: 40))
                    .foregroundColor(Theme.Colors.primary)
                
                Text(household.name)
                    .font(Theme.Typography.titleFontSystem)
                    .foregroundColor(Theme.Colors.text)
                    .multilineTextAlignment(.center)
            }
            
            // Household stats
            HStack(spacing: 24) {
                VStack(spacing: 4) {
                    Text("\(viewModel.householdMembers.count)")
                        .font(Theme.Typography.subheadingFontSystem.bold())
                        .foregroundColor(Theme.Colors.primary)
                    
                    Text("Members")
                        .font(Theme.Typography.captionFontSystem)
                        .foregroundColor(Theme.Colors.textSecondary)
                }
                
                VStack(spacing: 4) {
                    Text(household.createdAt.formatted(date: .abbreviated, time: .omitted))
                        .font(Theme.Typography.subheadingFontSystem.bold())
                        .foregroundColor(Theme.Colors.secondary)
                    
                    Text("Created")
                        .font(Theme.Typography.captionFontSystem)
                        .foregroundColor(Theme.Colors.textSecondary)
                }
            }
            
            // Invite code card
            Button {
                showingInviteSheet = true
            } label: {
                HStack {
                    Image(systemName: "person.badge.plus")
                        .font(.system(size: 20))
                        .foregroundColor(Theme.Colors.primary)
                    
                    Text("Share Invite Code")
                        .font(Theme.Typography.bodyFontSystem.bold())
                        .foregroundColor(Theme.Colors.primary)
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(Theme.Colors.primary.opacity(0.1))
                .cornerRadius(Theme.Dimensions.cornerRadiusMedium)
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
            
            ForEach(members, id: \.stableId) { member in
                memberRow(member: member)
            }
        }
        .padding(.vertical, 16)
        .background(Theme.Colors.cardBackground)
        .cornerRadius(Theme.Dimensions.cornerRadiusMedium)
        .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
    
    private func memberRow(member: User) -> some View {
        HStack(spacing: 16) {
            // Avatar
            Circle()
                .fill(Theme.Colors.secondary)
                .frame(width: 50, height: 50)
                .overlay(
                    Text(getInitials(from: member.name))
                        .font(Theme.Typography.bodyFontSystem.bold())
                        .foregroundColor(.white)
                )
            
            // Name and email
            VStack(alignment: .leading, spacing: 4) {
                Text(member.name)
                    .font(Theme.Typography.bodyFontSystem.bold())
                    .foregroundColor(Theme.Colors.text)
                
                Text(member.email)
                    .font(Theme.Typography.captionFontSystem)
                    .foregroundColor(Theme.Colors.textSecondary)
            }
            
            Spacer()
            
            // Creator badge or current user indicator
            if isCreator(member) {
                Text("Creator")
                    .font(Theme.Typography.captionFontSystem.bold())
                    .foregroundColor(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Theme.Colors.accent)
                    .cornerRadius(12)
            } else if isCurrentUser(member) {
                Text("You")
                    .font(Theme.Typography.captionFontSystem.bold())
                    .foregroundColor(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Theme.Colors.primary)
                    .cornerRadius(12)
            }
        }
        .padding(16)
    }
    
    private var actionsSection: some View {
        VStack(spacing: 16) {
            // Join or create household buttons (if no household selected)
            if viewModel.selectedHousehold == nil {
                Button {
                    showingCreateHousehold = true
                    onCreateNewHousehold?()
                } label: {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                        Text("Create New Household")
                    }
                    .font(Theme.Typography.bodyFontSystem.bold())
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Theme.Colors.primary)
                    .cornerRadius(Theme.Dimensions.cornerRadiusMedium)
                }
                
                Button {
                    showingJoinHousehold = true
                } label: {
                    HStack {
                        Image(systemName: "person.badge.plus")
                        Text("Join Household")
                    }
                    .font(Theme.Typography.bodyFontSystem.bold())
                    .foregroundColor(Theme.Colors.primary)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Theme.Colors.primary.opacity(0.1))
                    .cornerRadius(Theme.Dimensions.cornerRadiusMedium)
                }
            } else {
                // Leave current household
                Button {
                    showingLeaveAlert = true
                } label: {
                    HStack {
                        Image(systemName: "rectangle.portrait.and.arrow.right")
                        Text("Leave Household")
                    }
                    .font(Theme.Typography.bodyFontSystem.bold())
                    .foregroundColor(Theme.Colors.error)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Theme.Colors.error.opacity(0.1))
                    .cornerRadius(Theme.Dimensions.cornerRadiusMedium)
                }
            }
        }
        .padding(.top, 8)
    }
    
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
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                // Icon
                Image(systemName: "person.badge.plus")
                    .font(.system(size: 60))
                    .foregroundColor(Theme.Colors.primary)
                    .padding(.top, 40)
                
                // Title
                Text("Invite Others")
                    .font(Theme.Typography.titleFontSystem)
                    .foregroundColor(Theme.Colors.text)
                
                // Description
                Text("Share this code with others to invite them to your household")
                    .font(Theme.Typography.bodyFontSystem)
                    .foregroundColor(Theme.Colors.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                
                // Invite code display
                VStack(spacing: 8) {
                    Text("Invite Code")
                        .font(Theme.Typography.captionFontSystem)
                        .foregroundColor(Theme.Colors.textSecondary)
                    
                    Text(inviteCode)
                        .font(.system(size: 32, weight: .bold, design: .monospaced))
                        .kerning(2)
                        .foregroundColor(Theme.Colors.primary)
                        .padding(.vertical, 16)
                        .padding(.horizontal, 24)
                        .background(Theme.Colors.primary.opacity(0.1))
                        .cornerRadius(Theme.Dimensions.cornerRadiusMedium)
                }
                .padding(.top, 16)
                
                // Copy button
                Button {
                    UIPasteboard.general.string = inviteCode
                    copiedToClipboard = true
                    
                    // Hide the "Copied" message after a delay
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        copiedToClipboard = false
                    }
                } label: {
                    HStack {
                        Image(systemName: copiedToClipboard ? "checkmark" : "doc.on.doc")
                        Text(copiedToClipboard ? "Copied!" : "Copy to Clipboard")
                    }
                    .font(Theme.Typography.bodyFontSystem.bold())
                    .foregroundColor(.white)
                    .frame(width: 200)
                    .padding()
                    .background(copiedToClipboard ? Theme.Colors.success : Theme.Colors.primary)
                    .cornerRadius(Theme.Dimensions.cornerRadiusMedium)
                    .animation(.spring(), value: copiedToClipboard)
                }
                
                Spacer()
            }
            .padding(.horizontal, 24)
            .navigationTitle("Invite Code")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    HouseholdView(selectedHouseholdId: .constant("preview_household_id"))
}
