package com.example.mychoresand.services

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
import com.example.mychoresand.models.Badge
import com.example.mychoresand.models.Chore
import com.google.firebase.messaging.FirebaseMessaging
import kotlinx.coroutines.tasks.await

/**
 * Service handling push notifications and local notifications
 */
class NotificationService(private val context: Context) {
    companion object {
        const val CHANNEL_ID_CHORES = "chores_channel"
        const val CHANNEL_ID_BADGES = "badges_channel"
        const val NOTIFICATION_ID_CHORE_DUE = 1000
        const val NOTIFICATION_ID_BADGE_EARNED = 2000
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
                description = "Reminders for chores that are due soon"
            }
            
            // Badges channel
            val badgesChannel = NotificationChannel(
                CHANNEL_ID_BADGES,
                "Achievements",
                NotificationManager.IMPORTANCE_DEFAULT
            ).apply {
                description = "Notifications for earned badges and achievements"
            }
            
            manager.createNotificationChannels(listOf(choresChannel, badgesChannel))
        }
    }
    
    /**
     * Subscribe to FCM topics for notifications
     * @return Result indicating success or failure
     */
    suspend fun subscribeToNotifications(): Result<Unit> {
        return try {
            FirebaseMessaging.getInstance().subscribeToTopic("chore_reminders").await()
            Result.success(Unit)
        } catch (e: Exception) {
            Result.failure(e)
        }
    }
    
    /**
     * Show a notification for a chore that is due soon
     * @param chore The chore that's due
     */
    fun showChoreDueNotification(chore: Chore) {
        val intent = Intent(context, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TASK
            putExtra("CHORE_ID", chore.id)
        }
        
        val pendingIntent = PendingIntent.getActivity(
            context, 0, intent,
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT
        )
        
        val notification = NotificationCompat.Builder(context, CHANNEL_ID_CHORES)
            .setSmallIcon(R.drawable.ic_notification) // You'll need to create this icon
            .setContentTitle("Chore Due")
            .setContentText("Reminder: '${chore.title}' is due now")
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .setContentIntent(pendingIntent)
            .setAutoCancel(true)
            .build()
        
        try {
            NotificationManagerCompat.from(context).notify(
                NOTIFICATION_ID_CHORE_DUE + (chore.id?.hashCode() ?: 0) % 1000,
                notification
            )
        } catch (e: SecurityException) {
            // Handle missing notification permission
        }
    }
    
    /**
     * Show a notification for a badge that was earned
     * @param badgeKey The key of the earned badge
     */
    fun showBadgeEarnedNotification(badgeKey: String) {
        val badge = Badge.getBadge(byKey = badgeKey) ?: return
        
        val intent = Intent(context, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TASK
            putExtra("SHOW_BADGES", true)
        }
        
        val pendingIntent = PendingIntent.getActivity(
            context, 0, intent, 
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT
        )
        
        val notification = NotificationCompat.Builder(context, CHANNEL_ID_BADGES)
            .setSmallIcon(R.drawable.ic_badge) // You'll need to create this icon
            .setContentTitle("Achievement Unlocked!")
            .setContentText("You earned the '${badge.name}' badge")
            .setStyle(NotificationCompat.BigTextStyle()
                .bigText("Congratulations! You earned the '${badge.name}' badge: ${badge.description}"))
            .setPriority(NotificationCompat.PRIORITY_DEFAULT)
            .setContentIntent(pendingIntent)
            .setAutoCancel(true)
            .build()
        
        try {
            NotificationManagerCompat.from(context).notify(
                NOTIFICATION_ID_BADGE_EARNED + badgeKey.hashCode() % 1000,
                notification
            )
        } catch (e: SecurityException) {
            // Handle missing notification permission
        }
    }
}
