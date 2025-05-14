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
    @ObservedObject private var householdViewModel: HouseholdViewModel // Added to fetch household members for assignee picker

    // Chore properties
    @State private var title = ""
    @State private var description = ""
    @State private var assignedToUserId: String?
    @State private var dueDate = Date().addingTimeInterval(24 * 60 * 60) // Tomorrow by default
    @State private var hasDueDate = true
    @State private var points: Int = 1 // Default points

    // Recurrence properties
    @State private var selectedRecurrenceType: RecurrenceRuleType = .none
    @State private var recurrenceIntervalString: String = "1" // For "every X days/weeks"
    @State private var selectedDaysOfWeek: Set<DayOfWeek> = [] // For weekly recurrence
    @State private var selectedDayOfMonth: Int = 1 // For specific day of month
    @State private var selectedWeekOfMonth: WeekOfMonthOption = .first // For specific weekday of month
    @State private var selectedWeekdayForMonthlyRecurrence: DayOfWeek = .monday // For specific weekday of month
    @State private var recurrenceMonthIntervalString: String = "1" // For monthly types
    @State private var recurrenceEndDate: Date? = nil
    @State private var hasRecurrenceEndDate: Bool = false
    
    // To present the household selection
    init(viewModel: ChoreViewModel, householdViewModel: HouseholdViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
        _householdViewModel = ObservedObject(wrappedValue: householdViewModel)
    }

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Chore Details")) {
                    TextField("Title", text: $title)
                    TextField("Description (Optional)", text: $description, axis: .vertical)
                        .lineLimit(3...)
                    
                    Picker("Assign To", selection: $assignedToUserId) {
                        Text("Unassigned").tag(String?.none)
                        ForEach(householdViewModel.householdMembers) { member in
                            Text(member.name).tag(member.id as String?)
                        }
                    }

                    Stepper("Points: \\(points)", value: $points, in: 1...100)
                }

                Section(header: Text("Due Date")) {
                    Toggle("Set Due Date", isOn: $hasDueDate.animation())
                    if hasDueDate {
                        DatePicker("Due On", selection: $dueDate, displayedComponents: .date)
                    }
                }

                Section(header: Text("Recurrence")) {
                    Picker("Repeats", selection: $selectedRecurrenceType) {
                        Text("Never").tag(RecurrenceRuleType.none)
                        Text("Daily").tag(RecurrenceRuleType.daily)
                        Text("Weekly").tag(RecurrenceRuleType.weekly)
                        Text("Every X Days").tag(RecurrenceRuleType.everyXDays)
                        Text("Every X Weeks").tag(RecurrenceRuleType.everyXWeeks)
                        Text("Specific Day of Month").tag(RecurrenceRuleType.specificDayOfMonth)
                        Text("Specific Weekday of Month").tag(RecurrenceRuleType.specificWeekdayOfMonth)
                    }
                    .pickerStyle(MenuPickerStyle())

                    // Conditional UI for recurrence options will be added here
                    // For example:
                    if selectedRecurrenceType == .everyXDays {
                        HStack {
                            Text("Every")
                            TextField("Interval", text: $recurrenceIntervalString)
                                .keyboardType(.numberPad)
                                .frame(width: 50)
                            Text( (Int(recurrenceIntervalString) ?? 1) == 1 ? "Day" : "Days")
                        }
                    } else if selectedRecurrenceType == .weekly {
                        WeekdaysSelectorView(selectedDays: $selectedDaysOfWeek)
                    } else if selectedRecurrenceType == .everyXWeeks {
                        HStack {
                            Text("Every")
                            TextField("Interval", text: $recurrenceIntervalString)
                                .keyboardType(.numberPad)
                                .frame(width: 50)
                            Text( (Int(recurrenceIntervalString) ?? 1) == 1 ? "Week" : "Weeks")
                        }
                        WeekdaysSelectorView(selectedDays: $selectedDaysOfWeek)
                    } else if selectedRecurrenceType == .specificDayOfMonth {
                        Picker("Day of Month", selection: $selectedDayOfMonth) {
                            ForEach(1...31, id: \.self) { day in
                                Text("\\(day)").tag(day)
                            }
                        }
                        HStack {
                            Text("Every")
                            TextField("Interval", text: $recurrenceMonthIntervalString)
                                .keyboardType(.numberPad)
                                .frame(width: 50)
                            Text( (Int(recurrenceMonthIntervalString) ?? 1) == 1 ? "Month" : "Months")
                        }
                    } else if selectedRecurrenceType == .specificWeekdayOfMonth {
                        Picker("On the", selection: $selectedWeekOfMonth) {
                            ForEach(WeekOfMonthOption.allCases) { option in
                                Text(option.displayName).tag(option)
                            }
                        }
                        Picker("Day", selection: $selectedWeekdayForMonthlyRecurrence) {
                            ForEach(DayOfWeek.allCases) { day in
                                Text(day.fullName).tag(day)
                            }
                        }
                        HStack {
                            Text("Every")
                            TextField("Interval", text: $recurrenceMonthIntervalString)
                                .keyboardType(.numberPad)
                                .frame(width: 50)
                            Text( (Int(recurrenceMonthIntervalString) ?? 1) == 1 ? "Month" : "Months")
                        }
                    } else if selectedRecurrenceType == .monthly {
                        HStack {
                            Text("Every")
                            TextField("Interval", text: $recurrenceMonthIntervalString)
                                .keyboardType(.numberPad)
                                .frame(width: 50)
                            Text( (Int(recurrenceMonthIntervalString) ?? 1) == 1 ? "Month" : "Months")
                        }
                    }
                    // More conditional UI sections to be added...

                    if selectedRecurrenceType != .none {
                        Toggle("Set End Date for Recurrence", isOn: $hasRecurrenceEndDate.animation())
                        if hasRecurrenceEndDate {
                            DatePicker("Ends On", selection: Binding(
                                get: { recurrenceEndDate ?? Date() },
                                set: { recurrenceEndDate = $0 }
                            ), displayedComponents: .date)
                        }
                    }
                }
                
                Section {
                    Button("Add Chore") {
                        saveChore()
                    }
                    .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .navigationTitle("Add New Chore")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                // Fetch household members if not already loaded by HouseholdViewModel
                // This might be handled by the parent view passing the householdViewModel
                // or by having householdViewModel fetch them if needed.
                // For now, assuming householdViewModel.householdMembers is populated.
            }
        }
    }

    private func saveChore() {
        guard let householdId = householdViewModel.selectedHousehold?.id else {
            // Handle error: no selected household
            print("Error: No selected household ID.")
            return
        }
        
        var rule: RecurrenceRule? = nil
        if selectedRecurrenceType != .none {
            let interval = Int(recurrenceIntervalString)
            let monthInterval = Int(recurrenceMonthIntervalString)
            
            // Convert Set<DayOfWeek> to [Int] for daysOfWeek
            let daysOfWeekInt = selectedDaysOfWeek.map { $0.rawValue }.sorted()
            
            // Determine weekOfMonth value for RecurrenceRule
            // The RecurrenceRule uses 1-4 for first to fourth, and -1 for last.
            // Our WeekOfMonthOption uses 1-4 for first to fourth, and 5 for last.
            var ruleWeekOfMonth: Int? = nil
            if selectedRecurrenceType == .specificWeekdayOfMonth {
                if selectedWeekOfMonth == .last {
                    ruleWeekOfMonth = -1
                } else {
                    ruleWeekOfMonth = selectedWeekOfMonth.rawValue
                }
            }
            
            // Determine daysOfWeek for specificWeekdayOfMonth
            // RecurrenceRule.daysOfWeek is [Int] where 0 is Sunday.
            // For specificWeekdayOfMonth, we store the selected weekday (e.g., Monday) as a single element array.
            var ruleDaysOfWeekForSpecificWeekday: [Int]? = nil
            if selectedRecurrenceType == .specificWeekdayOfMonth {
                ruleDaysOfWeekForSpecificWeekday = [selectedWeekdayForMonthlyRecurrence.rawValue]
            }

            rule = RecurrenceRule(
                type: selectedRecurrenceType,
                interval: selectedRecurrenceType == .everyXDays || selectedRecurrenceType == .everyXWeeks ? interval : nil,
                daysOfWeek: selectedRecurrenceType == .weekly || selectedRecurrenceType == .everyXWeeks ? daysOfWeekInt : (selectedRecurrenceType == .specificWeekdayOfMonth ? ruleDaysOfWeekForSpecificWeekday : nil),
                dayOfMonth: selectedRecurrenceType == .specificDayOfMonth ? selectedDayOfMonth : nil,
                weekOfMonth: ruleWeekOfMonth,
                monthInterval: (selectedRecurrenceType == .specificDayOfMonth || selectedRecurrenceType == .specificWeekdayOfMonth || selectedRecurrenceType == .monthly) ? (Int(recurrenceMonthIntervalString) ?? 1) : nil,
                endDate: hasRecurrenceEndDate ? recurrenceEndDate : nil
            )
        }

        // The actual Chore object creation needs to align with the full definition in Chore.swift
        // including createdByUserId, createdAt, etc.
        // This part will be refined when ChoreViewModel.createChore is updated.
        
        // Placeholder for actual chore creation and saving
        // viewModel.createChore(
        // title: title,
        // description: description,
        // householdId: householdId,
        // assignedToUserId: assignedToUserId,
        // dueDate: hasDueDate ? dueDate : nil,
        // points: points,
        // recurrenceRule: rule
        // )
        
        // For now, just print and dismiss
        print("Chore to save: Title: \\(title), Points: \\(points), Rule: \\(String(describing: rule))")
        // Example of how it might be called (actual method signature in ChoreViewModel will vary)
        Task {
            do {
                // This is a placeholder. The actual createChore method in ChoreViewModel
                // will need to be updated to accept these parameters or a Chore object.
                // For now, we are just preparing the data.
                
                // let newChore = Chore(
                // title: title,
                // description: description,
                // householdId: householdId, // Assuming this is available
                // assignedToUserId: assignedToUserId,
                // createdByUserId: Auth.auth().currentUser?.uid, // Example
                // dueDate: hasDueDate ? dueDate : Date(), // Ensure dueDate is not nil if hasDueDate is false, or handle appropriately
                // isCompleted: false,
                // createdAt: Date(),
                // points: points,
                // recurrenceRule: rule,
                // updatedAt: Date()
                // )
                // try await viewModel.addChore(newChore) // Example call
                
                dismiss()
            } catch {
                // Handle error
                print("Error saving chore: \\(error.localizedDescription)")
            }
        }
    }
}

enum DayOfWeek: Int, CaseIterable, Identifiable, Equatable, Hashable {
    case sunday = 0, monday, tuesday, wednesday, thursday, friday, saturday

    var id: Int { self.rawValue }

    var shortName: String {
        switch self {
        case .sunday: return "Sun"
        case .monday: return "Mon"
        case .tuesday: return "Tue"
        case .wednesday: return "Wed"
        case .thursday: return "Thu"
        case .friday: return "Fri"
        case .saturday: return "Sat"
        }
    }
    
    var fullName: String {
        switch self {
        case .sunday: return "Sunday"
        case .monday: return "Monday"
        case .tuesday: return "Tuesday"
        case .wednesday: return "Wednesday"
        case .thursday: return "Thursday"
        case .friday: return "Friday"
        case .saturday: return "Saturday"
        }
    }
}

enum WeekOfMonthOption: Int, CaseIterable, Identifiable, Equatable {
    case first = 1
    case second = 2
    case third = 3
    case fourth = 4
    case last = 5 // Mapped to -1 in RecurrenceRule

    var id: Int { self.rawValue }

    var displayName: String {
        switch self {
        case .first: return "First"
        case .second: return "Second"
        case .third: return "Third"
        case .fourth: return "Fourth"
        case .last: return "Last"
        }
    }
}

struct WeekdaysSelectorView: View {
    @Binding var selectedDays: Set<DayOfWeek>
    private let days = DayOfWeek.allCases
    private let columns = [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())]

    var body: some View {
        VStack(alignment: .leading) {
            Text("Repeat on:")
                .font(.headline)
            LazyVGrid(columns: columns, spacing: 10) {
                ForEach(days, id: \.self) { day in
                    Button(action: {
                        toggleSelection(for: day)
                    }) {
                        Text(day.shortName)
                            .font(.caption)
                            .padding(.vertical, 8)
                            .padding(.horizontal, 4)
                            .frame(minWidth: 0, maxWidth: .infinity)
                            .background(selectedDays.contains(day) ? Color.accentColor : Color.gray.opacity(0.2))
                            .foregroundColor(selectedDays.contains(day) ? .white : .primary)
                            .cornerRadius(8)
                    }
                }
            }
        }
    }

    private func toggleSelection(for day: DayOfWeek) {
        if selectedDays.contains(day) {
            selectedDays.remove(day)
        } else {
            selectedDays.insert(day)
        }
    }
}

#if DEBUG
//struct AddChoreView_Previews: PreviewProvider {
//    static var previews: some View {
//        AddChoreView(viewModel: ChoreViewModel(householdId: "sampleHouseholdId", choreService: MockChoreService()), // Requires MockChoreService
// householdViewModel: HouseholdViewModel()) // Requires a configured HouseholdViewModel
//    }
//}
#endif
