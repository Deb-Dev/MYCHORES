// NotificationService.swift
// MyChores
//
// Created on 2025-05-02.
//

import Foundation
import UserNotifications
import FirebaseFirestore
import FirebaseAuth
import FirebaseFunctions

/// Service for managing push notifications and reminders
class NotificationService {
    // MARK: - Shared Instance
    
    /// Shared instance for singleton access
    static let shared = NotificationService()
    
    // MARK: - Private Properties
    
    /// Firestore database reference
    private let db = Firestore.firestore()
    
    /// Firebase Cloud Functions reference
    private lazy var functions = Functions.functions()
    
    // MARK: - Initialization
    
    /// Private initializer to enforce singleton pattern
    private init() {
        requestNotificationPermission()
    }
    
    // MARK: - Notification Methods
    
    /// Request permission to send notifications
    func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            if granted {
                print("Notification permission granted")
            } else if let error = error {
                print("Notification permission error: \(error.localizedDescription)")
            }
        }
    }
    
    /// Schedule a reminder for a chore
    /// - Parameters:
    ///   - choreId: Chore ID
    ///   - title: Chore title
    ///   - forUserId: User ID to send reminder to
    ///   - dueDate: Due date for the chore
    func scheduleChoreReminder(choreId: String, title: String, forUserId: String, dueDate: Date) {
        // Cancel any existing reminders
        cancelChoreReminder(choreId: choreId)
        
        // First, schedule a local notification
        scheduleLocalChoreReminder(choreId: choreId, title: title, dueDate: dueDate)
        
        // Then, schedule a server-side reminder (for when app is closed)
        scheduleServerChoreReminder(choreId: choreId, title: title, forUserId: forUserId, dueDate: dueDate)
    }
    
    /// Cancel reminders for a chore
    /// - Parameter choreId: Chore ID
    func cancelChoreReminder(choreId: String) {
        // Cancel local notification
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["chore-\(choreId)"])
        
        // Cancel cloud function reminder (if any)
        let data: [String: Any] = [
            "choreId": choreId
        ]
        
        functions.httpsCallable("cancelChoreReminder").call(data) { result, error in
            if let error = error {
                print("Error canceling server reminder: \(error.localizedDescription)")
            }
        }
    }
    
    /// Send a badge earned notification
    /// - Parameters:
    ///   - userId: User ID to notify
    ///   - badgeKey: Badge key
    func sendBadgeEarnedNotification(toUserId userId: String, badgeKey: String) {
        guard let badge = Badge.getBadge(byKey: badgeKey) else { return }
        
        // Create a local notification
        let content = UNMutableNotificationContent()
        content.title = "New Badge Earned! 🏆"
        content.body = "Congratulations! You earned the \(badge.name) badge."
        content.sound = .default
        
        let request = UNNotificationRequest(
            identifier: "badge-\(badgeKey)-\(UUID().uuidString)",
            content: content,
            trigger: UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error sending badge notification: \(error.localizedDescription)")
            }
        }
        
        // Also send a server notification (for when app is closed)
        let data: [String: Any] = [
            "userId": userId,
            "badgeKey": badgeKey,
            "badgeName": badge.name
        ]
        
        functions.httpsCallable("sendBadgeEarnedNotification").call(data) { result, error in
            if let error = error {
                print("Error sending server badge notification: \(error.localizedDescription)")
            }
        }
    }
    
    // MARK: - Helper Methods
    
    /// Schedule a local notification for a chore
    /// - Parameters:
    ///   - choreId: Chore ID
    ///   - title: Chore title
    ///   - dueDate: Due date
    private func scheduleLocalChoreReminder(choreId: String, title: String, dueDate: Date) {
        let content = UNMutableNotificationContent()
        content.title = "Chore Reminder"
        content.body = "Don't forget to \(title)"
        content.sound = .default
        content.userInfo = ["choreId": choreId]
        
        // Calculate time interval until due date and also create a 1-hour advance notice
        let advanceNoticeDuration: TimeInterval = 3600 // 1 hour in seconds
        let timeUntilDue = dueDate.timeIntervalSinceNow
        
        if timeUntilDue <= 0 {
            // Already due, send immediately
            let request = UNNotificationRequest(
                identifier: "chore-\(choreId)",
                content: content,
                trigger: UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
            )
            
            UNUserNotificationCenter.current().add(request) { error in
                if let error = error {
                    print("Error scheduling notification: \(error.localizedDescription)")
                }
            }
        } else {
            // Schedule an advance notice if there's enough time
            if timeUntilDue > advanceNoticeDuration {
                let advanceContent = content.copy() as! UNMutableNotificationContent
                advanceContent.title = "Upcoming Chore"
                advanceContent.body = "You have a chore \"\(title)\" due in 1 hour"
                
                let advanceRequest = UNNotificationRequest(
                    identifier: "chore-advance-\(choreId)",
                    content: advanceContent,
                    trigger: UNTimeIntervalNotificationTrigger(timeInterval: timeUntilDue - advanceNoticeDuration, repeats: false)
                )
                
                UNUserNotificationCenter.current().add(advanceRequest) { error in
                    if let error = error {
                        print("Error scheduling advance notification: \(error.localizedDescription)")
                    }
                }
            }
            
            // Schedule notification at due time
            let dueRequest = UNNotificationRequest(
                identifier: "chore-\(choreId)",
                content: content,
                trigger: UNTimeIntervalNotificationTrigger(timeInterval: timeUntilDue, repeats: false)
            )
            
            UNUserNotificationCenter.current().add(dueRequest) { error in
                if let error = error {
                    print("Error scheduling due notification: \(error.localizedDescription)")
                }
            }
        }
    }
    
    /// Schedule a server-side reminder (using Cloud Functions)
    /// - Parameters:
    ///   - choreId: Chore ID
    ///   - title: Chore title
    ///   - forUserId: User ID to notify
    ///   - dueDate: Due date
    private func scheduleServerChoreReminder(choreId: String, title: String, forUserId: String, dueDate: Date) {
        let data: [String: Any] = [
            "choreId": choreId,
            "choreTitle": title,
            "userId": forUserId,
            "dueDate": Timestamp(date: dueDate)
        ]
        
        functions.httpsCallable("scheduleChoreReminder").call(data) { result, error in
            if let error = error {
                print("Error scheduling server reminder: \(error.localizedDescription)")
            }
        }
    }
}
