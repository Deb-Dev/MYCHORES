package com.example.mychoresand.utils

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.os.Build
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat
import com.example.mychoresand.MainActivity
import com.example.mychoresand.R

/**
 * Utility class for local notification management
 */
object NotificationUtils {
    
    private const val CHANNEL_ID = "mychores_notifications"
    private const val CHANNEL_NAME = "MyChores Notifications"
    private const val CHANNEL_DESCRIPTION = "Notifications for chores and updates"
    
    private const val CHORE_DUE_NOTIFICATION_ID = 1001
    private const val CHORE_ASSIGNED_NOTIFICATION_ID = 1002
    private const val ACHIEVEMENT_NOTIFICATION_ID = 1003
    
    /**
     * Create the notification channel (required for Android 8.0+)
     */
    fun createNotificationChannel(context: Context) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val importance = NotificationManager.IMPORTANCE_DEFAULT
            val channel = NotificationChannel(CHANNEL_ID, CHANNEL_NAME, importance).apply {
                description = CHANNEL_DESCRIPTION
            }
            
            val notificationManager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            notificationManager.createNotificationChannel(channel)
        }
    }
    
    /**
     * Show a notification for a chore that is due
     */
    fun showChoreDueNotification(
        context: Context,
        choreId: String,
        choreTitle: String
    ) {
        // Create an intent that opens the app
        val intent = Intent(context, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TASK
            putExtra("NAVIGATE_TO_CHORE", choreId)
        }
        
        val pendingIntent = PendingIntent.getActivity(
            context, 
            0, 
            intent, 
            PendingIntent.FLAG_IMMUTABLE
        )
        
        // Build the notification
        val builder = NotificationCompat.Builder(context, CHANNEL_ID)
            .setSmallIcon(R.drawable.ic_notification) // Make sure this icon exists in the resources
            .setContentTitle("Chore Due")
            .setContentText("Your chore '$choreTitle' is due now.")
            .setPriority(NotificationCompat.PRIORITY_DEFAULT)
            .setContentIntent(pendingIntent)
            .setAutoCancel(true)
        
        // Show the notification
        with(NotificationManagerCompat.from(context)) {
            notify(CHORE_DUE_NOTIFICATION_ID, builder.build())
        }
    }
    
    /**
     * Show a notification for a newly assigned chore
     */
    fun showChoreAssignedNotification(
        context: Context,
        choreId: String,
        choreTitle: String,
        assignedByName: String
    ) {
        val intent = Intent(context, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TASK
            putExtra("NAVIGATE_TO_CHORE", choreId)
        }
        
        val pendingIntent = PendingIntent.getActivity(
            context, 
            0, 
            intent, 
            PendingIntent.FLAG_IMMUTABLE
        )
        
        val builder = NotificationCompat.Builder(context, CHANNEL_ID)
            .setSmallIcon(R.drawable.ic_notification)
            .setContentTitle("New Chore Assigned")
            .setContentText("$assignedByName assigned you a new chore: $choreTitle")
            .setPriority(NotificationCompat.PRIORITY_DEFAULT)
            .setContentIntent(pendingIntent)
            .setAutoCancel(true)
        
        with(NotificationManagerCompat.from(context)) {
            notify(CHORE_ASSIGNED_NOTIFICATION_ID, builder.build())
        }
    }
    
    /**
     * Show a notification for a newly earned achievement
     */
    fun showAchievementNotification(
        context: Context,
        badgeName: String
    ) {
        val intent = Intent(context, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TASK
            putExtra("NAVIGATE_TO_ACHIEVEMENTS", true)
        }
        
        val pendingIntent = PendingIntent.getActivity(
            context, 
            0, 
            intent, 
            PendingIntent.FLAG_IMMUTABLE
        )
        
        val builder = NotificationCompat.Builder(context, CHANNEL_ID)
            .setSmallIcon(R.drawable.ic_notification)
            .setContentTitle("Achievement Unlocked!")
            .setContentText("Congratulations! You earned the $badgeName badge.")
            .setPriority(NotificationCompat.PRIORITY_DEFAULT)
            .setContentIntent(pendingIntent)
            .setAutoCancel(true)
        
        with(NotificationManagerCompat.from(context)) {
            notify(ACHIEVEMENT_NOTIFICATION_ID, builder.build())
        }
    }
}
