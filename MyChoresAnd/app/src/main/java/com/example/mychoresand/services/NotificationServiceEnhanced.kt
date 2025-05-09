package com.example.mychoresand.services

import android.Manifest
import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import androidx.core.app.ActivityCompat
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat
import androidx.core.content.ContextCompat
import com.example.mychoresand.MainActivity
import com.example.mychoresand.R
import com.example.mychoresand.models.Badge
import com.example.mychoresand.models.Chore
import com.google.firebase.functions.FirebaseFunctions
import com.google.firebase.functions.ktx.functions
import com.google.firebase.ktx.Firebase
import com.google.firebase.messaging.FirebaseMessaging
import kotlinx.coroutines.tasks.await
import java.util.Date

/**
 * Enhanced service handling push notifications and local notifications
 * Designed to match iOS implementation functionality
 */
class NotificationServiceEnhanced(private val context: Context) {
    companion object {
        const val CHANNEL_ID_CHORES = "chores_channel"
        const val CHANNEL_ID_BADGES = "badges_channel"
        const val CHANNEL_ID_REMINDERS = "reminders_channel"
        const val NOTIFICATION_ID_CHORE_DUE = 1000
        const val NOTIFICATION_ID_BADGE_EARNED = 2000
        
        // Permission request code for notifications
        const val NOTIFICATION_PERMISSION_REQUEST_CODE = 100
    }
    
    // Firebase Functions for server-side notifications
    private val functions = Firebase.functions
    
    init {
        createNotificationChannels()
    }
    
    /**
     * Initialize notification channels for Android 8.0+
     */
    fun createNotificationChannels() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val manager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            
            // Chores channel
            val choresChannel = NotificationChannel(
                CHANNEL_ID_CHORES,
                "Chores",
                NotificationManager.IMPORTANCE_HIGH
            ).apply {
                description = "Notifications for chore assignments and updates"
                enableVibration(true)
                enableLights(true)
            }
            
            // Badges channel
            val badgesChannel = NotificationChannel(
                CHANNEL_ID_BADGES,
                "Achievements",
                NotificationManager.IMPORTANCE_DEFAULT
            ).apply {
                description = "Notifications for earned badges and achievements"
                enableVibration(true)
                enableLights(true)
            }
            
            // Reminders channel
            val remindersChannel = NotificationChannel(
                CHANNEL_ID_REMINDERS,
                "Reminders",
                NotificationManager.IMPORTANCE_HIGH
            ).apply {
                description = "Reminders for chores that are due soon"
                enableVibration(true)
                enableLights(true)
            }
            
            // Create all channels
            manager.createNotificationChannels(listOf(choresChannel, badgesChannel, remindersChannel))
        }
    }
    
    /**
     * Request notification permissions for Android 13+ (similar to iOS implementation)
     */
    fun requestNotificationPermission() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            if (ContextCompat.checkSelfPermission(
                    context,
                    Manifest.permission.POST_NOTIFICATIONS
                ) != PackageManager.PERMISSION_GRANTED
            ) {
                // We need to request permission from an Activity
                // This is a placeholder - the actual request would be done from an Activity
                // ActivityCompat.requestPermissions(
                //     context as Activity,
                //     arrayOf(Manifest.permission.POST_NOTIFICATIONS),
                //     NOTIFICATION_PERMISSION_REQUEST_CODE
                // )
            }
        }
    }
    
    /**
     * Wrapper to maintain consistent naming with iOS implementation
     */
    fun requestAuthorization() {
        requestNotificationPermission()
    }
    
    /**
     * Schedule a reminder for a chore (both local and server-side)
     */
    fun scheduleChoreReminder(choreId: String, title: String, forUserId: String, dueDate: Date) {
        // First cancel any existing reminders
        cancelChoreReminder(choreId)
        
        // Schedule local notification
        scheduleLocalChoreReminder(choreId, title, dueDate)
        
        // Schedule server-side reminder
        scheduleServerChoreReminder(choreId, title, forUserId, dueDate)
    }
    
    /**
     * Schedule a local notification for a chore reminder
     */
    private fun scheduleLocalChoreReminder(choreId: String, title: String, dueDate: Date) {
        // Create pending intent for when notification is tapped
        val intent = Intent(context, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TASK
            putExtra("NOTIFICATION_TYPE", "chore")
            putExtra("CHORE_ID", choreId)
        }
        
        val pendingIntent = PendingIntent.getActivity(
            context,
            choreId.hashCode(),
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        
        // Build the notification
        val notification = NotificationCompat.Builder(context, CHANNEL_ID_REMINDERS)
            .setContentTitle("Chore Due Soon")
            .setContentText("Don't forget: $title")
            .setSmallIcon(R.drawable.ic_notification)
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .setCategory(NotificationCompat.CATEGORY_REMINDER)
            .setContentIntent(pendingIntent)
            .setAutoCancel(true)
            .build()
        
        // Schedule for delivery at appropriate time
        // For simplicity, we're sending it immediately
        // In a real app, you would use AlarmManager or WorkManager to schedule
        if (ActivityCompat.checkSelfPermission(
                context,
                Manifest.permission.POST_NOTIFICATIONS
            ) == PackageManager.PERMISSION_GRANTED
        ) {
            NotificationManagerCompat.from(context).notify(
                "chore-$choreId".hashCode(),
                notification
            )
        }
    }
    
    /**
     * Schedule a server-side reminder using Firebase Cloud Functions
     */
    private fun scheduleServerChoreReminder(choreId: String, title: String, forUserId: String, dueDate: Date) {
        val data = hashMapOf(
            "choreId" to choreId,
            "title" to title,
            "userId" to forUserId,
            "dueDate" to dueDate.time
        )
        
        functions.getHttpsCallable("scheduleChoreReminder")
            .call(data)
            .addOnSuccessListener { result ->
                // Reminder scheduled successfully on server
                println("Server reminder scheduled successfully: ${result.data}")
            }
            .addOnFailureListener { exception ->
                // Handle error
                println("Error scheduling server reminder: ${exception.message}")
            }
    }
    
    /**
     * Cancel reminders for a chore (both local and server-side)
     */
    fun cancelChoreReminder(choreId: String) {
        // Cancel local notification
        NotificationManagerCompat.from(context).cancel("chore-$choreId".hashCode())
        
        // Cancel server-side reminder
        val data = hashMapOf(
            "choreId" to choreId
        )
        
        functions.getHttpsCallable("cancelChoreReminder")
            .call(data)
            .addOnSuccessListener { result ->
                // Successfully canceled server reminder
                println("Server reminder canceled successfully: ${result.data}")
            }
            .addOnFailureListener { exception ->
                // Handle error
                println("Error canceling server reminder: ${exception.message}")
            }
    }
    
    /**
     * Send a badge earned notification
     */
    fun sendBadgeEarnedNotification(toUserId: String, badgeKey: String, badgeName: String) {
        // Create intent for when notification is tapped
        val intent = Intent(context, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TASK
            putExtra("NOTIFICATION_TYPE", "badge")
            putExtra("BADGE_KEY", badgeKey)
        }
        
        val pendingIntent = PendingIntent.getActivity(
            context,
            badgeKey.hashCode(),
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        
        // Build the notification
        val notification = NotificationCompat.Builder(context, CHANNEL_ID_BADGES)
            .setContentTitle("New Badge Earned! 🏆")
            .setContentText("Congratulations! You earned the $badgeName badge.")
            .setSmallIcon(R.drawable.ic_notification)
            .setPriority(NotificationCompat.PRIORITY_DEFAULT)
            .setCategory(NotificationCompat.CATEGORY_SOCIAL)
            .setContentIntent(pendingIntent)
            .setAutoCancel(true)
            .build()
        
        // Send notification if permission granted
        if (ActivityCompat.checkSelfPermission(
                context,
                Manifest.permission.POST_NOTIFICATIONS
            ) == PackageManager.PERMISSION_GRANTED
        ) {
            NotificationManagerCompat.from(context).notify(
                "badge-$badgeKey".hashCode(),
                notification
            )
        }
    }
    
    /**
     * Send a chore assigned notification
     */
    fun sendChoreAssignedNotification(toUserId: String, choreId: String, choreTitle: String) {
        // Create intent for when notification is tapped
        val intent = Intent(context, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TASK
            putExtra("NOTIFICATION_TYPE", "chore")
            putExtra("CHORE_ID", choreId)
        }
        
        val pendingIntent = PendingIntent.getActivity(
            context,
            choreId.hashCode(),
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        
        // Build the notification
        val notification = NotificationCompat.Builder(context, CHANNEL_ID_CHORES)
            .setContentTitle("New Chore Assigned")
            .setContentText("You've been assigned: $choreTitle")
            .setSmallIcon(R.drawable.ic_notification)
            .setPriority(NotificationCompat.PRIORITY_DEFAULT)
            .setCategory(NotificationCompat.CATEGORY_REMINDER)
            .setContentIntent(pendingIntent)
            .setAutoCancel(true)
            .build()
        
        // Send notification if permission granted
        if (ActivityCompat.checkSelfPermission(
                context,
                Manifest.permission.POST_NOTIFICATIONS
            ) == PackageManager.PERMISSION_GRANTED
        ) {
            NotificationManagerCompat.from(context).notify(
                "chore-assigned-$choreId".hashCode(),
                notification
            )
        }
    }
    
    /**
     * Set the badge count for the app icon
     * Note: Not all Android launchers support this feature
     */
    fun setBadgeCount(count: Int) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val manager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            manager.getNotificationChannel(CHANNEL_ID_REMINDERS)?.let { channel ->
                // Some launchers check this badge number
                // But there's no standardized way to set badge counts on all Android devices
                // This is a simplification - actual implementation varies by device manufacturer
            }
        }
    }
}
