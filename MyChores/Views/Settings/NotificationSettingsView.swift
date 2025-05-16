// NotificationSettingsView.swift
// MyChores
//
// Created on 2025-05-16.
//

import SwiftUI
import Foundation
import UIKit

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

#Preview {
    NotificationSettingsView()
}
