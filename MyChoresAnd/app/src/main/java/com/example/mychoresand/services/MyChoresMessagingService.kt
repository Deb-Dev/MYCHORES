package com.example.mychoresand.services

import android.util.Log
import com.example.mychoresand.di.AppContainer
import com.google.firebase.messaging.FirebaseMessagingService
import com.google.firebase.messaging.RemoteMessage
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch

/**
 * Service for handling FCM messages for chore reminders and badge notifications
 */
class MyChoresMessagingService : FirebaseMessagingService() {
    
    private val tag = "FCM_Service"
    
    override fun onMessageReceived(message: RemoteMessage) {
        super.onMessageReceived(message)
        
        Log.d(tag, "Message received from: ${message.from}")
        
        // Handle data payload
        message.data.let { data ->
            Log.d(tag, "Message data: $data")
            
            when (data["type"]) {
                "chore_reminder" -> {
                    val choreId = data["choreId"] ?: return
                    val title = data["title"] ?: "Chore Reminder"
                    
                    // Fetch the chore details and show notification
                    CoroutineScope(Dispatchers.IO).launch {
                        AppContainer.choreService.getChore(choreId).collect { chore ->
                            chore?.let {
                                AppContainer.notificationService.showChoreDueNotification(it)
                            }
                        }
                    }
                }
                
                "badge_earned" -> {
                    val badgeKey = data["badgeKey"] ?: return
                    AppContainer.notificationService.showBadgeEarnedNotification(badgeKey)
                }
            }
        }
        
        // Handle notification payload
        message.notification?.let { notification ->
            Log.d(tag, "Notification: ${notification.title} - ${notification.body}")
            // The system already shows these notifications automatically
        }
    }
    
    override fun onNewToken(token: String) {
        super.onNewToken(token)
        Log.d(tag, "New FCM token: $token")
        
        // Update the token in Firestore for the current user
        CoroutineScope(Dispatchers.IO).launch {
            try {
                AppContainer.authService.updateFcmToken()
            } catch (e: Exception) {
                Log.e(tag, "Failed to update FCM token: ${e.message}")
            }
        }
    }
}
