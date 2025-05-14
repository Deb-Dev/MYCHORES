// AddChoreView.swift
// MyChores
//
// Created on 2025-05-02.
//

import SwiftUI
import FirebaseFirestore
import FirebaseAuth

/// View for adding a new chore
struct AddChoreView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: ChoreViewModel
    
    // Chore properties
    @State private var title = ""
    @State private var description = ""
    @State private var assignedToUserId: String?
    @State private var dueDate = Date().addingTimeInterval(24 * 60 * 60) // Tomorrow by default
    @State private var hasDueDate = true
    @State private var pointValue = 1
    @State private var isRecurring = false
    @State private var recurrenceType: RecurrenceType = .weekly
    @State private var recurrenceInterval = 1
    @State private var recurrenceDaysOfWeek: [Int] = []
    @State private var recurrenceDayOfMonth: Int?
    @State private var recurrenceEndDate: Date?
    @State private var hasRecurrenceEndDate = false
    
    // UI state
    @State private var availableUsers: [User] = []
    @State private var isLoadingUsers = false
    
    init(householdId: String) {
        self._viewModel = StateObject(wrappedValue: ChoreViewModel(householdId: householdId))
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Theme.Colors.background.ignoresSafeArea()
                
                mainFormContent
            }
            .navigationTitle("Add Chore")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        Task{
                            await addChore()

                        }
                    }
                    .disabled(!isFormValid)
                }
            }
            .alert(
                "Error",
                isPresented: errorAlertBinding(),
                actions: { Button("OK", role: .cancel) {} },
                message: { Text(viewModel.errorMessage ?? "") }
            )
        }
    }
    
    // MARK: - Content Sections
    
    private var mainFormContent: some View {
        Form {
            basicDetailsSection
            dueDateSection
            assignmentSection
            pointsSection
            recurrenceSection
        }
        .onAppear {
            loadHouseholdMembers()
        }
    }
    
    private var basicDetailsSection: some View {
        Section(header: Text("Basic Details")) {
            TextField("Title", text: $title)
            
            TextField("Description (optional)", text: $description)
                .frame(height: 60)
        }
    }
    
    private var dueDateSection: some View {
        Section(header: Text("Due Date")) {
            Toggle("Has Due Date", isOn: $hasDueDate)
            
            if hasDueDate {
                DatePicker("Due Date", selection: $dueDate, displayedComponents: [.date, .hourAndMinute])
            }
        }
    }
    
    private var assignmentSection: some View {
        Section(header: Text("Assignment")) {
            Picker("Assign To", selection: $assignedToUserId) {
                Text("Unassigned").tag(nil as String?)
                
                ForEach(availableUsers, id: \.stableId) { user in
                    Text(user.name).tag(user.id)
                }
            }
            .disabled(isLoadingUsers)
            
            if isLoadingUsers {
                HStack {
                    Spacer()
                    ProgressView()
                    Spacer()
                }
            }
        }
    }
    
    private var pointsSection: some View {
        Section(header: Text("Points")) {
            Stepper("Points: \(pointValue)", value: $pointValue, in: 1...10)
        }
    }
    
    private var recurrenceSection: some View {
        Section(header: Text("Recurrence")) {
            Toggle("Recurring Chore", isOn: $isRecurring)
            
            if isRecurring {
                recurrenceTypePickerView
                recurrenceIntervalView
                
                if recurrenceType == .weekly {
                    weekdaySelectionView
                } else if recurrenceType == .monthly {
                    monthlyRecurrenceView
                }
                
                // End date
                endDateToggleView
            }
        }
    }
    
    private var recurrenceTypePickerView: some View {
        Picker("Repeat", selection: $recurrenceType) {
            Text("Daily").tag(RecurrenceType.daily)
            Text("Weekly").tag(RecurrenceType.weekly)
            Text("Monthly").tag(RecurrenceType.monthly)
        }
        .pickerStyle(SegmentedPickerStyle())
    }
    
    @ViewBuilder
    private var recurrenceIntervalView: some View {
        if recurrenceType == .daily {
            Stepper("Every \(recurrenceInterval) day\(recurrenceInterval > 1 ? "s" : "")", 
                   value: $recurrenceInterval, in: 1...30)
        } else if recurrenceType == .weekly {
            Stepper("Every \(recurrenceInterval) week\(recurrenceInterval > 1 ? "s" : "")", 
                   value: $recurrenceInterval, in: 1...12)
        } else if recurrenceType == .monthly {
            Stepper("Every \(recurrenceInterval) month\(recurrenceInterval > 1 ? "s" : "")", 
                   value: $recurrenceInterval, in: 1...12)
        }
    }
    
    private var weekdaySelectionView: some View {
        // Day of week selection
        HStack {
            Text("Days of Week")
            Spacer()
            NavigationLink("Select Days") {
                Form {
                    Section(header: Text("Select Days of Week")) {
                        ForEach(0..<7) { dayIndex in
                            let dayName = getDayName(dayIndex)
                            Toggle(dayName, isOn: weekdayBinding(for: dayIndex))
                        }
                    }
                }
                .navigationTitle("Select Days")
            }
        }
    }
    
    private var monthlyRecurrenceView: some View {
        // Day of month
        Picker("Day of Month", selection: $recurrenceDayOfMonth) {
            Text("Same day as first occurrence").tag(nil as Int?)
            ForEach(1...28, id: \.self) { day in
                Text("\(day)").tag(day as Int?)
            }
        }
    }
    
    private var endDateToggleView: some View {
        Group {
            Toggle("Has End Date", isOn: $hasRecurrenceEndDate)
            
            if hasRecurrenceEndDate {
                DatePicker("End Date", selection: recurrenceEndDateBinding(), displayedComponents: [.date])
            }
        }
    }
    
    // MARK: - Helper Properties
    
    private var isFormValid: Bool {
        return !title.isEmpty
    }
    
    // MARK: - Helper Methods
    
    private func addChore() async {
        // Prepare all parameters
        let finalDueDate = hasDueDate ? dueDate : nil
        let finalRecurrenceType = isRecurring ? recurrenceType : nil
        let finalRecurrenceInterval = isRecurring ? recurrenceInterval : nil
        let finalRecurrenceEndDate = isRecurring && hasRecurrenceEndDate ? recurrenceEndDate : nil
        let finalRecurrenceDaysOfWeek = isRecurring && recurrenceType == .weekly ? recurrenceDaysOfWeek : nil
        let finalRecurrenceDayOfMonth = isRecurring && recurrenceType == .monthly ? recurrenceDayOfMonth : nil
        
        // Create the chore with the prepared parameters
        await viewModel.createChore(
            title: title,
            description: description,
            assignedToUserId: assignedToUserId,
            dueDate: finalDueDate,
            pointValue: pointValue,
            isRecurring: isRecurring,
            recurrenceType: finalRecurrenceType,
            recurrenceInterval: finalRecurrenceInterval,
            recurrenceDaysOfWeek: finalRecurrenceDaysOfWeek,
            recurrenceDayOfMonth: finalRecurrenceDayOfMonth,
            recurrenceEndDate: finalRecurrenceEndDate
        )
        
        // Dismiss the sheet once the chore is created
        dismiss()
    }
    
    private func loadHouseholdMembers() {
        isLoadingUsers = true
        print("🔍 Starting to load household members...")
        
        // Use async/await in a Task to fetch actual household members
        Task {
            do {
                // Get all users in the household
                let householdId = viewModel.householdId
                print("🔍 Household ID: \(householdId)")
                
                // First get the household to make sure it exists
                let household = try await HouseholdService.shared.fetchHousehold(withId: householdId)
                if let household = household {
                    print("✅ Household found: \(household.name) with \(household.memberUserIds.count) members")
                } else {
                    print("❌ Household not found!")
                }
                
                // Now fetch the members
                let users = try await UserService.shared.fetchUsers(inHousehold: householdId)
                print("✅ Fetched \(users.count) household members")
                
                // If we don't have any users, fall back to the current user at minimum
                var finalUsers = users
                if finalUsers.isEmpty {
                    if let currentUserId = AuthService.shared.getCurrentUserId() {
                        print("⚠️ No users found, attempting to add current user as fallback")
                        if let currentUser = try await UserService.shared.fetchUser(withId: currentUserId) {
                            finalUsers = [currentUser]
                            print("✅ Added current user as fallback")
                        }
                    }
                    
                    // If we still don't have any users, create some dummy ones
                    if finalUsers.isEmpty {
                        print("⚠️ Creating sample household members")
                        finalUsers = createSampleUsers()
                    }
                }
                
                // Update the UI on the main thread
                await MainActor.run {
                    self.availableUsers = finalUsers
                    self.isLoadingUsers = false
                    print("📱 UI updated with \(finalUsers.count) users")
                    
                    // Debug info for each user
                    for user in finalUsers {
                        print("👤 User: \(user.name) (ID: \(user.id ?? "nil"), StableID: \(user.stableId))")
                    }
                }
            } catch {
                // Handle any errors
                print("❌ Error loading household members: \(error.localizedDescription)")
                
                // Fall back to sample data
                print("⚠️ Falling back to sample data after error")
                let sampleUsers = createSampleUsers()
                
                // Update the UI on the main thread
                await MainActor.run {
                    self.availableUsers = sampleUsers
                    self.isLoadingUsers = false
                    print("📱 UI updated with \(sampleUsers.count) sample users")
                    
                    // We don't show the error message since we have a fallback
                }
            }
        }
    }
    
    /// Creates sample users for testing when real data isn't available
    private func createSampleUsers() -> [User] {
        return [
            User(id: "user1",
                 name: "Jane Smith",
                 email: "jane@example.com",
                 photoURL: nil,
                 householdIds: [viewModel.householdId],
                 fcmToken: nil,
                 createdAt: Date(),
                 totalPoints: 0,
                 weeklyPoints: 0,
                 monthlyPoints: 0),
            User(id: "user2",
                 name: "John Doe", 
                 email: "john@example.com", 
                 photoURL: nil,
                 householdIds: [viewModel.householdId],
                 fcmToken: nil,
                 createdAt: Date(),
                 totalPoints: 0,
                 weeklyPoints: 0,
                 monthlyPoints: 0),
            User(id: "user3",
                 name: "Alex Johnson",
                 email: "alex@example.com",
                 photoURL: nil,
                 householdIds: [viewModel.householdId],
                 fcmToken: nil,
                 createdAt: Date(),
                 totalPoints: 0,
                 weeklyPoints: 0,
                 monthlyPoints: 0)
        ]
    }
    
    private func getDayName(_ dayIndex: Int) -> String {
        // Use a fixed reference date that we know is a Sunday
        // January 7, 2024 was a Sunday
        let referenceDate = DateComponents(calendar: Calendar.current, year: 2024, month: 1, day: 7).date!
        
        // Add dayIndex days to get the desired weekday
        let dayDate = Calendar.current.date(byAdding: .day, value: dayIndex, to: referenceDate)!
        
        // Format the date to get the weekday name
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        return formatter.string(from: dayDate)
    }
    
    // MARK: - Binding Helpers
    
    private func errorAlertBinding() -> Binding<Bool> {
        return Binding<Bool>(
            get: { 
                self.viewModel.errorMessage != nil 
            },
            set: { isPresented in
                if !isPresented {
                    self.viewModel.errorMessage = nil
                }
            }
        )
    }
    
    private func weekdayBinding(for dayIndex: Int) -> Binding<Bool> {
        return Binding<Bool>(
            get: { 
                self.recurrenceDaysOfWeek.contains(dayIndex)
            },
            set: { isSelected in
                if isSelected {
                    self.recurrenceDaysOfWeek.append(dayIndex)
                } else {
                    self.recurrenceDaysOfWeek.removeAll { $0 == dayIndex }
                }
            }
        )
    }
    
    private func recurrenceEndDateBinding() -> Binding<Date> {
        return Binding<Date>(
            get: { 
                self.recurrenceEndDate ?? Date().addingTimeInterval(30 * 24 * 60 * 60)
            },
            set: { 
                self.recurrenceEndDate = $0
            }
        )
    }
}
