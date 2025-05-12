package com.example.mychoresand.models

import com.google.firebase.Timestamp
import com.google.firebase.firestore.DocumentId
import com.google.firebase.firestore.PropertyName
import java.util.Date
import java.util.UUID

/**
 * Represents a user in the app
 */
data class User(
    @DocumentId var id: String? = null,
    var name: String = "",
    var email: String = "",
    var photoURL: String? = null,
    var householdIds: List<String> = emptyList(),
    var fcmToken: String? = null,
    var createdAt: Date = Date(),
    var updatedAt: Date = Date(),
    var totalPoints: Int = 0,
    var weeklyPoints: Int = 0,
    var monthlyPoints: Int = 0,
    var currentWeekStartDate: Date? = null,
    var currentMonthStartDate: Date? = null,
    var completedChoreIds: List<String> = emptyList(),
    var earnedBadgeIds: List<String> = emptyList(),
    var privacySettings: UserPrivacySettings = UserPrivacySettings()
) {
    /**
     * User's display name for UI
     */
    val displayName: String
        get() = name.ifEmpty { email.substringBefore('@') }

    /**
     * Stable ID for view identification when DocumentID might be nil
     */
    val stableId: String
        get() = id ?: UUID.randomUUID().toString()

    /**
     * Force set the ID when it's missing
     * This is needed because DocumentID can't be set directly
     * @param newId The ID to set
     */
    fun forceSetId(newId: String) {
        this.id = newId
    }

    companion object {
        // Sample user for preview and testing
        val sample = User(
            id = "sample_user_id",
            name = "John Doe",
            email = "john@example.com",
            photoURL = null,
            householdIds = listOf("sample_household_id"),
            fcmToken = "sample_fcm_token",
            createdAt = Date(),
            updatedAt = Date(),
            totalPoints = 120,
            weeklyPoints = 25,
            monthlyPoints = 75,
            currentWeekStartDate = com.example.mychoresand.utils.DateTimeUtils.getWeekStartDate(Date()),
            currentMonthStartDate = com.example.mychoresand.utils.DateTimeUtils.getMonthStartDate(Date()),
            completedChoreIds = emptyList(),
            earnedBadgeIds = listOf("first_chore", "ten_chores"),
            privacySettings = UserPrivacySettings(
                showProfile = true, 
                showAchievements = true,
                shareActivity = true
            )
        )
    }
}

/**
 * User privacy settings
 */
data class UserPrivacySettings(
    var showProfile: Boolean = true,
    var showAchievements: Boolean = true,
    var shareActivity: Boolean = true
)
