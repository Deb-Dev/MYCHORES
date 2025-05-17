// AddChoreView.swift
// MyChores
//
// Created on 2025-05-02.
// Enhanced on 2025-05-14
//

import SwiftUI

/// View for adding a new chore with modern UI
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
    
    // Animation states
    @State private var formAppeared = false
    @State private var headerAnimated = false
    @State private var detailsAnimated = false
    @State private var dateAnimated = false
    @State private var assignAnimated = false
    @State private var pointsAnimated = false
    @State private var recurrenceAnimated = false
    @State private var isSubmitting = false
    
    // Section expanded states
    @State private var detailsExpanded = true
    @State private var dateExpanded = true
    @State private var assignmentExpanded = true
    @State private var pointsExpanded = true
    @State private var recurrenceExpanded = true
    
    init(householdId: String) {
        self._viewModel = StateObject(wrappedValue: ChoreViewModel(householdId: householdId))
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background with subtle pattern
                Theme.Colors.background.ignoresSafeArea()
                
                // Background decorative elements
                VStack {
                    Circle()
                        .fill(Theme.Colors.primary.opacity(0.05))
                        .frame(width: 300, height: 300)
                        .offset(x: 150, y: -100)
                        .blur(radius: 60)
                    
                    Circle()
                        .fill(Theme.Colors.secondary.opacity(0.05))
                        .frame(width: 200, height: 200)
                        .offset(x: -150, y: 100)
                        .blur(radius: 50)
                    
                    Spacer()
                }
                .ignoresSafeArea()
                
                // Main content
                ScrollView {
                    VStack(spacing: 20) {
                        // Header section with icon
                        choreHeaderView
                            .opacity(headerAnimated ? 1 : 0)
                            .offset(y: headerAnimated ? 0 : -20)
                        
                        // Main form content
                        VStack(spacing: 16) {
                            basicDetailsSection
                                .opacity(detailsAnimated ? 1 : 0)
                                .offset(y: detailsAnimated ? 0 : 20)
                            
                            dueDateSection
                                .opacity(dateAnimated ? 1 : 0)
                                .offset(y: dateAnimated ? 0 : 20)
                            
                            assignmentSection
                                .opacity(assignAnimated ? 1 : 0)
                                .offset(y: assignAnimated ? 0 : 20)
                            
                            pointsSection
                                .opacity(pointsAnimated ? 1 : 0)
                                .offset(y: pointsAnimated ? 0 : 20)
                            
                            recurrenceSection
                                .opacity(recurrenceAnimated ? 1 : 0)
                                .offset(y: recurrenceAnimated ? 0 : 20)
                            
                            // Add chore button
                            addChoreButton
                                .padding(.vertical, 20)
                                .opacity(formAppeared ? 1 : 0)
                                .scaleEffect(formAppeared ? 1 : 0.9)
                        }
                        .padding(.horizontal, 16)
                    }
                    .padding(.bottom, 30)
                }
            }
            .navigationTitle("New Chore")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .alert(
                "Error",
                isPresented: errorAlertBinding(),
                actions: { Button("OK", role: .cancel) {} },
                message: { Text(viewModel.errorMessage ?? "") }
            )
            .onAppear {
                loadHouseholdMembers()
                animateEntrance()
            }
        }
    }
    
    // MARK: - Animation Methods
    
    private func animateEntrance() {
        // Start animations for persistent elements
        withAnimation {
            headerAnimated = true
            pointsAnimated = true
        }
        
        // Stagger the section animations for a dynamic feel
        withAnimation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.1)) {
            headerAnimated = true
        }
        
        withAnimation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.2)) {
            detailsAnimated = true
            detailsExpanded = true
        }
        
        withAnimation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.3)) {
            dateAnimated = true
            dateExpanded = true
        }
        
        withAnimation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.4)) {
            assignAnimated = true
            assignmentExpanded = false // Start collapsed
        }
        
        withAnimation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.5)) {
            pointsAnimated = true
            pointsExpanded = false // Start collapsed
        }
        
        withAnimation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.6)) {
            recurrenceAnimated = true
            recurrenceExpanded = false // Start collapsed
        }
        
        withAnimation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.7)) {
            formAppeared = true
        }
    }
    
    // MARK: - Header Components
    
    private var choreHeaderView: some View {
        VStack(spacing: 12) {
            // Icon with animated background
            ZStack {
                // Background circles with different opacities
                Circle()
                    .fill(Theme.Colors.primary.opacity(0.15))
                    .frame(width: 100, height: 100)
                
                Circle()
                    .fill(Theme.Colors.primary.opacity(0.05))
                    .frame(width: 130, height: 130)
                    .scaleEffect(headerAnimated ? 1.0 : 0.9)
                    .animation(
                        Animation.easeInOut(duration: 2.0).repeatForever(autoreverses: true),
                        value: headerAnimated
                    )
                
                // Rotating gradient overlay
                Circle()
                    .stroke(
                        AngularGradient(
                            gradient: Gradient(colors: [
                                Theme.Colors.primary.opacity(0.8),
                                Theme.Colors.primary.opacity(0.2),
                                Theme.Colors.primary.opacity(0.0),
                                Theme.Colors.primary.opacity(0.0),
                                Theme.Colors.primary.opacity(0.8)
                            ]),
                            center: .center
                        ),
                        lineWidth: 2.5
                    )
                    .frame(width: 100, height: 100)
                    .rotationEffect(Angle(degrees: headerAnimated ? 360 : 0))
                    .animation(
                        Animation.linear(duration: 10).repeatForever(autoreverses: false),
                        value: headerAnimated
                    )
                
                // Main icon
                Image(systemName: "checklist")
                    .font(.system(size: 40))
                    .foregroundColor(Theme.Colors.primary)
                    .symbolEffect(.bounce.down, options: .repeating.speed(0.7), value: headerAnimated)
                    .shadow(color: Theme.Colors.primary.opacity(0.5), radius: 10, x: 0, y: 0)
                    .scaleEffect(headerAnimated ? 1.0 : 0.8)
                    .animation(
                        Animation.spring(response: 0.6, dampingFraction: 0.6, blendDuration: 0.6),
                        value: headerAnimated
                    )
            }
            
            // Title with typewriter effect
            Text("Create a new chore")
                .font(Theme.Typography.subheadingFontSystem.bold())
                .foregroundColor(Theme.Colors.textSecondary)
                .padding(.bottom, 8)
                .overlay(
                    Rectangle()
                        .fill(Theme.Colors.background)
                        .mask(
                            HStack {
                                Rectangle()
                                    .offset(x: headerAnimated ? -200 : 0)
                                
                                Rectangle()
                                    .offset(x: headerAnimated ? -200 : 200)
                            }
                        )
                )
                .animation(.easeInOut(duration: 1.2).delay(0.3), value: headerAnimated)
        }
        .padding(.vertical, 20)
    }
    
    // MARK: - Form Components
    
    private var addChoreButton: some View {
        Button {
            withAnimation {
                isSubmitting = true
            }
            Task {
                await addChore()
            }
        } label: {
            HStack {
                Spacer()
                
                if isSubmitting {
                    ProgressView()
                        .tint(.white)
                        .scaleEffect(1.2)
                } else {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 20))
                        .symbolRenderingMode(.hierarchical)
                        .symbolEffect(.bounce.up.byLayer, options: .repeating, value: formAppeared)
                }
                
                Text(isSubmitting ? "Creating..." : "Create Chore")
                    .font(Theme.Typography.bodyFontSystem.bold())
                    .padding(.leading, 8)
                
                Spacer()
            }
            .foregroundColor(.white)
            .padding()
            .frame(maxWidth: .infinity)
            .background(
                ZStack {
                    // Base gradient
                    LinearGradient(
                        colors: [Theme.Colors.primary, Theme.Colors.primary.opacity(0.8)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    
                    // Animated overlay
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.0),
                            Color.white.opacity(0.2),
                            Color.white.opacity(0.0)
                        ],
                        startPoint: .init(x: 0, y: 0.5),
                        endPoint: .init(x: 1, y: 0.5)
                    )
                    .mask(
                        Rectangle()
                            .fill(
                                LinearGradient(
                                    colors: [.black, .clear, .black],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .offset(x: formAppeared ? 400 : -400)
                            .animation(
                                Animation.easeInOut(duration: 3)
                                    .repeatForever(autoreverses: false)
                                    .delay(1),
                                value: formAppeared
                            )
                    )
                    .blendMode(.overlay)
                }
            )
            .cornerRadius(Theme.Dimensions.cornerRadiusMedium)
            .overlay(
                RoundedRectangle(cornerRadius: Theme.Dimensions.cornerRadiusMedium)
                    .stroke(Color.white.opacity(0.3), lineWidth: 1)
            )
            .shadow(color: Theme.Colors.primary.opacity(0.3), radius: 8, x: 0, y: 4)
        }
        .disabled(!isFormValid || isSubmitting)
        .opacity(isFormValid ? 1.0 : 0.7)
        .scaleEffect(isSubmitting ? 0.98 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isSubmitting)
    }
    
    private var basicDetailsSection: some View {
        SectionCardView(
            title: "Basic Details", 
            systemImage: "square.and.pencil",
            isExpanded: $detailsExpanded
        ) {
            VStack(spacing: 16) {
                // Title field with fancy styling
                VStack(alignment: .leading, spacing: 8) {
                    Text("Title")
                        .font(Theme.Typography.captionFontSystem)
                        .foregroundColor(Theme.Colors.textSecondary)
                    
                    TextField("", text: $title)
                        .font(Theme.Typography.bodyFontSystem)
                        .padding()
                        .background(Theme.Colors.cardBackground)
                        .cornerRadius(Theme.Dimensions.cornerRadiusSmall)
                        .overlay(
                            RoundedRectangle(cornerRadius: Theme.Dimensions.cornerRadiusSmall)
                                .stroke(Theme.Colors.primary.opacity(0.3), lineWidth: 1)
                        )
                        .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
                        .overlay(
                            Text("Title")
                                .font(Theme.Typography.bodyFontSystem)
                                .foregroundColor(Theme.Colors.textSecondary.opacity(0.7))
                                .padding(.horizontal, 8)
                                .background(Theme.Colors.cardBackground)
                                .opacity(title.isEmpty ? 1 : 0)
                                .allowsHitTesting(false)
                                .padding(.leading, 16),
                            alignment: .leading
                        )
                }
                
                // Description field
                VStack(alignment: .leading, spacing: 8) {
                    Text("Description")
                        .font(Theme.Typography.captionFontSystem)
                        .foregroundColor(Theme.Colors.textSecondary)
                    
                    TextEditor(text: $description)
                        .font(Theme.Typography.bodyFontSystem)
                        .scrollContentBackground(.hidden)
                        .frame(minHeight: 100)
                        .padding(10)
                        .background(Theme.Colors.cardBackground)
                        .cornerRadius(Theme.Dimensions.cornerRadiusSmall)
                        .overlay(
                            RoundedRectangle(cornerRadius: Theme.Dimensions.cornerRadiusSmall)
                                .stroke(Theme.Colors.primary.opacity(0.3), lineWidth: 1)
                        )
                        .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
                        .overlay(
                            Text("Enter description (optional)")
                                .font(Theme.Typography.bodyFontSystem)
                                .foregroundColor(Theme.Colors.textSecondary.opacity(0.7))
                                .padding(.horizontal, 8)
                                .background(Theme.Colors.cardBackground)
                                .opacity(description.isEmpty ? 1 : 0)
                                .allowsHitTesting(false)
                                .padding([.leading, .top], 16),
                            alignment: .topLeading
                        )
                }
            }
            .padding(.vertical, 10)
        }
    }
    
    private var dueDateSection: some View {
        SectionCardView(
            title: "Due Date", 
            systemImage: "calendar",
            isExpanded: $dateExpanded
        ) {
            VStack(spacing: 16) {
                // Has due date toggle
                Toggle(isOn: $hasDueDate) {
                    HStack {
                        Image(systemName: "clock.fill")
                            .font(.system(size: 16))
                            .foregroundColor(Theme.Colors.primary)
                        
                        Text("Set a deadline")
                            .font(Theme.Typography.bodyFontSystem)
                    }
                }
                .toggleStyle(SwitchToggleStyle(tint: Theme.Colors.primary))
                .padding(.vertical, 8)
                
                // Date picker with conditional visibility
                if hasDueDate {
                    DatePicker("", selection: $dueDate, displayedComponents: [.date, .hourAndMinute])
                        .datePickerStyle(.graphical)
                        .tint(Theme.Colors.primary)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: Theme.Dimensions.cornerRadiusSmall)
                                .fill(Theme.Colors.cardBackground)
                                .shadow(color: Color.black.opacity(0.05), radius: 3, x: 0, y: 1)
                        )
                        .padding(.bottom, 10)
                }
            }
            .padding(.vertical, 10)
        }
    }
    
    private var assignmentSection: some View {
        SectionCardView(
            title: "Assignment", 
            systemImage: "person.fill",
            isExpanded: $assignmentExpanded
        ) {
            VStack(spacing: 16) {
                if isLoadingUsers {
                    HStack {
                        Spacer()
                        VStack(spacing: 12) {
                            ProgressView()
                                .scaleEffect(1.2)
                            Text("Loading members...")
                                .font(Theme.Typography.captionFontSystem)
                                .foregroundColor(Theme.Colors.textSecondary)
                        }
                        Spacer()
                    }
                    .padding(.vertical, 20)
                } else if availableUsers.isEmpty {
                    // Empty state
                    HStack {
                        Spacer()
                        Text("No household members found")
                            .font(Theme.Typography.bodyFontSystem)
                            .foregroundColor(Theme.Colors.textSecondary)
                        Spacer()
                    }
                    .padding(.vertical, 20)
                } else {
                    // Assignment picker
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Assign to")
                            .font(Theme.Typography.captionFontSystem)
                            .foregroundColor(Theme.Colors.textSecondary)
                        
                        // Custom picker view
                        VStack {
                            Menu {
                                Button {
                                    assignedToUserId = nil
                                } label: {
                                    Label("Unassigned", systemImage: "person.slash")
                                }
                                
                                Divider()
                                
                                ForEach(availableUsers, id: \.stableId) { user in
                                    Button {
                                        assignedToUserId = user.id
                                    } label: {
                                        Label(user.name, systemImage: user.id == assignedToUserId ? "checkmark" : "person")
                                    }
                                }
                            } label: {
                                HStack {
                                    // User avatar or placeholder
                                    ZStack {
                                        Circle()
                                            .fill(getUserColor(userId: assignedToUserId))
                                            .frame(width: 36, height: 36)
                                        
                                        if assignedToUserId == nil {
                                            Image(systemName: "person.slash")
                                                .font(.system(size: 16))
                                                .foregroundColor(.white)
                                        } else {
                                            Text(getUserInitials())
                                                .font(.system(size: 14, weight: .bold))
                                                .foregroundColor(.white)
                                        }
                                    }
                                    
                                    Text(getUserName())
                                        .font(Theme.Typography.bodyFontSystem)
                                        .foregroundColor(Theme.Colors.text)
                                    
                                    Spacer()
                                    
                                    Image(systemName: "chevron.down")
                                        .foregroundColor(Theme.Colors.textSecondary)
                                        .font(.system(size: 14))
                                }
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: Theme.Dimensions.cornerRadiusSmall)
                                        .fill(Theme.Colors.cardBackground)
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: Theme.Dimensions.cornerRadiusSmall)
                                        .stroke(Theme.Colors.primary.opacity(0.3), lineWidth: 1)
                                )
                            }
                        }
                        .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
                    }
                }
            }
            .padding(.vertical, 10)
        }
    }
    
    private var pointsSection: some View {
        SectionCardView(
            title: "Points",
            systemImage: "star.fill",
            iconColor: Theme.Colors.accent,
            isExpanded: $pointsExpanded
        ) {
            VStack(alignment: .leading, spacing: 16) {
                Text("How many points is this chore worth?")
                    .font(Theme.Typography.bodyFontSystem)
                    .foregroundColor(Theme.Colors.textSecondary)
                
                // Custom points stepper
                HStack(spacing: 20) {
                    Button {
                        if pointValue > 1 {
                            pointValue -= 1
                        }
                    } label: {
                        Image(systemName: "minus.circle.fill")
                            .font(.system(size: 32))
                            .foregroundColor(pointValue > 1 ? Theme.Colors.primary : Theme.Colors.textSecondary.opacity(0.3))
                    }
                    .disabled(pointValue <= 1)
                    
                    // Points display
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [Theme.Colors.accent, Theme.Colors.accent.opacity(0.7)],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .frame(width: 80, height: 80)
                            .shadow(color: Theme.Colors.accent.opacity(0.3), radius: 5, x: 0, y: 2)
                            .overlay(
                                Circle()
                                    .stroke(Color.white, lineWidth: 3)
                                    .blur(radius: 2)
                                    .opacity(0.4)
                            )
                            .overlay(
                                Circle()
                                    .stroke(
                                        AngularGradient(
                                            colors: [
                                                Color.white.opacity(0.8),
                                                Color.white.opacity(0.0),
                                                Color.white.opacity(0.0),
                                                Color.white.opacity(0.0)
                                            ],
                                            center: .center
                                        ),
                                        lineWidth: 2
                                    )
                                    .rotationEffect(.degrees(pointsAnimated ? 360 : 0))
                                    .animation(Animation.linear(duration: 8).repeatForever(autoreverses: false), value: pointsAnimated)
                            )
                            .rotation3DEffect(
                                .degrees(pointsAnimated ? 5 : 0),
                                axis: (x: 0.0, y: 1.0, z: 0.0)
                            )
                            .animation(
                                Animation.easeInOut(duration: 2).repeatForever(autoreverses: true),
                                value: pointsAnimated
                            )
                        
                        VStack(spacing: 0) {
                            Text("\(pointValue)")
                                .font(.system(size: 28, weight: .bold))
                                .foregroundColor(.white)
                            
                            Text("pts")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.white.opacity(0.9))
                        }
                        .scaleEffect(pointsAnimated ? 1 : 0.97)
                        .animation(
                            Animation.easeInOut(duration: 1.5).repeatForever(autoreverses: true),
                            value: pointsAnimated
                        )
                    }
                    
                    Button {
                        if pointValue < 10 {
                            pointValue += 1
                        }
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 32))
                            .foregroundColor(pointValue < 10 ? Theme.Colors.primary : Theme.Colors.textSecondary.opacity(0.3))
                    }
                    .disabled(pointValue >= 10)
                }
                .padding(.horizontal)
                .frame(maxWidth: .infinity)
                
                // Hint text
                Text("Higher points are for more challenging chores")
                    .font(Theme.Typography.captionFontSystem)
                    .foregroundColor(Theme.Colors.textSecondary)
                    .padding(.top, 8)
            }
            .padding(.vertical, 10)
        }
    }
    
    private var recurrenceSection: some View {
        SectionCardView(
            title: "Recurrence", 
            systemImage: "repeat",
            iconColor: Theme.Colors.secondary,
            isExpanded: $recurrenceExpanded
        ) {
            VStack(spacing: 16) {
                // Recurring toggle
                Toggle(isOn: $isRecurring) {
                    HStack {
                        Image(systemName: "arrow.triangle.2.circlepath")
                            .font(.system(size: 16))
                            .foregroundColor(Theme.Colors.secondary)
                        
                        Text("Make this a recurring chore")
                            .font(Theme.Typography.bodyFontSystem)
                    }
                }
                .toggleStyle(SwitchToggleStyle(tint: Theme.Colors.secondary))
                .padding(.vertical, 8)
                
                if isRecurring {
                    // Recurrence type selector
                    recurrenceTypePickerView
                        .padding(.horizontal, 4)
                    
                    // Recurrence interval
                    recurrenceIntervalView
                        .padding(.vertical, 8)
                    
                    // Weekly & monthly specific options
                    Group {
                        if recurrenceType == .weekly {
                            weekdaySelectionView
                        } else if recurrenceType == .monthly {
                            monthlyRecurrenceView
                        }
                    }
                    .transition(.opacity)
                    
                    // End date
                    endDateToggleView
                        .padding(.top, 8)
                }
            }
            .padding(.vertical, 10)
            .animation(.spring(response: 0.3, dampingFraction: 0.8), value: isRecurring)
            .animation(.spring(response: 0.3, dampingFraction: 0.8), value: recurrenceType)
        }
    }
    
    // MARK: - Recurrence Components
    
    private var recurrenceTypePickerView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Repeat every")
                .font(Theme.Typography.captionFontSystem)
                .foregroundColor(Theme.Colors.textSecondary)
            
            // Enhanced segmented picker
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.black.opacity(0.03))
                    .frame(height: 44)
                
                HStack(spacing: 0) {
                    ForEach([RecurrenceType.daily, RecurrenceType.weekly, RecurrenceType.monthly], id: \.self) { type in
                        Button {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                recurrenceType = type
                            }
                        } label: {
                            HStack {
                                Image(systemName: getRecurrenceIcon(type))
                                    .font(.system(size: 14))
                                Text(getRecurrenceLabel(type))
                                    .font(.system(size: 14, weight: recurrenceType == type ? .medium : .regular))
                            }
                            .padding(.vertical, 10)
                            .frame(maxWidth: .infinity)
                            .background(
                                ZStack {
                                    if recurrenceType == type {
                                        RoundedRectangle(cornerRadius: 6)
                                            .fill(
                                                LinearGradient(
                                                    colors: [Theme.Colors.secondary, Theme.Colors.secondary.opacity(0.8)],
                                                    startPoint: .top,
                                                    endPoint: .bottom
                                                )
                                            )
                                            .shadow(color: Theme.Colors.secondary.opacity(0.3), radius: 2, x: 0, y: 1)
                                    }
                                }
                            )
                            .foregroundColor(recurrenceType == type ? .white : Theme.Colors.text)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding(4)
            }
            .padding(.vertical, 4)
        }
    }
    
    // Helper method for recurrence icons
    private func getRecurrenceIcon(_ type: RecurrenceType) -> String {
        switch type {
        case .daily:
            return "clock"
        case .weekly:
            return "calendar.day.timeline.left"
        case .monthly:
            return "calendar"
        }
    }
    
    // Helper method for recurrence labels
    private func getRecurrenceLabel(_ type: RecurrenceType) -> String {
        switch type {
        case .daily:
            return "Daily"
        case .weekly:
            return "Weekly"
        case .monthly:
            return "Monthly"
        }
    }
    
    @ViewBuilder
    private var recurrenceIntervalView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Frequency")
                .font(Theme.Typography.captionFontSystem)
                .foregroundColor(Theme.Colors.textSecondary)
            
            HStack(spacing: 16) {
                // Decrement button
                Button {
                    if recurrenceInterval > 1 {
                        recurrenceInterval -= 1
                    }
                } label: {
                    ZStack {
                        Circle()
                            .fill(recurrenceInterval > 1 ? Theme.Colors.secondary.opacity(0.15) : Color.gray.opacity(0.1))
                            .frame(width: 36, height: 36)
                        
                        Image(systemName: "minus")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(recurrenceInterval > 1 ? Theme.Colors.secondary : Theme.Colors.textSecondary.opacity(0.3))
                    }
                }
                .buttonStyle(ScaleButtonStyle())
                .disabled(recurrenceInterval <= 1)
                
                // Interval display
                VStack(alignment: .center, spacing: 2) {
                    Text("\(recurrenceInterval)")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(Theme.Colors.text)
                    
                    Text(intervalLabel)
                        .font(.system(size: 14))
                        .foregroundColor(Theme.Colors.textSecondary)
                }
                .frame(minWidth: 80)
                .padding(.vertical, 8)
                .padding(.horizontal, 16)
                .background(
                    RoundedRectangle(cornerRadius: Theme.Dimensions.cornerRadiusSmall)
                        .fill(Theme.Colors.cardBackground)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: Theme.Dimensions.cornerRadiusSmall)
                        .stroke(Theme.Colors.secondary.opacity(0.2), lineWidth: 1)
                )
                
                // Increment button
                Button {
                    if recurrenceInterval < getMaxInterval() {
                        recurrenceInterval += 1
                    }
                } label: {
                    ZStack {
                        Circle()
                            .fill(recurrenceInterval < getMaxInterval() ? Theme.Colors.secondary.opacity(0.15) : Color.gray.opacity(0.1))
                            .frame(width: 36, height: 36)
                        
                        Image(systemName: "plus")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(recurrenceInterval < getMaxInterval() ? Theme.Colors.secondary : Theme.Colors.textSecondary.opacity(0.3))
                    }
                }
                .buttonStyle(ScaleButtonStyle())
                .disabled(recurrenceInterval >= getMaxInterval())
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: Theme.Dimensions.cornerRadiusSmall)
                    .fill(Theme.Colors.cardBackground)
                    .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
            )
        }
    }
    
    private var weekdaySelectionView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("On which days?")
                .font(Theme.Typography.captionFontSystem)
                .foregroundColor(Theme.Colors.textSecondary)
            
            // Custom weekday selection UI with more visual appeal
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 7), spacing: 10) {
                ForEach(0..<7) { dayIndex in
                    let isSelected = recurrenceDaysOfWeek.contains(dayIndex)
                    let dayName = getDayShortName(dayIndex)
                    
                    Button {
                        toggleWeekday(dayIndex)
                    } label: {
                        VStack(spacing: 2) {
                            Text(dayName)
                                .font(.system(size: 14, weight: isSelected ? .bold : .regular))
                                .frame(width: 36, height: 36)
                                .background(
                                    ZStack {
                                        if isSelected {
                                            Circle()
                                                .fill(
                                                    LinearGradient(
                                                        colors: [Theme.Colors.secondary, Theme.Colors.secondary.opacity(0.8)],
                                                        startPoint: .top,
                                                        endPoint: .bottom
                                                    )
                                                )
                                                .shadow(color: Theme.Colors.secondary.opacity(0.4), radius: 3, x: 0, y: 2)
                                        } else {
                                            Circle()
                                                .fill(Theme.Colors.cardBackground)
                                                .shadow(color: Color.black.opacity(0.05), radius: 1, x: 0, y: 1)
                                        }
                                    }
                                )
                                .foregroundColor(isSelected ? .white : Theme.Colors.text)
                                .overlay(
                                    Circle()
                                        .stroke(Theme.Colors.secondary.opacity(0.4), lineWidth: isSelected ? 0 : 1)
                                )
                        }
                        .scaleEffect(isSelected ? 1.05 : 1.0)
                        .animation(.spring(response: 0.2), value: isSelected)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(.vertical, 10)
            
            // Warning if no days selected
            if recurrenceDaysOfWeek.isEmpty {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 14))
                        .foregroundColor(Theme.Colors.error.opacity(0.7))
                    
                    Text("Please select at least one day")
                        .font(Theme.Typography.captionFontSystem)
                        .foregroundColor(Theme.Colors.error)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Theme.Colors.error.opacity(0.1))
                )
                .padding(.top, 4)
            }
        }
    }
    
    private var monthlyRecurrenceView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("On which day of the month?")
                .font(Theme.Typography.captionFontSystem)
                .foregroundColor(Theme.Colors.textSecondary)
            
            // Custom month day selector with Menu
            Menu {
                Button {
                    recurrenceDayOfMonth = nil
                } label: {
                    Label("Same day as first occurrence", systemImage: "calendar")
                }
                
                Divider()
                
                ForEach(Array(stride(from: 1, through: 28, by: 1)), id: \.self) { day in
                    Button {
                        recurrenceDayOfMonth = day
                    } label: {
                        HStack {
                            if recurrenceDayOfMonth == day {
                                Image(systemName: "checkmark")
                            }
                            Text("\(day)\(daySuffix(day))")
                        }
                    }
                }
            } label: {
                // Custom month day selector
                ZStack {
                    RoundedRectangle(cornerRadius: Theme.Dimensions.cornerRadiusSmall)
                        .fill(Theme.Colors.cardBackground)
                        .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
                    
                    VStack(spacing: 12) {
                        // Selected day display
                        HStack {
                            Image(systemName: "calendar.day.timeline.leading")
                                .foregroundColor(Theme.Colors.secondary)
                                .font(.system(size: 18))
                                .padding(.trailing, 4)
                            
                            Text(getDayOfMonthText())
                                .font(Theme.Typography.bodyFontSystem)
                                .foregroundColor(Theme.Colors.text)
                            
                            Spacer()
                            
                            Image(systemName: "chevron.up.chevron.down")
                                .foregroundColor(Theme.Colors.textSecondary)
                                .font(.system(size: 14))
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        
                        // Day grid (shown in compact form)
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 4) {
                            ForEach(1...14, id: \.self) { day in
                                Text("\(day)")
                                    .font(.system(size: 12))
                                    .frame(width: 24, height: 24)
                                    .background(
                                        Circle()
                                            .fill(recurrenceDayOfMonth == day ? Theme.Colors.secondary : Color.clear)
                                    )
                                    .foregroundColor(recurrenceDayOfMonth == day ? .white : Theme.Colors.textSecondary)
                                    .opacity(day > 12 ? 0.3 : 0.8)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.horizontal, 8)
                        .padding(.bottom, 8)
                    }
                }
                .contentShape(Rectangle())
            }
        }
    }
    
    // MARK: - Reusable Components
    
    /// Reusable card component for form sections
    struct SectionCardView<Content: View>: View {
        let title: String
        let systemImage: String
        var iconColor: Color = Theme.Colors.primary
        @Binding var isExpanded: Bool
        let content: () -> Content
        
        @State private var isRotating = false
        @State private var cardHover = false
        
        var body: some View {
            VStack(alignment: .leading, spacing: 0) {
                // Header
                HStack {
                    // Icon with background
                    ZStack {
                        Circle()
                            .fill(iconColor.opacity(0.15))
                            .frame(width: 36, height: 36)
                        
                        Image(systemName: systemImage)
                            .font(.system(size: 16))
                            .foregroundColor(iconColor)
                            .symbolEffect(.pulse, options: .repeating, value: cardHover)
                    }
                    
                    Text(title)
                        .font(Theme.Typography.subheadingFontSystem)
                        .foregroundColor(Theme.Colors.text)
                    
                    Spacer()
                    
                    // Expand/collapse button
                    Button {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            isExpanded.toggle()
                        }
                    } label: {
                        Image(systemName: "chevron.down")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(Theme.Colors.textSecondary)
                            .rotationEffect(.degrees(isExpanded ? 180 : 0))
                            .frame(width: 28, height: 28)
                            .background(
                                Circle()
                                    .fill(Color.black.opacity(isExpanded ? 0.05 : 0.03))
                            )
                    }
                }
                .padding(.vertical, 12)
                .padding(.horizontal, 16)
                .contentShape(Rectangle())
                .onTapGesture {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        isExpanded.toggle()
                    }
                    // Trigger hover effect briefly when tapped
                    withAnimation {
                        cardHover = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                            cardHover = false
                        }
                    }
                }
                
                // Divider
                Divider()
                    .opacity(isExpanded ? 0.6 : 0)
                    .padding(.horizontal, 16)
                
                // Content
                if isExpanded {
                    content()
                        .padding(.horizontal, 16)
                        .transition(.asymmetric(
                            insertion: .opacity.combined(with: .scale(scale: 0.95, anchor: .top)).animation(.spring(response: 0.35, dampingFraction: 0.7)),
                            removal: .opacity.combined(with: .scale(scale: 0.95, anchor: .top)).animation(.spring(response: 0.25, dampingFraction: 0.8))
                        ))
                }
            }
            .background(
                RoundedRectangle(cornerRadius: Theme.Dimensions.cornerRadiusMedium)
                    .fill(Theme.Colors.cardBackground)
                    .shadow(
                        color: Color.black.opacity(isExpanded ? 0.08 : 0.05),
                        radius: isExpanded ? 5 : 3,
                        x: 0,
                        y: isExpanded ? 3 : 2
                    )
            )
            .animation(.spring(response: 0.3), value: isExpanded)
        }
    }
    
    // MARK: - Helper Properties
    
    private var isFormValid: Bool {
        return !title.isEmpty
    }
    
    // MARK: - Helper Methods
    
    /// Creates the chore with all the configured parameters
    private func addChore() async {
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
    
    /// Get the day's suffix (st, nd, rd, th)
    private func daySuffix(_ day: Int) -> String {
        switch day {
        case 1, 21, 31: return "st"
        case 2, 22: return "nd"
        case 3, 23: return "rd"
        default: return "th"
        }
    }
    
    /// Get the short name of the day of the week
    private func getDayShortName(_ dayIndex: Int) -> String {
        let weekdays = ["Su", "Mo", "Tu", "We", "Th", "Fr", "Sa"]
        return weekdays[dayIndex]
    }
    
    /// Get the maximum interval based on recurrence type
    private func getMaxInterval() -> Int {
        switch recurrenceType {
        case .daily: return 30
        case .weekly: return 12
        case .monthly: return 12
        }
    }
    
    /// Toggle a weekday in the selection
    private func toggleWeekday(_ dayIndex: Int) {
        if recurrenceDaysOfWeek.contains(dayIndex) {
            recurrenceDaysOfWeek.removeAll { $0 == dayIndex }
        } else {
            recurrenceDaysOfWeek.append(dayIndex)
        }
    }
    
    /// Get the label for the interval (days, weeks, months)
    private var intervalLabel: String {
        switch recurrenceType {
        case .daily: return recurrenceInterval == 1 ? "day" : "days"
        case .weekly: return recurrenceInterval == 1 ? "week" : "weeks"
        case .monthly: return recurrenceInterval == 1 ? "month" : "months"
        }
    }
    
    /// Get the display text for the day of the month
    private func getDayOfMonthText() -> String {
        if let day = recurrenceDayOfMonth {
            return "\(day)\(daySuffix(day)) day of the month"
        } else {
            return "Same day as first occurrence"
        }
    }
    
    /// Get a color for a user based on their ID
    private func getUserColor(userId: String?) -> Color {
        guard let userId = userId else { return Theme.Colors.textSecondary }
        
        // Generate a consistent color based on user ID
        let colors: [Color] = [
            .blue, .green, .orange, .purple, .red, .pink, .teal
        ]
        
        let hash = abs(userId.hashValue)
        return colors[hash % colors.count]
    }
    
    /// Get the initials of the assigned user
    private func getUserInitials() -> String {
        guard let userId = assignedToUserId else { return "" }
        
        // Find the user in the available users
        if let user = availableUsers.first(where: { $0.id == userId }) {
            let components = user.name.components(separatedBy: " ")
            if components.count > 1 {
                return String(components[0].prefix(1)) + String(components[1].prefix(1))
            } else if let firstChar = user.name.first {
                return String(firstChar)
            }
        }
        
        return "??"
    }
    
    /// Get the display name of the assigned user
    private func getUserName() -> String {
        guard let userId = assignedToUserId else { return "Unassigned" }
        
        // Find the user in the available users
        if let user = availableUsers.first(where: { $0.id == userId }) {
            return user.name
        }
        
        return "Unknown User"
    }
    
    /// Load the members of the household
    private func loadHouseholdMembers() {
        // In a real app, this would fetch from a database
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
    
    /// Creates sample users for testing
    private func createSampleUsers() -> [User] {
        return [
            User(id: "user1",
                 name: "Jane Smith",
                 email: "jane@example.com"),
            User(id: "user2",
                 name: "John Doe", 
                 email: "john@example.com"),
            User(id: "user3",
                 name: "Alex Johnson",
                 email: "alex@example.com")
        ]
    }
    
    /// Binding for error alert
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
    
    /// Binding for recurrence end date
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
    
    private var endDateToggleView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Toggle(isOn: $hasRecurrenceEndDate) {
                HStack {
                    Image(systemName: "calendar.badge.clock")
                        .font(.system(size: 16))
                        .foregroundColor(Theme.Colors.secondary)
                    
                    Text("Set an end date")
                        .font(Theme.Typography.bodyFontSystem)
                }
            }
            .toggleStyle(SwitchToggleStyle(tint: Theme.Colors.secondary))
            
            if hasRecurrenceEndDate {
                DatePicker("", selection: recurrenceEndDateBinding(), displayedComponents: [.date])
                    .datePickerStyle(.compact)
                    .tint(Theme.Colors.secondary)
                    .padding(.vertical, 8)
                    .padding(.horizontal, 16)
                    .background(
                        RoundedRectangle(cornerRadius: Theme.Dimensions.cornerRadiusSmall)
                            .fill(Theme.Colors.cardBackground)
                            .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
                    )
            }
        }
        .padding(.vertical, 4)
    }
}
