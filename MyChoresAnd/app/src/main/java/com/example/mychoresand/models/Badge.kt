package com.example.mychoresand.models

import com.google.firebase.firestore.DocumentId

/**
 * Represents an achievement badge that users can earn
 */
data class Badge(
    @DocumentId var id: String? = null,
    var badgeKey: String = "",
    var name: String = "",
    var description: String = "",
    var iconName: String = "",
    var colorName: String = "",
    var requiredTaskCount: Int? = null
) {
    companion object {
        /**
         * Standard badges available in the app
         */
        val predefinedBadges = listOf(
            Badge(
                badgeKey = "first_chore",
                name = "First Step",
                description = "Completed your first chore",
                iconName = "check_circle",
                colorName = "primary",
                requiredTaskCount = 1
            ),
            Badge(
                badgeKey = "ten_chores",
                name = "Getting Things Done",
                description = "Completed 10 chores",
                iconName = "verified",
                colorName = "secondary",
                requiredTaskCount = 10
            ),
            Badge(
                badgeKey = "fifty_chores",
                name = "Task Master",
                description = "Completed 50 chores",
                iconName = "workspace_premium",
                colorName = "accent",
                requiredTaskCount = 50
            )
        )
        
        /**
         * Get a predefined badge by its key
         */
        fun getBadge(byKey: String): Badge? {
            return predefinedBadges.firstOrNull { it.badgeKey == byKey }
        }
    }
}
