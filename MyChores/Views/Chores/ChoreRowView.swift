// ChoreRowView.swift
// MyChores
//
// Created on 2025-05-02.
// Enhanced on 2025-05-14.
//

import SwiftUI
import FirebaseFirestore

/// Row view for a single chore in the list
struct ChoreRowView: View {
    // MARK: - Properties
    
    let chore: Chore
    @Environment(\.colorScheme) private var colorScheme
    @State private var assignedUserName: String = "Loading..."
    @State private var showDetails = false
    
    // MARK: - Body
    
    var body: some View {
        VStack(spacing: 0) {
            // Card content
            VStack(spacing: 0) {
                // Title row with status circle - Always visible
                HStack(alignment: .center, spacing: 12) {
                    // Status circle with icon
                    ZStack {
                        Circle()
                            .fill(statusColor.opacity(0.15))
                            .frame(width: 36, height: 36)
                        
                        Circle()
                            .fill(statusColor)
                            .frame(width: 28, height: 28)
                        
                        if chore.isCompleted {
                            Image(systemName: "checkmark")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.white)
                                .transition(.scale.combined(with: .opacity))
                        } else if chore.isOverdue {
                            Image(systemName: "exclamationmark")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.white)
                                .transition(.scale.combined(with: .opacity))
                        } else {
                            Image(systemName: "checklist")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.white)
                                .transition(.scale.combined(with: .opacity))
                        }
                    }
                    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: chore.isCompleted)
                    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: chore.isOverdue)
                    
                    // Title and points
                    VStack(alignment: .leading, spacing: 2) {
                        Text(chore.title)
                            .font(Theme.Typography.bodyFontSystem.weight(.medium))
                            .foregroundColor(Theme.Colors.text)
                            .lineLimit(1)
                            .strikethrough(chore.isCompleted)
                        
                        if let dueDate = chore.dueDate {
                            Text(formatDate(dueDate))
                                .font(Theme.Typography.captionFontSystem)
                                .foregroundColor(dueDateColor)
                        }
                    }
                    
                    Spacer()
                    
                    // Points badge
                    ZStack {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Theme.Colors.accent.opacity(0.15))
                            .frame(width: 50, height: 24)
                        
                        HStack(spacing: 4) {
                            Image(systemName: "star.fill")
                                .foregroundColor(Theme.Colors.accent)
                                .font(.system(size: 10))
                            
                            Text("\(chore.pointValue)pts")
                                .font(.system(size: 12, weight: .semibold, design: .rounded))
                                .foregroundColor(Theme.Colors.accent)
                        }
                    }
                    
                    // Expand/collapse button
                    Button {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            showDetails.toggle()
                        }
                    } label: {
                        Image(systemName: showDetails ? "chevron.up" : "chevron.down")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(Theme.Colors.textSecondary)
                            .frame(width: 24, height: 24)
                            .background(Theme.Colors.cardBackground)
                            .clipShape(Circle())
                            .overlay(
                                Circle()
                                    .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                            )
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 12)
                
                // Details section - Only visible when expanded
                if showDetails {
                    VStack(spacing: 8) {
                        Divider()
                            .padding(.horizontal, 12)
                        
                        // Description if available
                        if !chore.description.isEmpty {
                            HStack(alignment: .top, spacing: 10) {
                                Image(systemName: "doc.text")
                                    .foregroundColor(Theme.Colors.textSecondary)
                                    .frame(width: 20)
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Description")
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundColor(Theme.Colors.textSecondary)
                                    
                                    Text(chore.description)
                                        .font(Theme.Typography.bodyFontSystem)
                                        .foregroundColor(Theme.Colors.text)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                                
                                Spacer()
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 4)
                        }
                        
                        // Assigned to
                        HStack(spacing: 10) {
                            Image(systemName: "person.fill")
                                .foregroundColor(Theme.Colors.textSecondary)
                                .frame(width: 20)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Assigned to")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(Theme.Colors.textSecondary)
                                
                                Text(assignedUserName)
                                    .font(Theme.Typography.bodyFontSystem)
                                    .foregroundColor(Theme.Colors.text)
                            }
                            
                            Spacer()
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 4)
                        
                        // Recurrence pattern if this is a recurring chore
                        if chore.isRecurring {
                            HStack(spacing: 10) {
                                Image(systemName: "repeat")
                                    .foregroundColor(Theme.Colors.textSecondary)
                                    .frame(width: 20)
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Repeats")
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundColor(Theme.Colors.textSecondary)
                                    
                                    Text(recurrenceText)
                                        .font(Theme.Typography.bodyFontSystem)
                                        .foregroundColor(Theme.Colors.text)
                                }
                                
                                Spacer()
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 4)
                        }
                        
                        // Spacing at the bottom
                        Spacer()
                            .frame(height: 4)
                    }
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
        }
        .onAppear {
            // Load assigned user name if available
            loadAssignedUserName()
        }
    }
    
    // MARK: - Helper Properties
    
    private var statusColor: Color {
        if chore.isCompleted {
            return Theme.Colors.success
        } else if chore.isOverdue {
            return Theme.Colors.error
        } else {
            return Theme.Colors.primary
        }
    }
    
    private var dueDateColor: Color {
        if chore.isCompleted {
            return Theme.Colors.textSecondary
        } else if chore.isOverdue {
            return Theme.Colors.error
        } else if let dueDate = chore.dueDate, Calendar.current.isDateInTomorrow(dueDate) {
            return Theme.Colors.secondary
        } else {
            return Theme.Colors.textSecondary
        }
    }
    
    private var recurrenceText: String {
        guard let recurrenceType = chore.recurrenceType else { return "Not recurring" }
        
        switch recurrenceType {
        case .daily:
            return "Daily"
        case .weekly:
            return "Weekly"
        case .monthly:
            return "Monthly"
        }
    }
    
    // MARK: - Helper Methods
    
    private func formatDate(_ date: Date) -> String {
        if Calendar.current.isDateInToday(date) {
            return "Due Today"
        } else if Calendar.current.isDateInTomorrow(date) {
            return "Due Tomorrow"
        } else if date < Date() {
            return "Overdue: \(date.relativeFormatted())"
        } else {
            return "Due \(date.relativeFormatted())"
        }
    }
    
    private func loadAssignedUserName() {
        guard let assignedToUserId = chore.assignedToUserId else {
            assignedUserName = "Unassigned"
            return
        }
        
        let db = Firestore.firestore()
        db.collection("users").document(assignedToUserId).getDocument { snapshot, error in
            guard let userData = snapshot?.data(),
                  let name = userData["name"] as? String else {
                DispatchQueue.main.async {
                    self.assignedUserName = "Unknown User"
                }
                return
            }
            
            DispatchQueue.main.async {
                self.assignedUserName = name
            }
        }
    }
}

#Preview {
    ChoreRowView(chore: Chore.samples.first!)
        .padding()
        .background(Theme.Colors.background)
}
