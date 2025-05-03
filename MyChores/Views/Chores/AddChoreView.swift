// AddChoreView.swift
// MyChores
//
// Created on 2025-05-02.
//

import SwiftUI

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
    @State private var recurrenceType: Chore.RecurrenceType = .weekly
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
                        addChore()
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
                
                ForEach(availableUsers) { user in
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
            Text("Daily").tag(Chore.RecurrenceType.daily)
            Text("Weekly").tag(Chore.RecurrenceType.weekly)
            Text("Monthly").tag(Chore.RecurrenceType.monthly)
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
    
    private func addChore() {
        // Prepare all parameters
        let finalDueDate = hasDueDate ? dueDate : nil
        let finalRecurrenceType = isRecurring ? recurrenceType : nil
        let finalRecurrenceInterval = isRecurring ? recurrenceInterval : nil
        let finalRecurrenceEndDate = isRecurring && hasRecurrenceEndDate ? recurrenceEndDate : nil
        let finalRecurrenceDaysOfWeek = isRecurring && recurrenceType == .weekly ? recurrenceDaysOfWeek : nil
        let finalRecurrenceDayOfMonth = isRecurring && recurrenceType == .monthly ? recurrenceDayOfMonth : nil
        
        // Create the chore with the prepared parameters
        viewModel.createChore(
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
        // In a real implementation, this would fetch actual users from the household
        // For now, just use some sample data
        isLoadingUsers = true
        
        // Simulate network fetch
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            availableUsers = [
                User.sample
                // Add more sample users as needed
            ]
            isLoadingUsers = false
        }
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
