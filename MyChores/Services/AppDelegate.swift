// AppDelegate.swift
// MyChores
//
// Created on 2025-05-02.
//

import SwiftUI
import FirebaseCore
import FirebaseMessaging
import UserNotifications

/// App Delegate for handling Firebase setup and push notifications
class AppDelegate: NSObject, UIApplicationDelegate, MessagingDelegate, UNUserNotificationCenterDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        // Configure Firebase
        FirebaseApp.configure()
        
        // Set up Messaging delegate
        Messaging.messaging().delegate = self
        
        // Set up notifications
        UNUserNotificationCenter.current().delegate = self
        
        // Request notification authorization
        let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
        UNUserNotificationCenter.current().requestAuthorization(
            options: authOptions,
            completionHandler: { granted, error in
                if granted {
                    print("Notification authorization granted")
                    DispatchQueue.main.async {
                        application.registerForRemoteNotifications()
                    }
                } else if let error = error {
                    print("Notification authorization denied: \(error.localizedDescription)")
                }
            }
        )
        
        return true
    }
    
    // MARK: - MessagingDelegate
    
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        print("Firebase registration token: \(String(describing: fcmToken))")
        
        // Store this token to Firestore for the current user
        if let token = fcmToken {
            Task{
                do{
                    try await UserService.shared.updateFCMToken(token)

                } catch {
                    print("UserService.shared.updateFCMToken(token) error: \(error)")
                }

            }
        }
    }
    
    // MARK: - UNUserNotificationCenterDelegate
    
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        // Show notification banner when the app is in the foreground
        completionHandler([.banner, .sound])
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse,
                                withCompletionHandler completionHandler: @escaping () -> Void) {
        // Handle notification tap
        let userInfo = response.notification.request.content.userInfo
        
        // Handle navigation based on notification type
        if let choreId = userInfo["choreId"] as? String {
            NotificationCenter.default.post(
                name: .didTapChoreNotification,
                object: nil,
                userInfo: ["choreId": choreId]
            )
        }
        
        completionHandler()
    }
    
    // MARK: - Remote Notifications
    
    func application(_ application: UIApplication,
                     didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        Messaging.messaging().apnsToken = deviceToken
    }
    
    func application(_ application: UIApplication,
                     didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("Failed to register for remote notifications: \(error.localizedDescription)")
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let didTapChoreNotification = Notification.Name("didTapChoreNotification")
}
